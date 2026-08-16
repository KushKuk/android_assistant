# JARVIS Phase 1 Baseline

## Architecture

JARVIS follows a layered architecture separating Flutter (UI/business logic) from native Android (platform-specific capabilities):

```
Flutter Layer:
  ├── Assistant UI (Screens: Home, Settings)
  ├── AssistantController (State management, command coordination)
  ├── AssistantOrchestrator (Routes commands to capabilities)
  ├── Capabilities (Call, Bluetooth, Connectivity, Flashlight, Screenshot, WhatsApp, Spotify)
  ├── AssistantPlatform (Abstraction layer for Android communication)
  ├── CommandParser (Deterministic voice command parsing)
  └── Models, Services, Widgets

Communication Layer:
  ├── MethodChannel (Synchronous request/response)
  └── EventChannel (Asynchronous native events)

Android Layer:
  ├── AssistantBridge (Flutter plugin entry point)
  ├── ContactResolver (Native contact resolution)
  ├── SafeCallPipeline (Safe call execution with confirmation)
  ├── AssistantTextToSpeech (TTS engine wrapper)
  ├── AssistantSpeechRecognizer (STT engine wrapper)
  ├── BluetoothManager (Bluetooth operations)
  ├── ConnectivityManager (Wi-Fi, mobile data, hotspot)
  └── Various result/model classes
```

### Responsibility of Each Layer:

**Flutter Layer:**
- UI presentation and user interaction
- Application state management (AssistantController)
- Command parsing and validation
- Orchestration of capabilities
- Settings persistence and synchronization
- Response formatting for user feedback

**AssistantPlatform (Abstraction Layer):**
- Defines interface for all Android capabilities
- Handles MethodChannel/EventChannel communication
- Translates Flutter calls to Android platform messages
- Manages permission flows and results

**Android Layer:**
- Implements native Android functionality
- Handles Android SDK integrations (contacts, telephony, Bluetooth, etc.)
- Manages permission requests and results
- Provides thread-safe execution of platform operations
- Communicates results back via EventChannel/MethodChannel

## Existing Capabilities

JARVIS currently implements the following capabilities:

1. **Call Capability** - Safe phone call execution with contact resolution and confirmation
2. **Bluetooth Capability** - Device discovery, connection/disconnection, enable/disable, status
3. **Connectivity Capability** - Wi-Fi, mobile data, and hotspot control/settings
4. **Flashlight Capability** - Device flashlight toggle
5. **Screenshot Capability** - Screen capture functionality
6. **WhatsApp Capability** - Messaging and voice/video calls (via intents)
7. **Spotify Capability** - Music playback control and search

Each capability follows the `AssistantCapability` interface with `canHandle()` and `execute()` methods.

## Command Flow

The voice command processing pipeline follows this sequence:

1. **Voice Input** → User speaks to device microphone
2. **STT (Speech-to-Text)** → Android SpeechRecognizer processes audio
3. **final_transcript Event** → AssistantSpeechRecognizer emits recognized text via EventChannel
4. **AssistantController** → Receives event, stores transcript, parses command
5. **CommandParser** → Deterministically parses transcript into AssistantCommand
6. **AssistantController** → Exposes parsed command via `pendingCommand`/`hasPendingCommand`
7. **AssistantOrchestrator** → Routes command to appropriate Capability
8. **Capability** → Validates and executes command via AssistantPlatform
9. **AssistantPlatform** → Communicates with Android layer via MethodChannel
10. **Android Layer** → Performs actual operation (call, Bluetooth action, etc.)
11. **Result Flow** → Result returns through same path back to AssistantController
12. **UI Update** → AssistantController state changes trigger UI rebuild

Key aspects:
- Command parsing is separate from execution (safety design)
- Pending commands are cleared after execution or on new listening session
- State transitions manage UI feedback throughout the process

## Permission Flow

Android permissions are handled through the AssistantPlatform abstraction:

### Microphone Permission (RECORD_AUDIO)
- Checked via `hasMicrophonePermission()`
- Requested via `requestMicrophonePermission()`
- Required for speech recognition (STT)
- Handled in `startListening()` method

### Contacts Permission (READ_CONTACTS)
- Checked via `hasContactsPermission()`
- Requested via `requestContactsPermission()`
- Required for contact resolution
- Handled during call command execution

### Phone Call Permission (CALL_PHONE)
- Checked via `hasCallPermission()`
- Requested via `requestCallPermission()`
- Required for initiating calls
- Handled during call command execution

### Bluetooth Permissions
- BLUETOOTH, BLUETOOTH_ADMIN, BLUETOOTH_CONNECT, BLUETOOTH_SCAN
- Handled via BluetoothManager in AssistantBridge
- Checked/requested through `hasBluetoothPermission()`/`requestBluetoothPermission()`

