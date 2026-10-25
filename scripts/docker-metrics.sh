#!/bin/zsh
# Custom Metrics 예제 생산자: Docker 컨테이너와 디스크 사용량을 JSON 으로 써 둔다.
# 설정 > Metrics > Custom Metrics 에서 출력 파일을 추가하면 대시보드 카드로 보인다.
# Docker Desktop, OrbStack, colima 등 docker CLI 가 붙는 엔진이면 된다. 엔진이 꺼져 있으면 꺼짐으로 표시한다.
#
#   ./scripts/docker-metrics.sh ~/custom-metrics/docker.json          # 한 번 쓰기
#   ./scripts/docker-metrics.sh ~/custom-metrics/docker.json --watch  # 30초마다 갱신
set -euo pipefail

OUTPUT=${1:?usage: $0 <output.json> [--watch]}
command -v docker > /dev/null || { echo "docker is required" >&2; exit 1; }
command -v jq > /dev/null || { echo "jq is required (brew install jq)" >&2; exit 1; }
mkdir -p "${OUTPUT:h}"

# $info 는 docker info, $df 는 docker system df 의 줄들(종류마다 한 줄)이다. 엔진이 꺼져 있으면 $info 가 null.
SUMMARY=$(cat <<'JQ'
def row($type; $title):
  ($df[] | select(.Type == $type)) as $r
  | {title: $title, formattedValue: "\($r.TotalCount) · \($r.Size) (\($r.Reclaimable | sub(" \\(.*\\)"; "")) reclaimable)"};
{
  title: "Docker",
  symbol: "shippingbox.fill",
  metricsBarValue: (if $info == null then "off" else "\($info.ContainersRunning)" end),
  metrics: (
    if $info == null then [{title: "Engine", formattedValue: "Not running"}]
    else [
      {title: "Engine", formattedValue: "\($info.Name) · \($info.ServerVersion)"},
      {title: "Containers",
       formattedValue: "\($info.ContainersRunning) running / \($info.Containers)",
       normalizedValue: (if $info.Containers > 0 then ($info.ContainersRunning / $info.Containers * 1000 | round / 1000) else 0 end)},
      row("Images"; "Images"),
      row("Local Volumes"; "Volumes"),
      row("Build Cache"; "Build cache")
    ] end),
  lastUpdatedDate: (now | floor | todate)
}
JQ
)

write_once() {
    local info df tmp
    # 엔진이 꺼져 있으면 docker info 가 실패하면서도 빈 값으로 채운 JSON 을 내놓으므로 종료 코드로 가른다.
    if info=$(docker info --format '{{json .}}' 2> /dev/null); then
        df=$(docker system df --format '{{json .}}' | jq -s .)
    else
        info=null df='[]'
    fi

    # 같은 디렉터리에 임시 파일을 쓰고 rename 해서 반쯤 쓰인 파일을 읽지 않게 한다.
    tmp=$(mktemp "${OUTPUT:h}/.docker.XXXXXX")
    jq -n --argjson info "$info" --argjson df "$df" "$SUMMARY" > "$tmp"
    mv -f "$tmp" "$OUTPUT"
}

write_once
if [[ ${2:-} == --watch ]]; then
    while sleep 30; do write_once; done
fi
