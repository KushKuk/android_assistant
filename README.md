# Android Personal Assistant

A personal Android voice assistant built with Flutter and native Kotlin.

The long-term goal is to create a lightweight, privacy-conscious Android assistant that can interact with the phone through voice, execute system actions, and eventually operate as a background voice assistant.

The project is being developed incrementally, starting with the Android integration layer and progressing toward voice interaction, calling, wake-word detection, automation, and AI-powered capabilities.

---

## Current Status

Phase 2 is complete.

The current implementation provides a Flutter-to-Kotlin communication bridge using Android platform channels.

### Implemented

- Flutter application foundation
- Configurable assistant settings
- Persistent settings synchronization
- Flutter-to-Kotlin communication through `MethodChannel`
- Kotlin-to-Flutter event communication through `EventChannel`
- Native settings storage
- Android bridge status reporting
- Native `bridge_ready` event
- Android debug APK builds successfully
- Flutter static analysis passes
- Flutter tests pass

### Not Yet Implemented

- Microphone access
- Speech-to-text
- Text-to-speech
- Contact access
- Phone calls
- SMS
- Wake-word detection
- Background voice activation
- `VoiceInteractionService`
- Default Android assistant integration
- AI/LLM command processing
- Reminders
- Alarms
- Timers
- NFC automation
- Sensor integrations

These capabilities will be introduced incrementally in later phases.

---

## Vision

The eventual goal is for the Assistant to function as a personal Android assistant rather than simply a voice-controlled Flutter application.

The intended interaction is:

```text
Phone idle
    |
    v
Wake-word detection
    |
    v
"Hey Assistant"
    |
    v
Voice interaction
    |
    v
Speech-to-text
    |
    v
Command parsing
    |
    v
Android action
    |
    v
Text-to-speech response
    |
    v
Return to idle
```

For example:

```
User: "Hey Assistant"
A: "Yes?"
User: "Call Mom."
A: "Call Mom?"
User: "Yes."
A: "Calling Mom."
```

The first major functional milestone is reliable voice-controlled phone calling.

---

## Architecture

The Assistant uses Flutter for the application layer and Kotlin for Android-specific functionality.

```text
                    Assistant
                        |
           +------------+------------+
           |                         |
        Flutter                    Kotlin
           |                         |
           |                    Android APIs
           |                         |
           +-------- Platform -------+
                    Channels
```

### Flutter

Flutter is responsible for:

- User interface
- Settings
- Assistant configuration
- Assistant state visualization
- Command history
- Contact aliases
- Local application state
- Onboarding
- Permission status
- Cross-platform application logic

### Kotlin

Native Kotlin will handle Android-specific functionality such as:

- Voice interaction
- Android assistant integration
- Contacts
- Phone calls
- Speech recognition
- Text-to-speech
- Wake-word integration
- Android intents
- Permissions
- Background behavior
- System integrations

### Platform Bridge

The current Android integration uses two Flutter platform channels.

#### MethodChannel

MethodChannel is used for request/response communication between Flutter and Kotlin.

```text
Flutter
    |
    | MethodChannel
    v
Kotlin
```

The bridge currently supports:

- Synchronization of persisted assistant settings
- Retrieval of Android integration status

#### EventChannel

EventChannel is used for asynchronous native events.

```text
Kotlin
    |
    | EventChannel
    v
Flutter
```

The current native event is:

- `bridge_ready`

The event architecture is intentionally designed to support future assistant events such as:

- `wake_word_detected`
- `listening_started`
- `speech_received`
- `processing_started`
- `command_executing`
- `command_completed`
- `speaking_started`
- `assistant_error`

### Assistant Identity

The Assistant's name is configurable.

The default name is:

> Assistant

The application is designed so that the assistant name is not hard-coded throughout the application.

For example, the user could change the name to:

- Jarvis
- Atlas
- or any other supported name

The assistant name and wake word are treated as separate concepts. Changing the assistant name does not automatically change the wake-word detection model.

### Settings

The Assistant is designed around a persistent settings model.

Example settings include:

- Assistant Name
- Wake Word
- Calling Mode
- Voice
- Speech Rate
- Speech Pitch
- Language
- Wake Word Enabled
- Voice Feedback Enabled

Settings are persisted locally and synchronized between Flutter and Kotlin.

The Flutter application is responsible for providing the user interface for these settings. The native Android layer can access synchronized settings when required by future native services.

---

## Planned Capabilities

The architecture is designed to eventually support multiple capability modules.

### Communication

Planned:

- Voice-controlled phone calls
- Contact resolution
- Contact aliases
- SMS
- Communication confirmations

Example:

> "Call Mom."

The intended flow is:

```text
Voice command
    |
    v
Command parser
    |
    v
Contact resolver
    |
    v
Contact / phone number
    |
    v
Confirmation
    |
    v
Android phone call
```