Permission flow pattern:
1. Flutter requests permission check via MethodChannel
2. AssistantBridge delegates to Android permission APIs
3. Result returned through MethodChannel callback
4. Pending results stored for async permission requests
5. onRequestPermissionsResult() handles user response
6. Result forwarded back to Flutter via stored pending result

## Call Safety

The call safety mechanism implements a multi-step confirmation process:

### Call Execution Flow:
1. **Contact Resolution** → Resolve voice command to contact
2. **Validation** → Verify contact exists and has phone number(s)
3. **Prepare Call** → Generate confirmation token via SafeCallPipeline
4. **Confirmation Required** → System awaits explicit user confirmation
5. **Explicit Confirmation** → User must confirm via UI or voice
6. **Call Execution** → Android ACTION_CALL initiated

### Safety Features:
- **Permission Validation** → Checks Contacts and CALL_PHONE permissions before proceeding
- **Contact Ownership** → Ensures resolved contact belongs to device
- **Phone Number Validation** → Normalizes and validates phone number format
- **Confirmation Tokens** → Time-limited tokens (60 second expiry) prevent replay attacks
- **Explicit Confirmation** → Requires deliberate user action to proceed
- **Error Handling** → Graceful handling of permission denials, missing contacts, etc.
- **State Management** → Clear state transitions prevent accidental execution

### Key Components:
- **SafeCallPipeline.kt** → Core safety logic in Android layer
- **confirmCall() Method** → Requires token and boolean confirmation
- **AssistantController** → Manages confirmation state (`awaitingConfirmation`)
- **UI Layer** → Presents confirmation dialog to user

## Known Issues

Based on code inspection and test analysis:

1. **Print Statements in Production Code** - Numerous `print()` statements throughout capabilities should be replaced with proper logging (avoid_print warnings from flutter analyze)

2. **Unnecessary Casts** - Several capabilities (spotify, whatsapp) contain unnecessary type casts that could be simplified

3. **Bluetooth Implementation Limitations** - 
   - `getBluetoothDevices()` always returns bonded devices only, ignoring `onlyBonded` parameter
   - No Bluetooth scanning capabilities implemented
   - Connection/disconnection uses basic APIs without error handling for edge cases

4. **Duplicate Permission Request Protection** - While protection exists, the logic could be simplified in some areas

5. **Wake Word Service** - Currently a mock implementation; actual wake-word detection not implemented in Phase 1

6. **STT/Listening State Timing** - Complex timing between `listening_stopped` and `final_transcript` events requires careful handling

7. **Command Execution Timing** - Potential race conditions if wake word fires during command processing (mitigated but needs verification)

8. **Test Coverage Gaps** - While tests exist, edge cases around simultaneous permission requests and rapid state transitions could be better covered

None of these issues represent critical bugs that break existing functionality, but they represent areas for improvement.

## Baseline Test Results

### flutter analyze
- **Issues Found**: 136 warnings (primarily avoid_print and unnecessary_cast)
- **Errors**: 0
- **Result**: Analysis completed successfully with only lint-level warnings

### flutter test
- **Total Tests**: 37 (from README)
- **Passing Tests**: 37
- **Failing Tests**: 0
- **Test Coverage**: Not measured but test suite exercises core functionality

### flutter build apk --debug
- **Result**: ✓ Built build\app\outputs\flutter-apk\app-debug.apk
- **Build Success**: Yes
- **APK Location**: build/app/outputs/flutter-apk/app-debug.apk

## Phase 2 Readiness

Based on the stabilization audit, JARVIS is **ready to begin Phase 2 work** with the following considerations:

### Readiness Indicators:
✅ Architecture understood and documented
✅ Existing capabilities listed and functional
✅ Permission and safety mechanisms documented
✅ Existing tests continue to pass
✅ Static analysis passes (warnings only)
✅ Debug APK builds successfully
✅ No major architectural changes made during Phase 1

### Recommended Preparations Before Phase 2:
1. **Address Lint Warnings** - Replace print() statements with proper logging to maintain code quality
2. **Review Permission Handling** - Ensure consistency across all capability permission requests
3. **Validate State Transitions** - Double-check complex timing in listening/processing states
4. **Document Extension Points** - Clearly mark where new capabilities should be added
5. **Maintain Backward Compatibility** - Ensure Phase 2 additions don't break existing Phase 1 functionality

### Risks to Address Before AOSP Work:
1. **State Management Complexity** - The AssistantController has complex state transitions that could be challenging to extend
2. **Permission Flow Fragmentation** - Permission handling is distributed across multiple layers
3. **Tight Coupling in AssistantController** - The controller contains significant logic that could benefit from further separation
4. **Event Handling Timing** - Asynchronous event processing requires careful timing considerations

The existing architecture provides a solid foundation for Phase 2 AOSP/system-level work. The layered separation between Flutter and Android layers means that AOSP work (JarvisSystemService, Binder services) can be implemented as a replacement for the current AssistantPlatform/Android layer without affecting the Flutter application layer.

Phase 2 readiness: **Yes, with minor preparatory work recommended**.