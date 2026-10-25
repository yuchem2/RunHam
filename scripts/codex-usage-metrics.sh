#!/bin/zsh
# Custom Metrics 예제 생산자: OpenAI Codex CLI 의 사용 한도와 토큰 사용량을 JSON 으로 써 둔다.
# 설정 > Metrics > Custom Metrics 에서 출력 파일을 추가하면 대시보드 카드로 보인다.
# Codex 가 ~/.codex/sessions 에 남기는 세션 기록(JSONL)만 읽고, 네트워크와 인증 정보는 쓰지 않는다.
# 사용 한도는 Codex 가 마지막 응답 때 받아 기록해 둔 값이라 Codex 를 쓰지 않는 동안에는 갱신되지 않는다.
# jq 가 필요하다(macOS 15 이상은 기본 포함, 그 전에는 brew install jq).
#
#   ./scripts/codex-usage-metrics.sh ~/custom-metrics/codex.json          # 한 번 쓰기
#   ./scripts/codex-usage-metrics.sh ~/custom-metrics/codex.json --watch  # 60초마다 갱신
set -euo pipefail

OUTPUT=${1:?usage: $0 <output.json> [--watch]}
SESSIONS=${CODEX_HOME:-$HOME/.codex}/sessions
command -v jq > /dev/null || { echo "jq is required (brew install jq)" >&2; exit 1; }
mkdir -p "${OUTPUT:h}"

CACHE=${XDG_CACHE_HOME:-$HOME/Library/Caches}/RunHam/codex-usage
mkdir -p "$CACHE"

