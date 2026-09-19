---
name: apple-appicon
description: >-
  Generate Apple platform app icons (iOS, iPadOS, macOS, visionOS) from one source image, with Apple's Human Interface Guidelines as the north star and first-class Tauri support. Validates the source first — square aspect, >=1024px, alpha, sRGB/P3, 8-bit — then generates AppIcon.appiconset (with dark/tinted variants), .icns via iconutil with Apple's rounded-rect margins for legacy macOS, visionOS layered image stacks, and Tauri's full icon set including the dock-icon margin fix. Dependency-free on macOS (sips, iconutil, Swift/CoreGraphics). Use for "generate app icons", "app icon from this image", "make an .icns", "AppIcon.appiconset", "tauri icon", "dock icon looks too big/square", "App Store icon". Roadmap: Flutter, React Native, Ionic.
license: MIT
compatibility: >-
  macOS with Xcode Command Line Tools (sips, iconutil, swift) for native output; on Linux or Windows, Tauri projects use the Tauri CLI and asset catalogs need ImageMagick 7.
metadata:
  version: "0.1.2"
  source: https://github.com/k97/skills/tree/main/skills/apple-appicon
---

# Icon sets for Apple platforms

Turns one source image into a complete, HIG-correct set of app icons for iOS, iPadOS, macOS, visionOS and Tauri. It checks the image first, then writes the asset catalogs, `.icns` and Tauri icon files, with nothing to install on a Mac beyond Xcode's command line tools.

Agent-agnostic: nothing here depends on a specific coding agent — only on a shell. Commands write `<skill-dir>` for this skill's directory; resolve it to wherever your agent installed the skill (Claude Code exposes it as `${CLAUDE_SKILL_DIR}`; otherwise it is the directory containing this SKILL.md). The working directory is the user's project.

**Requirements — check the platform first.** The native toolchain is macOS: `sips`, `iconutil`, `swift` from Xcode Command Line Tools, no installs. Run `uname -s` (or equivalent) before promising anything, and on anything other than macOS tell the user up front, in plain terms, what works on their machine and what doesn't — then proceed with what does:

- **macOS** → everything below, natively.
- **Linux / Windows (WSL or Git Bash)** → Tauri projects keep _full_ support: `tauri icon` is Rust and cross-platform, `.icns` included, and the margin fix routes through it ([references/tauri.md](references/tauri.md)). Asset-catalog PNGs and `Contents.json` files need ImageMagick 7 — command equivalents are in the "Non-macOS fallbacks" section of [references/platform-recipes.md](references/platform-recipes.md). A bare `.icns` outside a Tauri project is the one thing that genuinely needs `png2icns`, a Mac, or CI — say so rather than approximating.

Never discover a missing `sips` mid-run: state the limitation before generating, and never silently drop the macOS margin treatment because the native tool is absent.

## Step 0 — establish source and targets

- **Source**: the image path from the arguments or conversation. No path → ask for one; never invent or generate artwork unless the user asks.
- **Targets**: `--platform` wins. Otherwise detect: `src-tauri/tauri.conf.json` → tauri; an `.xcodeproj`/`Assets.xcassets` → the Xcode platforms it targets; neither → ask, defaulting to `all` written under `./AppIcons/<platform>/`. `--out` overrides the destination. `ipados` is the `ios` recipe (universal appiconset).

## Step 1 — validate, then look at it (gate)

```bash
bash "<skill-dir>/scripts/validate-source.sh" <source>
```

Show the PASS/WARN/FAIL output. On **FAIL** (not square, <512px, unreadable): stop, present the fix commands the script printed (crop vs pad for aspect; re-export for resolution), apply the one the user picks, re-validate. Never generate from a failing source. WARNs are stated, not blocking.

Then, if your agent can view images, **look at the source** and check it against the design advisories in [references/apple-hig.md](references/apple-hig.md): pre-rounded corners or baked shadows (double-masking risk), thin lines that die at 16px, text, photographic content. Report what you see in one or two sentences; advisory only. No image input? Say the visual advisories were skipped and ask the user to eyeball that list themselves.

## Step 2 — generate per target

Read [references/platform-recipes.md](references/platform-recipes.md) for the exact commands and asset-catalog templates; for Tauri read [references/tauri.md](references/tauri.md). The shape rules that must never be mixed up:

| Target | Output | Shape treatment |
| --- | --- | --- |
| iOS / iPadOS | `AppIcon.appiconset`, 1024 single-size (+ dark/tinted) | full-bleed square; marketing icon flattened, **alpha stripped** |
| macOS (Xcode) | `AppIcon.appiconset`, 10 sizes | margined rounded-rect via `appicon.swift macos` |
| macOS (`.icns`) | `icon.icns` via `iconutil` | same margined treatment |
| visionOS | `AppIcon.solidimagestack` | full-bleed square layers; system applies circular mask |
| Tauri | full `src-tauri/icons/` set | `tauri icon` for everything, then rebuild `icon.icns` margined |

Square, system-masked platforms (iOS/iPadOS/visionOS) get **no** baked corners or margins; only legacy macOS `.icns` does. The [scripts/appicon.swift](scripts/appicon.swift) modes — `resize`, `flatten` (opaque, alpha-stripped), `pad` (square-ify), `macos` (824/1024 rounded rect + margins + shadow) — cover every transform; `sips` is fine for plain resizes too.

Before overwriting an existing `AppIcon.appiconset` or `src-tauri/icons/`, say what will be replaced; back up or get a nod if the user didn't already ask for exactly that.

## Step 3 — verify and report

- `sips -g pixelWidth -g pixelHeight` spot-checks; the iOS marketing icon must report `hasAlpha: no`; `file icon.icns` says "Mac OS X icon".
- If you can view images: open the finished macOS 1024 and one small size — margins present, corners clipped, artwork not visibly soft. Otherwise point the user at `qlmanage -p` / Finder Quick Look for the eyeball check.
- Report a table: file → pixel size → where it's wired (`Contents.json`, `tauri.conf.json` `bundle.icon`, `ASSETCATALOG_COMPILER_APPICON_NAME`), plus any HIG advisories from Step 1 worth acting on. For Tauri, suggest a `tauri build` to see the real Dock icon (dev mode uses the PNGs).

## Scope

watchOS and tvOS are out of scope in v1 (geometry noted in [references/apple-hig.md](references/apple-hig.md)). Layered Liquid Glass `.icon` bundles are Icon Composer's job — generate the flat baseline and point the user there when relevant. Framework roadmap (Flutter, React Native, Ionic/Capacitor) and the interim answer for those users live at the end of [references/tauri.md](references/tauri.md).

## Sources

Apple HIG · App icons, Tauri v2 icon docs (both distilled in `references/`). Workflow shape inspired by brianlovin's `favicon` skill (validate → generate → wire up) and michaelboeding's `icon-generation`.
