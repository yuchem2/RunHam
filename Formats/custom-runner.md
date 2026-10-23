# Custom runner format

**English** · [한국어](custom-runner.ko.md)

A custom runner is a set of PNG frames that RunHam plays in order in the menu bar.

![Runner frames](../Assets/readme/runner-guide.png)

## Frames

| | Rule |
|---|---|
| File type | PNG |
| Height | **36 px** (the menu bar is 18 pt tall, drawn at 2×) |
| Width | 10–100 px. Frames can have different widths; the widest one decides the runner's width. |
| Count | 1–30 frames |
| Order | Playback order. When you add a folder, files are sorted by name, with numbers in natural order (`frame-2` before `frame-10`). You can reorder frames in the editor. |
| Background | Transparent |

## Monochrome or color

- **Monochrome**: only the shape (alpha) of each frame is used, and it is painted in the menu bar text color.
  Draw in any single color on a transparent background. It turns white in dark mode automatically. This is the recommended style.
- **Color**: frames are shown as they are. Make sure they read well on both light and dark menu bars.

## Speed

At speed 1 (an idle Mac), RunHam plays **2 frames per second**, so a 6-frame runner takes 3 seconds per loop.
The busier the CPU, the faster it plays (up to 20×), or slower if *Slow down under load* is on.

## Tips for a good runner

- Use the full 36 px height. Small figures are hard to see in the menu bar.
- Leave 1–2 px of empty space at the top and sides so nothing touches the edge.
- Make the motion big. At 18 pt, a change of 1–2 px is barely noticeable.
- Keep the first and last frames close to each other so the loop is seamless.
- One white hole for an eye goes a long way in a monochrome silhouette.

## Adding it to RunHam

1. **Settings › Runner › Add Custom Runner…**
2. Drop the PNG files or the folder onto the frame grid, or click **+**.
3. Set the name, choose Monochrome or Color, check the order and the preview, and click **Add**.

RunHam copies the frames into `~/Library/Application Support/RunHam/Runners/`, so you can move or delete the originals afterwards.

## Examples

Every built-in runner is in [`Runners/`](../Runners/) in this format. Drop any of those folders into the editor to try it.
