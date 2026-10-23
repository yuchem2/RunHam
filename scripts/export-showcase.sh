#!/bin/zsh
# 저장소에 넣어 두는 이미지를 다시 만든다.
#   Runners/<id>/        기본 러너 프레임 PNG + 미리보기 GIF (러너를 바꾸거나 추가했을 때)
#   Assets/readme/       README 화면 (샘플 수치로 그린 대시보드·설정·커스텀 러너 편집기)
set -euo pipefail

ROOT=${0:A:h:h}
swift build --package-path "$ROOT"
BIN="$(swift build --package-path "$ROOT" --show-bin-path)/RunHam"
"$BIN" --export-runners "$ROOT/Runners"
"$BIN" --export-readme "$ROOT/Assets/readme"
echo "$ROOT/Runners"
echo "$ROOT/Assets/readme"
