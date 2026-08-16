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

codesign --force --sign - "$APP"

echo "Built: $APP"
