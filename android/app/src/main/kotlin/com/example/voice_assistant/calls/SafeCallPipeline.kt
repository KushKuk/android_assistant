package com.example.voice_assistant.calls

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.telephony.PhoneNumberUtils
import com.example.voice_assistant.contacts.ContactResolver
import java.util.UUID

enum class CallExecutionStatus {
    confirmationRequired,
    numberSelectionRequired,
    permissionRequired,
    confirmationDeclined,
    calling,
    invalidTarget,
    contactNotFound,
    contactNumberMismatch,
    expiredConfirmation,
    callFailed,
}

data class CallExecutionResult(
    val status: CallExecutionStatus,
    val message: String,
    val confirmationToken: String? = null,
    val displayName: String? = null,
    val phoneNumber: String? = null,
    val availableNumbers: List<String> = emptyList(),
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "status" to status.name,
        "message" to message,
        "confirmationToken" to confirmationToken,
        "displayName" to displayName,
        "phoneNumber" to phoneNumber,
        "availableNumbers" to availableNumbers,
    )
}

class SafeCallPipeline(
    private val activity: Activity,
    private val contactResolver: ContactResolver,
) {
    private val pendingCalls = mutableMapOf<String, PendingCall>()

    fun prepare(request: CallRequest): CallExecutionResult {
        val target = if (request.contactId == null) {
            directTarget(request)
        } else {
            contactTarget(request)
        }
        if (target is TargetResolution.Failure) return target.result
        target as TargetResolution.Success

        val token = UUID.randomUUID().toString()
        pendingCalls[token] = PendingCall(target.displayName, target.phoneNumber, System.currentTimeMillis())
        return CallExecutionResult(
            status = CallExecutionStatus.confirmationRequired,
            message = "Confirm call to ${target.displayName}.",
            confirmationToken = token,
            displayName = target.displayName,
            phoneNumber = target.phoneNumber,
        )
    }

    fun confirm(confirmationToken: String, confirmed: Boolean, hasCallPermission: Boolean): CallExecutionResult {
        val pendingCall = pendingCalls[confirmationToken] ?: return CallExecutionResult(
            CallExecutionStatus.expiredConfirmation,
            "This call confirmation is no longer available.",
        )
        if (System.currentTimeMillis() - pendingCall.createdAtMillis > CONFIRMATION_TIMEOUT_MILLIS) {
            pendingCalls.remove(confirmationToken)
            return CallExecutionResult(CallExecutionStatus.expiredConfirmation, "This call confirmation expired.")
        }
        if (!confirmed) {
            pendingCalls.remove(confirmationToken)
            return CallExecutionResult(
                CallExecutionStatus.confirmationDeclined,
                "Call to ${pendingCall.displayName} was cancelled.",
                displayName = pendingCall.displayName,
                phoneNumber = pendingCall.phoneNumber,
            )
        }
        if (!hasCallPermission) {
            return CallExecutionResult(
                CallExecutionStatus.permissionRequired,
                "Phone permission is required to place this call.",
                confirmationToken = confirmationToken,
                displayName = pendingCall.displayName,
                phoneNumber = pendingCall.phoneNumber,
            )
        }
        pendingCalls.remove(confirmationToken)
        return CallExecutor(activity).execute(pendingCall.displayName, pendingCall.phoneNumber)
    }

    private fun directTarget(request: CallRequest): TargetResolution {
        val number = request.phoneNumber ?: return TargetResolution.Failure(
            CallExecutionResult(CallExecutionStatus.invalidTarget, "A phone number is required."),
        )
        val normalized = PhoneNumberValidator.normalize(number) ?: return TargetResolution.Failure(
            CallExecutionResult(CallExecutionStatus.invalidTarget, "The phone number is not valid."),
        )
        return TargetResolution.Success(request.displayName?.trim()?.ifEmpty { normalized } ?: normalized, normalized)
    }

    private fun contactTarget(request: CallRequest): TargetResolution {
        val contactId = request.contactId?.toLongOrNull() ?: return TargetResolution.Failure(
            CallExecutionResult(CallExecutionStatus.invalidTarget, "The selected contact is not valid."),
        )
        val contact = contactResolver.phoneNumbersForContact(contactId) ?: return TargetResolution.Failure(
            CallExecutionResult(CallExecutionStatus.contactNotFound, "The selected contact was not found."),
        )
        if (contact.phoneNumbers.isEmpty()) return TargetResolution.Failure(
            CallExecutionResult(CallExecutionStatus.invalidTarget, "This contact has no phone numbers."),
        )
        if (request.phoneNumber.isNullOrBlank()) {
            if (contact.phoneNumbers.size > 1) return TargetResolution.Failure(
                CallExecutionResult(
                    CallExecutionStatus.numberSelectionRequired,
                    "Choose which number to call for ${contact.displayName}.",
                    displayName = contact.displayName,
                    availableNumbers = contact.phoneNumbers,
                ),
            )
            return selectedContactTarget(contact.displayName, contact.phoneNumbers.single(), contact.phoneNumbers)
        }
        return selectedContactTarget(contact.displayName, request.phoneNumber, contact.phoneNumbers)
    }

    private fun selectedContactTarget(
        displayName: String,
        selectedNumber: String,
        contactNumbers: List<String>,
    ): TargetResolution {
        val normalized = PhoneNumberValidator.normalize(selectedNumber) ?: return TargetResolution.Failure(
            CallExecutionResult(CallExecutionStatus.invalidTarget, "The selected phone number is not valid."),
        )
        if (contactNumbers.none { PhoneNumberValidator.normalize(it) == normalized }) {
            return TargetResolution.Failure(
                CallExecutionResult(
                    CallExecutionStatus.contactNumberMismatch,
                    "The selected number does not belong to $displayName.",
                ),
            )
        }
        return TargetResolution.Success(displayName, normalized)
    }

    private data class PendingCall(
        val displayName: String,
        val phoneNumber: String,
        val createdAtMillis: Long,
    )

    private sealed interface TargetResolution {
        data class Success(val displayName: String, val phoneNumber: String) : TargetResolution
        data class Failure(val result: CallExecutionResult) : TargetResolution
    }

    private companion object {
        const val CONFIRMATION_TIMEOUT_MILLIS = 60_000L
    }
}

data class CallRequest(
    val contactId: String?,
    val phoneNumber: String?,
    val displayName: String?,
)

object PhoneNumberValidator {
    fun normalize(value: String): String? {
        val normalized = PhoneNumberUtils.normalizeNumber(value)
        val digitCount = normalized.count(Char::isDigit)
        return normalized.takeIf {
            PhoneNumberUtils.isGlobalPhoneNumber(it) && digitCount in 3..15
        }
    }
}

class CallExecutor(private val activity: Activity) {
    fun execute(displayName: String, phoneNumber: String): CallExecutionResult {
        return try {
            activity.startActivity(Intent(Intent.ACTION_CALL, Uri.parse("tel:$phoneNumber")))
            CallExecutionResult(
                CallExecutionStatus.calling,
                "Calling $displayName.",
                displayName = displayName,
                phoneNumber = phoneNumber,
            )
        } catch (exception: SecurityException) {
            CallExecutionResult(CallExecutionStatus.permissionRequired, "Phone permission is required to place this call.")
        } catch (exception: ActivityNotFoundException) {
            CallExecutionResult(CallExecutionStatus.callFailed, "No phone application is available to place this call.")
        } catch (exception: RuntimeException) {
            CallExecutionResult(CallExecutionStatus.callFailed, "Android could not start the phone call.")
        }
    }
}
