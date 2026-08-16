# Android Voice Assistant

A modular personal voice assistant for Android built with Flutter and native Kotlin.

The project combines Flutter for the application layer and state management with native Android services for speech recognition, text-to-speech, contacts, calling, and other platform-specific capabilities.

The assistant is being developed incrementally, with each capability isolated and independently testable.

---

## Current Status

The project has completed Phases 1–7 and has undergone Phase 1 stabilization work.

### Completed

- Persistent assistant settings
- Configurable assistant name
- Flutter ↔ Kotlin MethodChannel bridge
- Flutter ↔ Kotlin EventChannel bridge
- Native Android contact resolution
- Safe phone-call execution pipeline
- Deterministic voice command parser
- Native Android Text-to-Speech
- Native Android Speech-to-Text
- Flutter AssistantController
- Speech-to-command integration
- Android debug APK builds successfully
- Comprehensive Flutter test suite
- Phase 1 stabilization and baseline completed

### Not Yet Implemented

- Wake-word detection
- Background listening
- Always-on microphone
- Default Android assistant integration
- VoiceInteractionService
- Automatic command execution beyond the currently implemented calling pipeline
- AI/LLM-based intent understanding
- Bluetooth control
- Wi-Fi control
- SMS
- Reminders
- General device automation

---

## Architecture

The project follows a layered architecture.

```text
                         Android Assistant
                                |
                                v
                       +------------------+
                       | Assistant UI     |
                       +--------+---------+
                                |
                                v
                    +-----------------------+
                    | AssistantController   |
                    |                       |
                    | State                 |
                    | Transcript            |
                    | Command coordination  |
                    +----------+------------+
                               |
                               v
                    +-----------------------+
                    | AssistantPlatform     |
                    |                       |
                    | Flutter abstraction   |
                    +----------+------------+
                               |
                 +-------------+-------------+
                 |                           |
                 v                           v
          MethodChannel                EventChannel
                 |                           |
                 +-------------+-------------+
                               |
                               v
                    +-----------------------+
                    | Android Kotlin Layer  |
                    +-----------------------+
                       |       |       |
                       v       v       v
                      STT     TTS   Android APIs
                                      |
                              +-------+-------+
                              |               |
                              v               v
                          Contacts         Calling
```

The Flutter layer is responsible for UI, state, orchestration, and deterministic command parsing.
The Kotlin layer handles Android-specific functionality.

---

## Phase 1 — Settings

**Status:** Complete

The application supports persistent assistant settings.

The assistant name can be configured through the Flutter interface.

Settings are persisted locally and synchronized with the native Android layer.

The architecture does not hard-code a specific assistant name.

---

## Phase 2 — Native Flutter/Kotlin Bridge

**Status:** Complete

The project uses a single native communication layer between Flutter and Android.

### MethodChannel

Used for request/response operations such as:

- settings synchronization
- Android bridge status
- speech operations
- TTS operations
- contact operations
- calling operations

### EventChannel

Used for asynchronous native events.

The bridge initially emits:

```
bridge_ready
```

and has since been extended to carry speech and TTS events.

Important files include:

```
lib/services/assistant_platform.dart
lib/models/assistant_integration_status.dart
android/app/src/main/kotlin/com/example/voice_assistant/AssistantBridge.kt
android/app/src/main/kotlin/com/example/voice_assistant/MainActivity.kt
```

No additional MethodChannel or EventChannel is created for individual capabilities.

---

## Phase 3 — Android Contacts

**Status:** Complete

Native Android contact resolution is implemented.

Main native component:

```
android/app/src/main/kotlin/com/example/voice_assistant/contacts/ContactResolver.kt
```

The application supports:

- checking contact permission
- requesting contact permission
- searching contacts by name
- ranking candidates
- deduplicating results
- retrieving phone numbers

Android permission:

```
READ_CONTACTS
```

Contact data is not persisted by the application.

Contact resolution explicitly fails when the required permission has not been granted.

---

## Phase 4 — Safe Call Execution

**Status:** Complete

The application contains a safety-focused native call execution pipeline.

Main component:

```
android/app/src/main/kotlin/com/example/voice_assistant/calls/SafeCallPipeline.kt
```

The calling flow is intentionally split into preparation and execution.

```text
prepareCall()
      |
      v
Validate target
      |
      v
Validate phone number
      |
      v
Validate contact ownership
      |
      v
Generate confirmation token
      |
      v
Explicit confirmation
      |
      v
confirmCall(token, true)
      |
      v
Android ACTION_CALL
```

A call cannot be placed directly from a parsed command.

### Safety Features

- Phone-number validation
- Phone-number normalization
- Contact ownership validation
- Multiple-number handling
- Expiring confirmation tokens
- Confirmation timeout
- Permission handling
- Phone application availability checks
- Android call-start error handling

