# Command Dictionary (MVP)

## Mode Switching

- `komut modu`
- `dikte modu`
- `okuma modu`
- `iptal`

## App Navigation

- `codex'e geç`
- `slack'e geç`
- `x'e geç` (generic app name)

## Messaging

- `gönder`
- `mesajı gönder`

## Read/Summarize

- `bunu oku`
- `seçili metni oku`
- `özetle`
- `seçili metni özetle`

## Dictation Pattern

- `yaz: <metin>`

If in dictation mode, all non-command utterances default to `dictate(text:)`.

## Intent Parsing Rules

1. Normalize text: lowercase, trim, Turkish apostrophe variants.
2. Exact command match first.
3. Prefix match (`x'e geç`, `yaz:`).
4. Fallback:
   - In `command` mode -> `unknown`
   - In `dictation` mode -> `dictate(text:)`

## Send Key Mapping

- App overrides:
  - `Codex`: `Enter` (default)
  - `Slack`: `Enter` or `Cmd+Enter` (configurable)
- Global fallback: `Enter`

Store in local config:

```json
{
  "sendBindings": {
    "Codex": "enter",
    "Slack": "enter"
  }
}
```
