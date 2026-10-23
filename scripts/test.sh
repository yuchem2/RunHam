#!/bin/zsh
# Command Line Tools 만 설치된 환경에선 Swift Testing 매크로 플러그인 경로를 직접 넘겨야 한다.
set -euo pipefail

ROOT=${0:A:h:h}
PLUGINS="$(xcode-select -p)/usr/lib/swift/host/plugins/testing"

if [[ -d "$PLUGINS" ]]; then
    swift test --package-path "$ROOT" -Xswiftc -plugin-path -Xswiftc "$PLUGINS" "$@"
else
    swift test --package-path "$ROOT" "$@"
fi
