# MVP Scope (v1)

## Product Objective

Enable end-to-end voice control for personal daily workflows on macOS, starting with Codex + Slack style messaging flows.

## In-Scope

- Activation: `Fn` key (push-to-talk)
- Two modes:
  - `DICTATION_MODE`: transcribe speech into currently focused text input
  - `COMMAND_MODE`: execute intents (`send`, `switch app`, `cancel`, `read`, `summarize`)
- App switching by voice
- Send action by voice after dictation
- Read/summarize selected text
- Basic confirmation feedback (beep + small on-screen status)

## Out-of-Scope (for MVP)

- Full-screen OCR reading
- Multi-step autonomous desktop agents
- Cloud account sync / user profiles
- Non-macOS platforms

## Hard Constraints

- macOS only
- Works with local system permissions:
  - Microphone
  - Accessibility
  - Input Monitoring
- Low latency interaction (< 500ms perceived command response, excluding long summaries)

## Key Risks

- `Fn` as standalone trigger is harder than regular hotkeys; may need event tap handling of modifier changes.
- App-specific send behavior differs (`Enter` vs `Cmd+Enter`).
- Focus detection reliability in Electron apps may vary.