### Productivity

Planned:

- Tasks
- Reminders
- Alarms
- Timers
- Notes
- Command history

Examples:

- "Remind me to submit my assignment at 8 PM."
- "Set a timer for 25 minutes."
- "Set an alarm for 7 AM."
- "Add study operating systems to my tasks."
- "Take a note: buy solder."

### Applications

Planned:

- Launch installed applications
- Open specific Android screens
- Media controls
- Application-specific actions where Android allows them

Examples:

- "Open Spotify."
- "Open Chrome."
- "Open the camera."

Application-specific functionality will depend on the APIs and intents exposed by the target application.

### Device Control

Potential future functionality includes:

- Flashlight
- Bluetooth
- Wi-Fi
- Do Not Disturb
- Volume
- System settings

Examples:

- "Turn on the flashlight."
- "Turn on Bluetooth."
- "Turn off Do Not Disturb."

Android restrictions will be respected where direct modification is not permitted.

### Media Control

Potential future functionality includes:

- Play
- Pause
- Next track
- Previous track
- Volume control
- Media session interaction
- Opening music applications

Examples:

- "Play music."
- "Pause."
- "Next song."
- "Turn the volume up."

The exact functionality will depend on Android's media-session APIs and the target application's capabilities.

### Notes and Memory

The Assistant may eventually provide a local note and memory system.

Examples:

- "Take a note: buy solder."
- "Remember that my project deadline is Friday."
- "What did I ask you to remember?"

Notes and user-created memory should be stored locally unless the user explicitly enables another storage mechanism.

### Navigation

Potential future functionality includes integration with navigation applications.

Examples:

- "Navigate home."
- "Take me to college."
- "How long will it take to get to the airport?"
- "Find the nearest petrol station."

Navigation functionality may use Android intents and available navigation applications.

### Sensors

The Assistant may eventually interact with Android device sensors.

Potential integrations include:

- Accelerometer
- Gyroscope
- Magnetometer
- GPS
- Proximity sensor
- Ambient light sensor
- Other available device sensors

Examples:

- "Is my phone level?"
- "Which direction am I facing?"
- "How fast am I moving?"
- "What's the current location?"

Sensor availability varies by device.

### NFC

NFC may eventually be used as a physical trigger for Assistant actions.

For example:

```text
Desk NFC Tag
      |
      v
Start focus timer
      |
      v
Open development environment
      |
      v
Enable focus mode
      |
      v
Start music
```

Another example:

```text
Bed NFC Tag
      |
      v
Enable Do Not Disturb
      |
      v
Set alarm
      |
      v
Start sleep timer
```

NFC functionality will be implemented as an optional automation module.

### Automation

The long-term architecture may support custom routines.

The basic model is:

```text
Trigger
   |
   v
Condition
   |
   v
Action
```

Examples:

```text
Headphones connected
        |
        v
Open Spotify
        |
        v
Enable focus mode
```

Or:

```text
NFC tag scanned
        |
        v
Start 50-minute timer
        |
        v
Open development environment
```

Potential triggers include:

- Voice commands
- NFC
- Device charging
- Bluetooth connections
- Application launches
- Time
- Sensors
- Location
- Other Android events

Android restrictions and permission requirements will be respected.

### AI

An optional AI layer may eventually handle more complex natural-language commands.

The architecture is intentionally designed so that basic commands do not require an LLM.

For example:

> "Call Mom."

should be handled deterministically.

More complex commands could optionally use an AI model:

> "I have about an hour before class. Set up something useful so I can get some work done."

The AI layer should produce structured intents rather than receiving unrestricted control over the Android system.

A potential architecture is:

```text
User command
     |
     v
Command classifier
     |
     +----------------------+
     |                      |
     v                      v
Simple command          Complex command
     |                      |
     v                      v
Local parser                AI
     |                      |
     +----------+-----------+
                |
                v
        Structured intent
                |
                v
        Command executor
                |
                v
          Android action
```

This keeps basic functionality reliable and reduces unnecessary AI usage.

### Natural Language Understanding

The Assistant should eventually understand variations of the same command.

For example:

- "Call Mom."
- "Give Mom a call."
- "Phone Mom."
- "Can you call Mom?"
- "Please call Mom."

All of these should resolve to the same underlying intent:

> CALL

The command architecture should separate:

- Intent detection
- Entity extraction
- Validation
- Command execution

### Multi-Turn Conversations

The Assistant may eventually support multi-step conversations.

Example:

```
User: "Set a timer."
A: "How long?"
User: "45 minutes."
A: "Timer set."
```

Another example:

```
User: "Call Mom."
A: "Which number?"
User: "Mobile."
A: "Calling Mom."
```

This requires an assistant state machine capable of maintaining short-lived conversational context.

