#!/bin/zsh
# Custom Metrics 예제 생산자: GitHub 에서 나를 기다리는 일(리뷰 요청, 내 PR 의 CI, 할당된 이슈)을 JSON 으로 써 둔다.
# 설정 > Metrics > Custom Metrics 에서 출력 파일을 추가하면 대시보드 카드로 보인다.
# gh 가 필요하다(brew install gh 후 gh auth login). GraphQL 요청 한 번과 REST 요청 한 번만 보낸다.
#
#   ./scripts/github-metrics.sh ~/custom-metrics/github.json          # 한 번 쓰기
#   ./scripts/github-metrics.sh ~/custom-metrics/github.json --watch  # 5분마다 갱신
set -euo pipefail

OUTPUT=${1:?usage: $0 <output.json> [--watch]}
command -v gh > /dev/null || { echo "gh is required (brew install gh)" >&2; exit 1; }
command -v jq > /dev/null || { echo "jq is required (brew install jq)" >&2; exit 1; }
mkdir -p "${OUTPUT:h}"

QUERY='{
  viewer { login }
  reviews: search(query: "is:pr is:open review-requested:@me archived:false", type: ISSUE) { issueCount }
  mine: search(query: "is:pr is:open author:@me archived:false", type: ISSUE, first: 50) {
    issueCount
    nodes { ... on PullRequest { isDraft commits(last: 1) { nodes { commit { statusCheckRollup { state } } } } } }
  }
  issues: search(query: "is:issue is:open assignee:@me archived:false", type: ISSUE) { issueCount }
}'

SUMMARY=$(cat <<'JQ'
.data as $d
| [$d.mine.nodes[] | .commits.nodes[0].commit.statusCheckRollup.state // "NONE"] as $checks
| ($checks | map(select(. == "FAILURE" or . == "ERROR")) | length) as $failing
| ($checks | map(select(. == "PENDING" or . == "EXPECTED")) | length) as $pending
| {
    title: "GitHub",
    symbol: "arrow.triangle.pull",
    metricsBarValue: "\($d.reviews.issueCount)",
    metrics: [
      {title: "Account", formattedValue: "@\($d.viewer.login)"},
      {title: "Review requests", formattedValue: "\($d.reviews.issueCount)"},
      {title: "My open PRs",
       formattedValue: "\($d.mine.issueCount) · \($d.mine.nodes | map(select(.isDraft)) | length) draft"},
      if ($checks | length) > 0 then
        {title: "CI on my PRs",
         formattedValue: (if $failing > 0 then "\($failing) failing" elif $pending > 0 then "\($pending) running" else "All passing" end),
         normalizedValue: ((($checks | length) - $failing) / ($checks | length) * 1000 | round / 1000)}
      else {title: "CI on my PRs", formattedValue: "—"} end,
      {title: "Assigned issues", formattedValue: "\($d.issues.issueCount)"},
      {title: "Unread notifications", formattedValue: (if $unread >= 50 then "50+" else "\($unread)" end)}
    ],
    lastUpdatedDate: (now | floor | todate)
  }
JQ
)

write_once() {
    local response unread tmp
    # 네트워크가 끊기거나 로그인이 풀리면 파일을 그대로 두어 RunHam 이 마지막 카드를 계속 보이게 한다.
    response=$(gh api graphql -f query="$QUERY") || { echo "gh api graphql failed" >&2; return 0; }
    unread=$(gh api 'notifications?per_page=50' --jq length 2> /dev/null || echo 0)

    # 같은 디렉터리에 임시 파일을 쓰고 rename 해서 반쯤 쓰인 파일을 읽지 않게 한다.
    tmp=$(mktemp "${OUTPUT:h}/.github.XXXXXX")
    jq --argjson unread "$unread" "$SUMMARY" <<< "$response" > "$tmp"
    mv -f "$tmp" "$OUTPUT"
}

write_once
if [[ ${2:-} == --watch ]]; then
    while sleep 300; do write_once; done
fi
