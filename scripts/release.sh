#!/bin/zsh
# 릴리스용 zip 을 만든다(Apple Silicon 전용, ad-hoc 서명).
#   ./scripts/release.sh            → build/RunHam-<버전>.zip
#   ./scripts/release.sh --upload   → 위 zip 으로 GitHub 릴리스 v<버전> 을 만들고 올린다(ReleaseNotes/v<버전>.md 를 본문으로)
set -euo pipefail

ROOT=${0:A:h:h}
"$ROOT/scripts/bundle.sh" release >/dev/null

APP="$ROOT/build/RunHam.app"
VERSION=$(/usr/libexec/PlistBuddy -c "Print CFBundleShortVersionString" "$APP/Contents/Info.plist")
ZIP="$ROOT/build/RunHam-$VERSION.zip"

[[ $(lipo -archs "$APP/Contents/MacOS/RunHam") == arm64 ]] || { echo "arm64 빌드가 아닙니다" >&2; exit 1; }
codesign --verify --deep --strict "$APP"

# ditto 로 묶어야 확장 속성·심볼릭 링크가 그대로 남는다
rm -f "$ZIP"
ditto -c -k --keepParent "$APP" "$ZIP"
shasum -a 256 "$ZIP"

if [[ ${1:-} == --upload ]]; then
    NOTES="$ROOT/ReleaseNotes/v$VERSION.md"
    [[ -f $NOTES ]] || { echo "릴리스 노트가 없습니다: $NOTES" >&2; exit 1; }
    git -C "$ROOT" rev-parse "v$VERSION" >/dev/null
    gh release create "v$VERSION" "$ZIP" --repo yuchem2/RunHam --title "RunHam $VERSION" --notes-file "$NOTES" --verify-tag
fi