---

## Command Architecture

The Assistant should use a modular command architecture rather than a large conditional statement.

A possible structure is:

```text
Command
 ├── CallCommand
 ├── MessageCommand
 ├── ReminderCommand
 ├── TimerCommand
 ├── AlarmCommand
 ├── OpenAppCommand
 ├── NoteCommand
 └── DeviceCommand
```

Supporting components may include:

- CommandParser
- CommandExecutor
- CommandResult
- ContactResolver
- CallExecutor
- ReminderExecutor
- TimerExecutor
- AlarmExecutor
- AppLauncher
- NoteManager

Example:

```text
"Call Mom"
      |
      v
CommandParser
      |
      v
CallCommand
      |
      v
ContactResolver
      |
      v
Phone number
      |
      v
CallExecutor
      |
      v
Android phone call
```

---

## Voice Pipeline

The eventual voice pipeline is:

```text
Wake Word
    |
    v
Voice Capture
    |
    v
Speech-to-Text
    |
    v
Intent Detection
    |
    v
Entity Extraction
    |
    v
Command Execution
    |
    v
Text-to-Speech
```

Each stage should be independently replaceable.

### Speech Recognition

A replaceable speech-recognition abstraction is planned.

Example interface:

```text
SpeechRecognizer

startListening()
stopListening()
onPartialResult()
onFinalResult()
onError()
```

The implementation should be isolated from the command engine.

Where practical, on-device speech recognition should be preferred.

### Text-to-Speech

A replaceable text-to-speech abstraction is planned.

Example interface:

```text
TextToSpeechManager

speak()
stop()
setVoice()
setRate()
setPitch()
```

Responses should generally be concise.

Examples:

- "Calling Mom."
- "Timer set."
- "I couldn't find that contact."
- "Which contact do you mean?"

### Wake Word

The long-term goal is local wake-word detection.

Example:

> "Hey Assistant"

The preferred architecture is:

```text
Low-power wake-word detection
          |
          v
Wake word detected
          |
          v
Full speech recognition
```

The application should not continuously send microphone audio to a cloud service solely for wake-word detection.

A replaceable abstraction is planned:

```text
WakeWordDetector

start()
stop()
onWakeWordDetected()
dispose()
```

The wake-word implementation will be integrated separately from the assistant-name configuration.

---

## Android Assistant Integration

The long-term Android architecture may use official Android assistant APIs such as:

- `VoiceInteractionService`
- `VoiceInteractionSession`
- `RoleManager`
- `ROLE_ASSISTANT`
- Android Contacts APIs
- Android Telecom APIs
- Speech recognition APIs
- Text-to-Speech APIs
- Android notification APIs
- Appropriate background execution APIs

The implementation will respect Android security and lifecycle restrictions.

No undocumented mechanisms will be used to bypass Android restrictions.

---

## Privacy

Privacy is a core design consideration.

The Assistant should not:

- Secretly record audio
- Store raw microphone recordings without explicit user configuration
- Upload microphone audio unnecessarily
- Bypass Android permissions
- Bypass Android background restrictions
- Use undocumented APIs to circumvent system protections

Where practical, processing should happen locally.

The user should have clear control over:

- Microphone access
- Contacts access
- Phone access
- Voice features
- Wake-word detection
- Command history
- Assistant settings

Command history should be locally stored and deletable.

---

## Battery Usage

Background voice assistants can consume significant battery if implemented incorrectly.

The intended architecture is:

```text
LOW POWER
    |
    v
Wake-word detection
    |
    v
Wake word detected
    |
    v
Full voice processing
    |
    v
Return to low-power state
```

The system should avoid:

- Constant polling
- Unnecessary background services
- Expensive continuous inference
- Continuous cloud audio streaming

Battery behavior will be optimized after the core functionality is implemented.

---

## Security

The Assistant will interact with sensitive Android capabilities.

Examples include:

- Microphone
- Contacts
- Phone calls
- Messages
- Notifications
- Location
- Device settings

Each capability should use Android's permission model.

Commands that can cause significant side effects should support confirmation where appropriate.

For example:

```
User: "Call Mom."
A: "Call Mom?"
User: "Yes."
A: "Calling Mom."
```

A direct execution mode may be added later as an explicit user preference.

---

## Development Roadmap

### Phase 0 — Project Setup

- Flutter project
- Android configuration
- Development environment
- Build system

**Status:** Complete

### Phase 1 — Settings

Planned/implemented:

- Assistant settings model
- Persistent configuration
- Assistant name
- Voice settings
- Wake-word configuration
- Calling mode
- Local settings storage

**Status:** Complete

### Phase 2 — Flutter/Kotlin Bridge

Implemented:

- MethodChannel
- EventChannel
- Settings synchronization
- Android bridge status
- Native event stream
- `bridge_ready` event

