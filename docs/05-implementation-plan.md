# Implementation Plan (Code-Ready)

## Milestone 0 - Bootstrap (Day 1)

- Initialize Swift project structure
- Add permission checks for Microphone, Speech, Accessibility, Input Monitoring
- Add minimal status UI (`Idle`, `Listening`, `Command`)

Acceptance:
- App launches
- Permission status visible
- Missing permissions clearly reported

## Milestone 1 - Voice Pipeline (Day 2-3)

- Implement `AudioCaptureService`
- Implement `SpeechToTextService` streaming
- Wire `Fn` press/release to start/stop capture

Acceptance:
- Hold `Fn` -> speech transcript appears live
- Release `Fn` -> final transcript event emitted

## Milestone 2 - Intent + Modes (Day 3-4)

- Implement `VoiceMode` + `ModeController`
- Implement rule-based `IntentParser`
- Add command dictionary from `docs/03-command-dictionary.md`

Acceptance:
- `komut modu`, `dikte modu`, `okuma modu`, `iptal` work reliably

## Milestone 3 - Action Engine + Adapters (Day 4-6)

- Implement app switch command (`x'e geç`)
- Implement send command with app-specific key mapping
- Implement Codex + Slack adapters

Acceptance:
- `slack'e geç` and `codex'e geç` switch apps
- After dictation, `gönder` sends without keyboard/mouse

## Milestone 4 - Read/Summarize (Day 6-7)

- Implement selected-text fetch via accessibility
- Add `bunu oku` (TTS)
- Add `özetle` (local or API-backed summarizer abstraction)

Acceptance:
- Selected text is read aloud
- Summary generated for selected text

## Milestone 5 - Hardening (Day 8-9)

- Add retries and better feedback
- Add latency + error logs
- Add smoke tests for parser and key mappings

Acceptance:
- Core flows stable across at least Codex + Slack + one generic app

## Implementation-First Backlog

1. `Fn` monitor spike: verify standalone `Fn` reliability on target macOS version.
2. Permission onboarding screen.
3. Transcript overlay HUD.
4. Parser unit tests (TR phrases).
5. Slack/Codex send strategy + config file.
6. Selected text extractor.

## Definition of Done (MVP)

- User can:
  - Hold `Fn`, dictate text into focused input
  - Say `gönder` and send message
  - Switch between Codex and Slack by voice
  - Ask to read or summarize selected text
- No regular mouse/keyboard sequence required besides `Fn`.
