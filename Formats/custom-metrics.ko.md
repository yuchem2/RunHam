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

## 바로 쓰는 카드

[`scripts/`](../scripts/)의 스크립트 하나가 카드 하나를 씁니다. 한 번 실행해 보고, `--watch`를 붙여 계속 갱신하게 한 뒤
**설정 › 메트릭 › 사용자 지정 메트릭**에서 파일을 추가하세요.

```bash
./scripts/github-metrics.sh ~/custom-metrics/github.json --watch
```

| 스크립트 | 카드 | 필요한 것 | 갱신 | 메트릭스 바 | 출력 예 |
|---|---|---|---|---|---|
| [`claude-usage-metrics.sh`](../scripts/claude-usage-metrics.sh) | Claude Code 토큰과 5시간 블록 | `jq` | 60초 | 오늘 토큰 | [claude-usage.json](examples/claude-usage.json) |
| [`codex-usage-metrics.sh`](../scripts/codex-usage-metrics.sh) | Codex 사용 한도와 토큰 | `jq` | 60초 | 5시간 한도 사용률 | [codex-usage.json](examples/codex-usage.json) |
| [`github-metrics.sh`](../scripts/github-metrics.sh) | 리뷰 요청, 내 PR과 CI, 할당된 이슈, 읽지 않은 알림 | `gh` 로그인 | 5분 | 리뷰 요청 수 | [github.json](examples/github.json) |
| [`docker-metrics.sh`](../scripts/docker-metrics.sh) | 엔진, 컨테이너, 이미지·볼륨·빌드 캐시 용량 | `docker` | 30초 | 실행 중인 컨테이너 | [docker.json](examples/docker.json) |
| [`homebrew-metrics.sh`](../scripts/homebrew-metrics.sh) | 업그레이드할 formula와 cask | `brew` | 30분 | 업그레이드할 패키지 | [homebrew.json](examples/homebrew.json) |
| [`kubernetes-metrics.sh`](../scripts/kubernetes-metrics.sh) | 현재 컨텍스트·네임스페이스의 노드, Pod, 재시작 | `kubectl` | 60초 | 준비된 Pod | [kubernetes.json](examples/kubernetes.json) |

- 모두 읽기만 합니다. `brew update`를 하지 않고, Docker와 클러스터에도 아무것도 바꾸지 않습니다.
- Docker가 꺼져 있거나 클러스터에 닿지 않으면 카드에 그렇게 표시합니다. GitHub에 닿지 않으면 파일을 그대로 두므로
  RunHam이 마지막 카드를 보여 주고 "…전 업데이트됨"이 계속 늘어납니다.
- `jq`는 macOS 15 이상에 기본으로 들어 있습니다. macOS 14에서는 `brew install jq`를 실행하세요.

### Claude Code

[Claude Code](https://claude.com/claude-code)가 `~/.claude/projects`에 남기는 대화 기록만 읽으며, 네트워크로 보내거나 인증 정보를 쓰지 않습니다.

| 줄 | 보여 주는 것 |
|---|---|
| 5h block | 지금 5시간 블록의 남은 시간과 토큰. 블록이 지날수록 막대가 찹니다 |
| Today | 자정 이후 토큰과 응답 수 |
| Input / Output | 오늘 캐시를 거치지 않은 입력 토큰과 출력 토큰 |
| Cache hit | 오늘 입력 중 프롬프트 캐시에서 읽은 비율 |
| Last 7 days | 오늘을 포함한 최근 7일 토큰 |
| Top model | 오늘 가장 많이 응답한 모델 |

- 블록은 [ccusage](https://github.com/ryoppippi/ccusage)와 같은 방식으로 나눕니다. 첫 응답 시각을 정시로 내린 때부터 5시간입니다.
  실제 요금제 한도와 다를 수 있으니 어림값으로 보세요.
- 토큰 수에는 캐시 읽기·쓰기가 들어가므로 직접 입력한 양보다 훨씬 크게 보입니다.
- 기록이 다른 곳에 있으면 `CLAUDE_CONFIG_DIR`을 지정하세요.
- 바뀌지 않은 기록은 `~/Library/Caches/RunHam/claude-usage`에 캐시하므로 처음 한 번만 전체를 읽습니다.

### Codex

[Codex CLI](https://github.com/openai/codex)가 `~/.codex/sessions`(또는 `$CODEX_HOME/sessions`)에 남기는 세션 기록만 읽습니다.

- 5시간·주간 한도 줄은 Codex가 마지막 응답 때 기록한 값이라 Codex를 쓰지 않는 동안에는 바뀌지 않습니다.
  기록된 재설정 시각이 지나면 **Reset**으로 표시합니다.
- Today, Input / Output, Cache hit, Last 7 days, Top model은 Claude Code 카드와 같습니다.
- 바뀌지 않은 기록은 `~/Library/Caches/RunHam/codex-usage`에 캐시합니다.

## 문제가 생기면

- 파일을 읽을 수 없거나 형식이 맞지 않으면, 마지막으로 정상이던 내용을 그대로 보여 주고 카드에 **오류 발생**을 표시합니다.
- 파일을 지우거나 이름을 바꿔도 괜찮습니다. 같은 경로를 계속 지켜보다가 파일이 다시 생기면 다시 읽습니다.
