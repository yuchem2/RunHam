<p align="center">
  <img src="Assets/readme/icon.png" width="128" alt="RunHam app icon">
</p>

<h1 align="center">RunHam</h1>

<p align="center">
  A hamster in your Mac's menu bar that hops faster as your CPU gets busier.
</p>

<p align="center">
  <img src="https://img.shields.io/badge/macOS-14%2B-black?logo=apple" alt="macOS 14+">
  <img src="https://img.shields.io/badge/Swift-6-F05138?logo=swift&logoColor=white" alt="Swift 6">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-Apache%202.0-blue" alt="Apache License 2.0"></a>
  <img src="https://img.shields.io/badge/languages-EN%20%7C%20KO%20%7C%20JA%20%7C%20ZH-lightgrey" alt="English, Korean, Japanese, Chinese">
</p>

<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="Assets/readme/hero-dark.gif">
    <img src="Assets/readme/hero-light.gif" height="160" alt="Hopping hamster runner">
  </picture>
</p>

<p align="center"><b>English</b> · <a href="README.ko.md">한국어</a></p>

---

## Features

- 🐹 **A runner that reacts to your Mac.** The busier the CPU, the faster the hamster hops. Prefer the opposite? Turn on *Slow down under load*.
- 📊 **Dashboard in one click.** CPU history, memory, storage, battery and network (type, speed and local IP) right from the menu bar.
- 📌 **Metrics Bar.** Keep the numbers you care about visible next to the runner all the time.
- 🎨 **Custom runners.** Bring your own PNG frames, reorder them by dragging, and preview the animation before adding.
- 🧩 **Custom metrics.** Point RunHam at a JSON file and it becomes a live dashboard card.
- 🌏 **Four languages.** English, 한국어, 日本語 and 简体中文, switchable without restarting.
- 🪶 **Lightweight.** Native Swift with no third-party libraries. It usually stays under 1% CPU.

## Screenshots

<table>
  <tr>
    <th>Dashboard</th>
    <th>Settings</th>
  </tr>
  <tr>
    <td valign="top">
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="Assets/readme/dashboard-en-dark.png">
        <img src="Assets/readme/dashboard-en-light.png" width="330" alt="Dashboard">
      </picture>
    </td>
    <td valign="top">
      <picture>
        <source media="(prefers-color-scheme: dark)" srcset="Assets/readme/settings-runner-en-dark.png">
        <img src="Assets/readme/settings-runner-en-light.png" width="420" alt="Runner settings">
      </picture>
    </td>
  </tr>
</table>

## Runners

| | Runner | |
|:---:|---|---|
| <picture><source media="(prefers-color-scheme: dark)" srcset="Runners/hamster/preview-dark.gif"><img src="Runners/hamster/preview-light.gif" height="56" alt="Hamster"></picture> | **Hamster** (default) | Crouches, kicks off and lands with a stretch. |
| <picture><source media="(prefers-color-scheme: dark)" srcset="Runners/hamster-ball/preview-dark.gif"><img src="Runners/hamster-ball/preview-light.gif" height="56" alt="Hamster Ball"></picture> | **Hamster Ball** | Scurries inside a rolling exercise ball. |
| <picture><source media="(prefers-color-scheme: dark)" srcset="Runners/hamster-snack/preview-dark.gif"><img src="Runners/hamster-snack/preview-light.gif" height="56" alt="Snacking Hamster"></picture> | **Snacking Hamster** | Munches a sunflower seed, dropping crumbs. |
| <picture><source media="(prefers-color-scheme: dark)" srcset="Runners/cat/preview-dark.gif"><img src="Runners/cat/preview-light.gif" height="56" alt="Cat"></picture> | **Cat** | A sleek galloping cat. |

Every built-in runner is also available as plain PNG frames in [`Runners/`](Runners/),
so you can use them in other apps or as a starting point for your own.

## Installation

Pre-built releases are not available yet. Build from source:

```bash
git clone https://github.com/yuchem2/RunHam.git
cd RunHam
./scripts/bundle.sh          # creates build/RunHam.app
open build/RunHam.app
```

Requires macOS 14 or later and Xcode (or the Command Line Tools) with Swift 6.
Move `build/RunHam.app` to `/Applications` and turn on **Launch at login** in Settings to keep it running.

## Usage

- **Dashboard**: click the runner in the menu bar. The ☰ button at the top opens Settings, Activity Monitor, About, Open Source Licenses, Report a Problem and Quit.
- **Settings › Runner**: choose a runner, flip it, show the CPU percentage next to it, or slow it down under load.
- **Settings › Metrics**: choose dashboard cards and what the Metrics Bar shows.

### Custom runners

<picture>
  <source media="(prefers-color-scheme: dark)" srcset="Assets/readme/custom-runner-en-dark.png">
  <img src="Assets/readme/custom-runner-en-light.png" width="440" align="right" alt="Custom runner editor">
</picture>

1. Open **Settings › Runner › Add Custom Runner…**
2. Click **+** or drop PNG files or a folder onto the frame grid.
3. Drag frames (or use ‹ ›) to set the order, check the preview, and click **Add**.

Frames must be PNG, 36 px tall, 10–100 px wide, up to 30 frames.
**Monochrome** runners follow the menu bar text color in light and dark mode; **Color** keeps the original colors.
Runners from the [Runner Gallery](https://runcat-dev.github.io/RunnerGallery/) work too.

<br clear="right">

### Custom metrics

Register a JSON file in **Settings › Metrics › Custom Metrics** and it shows up as a dashboard card that refreshes whenever the file changes.
The format follows the [RunCat Neo Custom Metrics schema](https://github.com/runcat-dev/RunCatNeo/blob/main/docs/CustomMetricsSchema.md).

```bash
./scripts/custom-metrics-example.sh ~/custom-metrics/load.json --watch   # writes system load every 5 seconds
```

## Development

```bash
./scripts/test.sh               # unit tests
./scripts/export-showcase.sh    # regenerates Runners/ and the README images
./scripts/make-icon.sh          # regenerates Assets/AppIcon.icns
```

- Runners and the app icon are drawn in code with Core Graphics (`Sources/RunHam/Runner/`, `AppIconRenderer`). No image assets are bundled.
- To add a built-in runner, see [`Runners/README.md`](Runners/README.md).
- To add a language, add `Sources/RunHam/Resources/<code>.lproj/Localizable.strings` with the same keys as English. The tests check that no key is missing.
- RunHam uses no third-party libraries. If you add one, list it in `LicensesView.entries` and put its license in `Sources/RunHam/Resources/Licenses/`.

## Report a problem

Choose **Report a Problem** from the ☰ menu to open a new issue with your environment details already filled in, or open one on [GitHub Issues](https://github.com/yuchem2/RunHam/issues).

## Acknowledgements

RunHam was built from scratch, inspired by the behavior and data formats of [RunCat Neo](https://github.com/runcat-dev/RunCatNeo)
(Copyright 2026 Kyome22 / Takuto Nakamura, Apache License 2.0). It does not include RunCat Neo's code or images.

## License

RunHam is released under the [Apache License 2.0](LICENSE).