# 세션 파일 하나를 응답마다 한 줄로 줄인다. token_count 이벤트의 total_token_usage 는 세션 누적값이라
# 바로 앞 값과의 차이를 그 응답의 사용량으로 본다(같은 값이 다시 기록되면 차이가 0 이라 건너뛴다).
EXTRACT=$(cat <<'JQ'
def epoch: sub("\\.[0-9]+"; "") | fromdateiso8601;
def window($time): if . == null then null
  else {usedPercent: .used_percent, minutes: .window_minutes,
        resetsAt: (.resets_at // (if .resets_in_seconds then $time + .resets_in_seconds else null end))} end;
foreach (inputs | fromjson?
         | select(.type == "turn_context" or (.type == "event_msg" and .payload.type == "token_count"))) as $line
  ({model: null, last: {input_tokens: 0, cached_input_tokens: 0, output_tokens: 0, total_tokens: 0}, emit: null};
   .emit = null
   | if $line.type == "turn_context" then .model = $line.payload.model
     else ($line.timestamp | epoch) as $time
       | (if $line.payload.rate_limits then
            .emit = {time: $time, limits: {primary: ($line.payload.rate_limits.primary | window($time)),
                                            secondary: ($line.payload.rate_limits.secondary | window($time))}}
          else . end)
       | ($line.payload.info.total_token_usage // null) as $total
       | if $total != null and $total.total_tokens > .last.total_tokens then
           .emit += {time: $time, model: .model,
                     input: ($total.input_tokens - .last.input_tokens),
                     cached: ($total.cached_input_tokens - .last.cached_input_tokens),
                     output: ($total.output_tokens - .last.output_tokens),
                     tokens: ($total.total_tokens - .last.total_tokens)}
           | .last = $total
         else . end
     end;
   .emit // empty)
JQ
)

SUMMARY=$(cat <<'JQ'
def compact:
  if . >= 1e9 then "\((. / 1e8 | floor) / 10)B"
  elif . >= 1e6 then "\((. / 1e5 | floor) / 10)M"
  elif . >= 1e3 then "\((. / 1e2 | floor) / 10)K"
  else tostring end;
def duration: (. / 60 | ceil) as $m
  | if $m >= 1440 then "\($m / 1440 | floor)d \($m % 1440 / 60 | floor)h"
    elif $m >= 60 then "\($m / 60 | floor)h \($m % 60)m" else "\($m)m" end;
def windowName: if . == 300 then "5h limit" elif . == 10080 then "Weekly limit"
  elif . == null then "Limit" elif . % 1440 == 0 then "\(. / 1440)d limit" else "\(. / 60 | round)h limit" end;
# 기록된 재설정 시각이 지났으면 그 뒤 사용량은 아직 모르므로 0% 로 둔다.
def limitRow:
  if .resetsAt != null and .resetsAt <= $now then
    {title: (.minutes | windowName), formattedValue: "Reset", normalizedValue: 0}
  else
    {title: (.minutes | windowName),
     formattedValue: "\(.usedPercent | round)% used" + (if .resetsAt then " · resets in \(.resetsAt - $now | duration)" else "" end),
     normalizedValue: (.usedPercent / 100)}
  end;

map(select(.time >= $week)) as $recent
| ($recent | map(select(.tokens != null))) as $usage
| ($usage | map(select(.time >= $today))) as $day
| ([$recent[] | select(.limits != null)] | max_by(.time) | .limits) as $limits
| ($day | map(.input) | add // 0) as $input
| ($day | map(.cached) | add // 0) as $cached
| ($day | map(.tokens) | add // 0) as $dayTokens
| {
    title: "Codex",
    symbol: "chevron.left.forwardslash.chevron.right",
    metricsBarValue: (if $limits.primary != null and ($limits.primary.resetsAt == null or $limits.primary.resetsAt > $now)
                      then "\($limits.primary.usedPercent | round)%" else ($dayTokens | compact) end),
    metrics: (
      [($limits.primary, $limits.secondary) | select(. != null) | limitRow]
      + [
        {title: "Today", formattedValue: "\($dayTokens | compact) tokens · \($day | length) replies"},
        {title: "Input / Output", formattedValue: "\($input - $cached | compact) / \($day | map(.output) | add // 0 | compact)"},
        if $input > 0 then
          {title: "Cache hit", formattedValue: "\($cached / $input * 100 | round)%", normalizedValue: ($cached / $input * 1000 | round / 1000)}
        else {title: "Cache hit", formattedValue: "—"} end,
        {title: "Last 7 days", formattedValue: "\($usage | map(.tokens) | add // 0 | compact) tokens"},
        {title: "Top model",
         formattedValue: ($day | map(select(.model != null)) | if length == 0 then "—"
                          else group_by(.model) | max_by(length) | .[0].model end)}
      ]),
    lastUpdatedDate: ($now | todate)
  }
JQ
)

write_once() {
    local now today week file cached tmp
    local -a records
    now=$(date +%s)
    today=$(date -j -v0H -v0M -v0S +%s)
    week=$(date -j -v-6d -v0H -v0M -v0S +%s)

    # 최근 8일 안에 바뀐 기록만 본다. 지난 기록은 거의 바뀌지 않으므로 파일이 캐시보다 새로울 때만 다시 줄인다.
    for file in ${(0)"$(find "$SESSIONS" -name '*.jsonl' -mtime -8 -print0 2> /dev/null)"}; do
        cached=$CACHE/$(md5 -qs "$file").jsonl
        if [[ ! -e $cached || $file -nt $cached ]]; then
            { grep -hE '"type":"(turn_context|event_msg)"' "$file" || true; } | jq -ncR "$EXTRACT" > "$cached.tmp"
            mv -f "$cached.tmp" "$cached"
        fi
        records+=("$cached")
    done
    find "$CACHE" -name '*.jsonl' -mtime +8 -delete

    # 같은 디렉터리에 임시 파일을 쓰고 rename 해서 반쯤 쓰인 파일을 읽지 않게 한다.
    tmp=$(mktemp "${OUTPUT:h}/.codex-usage.XXXXXX")
    cat /dev/null $records | jq -s --argjson now "$now" --argjson today "$today" --argjson week "$week" "$SUMMARY" > "$tmp"
    mv -f "$tmp" "$OUTPUT"
}

write_once
if [[ ${2:-} == --watch ]]; then
    while sleep 60; do write_once; done
fi
