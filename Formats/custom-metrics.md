# Custom metrics format

**English** · [한국어](custom-metrics.ko.md)

Point RunHam at a JSON file and it becomes a card on the dashboard. RunHam watches the file and redraws the card whenever it changes,
so anything that can write a file (a shell script, cron, a CI job, a home server) can show up in your menu bar.

- JSON Schema: [`custom-metrics.schema.json`](custom-metrics.schema.json)
- Examples: [`examples/`](examples/)

## Example

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

## Fields

| Field | Type | Required | Description |
|---|---|:---:|---|
| `title` | string | ✓ | Card title. |
| `symbol` | string | | [SF Symbols](https://developer.apple.com/sf-symbols/) name shown next to the title. Defaults to `chart.bar.horizontal.page.fill`. |
| `metricsBarValue` | string | | Short text for the Metrics Bar. Shown when this source is turned on in **Settings › Metrics**; `---` if missing. |
| `metrics` | array | ✓ | Rows of the card, from top to bottom. |
| `metrics[].title` | string | ✓ | Row label. |
| `metrics[].formattedValue` | string | ✓ | Value text, shown exactly as written (format numbers and units yourself). |
| `metrics[].normalizedValue` | number | | 0–1. When present, a progress bar is drawn under the row. Values outside 0–1 are clamped. |
| `lastUpdatedDate` | string | ✓ | ISO 8601 date and time with a time zone, such as `2026-10-23T09:00:00Z` or `2026-10-23T18:00:00.250+09:00`. Shown as "Updated … ago". |

Unknown fields are ignored, so you can keep extra data in the same file.

## Updating the file safely

Write to a temporary file in the same folder and rename it over the old one.
This way RunHam never reads a half-written file.

```bash
tmp=$(mktemp ~/custom-metrics/.load.XXXXXX)
echo "$json" > "$tmp"
mv -f "$tmp" ~/custom-metrics/load.json
```

[`scripts/custom-metrics-example.sh`](../scripts/custom-metrics-example.sh) does this and writes the system load every 5 seconds:

```bash
./scripts/custom-metrics-example.sh ~/custom-metrics/load.json --watch
```

## Ready-made cards

Each script in [`scripts/`](../scripts/) writes one card. Run it once to try it, add `--watch` to keep the file fresh,
then add the file in **Settings › Metrics › Custom Metrics**.

```bash
./scripts/github-metrics.sh ~/custom-metrics/github.json --watch
```

| Script | Card | Needs | Refresh | Metrics Bar | Sample |
|---|---|---|---|---|---|
| [`claude-usage-metrics.sh`](../scripts/claude-usage-metrics.sh) | Claude Code tokens and 5-hour block | `jq` | 60 s | Tokens today | [claude-usage.json](examples/claude-usage.json) |
| [`codex-usage-metrics.sh`](../scripts/codex-usage-metrics.sh) | Codex usage limits and tokens | `jq` | 60 s | 5-hour limit used | [codex-usage.json](examples/codex-usage.json) |
| [`github-metrics.sh`](../scripts/github-metrics.sh) | Review requests, your PRs and their CI, assigned issues, unread notifications | `gh`, signed in | 5 min | Review requests | [github.json](examples/github.json) |
| [`docker-metrics.sh`](../scripts/docker-metrics.sh) | Engine, containers, disk used by images, volumes and build cache | `docker` | 30 s | Running containers | [docker.json](examples/docker.json) |
| [`homebrew-metrics.sh`](../scripts/homebrew-metrics.sh) | Outdated formulae and casks | `brew` | 30 min | Outdated packages | [homebrew.json](examples/homebrew.json) |
| [`kubernetes-metrics.sh`](../scripts/kubernetes-metrics.sh) | Nodes, pods and restarts in the current context and namespace | `kubectl` | 60 s | Ready pods | [kubernetes.json](examples/kubernetes.json) |

- The scripts only read. They don't run `brew update` or change anything in Docker or your cluster.
- When Docker is stopped or the cluster can't be reached, the card says so. When GitHub can't be reached, the file is left as is,
  so RunHam keeps the last card and its "updated … ago" keeps growing.
- `jq` is built into macOS 15 and later. On macOS 14, run `brew install jq`.

### Claude Code

Reads only the conversation logs [Claude Code](https://claude.com/claude-code) keeps in `~/.claude/projects`.
Nothing is sent over the network and no credentials are used.

| Row | Shows |
|---|---|
| 5h block | Time left in the current 5-hour block and its tokens. The bar fills as the block goes by |
| Today | Tokens and replies since midnight |
| Input / Output | Uncached input and output tokens today |
| Cache hit | Share of today's input read from the prompt cache |
| Last 7 days | Tokens over the last 7 days, today included |
| Top model | The model that replied most today |

- Blocks are split the same way as [ccusage](https://github.com/ryoppippi/ccusage): a block starts at the hour of the first reply and lasts 5 hours.
  The real limits of your plan may differ, so treat it as an estimate.
- Token counts include cache reads and writes, so they look much larger than what you typed.
- Set `CLAUDE_CONFIG_DIR` if your logs live somewhere else.
- Logs that haven't changed are cached in `~/Library/Caches/RunHam/claude-usage`, so only the first run reads everything.

### Codex

Reads only the session logs [Codex CLI](https://github.com/openai/codex) keeps in `~/.codex/sessions` (or `$CODEX_HOME/sessions`).

- The 5-hour and weekly limit rows are the values Codex recorded with its last reply, so they don't move while you aren't using Codex.
  Once the recorded reset time passes, the row shows **Reset**.
- Today, Input / Output, Cache hit, Last 7 days and Top model work the same way as the Claude Code card.
- Logs that haven't changed are cached in `~/Library/Caches/RunHam/codex-usage`.

## When something is wrong

- If the file can't be read or doesn't match the format, RunHam keeps showing the last good content and marks the card with **Error Detected**.
- Deleting or renaming the file is fine. RunHam keeps watching the path and picks the file up again when it reappears.
