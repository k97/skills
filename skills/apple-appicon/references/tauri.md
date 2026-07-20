# Tauri — icon generation and the macOS dock-icon fix

Applies when the project has `src-tauri/tauri.conf.json`. Source of truth:
[v2.tauri.app/develop/icons](https://v2.tauri.app/develop/icons/).

## What `tauri icon` does

One command generates every platform target from a single source:

```bash
npm run tauri icon [./app-icon.png]     # or: yarn / pnpm / bun tauri icon, cargo tauri icon
```

- **Input**: square PNG *or SVG* with transparency; RGBA, 8-bit channels.
  1024×1024 recommended (docs say 512+ minimum).
- **Output** (default `src-tauri/icons/`, next to `tauri.conf.json`):
  `icon.icns` (macOS), `icon.ico` (Windows — 16/24/32/48/64/256 layers),
  `32x32.png`, `128x128.png`, `128x128@2x.png` (Linux + window icons),
  `Square*Logo.png` + `StoreLogo.png` (Windows Store), and mobile icons pushed
  into `src-tauri/gen/apple` / `src-tauri/gen/android` if those exist.
- Useful flags: `-o <dir>` output dir, `--png <sizes>` custom PNG sizes,
  `--ios-color '#rrggbb'` background for iOS icons (default `#fff`).

Pick the runner by lockfile: `pnpm-lock.yaml` → pnpm, `yarn.lock` → yarn,
`bun.lockb`/`bun.lock` → bun, `package-lock.json` → npm; none + `Cargo.toml` →
`cargo tauri icon` (needs tauri-cli installed).

`tauri.conf.json` must reference the outputs (default projects already do):

```json
{ "bundle": { "icon": [
  "icons/32x32.png", "icons/128x128.png", "icons/128x128@2x.png",
  "icons/icon.icns", "icons/icon.ico"
] } }
```

## The macOS fix (this skill's main value over plain `tauri icon`)

`tauri icon` puts the **full-bleed** source into `icon.icns`. On macOS that
renders as an oversized square in the Dock — Apple icons carry ~10% margins
and a rounded rectangle (see `apple-hig.md`). The fix: let `tauri icon`
generate everything, then rebuild only the `.icns` from a HIG-margined
variant.

```bash
# 1. full set from the full-bleed source (correct for every non-macOS target)
npm run tauri icon path/to/source.png

# 2. margined, rounded, shadowed 1024px variant
swift "$SKILL/scripts/appicon.swift" macos path/to/source.png /tmp/macos-1024.png

# 3. rebuild icon.icns from the margined variant (recipe in platform-recipes.md)
mkdir -p /tmp/icon.iconset
for entry in 16:icon_16x16 32:icon_16x16@2x 32:icon_32x32 64:icon_32x32@2x \
             128:icon_128x128 256:icon_128x128@2x 256:icon_256x256 \
             512:icon_256x256@2x 512:icon_512x512 1024:icon_512x512@2x; do
  swift "$SKILL/scripts/appicon.swift" resize /tmp/macos-1024.png \
        "/tmp/icon.iconset/${entry#*:}.png" "${entry%%:*}"
done
iconutil -c icns /tmp/icon.iconset -o src-tauri/icons/icon.icns
rm -r /tmp/icon.iconset
```

Leave `32x32.png` / `128x128.png` / `icon.ico` full-bleed — margins are a
macOS-only convention; Windows and Linux icons should fill the frame.

**Not on a Mac?** The whole fix still works: build the margined 1024 PNG with
the ImageMagick recipe in `platform-recipes.md` (non-macOS fallbacks), then
let `tauri icon` compile the container itself —
`tauri icon macos-1024.png -o /tmp/margined-icons` — and copy only
`/tmp/margined-icons/icon.icns` over `src-tauri/icons/icon.icns`. The Tauri
CLI writes `.icns` on any OS; `iconutil` is just the native shortcut.

Skip step 2–3 if the source already ships Apple-style margins (view it: artwork
floating in ~10% transparent padding) — then plain `tauri icon` is already
right, and conversely warn that its *other* outputs will inherit unwanted
margins; ask for a full-bleed export to do both properly.

Verify: `cargo tauri build` (or `npm run tauri build`) and check the Dock/Finder,
or quick-look the icns: `qlmanage -p src-tauri/icons/icon.icns`. The dev-mode
window icon comes from the PNGs, so the Dock icon in `tauri dev` may still look
full-bleed — judge by the built app.

## If `tauri icon` is unavailable

Everything except `icon.ico` can be produced natively (recipes in
`platform-recipes.md`; PNGs via `appicon.swift resize`). For the `.ico`,
use ImageMagick if present:

```bash
magick source.png -define icon:auto-resize=256,64,48,32,24,16 src-tauri/icons/icon.ico
```

Otherwise generate the rest, and tell the user the `.ico` needs either
ImageMagick or a one-off `tauri icon` run.

## Roadmap — other frameworks

Planned integrations, in order: **Flutter** (`flutter_launcher_icons`),
**React Native** (per-platform native folders), **Ionic/Capacitor**
(`@capacitor/assets`). Until then, if the user asks for one of these:
generate the Apple-side assets with the recipes here (they drop into the
framework's iOS/macOS folders unchanged — e.g. `ios/Runner/Assets.xcassets`),
and defer Android/adaptive icons to the framework's own tooling rather than
guessing its conventions.
