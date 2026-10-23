#!/bin/zsh
# SwiftPM 실행 파일을 LSUIElement 메뉴바 앱(.app)으로 감싼다.
set -euo pipefail

ROOT=${0:A:h:h}
CONFIG=${1:-release}
APP="$ROOT/build/RunCatClone.app"

swift build --package-path "$ROOT" -c "$CONFIG"
BIN_DIR=$(swift build --package-path "$ROOT" -c "$CONFIG" --show-bin-path)
RESOURCES="$BIN_DIR/RunCatClone_RunCatClone.bundle"

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp "$BIN_DIR/RunCatClone" "$APP/Contents/MacOS/RunCatClone"
# 문자열 테이블 등 SwiftPM 리소스 번들. 앱은 Contents/Resources 에서 먼저 찾는다(Localization.resources).
cp -R "$RESOURCES" "$APP/Contents/Resources/"

# 지원 언어 목록은 리소스 번들의 lproj 폴더에서 만든다. 새 언어 폴더를 추가하면 자동으로 포함된다.
LOCALIZATIONS=""
for dir in "$RESOURCES"/*.lproj(N) "$RESOURCES"/Contents/Resources/*.lproj(N); do
    LOCALIZATIONS+="        <string>${${dir:t}%.lproj}</string>"$'\n'
done

cat > "$APP/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>RunCatClone</string>
    <key>CFBundleIdentifier</key><string>dev.personal.RunCatClone</string>
    <key>CFBundleName</key><string>RunCatClone</string>
    <key>CFBundleDisplayName</key><string>RunCat Clone</string>
    <key>CFBundlePackageType</key><string>APPL</string>
    <key>CFBundleDevelopmentRegion</key><string>en</string>
    <key>CFBundleLocalizations</key>
    <array>
${LOCALIZATIONS}    </array>
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