Confirmation tokens expire after 60 seconds.

Android permission:

```
CALL_PHONE
```

If the permission is missing, the pipeline returns a structured `permissionRequired` result.

No actual phone call was executed during development verification.

---

## Phase 5A — Text-to-Speech

**Status:** Complete

Native Android Text-to-Speech is implemented using:

```
android.speech.tts.TextToSpeech
```

Main native component:

```
AssistantTextToSpeech.kt
```

Flutter can access:

```
speak(text)
stopSpeaking()
getTtsStatus()
```

The existing MethodChannel and EventChannel are reused.

### TTS Events

```
speaking_started
speaking_completed
speaking_stopped
speech_error
```

The implementation includes:

- Android TextToSpeech integration
- locale fallback
- device default locale
- `en_US` fallback
- utterance progress callbacks
- stale utterance protection
- thread-safe callback handling
- main-thread event dispatch
- lifecycle cleanup
- TTS engine shutdown

### Current Limitation

Speech rate and pitch settings are stored by the application but are not yet applied to the native TTS engine.

Runtime audio output has not been formally verified on a physical Android device.

---

## Phase 5B — Speech-to-Text

**Status:** Complete

Native Android Speech-to-Text is implemented using Android's speech recognition APIs.

The architecture is:

```text
Microphone
    |
    v
Android SpeechRecognizer
    |
    v
Native speech service
    |
    v
EventChannel
    |
    v
AssistantController
    |
    v
AssistantController
```

Speech recognition supports asynchronous recognition events including:

```
listening_started
partial_transcript
final_transcript
listening_stopped
speech_error
```

The microphone is not automatically activated when the application starts.

Speech recognition remains an explicit user action.

Android microphone permission:

```
RECORD_AUDIO
```

Speech recognition, contacts, and calling remain separate native capabilities.

---

## Phase 6 — AssistantController

**Status:** Complete

The Flutter application contains a dedicated `AssistantController`.

Main file:

```
lib/services/assistant_controller.dart
```

The controller uses the project's existing `ChangeNotifier` architecture.

It coordinates:

- speech recognition
- transcripts
- TTS state
- native events
- assistant state
- command parsing

It does not contain Android-specific implementation.

### Assistant State

The controller exposes high-level assistant states including:

```
idle
listening
processing
speaking
error
```

The controller receives native events through the existing EventChannel.

It handles both speech-recognition and TTS events.

### Transcript Handling

The controller maintains:

```
partialTranscript
finalTranscript
```

During speech recognition:

```
User: "Call Mo..."
        ↓
partialTranscript: "Call Mo..."
```

When recognition finishes:

```
finalTranscript: "Call Mom"
```

The controller then transitions into processing.

---

## Phase 7 — Speech-to-Command Integration

**Status:** Complete

The final speech transcript is now passed to the deterministic command parser.

The current pipeline is:

```text
Speech-to-Text
      |
      v
AssistantController
      |
      v
CommandParser
      |
      v
AssistantCommand
```

For example:

```
"Call Mom"
```

becomes:

```
CallCommand("Mom")
```

The resulting command is exposed through the controller.

The controller provides access to:

```
lastCommandParseResult
hasPendingCommand
pendingCommand
```

### Command Parser

The command parser is deterministic and side-effect free.

Important files:

```
lib/commands/assistant_command.dart
lib/commands/command_parse_result.dart
lib/commands/command_parser.dart
```

Currently supported examples include:

```
Call Mom
Phone Dad
Give Mom a call
Call 9876543210
```

The parser can return:

```
CallCommand(contactQuery)
```

or an explicit result for:

- missing targets
- unsupported commands
- invalid input

The parser does not:

- access contacts
- request permissions
- place calls
- access Android APIs
- use an LLM
- perform network requests

### Current End-to-End Flow

The currently implemented voice pipeline reaches command recognition.

```text
User
 |
 | speaks
 v
Android SpeechRecognizer
 |
 | final transcript
 v
AssistantController
 |
 | v
CommandParser
 |
 | v
CallCommand("Mom")
 |
 | v
pendingCommand
```

The command is currently exposed to the Flutter layer.

Execution must remain separate from parsing.

### Current Calling Architecture

The project already has the components necessary for command execution:

```text
CallCommand("Mom")
       |
       v
ContactResolver
       |
       v
Phone number
       |
       v
SafeCallPipeline.prepareCall()
       |
       v
Confirmation required
       |
       v
confirmCall(token, true)
       |
       v
Android ACTION_CALL
```

The speech-to-command layer does not bypass this safety mechanism.

---

## Testing

The project has a comprehensive Flutter test suite covering:

- settings behavior
- platform result parsing
- TTS result handling
- speech recognition behavior
- command parsing
- AssistantController state management
- transcript handling
- command integration
- disposal/lifecycle behavior

