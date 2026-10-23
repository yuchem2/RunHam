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

## 문제가 생기면

- 파일을 읽을 수 없거나 형식이 맞지 않으면, 마지막으로 정상이던 내용을 그대로 보여 주고 카드에 **오류 발생**을 표시합니다.
- 파일을 지우거나 이름을 바꿔도 괜찮습니다. 같은 경로를 계속 지켜보다가 파일이 다시 생기면 다시 읽습니다.
