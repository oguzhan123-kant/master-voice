#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/.run/MasterVoice.app"
CONTENTS_DIR="$APP_DIR/Contents"
MACOS_DIR="$CONTENTS_DIR/MacOS"

NO_OPEN=0
if [[ "${1:-}" == "--no-open" ]]; then
  NO_OPEN=1
fi

cd "$ROOT_DIR"
swift build -c debug --product master-voice

mkdir -p "$MACOS_DIR"
cp "$ROOT_DIR/.build/debug/master-voice" "$MACOS_DIR/MasterVoice"
cp "$ROOT_DIR/Sources/MasterVoice/Resources/Info.plist" "$CONTENTS_DIR/Info.plist"
chmod +x "$MACOS_DIR/MasterVoice"

# Ad-hoc sign to keep TCC identity consistent.
codesign --force --deep --sign - "$APP_DIR" >/dev/null 2>&1 || true

if [[ "$NO_OPEN" -eq 0 ]]; then
  open "$APP_DIR"
fi