The latest reported test count is:

```
37 tests
```

All tests pass.

---

## Verification

The project has repeatedly passed:

```
flutter analyze
flutter test
flutter build apk --debug
```

Current status:

```
flutter analyze       PASS (with lint warnings)
flutter test          PASS
flutter build apk     PASS
```

The Android debug APK is generated at:

```
build/app/outputs/flutter-apk/app-debug.apk
```

Runtime functionality should only be considered verified when explicitly tested on an Android device or emulator.

Several development phases were verified through compilation and unit testing without claiming runtime verification.

---

## Project Structure

A simplified structure:

```text
voice_assistant/
|
├── lib/
│   |
│   ├── commands/
│   │   ├── assistant_command.dart
│   │   ├── command_parse_result.dart
│   │   └── command_parser.dart
│   |
│   ├── models/
│   │   ├── assistant_integration_status.dart
│   │   ├── call_execution_result.dart
│   │   └── ...
│   |
│   ├── services/
│   │   ├── assistant_controller.dart
│   │   └── assistant_platform.dart
│   |
│   └── ...
|
├── android/
│   |
│   └── app/
│       |
│       └── src/main/kotlin/
│           |
│           └── com/example/voice_assistant/
│               |
│               ├── AssistantBridge.kt
│               ├── MainActivity.kt
│               |
│               ├── calls/
│               │   └── SafeCallPipeline.kt
│               |
│               ├── contacts/
│               │   └── ContactResolver.kt
│               |
│               └── speech/
│                   ├── AssistantTextToSpeech.kt
│                   └── ...
|
└── test/
    ├── assistant_controller_test.dart
    ├── command_parser_test.dart
    ├── tts_test.dart
    └── ...
```

The exact project structure may contain additional files.

---

## Design Principles

### Modular

Each Android capability is isolated.

```
Speech
Contacts
Calling
TTS
```

are separate concerns.

### Safe

Side-effecting actions are separated from parsing.

A command such as:

```
Call Mom
```

does not inherently mean:

```
Place a call
```

The call must pass through the existing validation and confirmation pipeline.

### Deterministic

Basic commands currently use deterministic parsing rather than an LLM.

This keeps core actions predictable and testable.

### Platform-Aware

Android-specific functionality stays in Kotlin.

Flutter communicates with it through the platform abstraction.

### Incremental

The assistant is being developed as independent phases rather than one large implementation.

Future functionality should not be implemented early simply because it is part of the long-term roadmap.

---

## Roadmap

### Phase 8

Connect parsed `CallCommand` objects to:

```text
ContactResolver
    ↓
SafeCallPipeline
    ↓
Explicit confirmation
    ↓
Call execution
```

This should preserve all existing Phase 4 safety guarantees.

### Future Capabilities

Potential future assistant capabilities include:

- Wake-word activation
- Background operation
- Android VoiceInteractionService
- Bluetooth control
- Wi-Fi/device controls
- Media controls
- SMS
- Reminders
- Alarms
- Device automation
- AI/LLM intent understanding
- Conversational responses

These are **NOT** currently implemented.

---

## Safety Model

The assistant is intentionally designed so that natural-language input does not directly trigger dangerous or irreversible actions.

For example:

```text
Speech
  ↓
Transcript
  ↓
Command
  ↓
Validation
  ↓
Explicit confirmation
  ↓
Execution
```

This separation should be maintained as new capabilities are added.

---

## Development Commands

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Build a debug APK:

```bash
flutter build apk --debug
```

---

## Current Status Summary

```
Phase 1   Settings                    COMPLETE
Phase 2   Native Bridge               COMPLETE
Phase 3   Contacts                    COMPLETE
Phase 4   Safe Calling                COMPLETE
Phase 5A  Text-to-Speech              COMPLETE
Phase 5B  Speech-to-Text              COMPLETE
Phase 6   AssistantController         COMPLETE
Phase 7   Speech-to-Command           COMPLETE
Phase 8   Command Execution           NEXT
```

The project currently has a functional foundation for an Android voice assistant.

The next major milestone is connecting the already-parsed `CallCommand` to the existing contact-resolution and safe-call pipeline without bypassing explicit confirmation.

---

## Phase 1 Stabilization Baseline

As part of Phase 1 work, a stabilization baseline has been established:

- Repository architecture understood and documented
- Existing capabilities identified and documented
- Permission and safety mechanisms analyzed and documented
- Existing command/state issues identified
- Only clearly justified bug fixes made (none found requiring changes)
- Existing tests continue to pass
- flutter analyze completes successfully (with only lint warnings)
- flutter build apk --debug succeeds
- PHASE_1_BASELINE.md created with detailed findings
- No new capabilities or major architectural changes introduced

The stabilization work confirms the project is ready to proceed to Phase 2 (AOSP/system-level work).