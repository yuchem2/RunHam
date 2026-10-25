# 커스텀 메트릭 형식

[English](custom-metrics.md) · **한국어**

JSON 파일을 RunHam에 등록하면 대시보드 카드가 됩니다. RunHam이 파일을 지켜보다가 바뀔 때마다 카드를 다시 그리므로,
파일을 쓸 수 있는 것이면 무엇이든(셸 스크립트, cron, CI 작업, 홈 서버) 메뉴바에 띄울 수 있습니다.

- JSON 스키마: [`custom-metrics.schema.json`](custom-metrics.schema.json)
- 예제: [`examples/`](examples/)

## 예제

```json
{
  "title": "Build Server",
  "symbol": "hammer.fill",
  "metricsBarValue": "3/4",
  "metrics": [
    { "title": "Status", "formattedValue": "Healthy" },
    { "title": "Queue", "formattedValue": "3 of 4 jobs", "normalizedValue": 0.75 },
    { "title": "Disk", "formattedValue": "42%", "normalizedValue": 0.42 }
  ],
  "lastUpdatedDate": "2026-10-23T00:00:00Z"
}
```

## 필드

| 필드 | 타입 | 필수 | 설명 |
|---|---|:---:|---|
| `title` | string | ✓ | 카드 제목 |
| `symbol` | string | | 제목 옆에 보일 [SF Symbols](https://developer.apple.com/sf-symbols/) 이름. 없으면 `chart.bar.horizontal.page.fill` |
| `metricsBarValue` | string | | 메트릭스 바에 보일 짧은 글자. **설정 › 메트릭**에서 이 항목을 켜면 보이고, 없으면 `---` |
| `metrics` | array | ✓ | 카드의 줄들(위에서 아래로) |
| `metrics[].title` | string | ✓ | 줄 이름 |
| `metrics[].formattedValue` | string | ✓ | 값 글자. 적은 그대로 보이므로 숫자·단위는 직접 꾸며 넣습니다 |
| `metrics[].normalizedValue` | number | | 0~1. 있으면 줄 아래에 진행 막대를 그립니다. 범위를 벗어나면 0~1로 자릅니다 |
| `lastUpdatedDate` | string | ✓ | 시간대가 붙은 ISO 8601 날짜·시각(예: `2026-10-23T09:00:00Z`, `2026-10-23T18:00:00.250+09:00`). "…전 업데이트됨"으로 보입니다 |

모르는 필드는 무시하므로 같은 파일에 다른 데이터를 함께 두어도 됩니다.

## 파일을 안전하게 갱신하기

같은 폴더에 임시 파일을 쓴 뒤 이름을 바꿔 덮어쓰세요. 그러면 RunHam이 반쯤 쓰인 파일을 읽지 않습니다.

```bash
tmp=$(mktemp ~/custom-metrics/.load.XXXXXX)
echo "$json" > "$tmp"
mv -f "$tmp" ~/custom-metrics/load.json
```

[`scripts/custom-metrics-example.sh`](../scripts/custom-metrics-example.sh)가 이 방식으로 5초마다 시스템 부하를 기록합니다.

```bash
./scripts/custom-metrics-example.sh ~/custom-metrics/load.json --watch
```

## Claude Code 사용량

[`scripts/claude-usage-metrics.sh`](../scripts/claude-usage-metrics.sh)는 [Claude Code](https://claude.com/claude-code) 토큰 사용량을 카드로 만듭니다.
Claude Code가 `~/.claude/projects`에 남기는 대화 기록만 읽으며, 네트워크로 보내거나 인증 정보를 쓰지 않습니다.

```bash
./scripts/claude-usage-metrics.sh ~/custom-metrics/claude.json --watch   # 60초마다 갱신
```

| 줄 | 보여 주는 것 |
|---|---|
| 5h block | 지금 5시간 블록의 남은 시간과 토큰. 블록이 지날수록 막대가 찹니다 |
| Today | 자정 이후 토큰과 응답 수. 메트릭스 바에도 이 값이 보입니다 |
| Input / Output | 오늘 캐시를 거치지 않은 입력 토큰과 출력 토큰 |
| Cache hit | 오늘 입력 중 프롬프트 캐시에서 읽은 비율 |
| Last 7 days | 오늘을 포함한 최근 7일 토큰 |
| Top model | 오늘 가장 많이 응답한 모델 |

- 블록은 [ccusage](https://github.com/ryoppippi/ccusage)와 같은 방식으로 나눕니다. 첫 응답 시각을 정시로 내린 때부터 5시간입니다.
  실제 요금제 한도와 다를 수 있으니 어림값으로 보세요.
- 토큰 수에는 캐시 읽기·쓰기가 들어가므로 직접 입력한 양보다 훨씬 크게 보입니다.
- `jq`가 필요합니다(macOS 15 이상은 기본 포함, 그 전에는 `brew install jq`). 기록이 다른 곳에 있으면 `CLAUDE_CONFIG_DIR`을 지정하세요.
- 바뀌지 않은 기록은 `~/Library/Caches/RunHam/claude-usage`에 캐시하므로 처음 한 번만 전체를 읽습니다.
- 출력 예: [`examples/claude-usage.json`](examples/claude-usage.json)

## 문제가 생기면

- 파일을 읽을 수 없거나 형식이 맞지 않으면, 마지막으로 정상이던 내용을 그대로 보여 주고 카드에 **오류 발생**을 표시합니다.
- 파일을 지우거나 이름을 바꿔도 괜찮습니다. 같은 경로를 계속 지켜보다가 파일이 다시 생기면 다시 읽습니다.
