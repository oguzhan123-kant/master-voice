# Architecture (Code-Ready)

## Stack Decision

- Language: Swift 5.10+
- Runtime: macOS app process (AppKit/SwiftUI shell)
- Voice input: `AVAudioEngine` + `Speech` framework
- Command execution:
  - `AXUIElement` for focused element inspection/actions
  - `CGEvent` for keyboard shortcuts (send, app switch fallbacks)
- Voice output: `AVSpeechSynthesizer` (optional for confirmations)

## Core Modules

1. `AudioCaptureService`
   - Starts/stops microphone stream
   - Exposes PCM frames to speech pipeline

2. `SpeechToTextService`
   - Streaming transcription
   - Partial + final transcript callbacks

3. `ModeController`
   - Owns current mode: `idle`, `dictation`, `command`, `read`
   - Handles `Fn` press/release transition

4. `IntentParser`
   - Rule-based parser for MVP
   - Maps transcript -> `Intent`

5. `ActionEngine`
   - Executes parsed intents
   - Delegates app-specific behavior to adapters

6. `AppAdapterRegistry`
   - `CodexAdapter`, `SlackAdapter`, `GenericTextAppAdapter`
   - `sendMessage()`, `focusComposer()`, `openApp()`

7. `SelectionReaderService`
   - Reads currently selected text via accessibility APIs
   - Passes text to summarize/read pipeline

8. `FeedbackService`
   - Beep, status HUD, optional TTS confirmations

## Suggested Folder Layout

```text
Sources/
  App/
    MasterVoiceApp.swift
    AppCoordinator.swift
  Core/
    Mode/
      ModeController.swift
      VoiceMode.swift
    Intent/
      Intent.swift
      IntentParser.swift
    Action/
      ActionEngine.swift
      ActionError.swift
  Services/
    Audio/
      AudioCaptureService.swift
    Speech/
      SpeechToTextService.swift
    Accessibility/
      AccessibilityPermissionService.swift
      SelectionReaderService.swift
    Input/
      FnHotkeyMonitor.swift
    Feedback/
      FeedbackService.swift
  Adapters/
    AppAdapter.swift
    CodexAdapter.swift
    SlackAdapter.swift
    GenericAdapter.swift
```

## Domain Model (MVP)

```swift
enum VoiceMode {
    case idle
    case dictation
    case command
    case read
}

enum Intent {
    case switchApp(name: String)
    case send
    case cancel
    case readSelection
    case summarizeSelection
    case dictate(text: String)
    case unknown(raw: String)
}
```

## Permission Gate at Startup

Startup flow blocks command execution until all required permissions are granted:
1. Accessibility
2. Input Monitoring
3. Microphone + Speech Recognition

If any missing, show guided setup screen.
