#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"

APP="build/Homebrew Installer.app"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

swiftc -O -parse-as-library \
  -target arm64-apple-macosx13.0 \
  Sources/main.swift \
  -o "$APP/Contents/MacOS/HomebrewInstaller"

cp Resources/Info.plist "$APP/Contents/Info.plist"
cp Resources/askpass.sh "$APP/Contents/Resources/askpass.sh"
chmod 755 "$APP/Contents/Resources/askpass.sh"

# Sign with CODESIGN_IDENTITY if set (e.g. "Developer ID Application").
# Fall back to an ad-hoc signature for local development builds.
IDENTITY="${CODESIGN_IDENTITY:-}"
if [ -n "$IDENTITY" ]; then
  codesign --force --options runtime --timestamp --sign "$IDENTITY" "$APP"
else
  codesign --force --sign - "$APP"
fi

echo "Built: $APP"
