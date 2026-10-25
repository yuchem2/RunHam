#!/bin/zsh
# Custom Metrics 예제 생산자: 업그레이드할 Homebrew 패키지를 JSON 으로 써 둔다.
# 설정 > Metrics > Custom Metrics 에서 출력 파일을 추가하면 대시보드 카드로 보인다.
# brew update 는 하지 않는다. 마지막 brew update 때 받아 둔 정보로만 비교한다.
#
#   ./scripts/homebrew-metrics.sh ~/custom-metrics/homebrew.json          # 한 번 쓰기
#   ./scripts/homebrew-metrics.sh ~/custom-metrics/homebrew.json --watch  # 30분마다 갱신
set -euo pipefail

OUTPUT=${1:?usage: $0 <output.json> [--watch]}
command -v brew > /dev/null || { echo "brew is required" >&2; exit 1; }
command -v jq > /dev/null || { echo "jq is required (brew install jq)" >&2; exit 1; }
mkdir -p "${OUTPUT:h}"

SUMMARY=$(cat <<'JQ'
([.formulae[], .casks[]] | map(.name)) as $names
| ($names | length) as $outdated
| ($formulae + $casks) as $installed
| {
    title: "Homebrew",
    symbol: "mug.fill",
    metricsBarValue: "\($outdated)",
    metrics: [
      {title: "Outdated", formattedValue: "\(.formulae | length) formulae · \(.casks | length) casks"},
      {title: "Next up",
       formattedValue: (if $outdated == 0 then "Nothing to upgrade"
                        else ($names[:3] | join(", ")) + (if $outdated > 3 then " +\($outdated - 3)" else "" end) end)},
      {title: "Installed",
       formattedValue: "\($installed) · \(if $installed > 0 then (($installed - $outdated) / $installed * 100 | round) else 100 end)% up to date",
       normalizedValue: (if $installed > 0 then (($installed - $outdated) / $installed * 1000 | round / 1000) else 1 end)},
      {title: "Last brew update", formattedValue: $updated}
    ],
    lastUpdatedDate: (now | floor | todate)
  }
JQ
)

write_once() {
    local outdated formulae casks fetched updated tmp
    outdated=$(HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --json=v2)
    formulae=$(brew list --formula -1 | wc -l | tr -d ' ')
    casks=$(brew list --cask -1 | wc -l | tr -d ' ')
    # brew update 는 매번 Homebrew 저장소를 fetch 하므로 FETCH_HEAD 의 수정 시각이 마지막 update 시각이다.
    fetched=$(brew --repository)/.git/FETCH_HEAD
    updated=$([[ -e $fetched ]] && LC_ALL=C date -r "$(stat -f %m "$fetched")" '+%b %-d %H:%M' || echo "Never")

    # 같은 디렉터리에 임시 파일을 쓰고 rename 해서 반쯤 쓰인 파일을 읽지 않게 한다.
    tmp=$(mktemp "${OUTPUT:h}/.homebrew.XXXXXX")
    jq --argjson formulae "$formulae" --argjson casks "$casks" --arg updated "$updated" "$SUMMARY" <<< "$outdated" > "$tmp"
    mv -f "$tmp" "$OUTPUT"
}

write_once
if [[ ${2:-} == --watch ]]; then
    while sleep 1800; do write_once; done
fi
