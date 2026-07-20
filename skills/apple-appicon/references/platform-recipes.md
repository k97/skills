# Platform recipes — exact commands and asset-catalog templates

All commands are macOS-native (`sips`, `iconutil`, `swift` from Xcode Command
Line Tools). `$SKILL` below means this skill's directory; `$SRC` is the
validated square source PNG (≥1024 px, RGBA). Run everything from the user's
project; put standalone output under `./AppIcons/<platform>/`.

Every recipe assumes validation already passed ([scripts/validate-source.sh](../scripts/validate-source.sh)).

## iOS / iPadOS — `AppIcon.appiconset` (single-size, Xcode 14+)

Modern Xcode needs exactly one 1024 px image (plus optional dark/tinted).
The marketing icon must be alpha-free, so flatten — pick a background colour
that matches the artwork's own background (ask the user if it isn't obvious):

```bash
OUT=AppIcon.appiconset && mkdir -p "$OUT"
swift "$SKILL/scripts/appicon.swift" flatten "$SRC" "$OUT/AppIcon-1024.png" 1024 "#FFFFFF"
# optional variants (see apple-hig.md — placeholders for designer review):
# dark:   flatten onto the dark background colour, or keep transparency (allowed for dark)
# tinted: grayscale — sips -s formatOptions default -M "$OUT/AppIcon-1024.png" ... or leave to a designer
```

`Contents.json` (include the `appearances` entries only when the variant file exists):

```json
{
  "images" : [
    { "filename" : "AppIcon-1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "dark" } ],
      "filename" : "AppIcon-1024-dark.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" },
    { "appearances" : [ { "appearance" : "luminosity", "value" : "tinted" } ],
      "filename" : "AppIcon-1024-tinted.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

Wire-up: the target's `ASSETCATALOG_COMPILER_APPICON_NAME` must equal the set
name (default `AppIcon`). If an `AppIcon.appiconset` already exists, show what
will be replaced and confirm before overwriting.

<details>
<summary>Legacy full-size matrix (only for projects that can't use single-size)</summary>

| idiom | role | pt | scale | px |
|---|---|---|---|---|
| iphone | notification | 20 | 2x, 3x | 40, 60 |
| iphone | settings | 29 | 2x, 3x | 58, 87 |
| iphone | spotlight | 40 | 2x, 3x | 80, 120 |
| iphone | app | 60 | 2x, 3x | 120, 180 |
| ipad | notification | 20 | 1x, 2x | 20, 40 |
| ipad | settings | 29 | 1x, 2x | 29, 58 |
| ipad | spotlight | 40 | 1x, 2x | 40, 80 |
| ipad | app | 76 | 1x, 2x | 76, 152 |
| ipad | app (12.9" Pro) | 83.5 | 2x | 167 |
| ios-marketing | App Store | 1024 | 1x | 1024 |

Generate each with `swift "$SKILL/scripts/appicon.swift" resize "$SRC" out.png <px>`
(marketing icon uses `flatten`).
</details>

## macOS — `.icns` (Tauri, Sparkle, anything pre-Tahoe)

Two steps: bake the HIG margin treatment, then compile the ten-entry iconset.

```bash
swift "$SKILL/scripts/appicon.swift" macos "$SRC" macos-1024.png   # rounded rect + margins + shadow

mkdir -p icon.iconset
for entry in 16:icon_16x16 32:icon_16x16@2x 32:icon_32x32 64:icon_32x32@2x \
             128:icon_128x128 256:icon_128x128@2x 256:icon_256x256 \
             512:icon_256x256@2x 512:icon_512x512 1024:icon_512x512@2x; do
  swift "$SKILL/scripts/appicon.swift" resize macos-1024.png \
        "icon.iconset/${entry#*:}.png" "${entry%%:*}"
done
iconutil -c icns icon.iconset -o icon.icns
rm -r icon.iconset
```

Skip the `macos` step (use `$SRC` directly) only if the source *already* has
Apple-style margins baked in — you can see this when you view the image:
artwork floating with ~10% transparent padding. Applying margins twice shrinks
the icon.

## macOS — `AppIcon.appiconset` (Xcode project)

Same margined `macos-1024.png`, ten entries:

```bash
OUT=AppIcon.appiconset && mkdir -p "$OUT"
for size in 16 32 64 128 256 512 1024; do
  swift "$SKILL/scripts/appicon.swift" resize macos-1024.png "$OUT/mac-$size.png" "$size"
