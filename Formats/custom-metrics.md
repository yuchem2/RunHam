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

## When something is wrong

- If the file can't be read or doesn't match the format, RunHam keeps showing the last good content and marks the card with **Error Detected**.
- Deleting or renaming the file is fine. RunHam keeps watching the path and picks the file up again when it reappears.
