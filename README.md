# Master Voice

macOS-first, voice-driven computer control app.

## MVP Goal

No repetitive keyboard/mouse use for core flows:
- Activate with `Fn`
- Dictate text into focused input
- Run voice commands (`switch app`, `send`, `cancel`)
- Read or summarize selected text

See `docs/` for implementation-ready plan.

## Run The App

```bash
cd /Users/oguzhandogan/Documents/master-voice
make dev
```

This builds and launches a local `.app` bundle (`.run/MasterVoice.app`).

On first run grant:
- Microphone
- Speech Recognition
- Accessibility
- Input Monitoring (manually from System Settings if needed)

Important:
- Since app runs as `MasterVoice.app`, grant permissions to `MasterVoice` (not `Terminal`).

Usage:
- Press `Fn` -> start listening, press `Fn` again -> stop and execute
- Commands: `komut modu`, `dikte modu`, `okuma modu`
- Actions: `gonder`, `slack'e gec`, `codex'e gec`, `bunu oku`, `ozetle`

## CLI Prototype (Optional)

```bash
swift run master-voice-cli
# or
make cli
```

## Tests

```bash
swift test
# or
make test
```
