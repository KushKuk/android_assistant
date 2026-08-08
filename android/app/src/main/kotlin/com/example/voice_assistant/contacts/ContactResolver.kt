package com.example.voice_assistant.contacts

import android.content.ContentResolver
import android.provider.ContactsContract.CommonDataKinds.Phone
import java.util.Locale

data class ContactCandidate(
    val contactId: Long,
    val displayName: String,
    val phoneNumbers: List<String>,
    val isExactNameMatch: Boolean,
) {
    fun toMap(): Map<String, Any> = mapOf(
        "contactId" to contactId.toString(),
        "displayName" to displayName,
        "phoneNumbers" to phoneNumbers,
        "isExactNameMatch" to isExactNameMatch,
    )
}

/** Queries Android's contacts provider and never initiates a phone call. */
class ContactResolver(private val contentResolver: ContentResolver) {
    fun search(query: String): List<ContactCandidate> {
        val trimmedQuery = query.trim()
        if (trimmedQuery.isEmpty()) return emptyList()

        val contacts = linkedMapOf<Long, MutableContact>()
        contentResolver.query(
            Phone.CONTENT_URI,
            PROJECTION,
            "${Phone.DISPLAY_NAME} LIKE ?",
            arrayOf("%$trimmedQuery%"),
            "${Phone.DISPLAY_NAME} COLLATE NOCASE ASC",
        )?.use { cursor ->
            val contactIdIndex = cursor.getColumnIndexOrThrow(Phone.CONTACT_ID)
            val displayNameIndex = cursor.getColumnIndexOrThrow(Phone.DISPLAY_NAME)
            val numberIndex = cursor.getColumnIndexOrThrow(Phone.NUMBER)

            while (cursor.moveToNext()) {
                val contactId = cursor.getLong(contactIdIndex)
                val displayName = cursor.getString(displayNameIndex) ?: continue
                val number = cursor.getString(numberIndex) ?: continue
                val contact = contacts.getOrPut(contactId) { MutableContact(displayName) }
                contact.phoneNumbers += number
            }
        }

        return contacts.map { (contactId, contact) ->
            ContactCandidate(
                contactId = contactId,
                displayName = contact.displayName,
                phoneNumbers = contact.phoneNumbers.distinct(),
                isExactNameMatch = contact.displayName.equals(trimmedQuery, ignoreCase = true),
            )
        }.sortedWith(
            compareByDescending<ContactCandidate> { it.isExactNameMatch }
                .thenBy { it.displayName.lowercase(Locale.getDefault()) },
        )
    }

    fun phoneNumbersForContact(contactId: Long): ContactPhoneNumbers? {
        var displayName: String? = null
        val numbers = mutableListOf<String>()
        contentResolver.query(
            Phone.CONTENT_URI,
            PROJECTION,
            "${Phone.CONTACT_ID} = ?",
            arrayOf(contactId.toString()),
            null,
        )?.use { cursor ->
            val displayNameIndex = cursor.getColumnIndexOrThrow(Phone.DISPLAY_NAME)
            val numberIndex = cursor.getColumnIndexOrThrow(Phone.NUMBER)
            while (cursor.moveToNext()) {
                displayName = displayName ?: cursor.getString(displayNameIndex)
                cursor.getString(numberIndex)?.let(numbers::add)
            }
        }
        val name = displayName ?: return null
        return ContactPhoneNumbers(name, numbers.distinct())
    }

    private class MutableContact(
        val displayName: String,
        val phoneNumbers: MutableList<String> = mutableListOf(),
    )

    private companion object {
        val PROJECTION = arrayOf(Phone.CONTACT_ID, Phone.DISPLAY_NAME, Phone.NUMBER)
    }
}

data class ContactPhoneNumbers(
    val displayName: String,
    val phoneNumbers: List<String>,
)