**Status:** Complete

### Phase 3 — Contacts

Planned:

- Contacts permission
- Android Contacts API
- Contact resolver
- Contact aliases
- Multiple-match handling
- Missing-contact handling
- Contacts without phone numbers

**Status:** Planned

### Phase 4 — Calling

Planned:

```text
Command
    |
    v
ContactResolver
    |
    v
Phone number
    |
    v
Confirmation
    |
    v
Android call
```

**Status:** Planned

### Phase 5 — Speech

Planned:

- Speech-to-text
- Text-to-speech
- Speech abstractions
- Voice state management

**Status:** Planned

### Phase 6 — Voice Interaction

Planned:

- VoiceInteractionService
- VoiceInteractionSession
- Android assistant role
- Background interaction
- Lifecycle management

**Status:** Planned

### Phase 7 — Wake Word

Planned:

- WakeWordDetector abstraction
- Local wake-word detection
- Low-power operation
- Wake-word event handling

**Status:** Planned

### Phase 8 — Commands

Planned:

- Calls
- Messages
- Timers
- Alarms
- Reminders
- Notes
- App launching
- Device actions

**Status:** Planned

### Phase 9 — AI

Planned:

- Natural-language understanding
- Complex command interpretation
- Optional LLM integration
- Context-aware interactions
- Structured intent generation

**Status:** Planned

### Phase 10 — Automation

Planned:

- Routines
- NFC triggers
- Sensor triggers
- Contextual actions
- Custom user automations

**Status:** Planned

---

## Project Structure

The project is organized around a clear separation between Flutter and Android functionality.

```text
voice_assistant/
|
+-- lib/
|   |
|   +-- core/
|   |
|   +-- models/
|   |
|   +-- commands/
|   |
|   +-- services/
|   |
|   +-- features/
|   |
|   +-- screens/
|   |
|   +-- widgets/
|   |
|   +-- main.dart
|
+-- android/
|   |
|   +-- app/
|       |
|       +-- src/
|           |
|           +-- main/
|               |
|               +-- kotlin/
|                   |
|                   +-- assistant/
|                   +-- voice/
|                   +-- calls/
|                   +-- contacts/
|                   +-- speech/
|                   +-- tts/
|                   +-- commands/
|                   +-- settings/
|
+-- test/
|
+-- pubspec.yaml
|
+-- README.md
```

The exact structure may evolve as the project grows.

---

## Technology Stack

### Frontend

- Flutter
- Dart

### Android

- Kotlin
- Android SDK
- Android platform APIs
- Flutter Platform Channels

### Communication

- MethodChannel
- EventChannel

### Future Voice Stack

- Android speech recognition
- Android Text-to-Speech
- Local wake-word detection

### Future AI Stack

The AI provider has intentionally not been hard-coded into the architecture.

An AI model may eventually be used for natural-language understanding and advanced assistant capabilities.

---

## Development Environment

### Requirements

- Flutter
- Dart
- Android SDK
- Android SDK Platform Tools
- Android SDK Build Tools
- Compatible Android NDK
- Kotlin/Java toolchain
- Android emulator or physical Android device

Verify the environment with:

```bash
flutter doctor
```

Check connected devices with:

```bash
flutter devices
```

### Running the Project

From the project directory:

```bash
flutter pub get
```

Run static analysis:

```bash
flutter analyze
```

Run tests:

```bash
flutter test
```

Run the application:

```bash
flutter run
```

Build a debug APK:

```bash
flutter build apk --debug
```

### Current Verification

The current Phase 2 implementation has been verified with:

```
flutter analyze          PASS
flutter test              PASS
flutter build apk --debug PASS
```

The Android NDK installation was repaired after the SDK reported a missing:

```
source.properties
```

The project currently builds successfully using:

```
NDK 28.2.13676358
```

Runtime verification of the MethodChannel/EventChannel bridge is currently pending.

---

## Development Philosophy

The Assistant is being built incrementally.

The project prioritizes:

- Real Android integration
- Reliability
- Privacy
- Low battery usage
- Clean architecture
- Modular capabilities
- UI polish

The goal is not to create a simulated assistant interface.

The goal is to progressively build a real Android assistant that can interact with the device and eventually operate independently of the Flutter UI.

---

## Contributing

The project is currently under active development.

New capabilities should follow the modular architecture and avoid coupling unrelated Android functionality to the Flutter UI.

When adding a new capability:

1. Define the capability interface.
2. Keep Android-specific implementation in Kotlin.
3. Expose only the necessary functionality through platform channels.
4. Keep command parsing separate from execution.
5. Handle Android permissions explicitly.
6. Add tests where practical.
7. Verify the feature on an Android emulator or physical device.
8. Document Android version and device limitations.

---

## License

License information will be added as the project approaches public release.