done
```

```json
{
  "images" : [
    { "filename" : "mac-16.png",   "idiom" : "mac", "scale" : "1x", "size" : "16x16" },
    { "filename" : "mac-32.png",   "idiom" : "mac", "scale" : "2x", "size" : "16x16" },
    { "filename" : "mac-32.png",   "idiom" : "mac", "scale" : "1x", "size" : "32x32" },
    { "filename" : "mac-64.png",   "idiom" : "mac", "scale" : "2x", "size" : "32x32" },
    { "filename" : "mac-128.png",  "idiom" : "mac", "scale" : "1x", "size" : "128x128" },
    { "filename" : "mac-256.png",  "idiom" : "mac", "scale" : "2x", "size" : "128x128" },
    { "filename" : "mac-256.png",  "idiom" : "mac", "scale" : "1x", "size" : "256x256" },
    { "filename" : "mac-512.png",  "idiom" : "mac", "scale" : "2x", "size" : "256x256" },
    { "filename" : "mac-512.png",  "idiom" : "mac", "scale" : "1x", "size" : "512x512" },
    { "filename" : "mac-1024.png", "idiom" : "mac", "scale" : "2x", "size" : "512x512" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

(Xcode tolerates one file referenced at two slots; duplicate the files instead
if the project lints against it.)

## visionOS — `AppIcon.solidimagestack`

Layered, circle-masked by the system. Layers are 1024×1024 @2x, square,
unmasked. With a single flat source, it becomes the **Back** layer (must be
opaque — flatten it) and Front/Middle stay empty placeholders; tell the user
real foreground layers need separate artwork (`--layers back.png,middle.png,front.png`
when they have it).

```
AppIcon.solidimagestack/
├── Contents.json
├── Back.solidimagestacklayer/
│   ├── Contents.json
│   └── Content.imageset/
│       ├── Contents.json
│       └── Back.png          ← 1024×1024, opaque
├── Middle.solidimagestacklayer/…   (imageset may be empty)
└── Front.solidimagestacklayer/…    (imageset may be empty)
```

Stack `Contents.json` (front → back order matters):

```json
{
  "layers" : [
    { "filename" : "Front.solidimagestacklayer" },
    { "filename" : "Middle.solidimagestacklayer" },
    { "filename" : "Back.solidimagestacklayer" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

Each `*.solidimagestacklayer/Contents.json`:

```json
{ "info" : { "author" : "xcode", "version" : 1 } }
```

Each `Content.imageset/Contents.json` (omit `filename` in the entry for empty layers):

```json
{
  "images" : [
    { "filename" : "Back.png", "idiom" : "vision", "scale" : "2x" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
```

Foreground layers keep their alpha (`resize`, not `flatten`); only the Back
layer must be opaque.

## Non-macOS fallbacks (ImageMagick 7)

For Linux or Windows (WSL / Git Bash), where `sips`, `iconutil`, and `swift`
don't exist. Tell the user which path you're on before generating. Windows
`.ico` stays the same everywhere (`tauri icon` or the `magick` one-liner in
[tauri.md](tauri.md)).

[appicon.swift](../scripts/appicon.swift) mode equivalents:

```bash
# resize
magick "$SRC" -resize 512x512! out.png

# flatten (opaque + alpha stripped — App Store icon)
magick "$SRC" -resize 1024x1024! -background '#FFFFFF' -alpha remove -alpha off out.png

# pad (square-ify on transparent canvas)
side=$(magick identify -format '%[fx:max(w,h)]' "$SRC")
magick "$SRC" -background none -gravity center -extent "${side}x${side}" out.png

# macos margin treatment (824/1024 rounded rect + margins + shadow)
magick "$SRC" -resize 824x824! \
  \( -size 824x824 xc:none -draw "roundrectangle 0,0,823,823,185,185" \) \
  -compose DstIn -composite \
  -background none -gravity center -extent 1024x1024 \
  \( +clone -background black -shadow 30x20+0+10 \) \
  +swap -background none -layers merge +repage \
  -gravity center -extent 1024x1024 macos-1024.png
```

After the margin treatment, verify with `magick identify` that the result is
1024×1024 and eyeball it if you can view images — the shadow/merge recipe is
the one piece worth double-checking per ImageMagick version.

`.icns` without `iconutil`:

- **Tauri project** — use `tauri icon` itself (cross-platform, Rust):
  generate the margined PNG above, then
  `tauri icon macos-1024.png -o /tmp/margined-icons` and copy only
  `/tmp/margined-icons/icon.icns` into `src-tauri/icons/`.
- **Otherwise** — `png2icns icon.icns 16.png 32.png 128.png 256.png 512.png 1024.png`
  (libicns; `apt install icnsutils`), or generate the PNG set here and build
  the `.icns` on a Mac or macOS CI runner. Don't fake the container format.

## Verify what you generated

```bash
# every PNG: expected pixel size?
sips -g pixelWidth -g pixelHeight <file>
# iOS marketing icon: must report hasAlpha: no
sips -g hasAlpha AppIcon-1024.png
# icns: file type sanity
file icon.icns        # → "Mac OS X icon"
```

Report a table: file → size → where it is referenced (Contents.json,
`tauri.conf.json`, Xcode build setting). For Tauri wiring, read [tauri.md](tauri.md).
