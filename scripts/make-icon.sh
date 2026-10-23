#!/bin/zsh
# 앱 아이콘(Assets/AppIcon.icns)을 AppIconRenderer 그림으로 다시 만든다.
# 아이콘 그림을 바꿨을 때만 실행하고, 만든 .icns 는 저장소에 함께 커밋한다.
set -euo pipefail

ROOT=${0:A:h:h}
WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

swift build --package-path "$ROOT"
BIN_DIR=$(swift build --package-path "$ROOT" --show-bin-path)
"$BIN_DIR/RunHam" --export-app-icon "$WORK/AppIcon.iconset"
mkdir -p "$ROOT/Assets"
iconutil --convert icns "$WORK/AppIcon.iconset" --output "$ROOT/Assets/AppIcon.icns"
echo "$ROOT/Assets/AppIcon.icns"
