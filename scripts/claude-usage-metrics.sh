#!/bin/zsh
# Custom Metrics 예제 생산자: Claude Code 토큰 사용량을 JSON 으로 써 둔다.
# 설정 > Metrics > Custom Metrics 에서 출력 파일을 추가하면 대시보드 카드로 보인다.
# Claude Code 가 ~/.claude/projects 에 남기는 대화 기록(JSONL)만 읽고, 네트워크와 인증 정보는 쓰지 않는다.
# jq 가 필요하다(macOS 15 이상은 기본 포함, 그 전에는 brew install jq).
#
#   ./scripts/claude-usage-metrics.sh ~/custom-metrics/claude.json          # 한 번 쓰기
#   ./scripts/claude-usage-metrics.sh ~/custom-metrics/claude.json --watch  # 60초마다 갱신
set -euo pipefail

OUTPUT=${1:?usage: $0 <output.json> [--watch]}
PROJECTS=${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects
command -v jq > /dev/null || { echo "jq is required (brew install jq)" >&2; exit 1; }
mkdir -p "${OUTPUT:h}"

CACHE=${XDG_CACHE_HOME:-$HOME/Library/Caches}/RunHam/claude-usage
mkdir -p "$CACHE"

# 기록 한 줄을 집계에 필요한 필드만 남긴 한 줄로 줄인다. 파일마다 한 번만 돌려 $CACHE 에 둔다.
EXTRACT=$(cat <<'JQ'
def epoch: sub("\\.[0-9]+"; "") | fromdateiso8601;
fromjson?
| select(.type == "assistant" and .message.usage != null and .message.model != "<synthetic>")
| {key: "\(.message.id):\(.requestId)", time: (.timestamp | epoch), model: .message.model,
   input: (.message.usage.input_tokens // 0), output: (.message.usage.output_tokens // 0),
   cacheWrite: (.message.usage.cache_creation_input_tokens // 0),
   cacheRead: (.message.usage.cache_read_input_tokens // 0)}
JQ
)

# 5시간 블록은 ccusage 와 같은 방식으로 나눈다: 첫 응답 시각을 정시로 내린 때부터 5시간,
# 그 안에 5시간 넘게 쉬거나 5시간이 지나면 다음 응답부터 새 블록이다.
SUMMARY=$(cat <<'JQ'
def compact:
  if . >= 1e9 then "\((. / 1e8 | floor) / 10)B"
  elif . >= 1e6 then "\((. / 1e5 | floor) / 10)M"
  elif . >= 1e3 then "\((. / 1e2 | floor) / 10)K"
  else tostring end;
def duration: (. / 60 | ceil) as $m | if $m >= 60 then "\($m / 60 | floor)h \($m % 60)m" else "\($m)m" end;
def total: .input + .output + .cacheWrite + .cacheRead;
def tally:
  reduce .[] as $e ({input: 0, output: 0, cacheWrite: 0, cacheRead: 0, replies: 0};
    .input += $e.input | .output += $e.output
    | .cacheWrite += $e.cacheWrite | .cacheRead += $e.cacheRead | .replies += 1);
def blocks:
  reduce .[] as $e ([];
    if length == 0 or $e.time >= .[-1].start + 18000 or $e.time - .[-1].last >= 18000
    then . + [{start: (($e.time / 3600 | floor) * 3600), last: $e.time, entries: [$e]}]
    else .[-1].last = $e.time | .[-1].entries += [$e] end);

map(select(.time >= $week))
# 한 응답이 내용 블록마다 한 줄씩 기록되면서 같은 usage 가 반복되므로 한 번만 센다.
| unique_by(.key) | sort_by(.time)
| map(select(.time >= $today)) as $todayEntries
| ($todayEntries | tally) as $day
| tally as $recent
| (blocks | last) as $block
| (if $block != null and $now < $block.start + 18000 and $now - $block.last < 18000 then $block else null end) as $active
| ($day.input + $day.cacheWrite + $day.cacheRead) as $prompt
| {
    title: "Claude Code",
    symbol: "sparkles",
    metricsBarValue: ($day | total | compact),
    metrics: [
      if $active != null then
        {title: "5h block",
         formattedValue: "\($active.start + 18000 - $now | duration) left · \($active.entries | tally | total | compact)",
         normalizedValue: (($now - $active.start) / 18000 * 1000 | round / 1000)}
      else {title: "5h block", formattedValue: "Idle"} end,
      {title: "Today", formattedValue: "\($day | total | compact) tokens · \($day.replies) replies"},
      {title: "Input / Output", formattedValue: "\($day.input | compact) / \($day.output | compact)"},
      if $prompt > 0 then
        ($day.cacheRead / $prompt) as $hit
        | {title: "Cache hit", formattedValue: "\($hit * 100 | round)%", normalizedValue: ($hit * 1000 | round / 1000)}
      else {title: "Cache hit", formattedValue: "—"} end,
      {title: "Last 7 days", formattedValue: "\($recent | total | compact) tokens"},
      {title: "Top model",
       formattedValue: ($todayEntries | if length == 0 then "—"
                        else group_by(.model) | max_by(length) | .[0].model | sub("^claude-"; "") end)}
    ],
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
    for file in ${(0)"$(find "$PROJECTS" -name '*.jsonl' -mtime -8 -print0 2> /dev/null)"}; do
        cached=$CACHE/$(md5 -qs "$file").jsonl
        if [[ ! -e $cached || $file -nt $cached ]]; then
            { grep -hF '"type":"assistant"' "$file" || true; } | jq -cR "$EXTRACT" > "$cached.tmp"
            mv -f "$cached.tmp" "$cached"
        fi
        records+=("$cached")
    done
    find "$CACHE" -name '*.jsonl' -mtime +8 -delete

    # 같은 디렉터리에 임시 파일을 쓰고 rename 해서 반쯤 쓰인 파일을 읽지 않게 한다.
    tmp=$(mktemp "${OUTPUT:h}/.claude-usage.XXXXXX")
    cat /dev/null $records | jq -s --argjson now "$now" --argjson today "$today" --argjson week "$week" "$SUMMARY" > "$tmp"
    mv -f "$tmp" "$OUTPUT"
}

write_once
if [[ ${2:-} == --watch ]]; then
    while sleep 60; do write_once; done
fi
