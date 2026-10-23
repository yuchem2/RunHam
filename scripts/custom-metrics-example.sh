#!/bin/zsh
# Custom Metrics 예제 생산자: 시스템 부하 정보를 JSON 으로 써 둔다.
# 설정 > Metrics > Custom Metrics 에서 출력 파일을 추가하면 대시보드 카드로 보인다.
#
#   ./scripts/custom-metrics-example.sh ~/custom-metrics/load.json          # 한 번 쓰기
#   ./scripts/custom-metrics-example.sh ~/custom-metrics/load.json --watch  # 5초마다 갱신
set -euo pipefail

OUTPUT=${1:?usage: $0 <output.json> [--watch]}
mkdir -p "${OUTPUT:h}"

write_once() {
    local cores load1 load5 procs uptime_text ratio now tmp
    cores=$(sysctl -n hw.logicalcpu)
    read -r load1 load5 _ <<< "$(sysctl -n vm.loadavg | tr -d '{}')"
    procs=$(ps -A -o pid= | wc -l | tr -d ' ')
    uptime_text=$(uptime | sed -E 's/.*up ([^,]+),.*/\1/')
    ratio=$(awk -v l="$load1" -v c="$cores" 'BEGIN { r = l / c; if (r > 1) r = 1; printf "%.3f", r }')
    now=$(date -u +%Y-%m-%dT%H:%M:%SZ)

    # 같은 디렉터리에 임시 파일을 쓰고 rename 해서 반쯤 쓰인 파일을 읽지 않게 한다.
    tmp=$(mktemp "${OUTPUT:h}/.custom-metrics.XXXXXX")
    cat > "$tmp" <<JSON
{
  "title": "Load Average",
  "symbol": "speedometer",
  "metricsBarValue": "$load1",
  "metrics": [
    { "title": "1 min", "formattedValue": "$load1 / $cores cores", "normalizedValue": $ratio },
    { "title": "5 min", "formattedValue": "$load5" },
    { "title": "Processes", "formattedValue": "$procs" },
    { "title": "Uptime", "formattedValue": "$uptime_text" }
  ],
  "lastUpdatedDate": "$now"
}
JSON
    mv -f "$tmp" "$OUTPUT"
}

write_once
if [[ ${2:-} == --watch ]]; then
    while sleep 5; do write_once; done
fi
