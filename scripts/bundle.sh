#!/bin/zsh
# SwiftPM 실행 파일을 LSUIElement 메뉴바 앱(.app)으로 감싼다.
set -euo pipefail

ROOT=${0:A:h:h}
CONFIG=${1:-release}
APP="$ROOT/build/RunCatClone.app"

swift build --package-path "$ROOT" -c "$CONFIG"
BIN=$(swift build --package-path "$ROOT" -c "$CONFIG" --show-bin-path)/RunCatClone

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN" "$APP/Contents/MacOS/RunCatClone"

cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>RunCatClone</string>
    <key>CFBundleIdentifier</key><string>dev.personal.RunCatClone</string>
    <key>CFBundleName</key><string>RunCatClone</string>
    <key>CFBundleDisplayName</key><string>RunCat Clone</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleShortVersionString</key><string>0.1.0</string>
    <key>CFBundleVersion</key><string>1</string>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
</dict>
</plist>
PLIST

codesign --force --sign - "$APP" >/dev/null
echo "$APP"
