# RunHam 🐹

**English** | [한국어](README.ko.md)

A macOS menu bar app where a hamster hops faster as your CPU gets busier.
Open the menu to see a dashboard of CPU, memory, storage, battery and network usage.

## Features

- **Runners**: Hopping Hamster (default), Hamster Ball, Snacking Hamster (munches faster under load) and a galloping Cat.
  The faster your CPU works, the faster the runner moves. You can also flip the runner or slow it down under load instead.
- **Dashboard**: CPU usage graph, memory, storage, battery, and network type, speed and local IP address.
  The hamburger button at the top opens Settings, Activity Monitor, About, Open Source Licenses, Report a Problem and Quit.
- **Metrics Bar**: Keeps the values you choose (CPU, memory, storage, battery, network, custom metrics) visible next to the runner.
  A sleeping hamster appears when nothing is selected.
- **Custom runners**: Add your own PNG frames (36px tall, 10–100px wide, up to 30 frames).
  Reorder frames by dragging, preview the animation, and choose monochrome (follows the menu bar color) or color.
  Runners from the [Runner Gallery](https://runcat-dev.github.io/RunnerGallery/) can be added too.
- **Custom metrics**: Register a JSON file and it appears as a dashboard card, refreshing whenever the file changes.
  The format is compatible with the [RunCat Neo Custom Metrics schema](https://github.com/runcat-dev/RunCatNeo/blob/main/docs/CustomMetricsSchema.md).
- **Languages**: English, 한국어, 日本語, 简体中文. Switch in Settings › General › Language without restarting.

## Requirements

macOS 14 or later.

## Build and run

```bash
./scripts/bundle.sh        # builds build/RunHam.app (release)
open build/RunHam.app
```

The app is a Swift Package and builds with Xcode or the Command Line Tools.

```bash
./scripts/test.sh          # unit tests
```

## Custom metrics example

```bash
./scripts/custom-metrics-example.sh ~/custom-metrics/load.json --watch   # writes system load every 5 seconds
```

Then add the output file in Settings › Metrics › Custom Metrics › Add Custom Metrics Source….

## Development notes

- Runner frames and the app icon are drawn in code with Core Graphics (`HamsterSilhouette`, `AppIconRenderer`). No image assets are bundled.
- After changing the icon drawing, run `./scripts/make-icon.sh` to regenerate `Assets/AppIcon.icns`.
- To add a language, add `Sources/RunHam/Resources/<code>.lproj/Localizable.strings` with the same keys as English.
- `RunHam --export-previews <dir>` exports runner frames and screens as PNG files.
- RunHam uses no third-party libraries. If you add one, list it in `LicensesView.entries` and put its license in `Resources/Licenses/`.

## Acknowledgements

RunHam was built from scratch with reference to the behavior and data formats of
[RunCat Neo](https://github.com/runcat-dev/RunCatNeo) (Copyright 2026 Kyome22 / Takuto Nakamura, Apache License 2.0).
It does not include RunCat Neo's code or images.

## Report a problem

Choose **Report a Problem** from the app menu to open a new issue with your environment details filled in,
or go to [Issues](https://github.com/yuchem2/RunHam/issues).

## License

[Apache License 2.0](LICENSE)
