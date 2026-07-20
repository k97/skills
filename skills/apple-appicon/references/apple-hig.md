# Apple HIG — app icon rules that drive this skill

Distilled from [Apple's Human Interface Guidelines — App icons](https://developer.apple.com/design/human-interface-guidelines/app-icons)
(current as of the June 2026 Liquid Glass refinements). This file is the design
authority; `platform-recipes.md` holds the commands that implement it.

## Per-platform geometry

| Platform | You provide | System applies | Canvas |
|---|---|---|---|
| iOS / iPadOS | square, full-bleed, unmasked | rounded-rectangle mask | 1024×1024 px |
| macOS (Tahoe+, Icon Composer) | square, full-bleed, unmasked layers | rounded-rectangle mask + Liquid Glass | 1024×1024 px |
| macOS (legacy `.icns`, pre-Tahoe / Tauri / Sparkle) | rounded-rect **baked in**, with margins and shadow | nothing (Tahoe re-masks it) | 1024×1024 px |
| visionOS | square, full-bleed, unmasked layers (1 background + up to 2 foreground) | circular mask, 3D depth, specular | 1024×1024 px |
| watchOS *(out of scope v1)* | square, unmasked | circular mask | 1088×1088 px |
| tvOS *(out of scope v1)* | landscape layers | rounded rect + parallax | 800×480 px |

The one place this skill *draws* a shape: **legacy macOS `.icns`**. Modern
system-masked platforms must receive plain full-bleed squares — never
pre-round corners for iOS/iPadOS/visionOS or the system mask will double-apply
and leave dark corner slivers.

## The legacy macOS icon grid (what `appicon.swift macos` implements)

Apple's Big Sur–Sequoia design template on a 1024 px canvas:

- content box **824×824 px**, centred (100 px margins)
- corner radius **≈185.4 px** (Apple uses a continuous-curvature squircle; a
  circular rounded rect at this radius is the standard approximation)
- subtle baked-in **drop shadow** (system does not add one for legacy icons):
  approximated as black 30%, y-offset ~1% of canvas, blur ~2% of canvas
- everything outside the rounded rect is transparent

Why it matters: a full-bleed square shipped as `.icns` renders as a giant
square in the Dock next to every other margined icon — the classic "Tauri/Electron
dock icon looks too big" bug. On macOS Tahoe the system re-masks legacy icons
into its squircle, but the margined version still degrades gracefully there,
so it is the correct output for any `.icns`.

## Appearance variants (iOS, iPadOS, macOS)

Six variants exist: **default, dark, clear light, clear dark, tinted light,
tinted dark**. From a single flat source this skill generates default, and can
derive placeholders for:

- **dark** — keep the foreground, swap to a darker background; transparent
  background is permitted (system provides the dark backdrop). Derive from the
  light icon, don't redesign it.
- **tinted** — grayscale version; system applies the user's tint. Keep it
  legible as pure luminance.

Core visual features must stay identical across variants. Flag to the user
that auto-derived dark/tinted variants are placeholders a designer should
review — deriving them mechanically from a flat PNG is a convenience, not a
design process.

## Liquid Glass / Icon Composer (know when to hand off)

The system now dynamically adds specular highlights, refraction, translucency,
inter-layer shadows, bevels, glows, and blurs. **Do not bake these effects into
source artwork** — static versions conflict with the dynamic ones.

Truly layered, Liquid Glass-native icons for iOS/iPadOS/macOS/watchOS are
authored in **Icon Composer** (ships with Xcode; also at
developer.apple.com/icon-composer) as `.icon` bundles. That is a GUI workflow
this skill does not replace: when the user wants layered Liquid Glass icons for
an Xcode-native app, generate the flat asset set as the baseline and point them
to Icon Composer. visionOS and tvOS layers go directly into the Xcode asset
catalog instead (image stacks — see `platform-recipes.md`).

## visionOS specifics

- System masks to a **circle** and adds depth between layers; the icon subtly
  expands on view.
- Up to 3 layers: background (must be **full-bleed and opaque**) + 1–2
  foreground layers (alpha allowed and encouraged for depth).
- Keep content centred — corners are cropped by the circular mask. Avoid
  concave "hole" shapes in the background; system shadows make them pop out.
- One flat source image → it becomes the background layer; recommend the user
  supply separate foreground artwork for real depth.

## App Store / asset-catalog hard rules

- The 1024 px iOS/iPadOS marketing icon must contain **no alpha channel**
  (flatten onto an opaque background; `appicon.swift flatten` strips alpha).
- Colour spaces: **sRGB** or **Display P3** (Gray Gamma 2.2 for grayscale).
- PNG for raster layers; 8 bits per channel.

## Design advisories — check when you view the source image

View the source image (agents with image input) and flag any of these against
the HIG; agents without image input should hand this list to the user instead.
Advisory, not blocking — report, don't refuse:

- **Pre-rounded corners or baked shadow** on a source meant for iOS/iPadOS/
  visionOS → double-masking artefacts. Offer to proceed anyway or get a
  full-bleed export.
- **Fine detail / thin lines / outline-only shapes** → lost at 16–128 px.
- **Text in the artwork** → only if essential to the brand; never UI
  instructions ("Play", "New").
- **Photographic content** → HIG says use illustration; photos degrade across
  sizes and appearances.
- **Replicas of Apple hardware** → not permitted (copyright).
- **Near-black background** intended for visionOS/watchOS → blends into the
  display; suggest lightening.

## Sources

- HIG · App icons — developer.apple.com/design/human-interface-guidelines/app-icons
- Configuring your app icon — developer.apple.com/documentation/Xcode/configuring-your-app-icon
- Icon Composer — developer.apple.com/documentation/Xcode/creating-your-app-icon-using-icon-composer
- Apple Design Resources (grid templates) — developer.apple.com/design/resources/
