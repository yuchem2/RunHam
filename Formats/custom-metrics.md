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

## Claude Code usage

[`scripts/claude-usage-metrics.sh`](../scripts/claude-usage-metrics.sh) turns your [Claude Code](https://claude.com/claude-code) token usage into a card.
It only reads the conversation logs Claude Code keeps in `~/.claude/projects`. Nothing is sent over the network and no credentials are used.

```bash
./scripts/claude-usage-metrics.sh ~/custom-metrics/claude.json --watch   # refresh every 60 seconds
```

| Row | Shows |
|---|---|
| 5h block | Time left in the current 5-hour block and its tokens. The bar fills as the block goes by |
| Today | Tokens and replies since midnight. This is also the Metrics Bar value |
| Input / Output | Uncached input and output tokens today |
| Cache hit | Share of today's input read from the prompt cache |
| Last 7 days | Tokens over the last 7 days, today included |
| Top model | The model that replied most today |

- Blocks are split the same way as [ccusage](https://github.com/ryoppippi/ccusage): a block starts at the hour of the first reply and lasts 5 hours.
  The real limits of your plan may differ, so treat it as an estimate.
- Token counts include cache reads and writes, so they look much larger than what you typed.
- Needs `jq` (built into macOS 15 and later; otherwise `brew install jq`). Set `CLAUDE_CONFIG_DIR` if your logs live somewhere else.
- Logs that haven't changed are cached in `~/Library/Caches/RunHam/claude-usage`, so only the first run reads everything.
- Sample output: [`examples/claude-usage.json`](examples/claude-usage.json)

## When something is wrong

- If the file can't be read or doesn't match the format, RunHam keeps showing the last good content and marks the card with **Error Detected**.
- Deleting or renaming the file is fine. RunHam keeps watching the path and picks the file up again when it reappears.
