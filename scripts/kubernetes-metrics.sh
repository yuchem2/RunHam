#!/bin/zsh
# Custom Metrics 예제 생산자: 지금 kubectl 컨텍스트의 노드와 Pod 상태를 JSON 으로 써 둔다.
# 설정 > Metrics > Custom Metrics 에서 출력 파일을 추가하면 대시보드 카드로 보인다.
# 읽기만 한다(get nodes, get pods). 네임스페이스는 컨텍스트에 정한 것을 따르고, 없으면 default 다.
#
#   ./scripts/kubernetes-metrics.sh ~/custom-metrics/kubernetes.json          # 한 번 쓰기
#   ./scripts/kubernetes-metrics.sh ~/custom-metrics/kubernetes.json --watch  # 60초마다 갱신
set -euo pipefail

OUTPUT=${1:?usage: $0 <output.json> [--watch]}
command -v kubectl > /dev/null || { echo "kubectl is required" >&2; exit 1; }
command -v jq > /dev/null || { echo "jq is required (brew install jq)" >&2; exit 1; }
mkdir -p "${OUTPUT:h}"

# $nodes 와 $pods 는 kubectl get -o json 결과. 클러스터에 닿지 않으면 $pods 가, 노드 권한이 없으면 $nodes 가 null.
SUMMARY=$(cat <<'JQ'
def ratio($a; $b): if $b > 0 then ($a / $b * 1000 | round / 1000) else 1 end;
def ready: .status.containerStatuses // [] | length > 0 and all(.ready);
def reason:
  [.status.containerStatuses // [] | .[] | .state.waiting.reason // .state.terminated.reason // empty][0]
  // .status.reason // .status.phase;
{
  title: "Kubernetes",
  symbol: "circle.hexagongrid.fill",
  lastUpdatedDate: (now | floor | todate)
}
+ if $context == "" then
    {metricsBarValue: "—", metrics: [{title: "Context", formattedValue: "Not set"}]}
  elif $pods == null then
    {metricsBarValue: "off", metrics: [
      {title: "Context", formattedValue: $context},
      {title: "Cluster", formattedValue: "Unreachable"}]}
  else
    # 끝난 Job 의 Pod(Succeeded)는 정상으로 보고 따로 세지 않는다.
    ($pods.items | map(select(.status.phase != "Succeeded"))) as $live
    | ($live | map(select(ready | not))) as $bad
    | {
        metricsBarValue: "\($live | length - ($bad | length))/\($live | length)",
        metrics: [
          {title: "Context", formattedValue: "\($context) · \($namespace)"},
          if $nodes == null then {title: "Nodes", formattedValue: "—"}
          else
            ($nodes.items | map(select(any(.status.conditions[]; .type == "Ready" and .status == "True"))) | length) as $up
            | {title: "Nodes", formattedValue: "\($up)/\($nodes.items | length) ready", normalizedValue: ratio($up; $nodes.items | length)}
          end,
          {title: "Pods", formattedValue: "\($live | length - ($bad | length))/\($live | length) ready",
           normalizedValue: ratio($live | length - ($bad | length); $live | length)},
          {title: "Not ready",
           formattedValue: (if $bad == [] then "None"
                            else "\($bad[0].metadata.name) (\($bad[0] | reason))"
                                 + (if ($bad | length) > 1 then " +\($bad | length - 1)" else "" end) end)},
          {title: "Restarts", formattedValue: "\([$live[] | .status.containerStatuses // [] | .[].restartCount] | add // 0)"}
        ]
      }
  end
JQ
)

write_once() {
    local context namespace nodes pods tmp
    context=$(kubectl config current-context 2> /dev/null || true)
    namespace=$(kubectl config view --minify -o 'jsonpath={..namespace}' 2> /dev/null || true)
    namespace=${namespace:-default}
    nodes=null pods=null
    if [[ -n $context ]]; then
        pods=$(kubectl get pods -n "$namespace" -o json --request-timeout=10s 2> /dev/null) || pods=null
        nodes=$(kubectl get nodes -o json --request-timeout=10s 2> /dev/null) || nodes=null
    fi

    # 같은 디렉터리에 임시 파일을 쓰고 rename 해서 반쯤 쓰인 파일을 읽지 않게 한다.
    tmp=$(mktemp "${OUTPUT:h}/.kubernetes.XXXXXX")
    jq -n --arg context "$context" --arg namespace "$namespace" \
        --argjson nodes "$nodes" --argjson pods "$pods" "$SUMMARY" > "$tmp"
    mv -f "$tmp" "$OUTPUT"
}

write_once
if [[ ${2:-} == --watch ]]; then
    while sleep 60; do write_once; done
fi
