#!/usr/bin/env bash
# validate-source.sh — gate a source image before app icon generation.
#
# Usage: bash validate-source.sh <image>
# Exit 0 = usable (warnings allowed), 1 = blocking problem(s).
#
# Checks: file exists, format, square aspect, resolution (>=1024 ideal),
# alpha channel, colour space, bit depth. Prints PASS/WARN/FAIL per check
# with a copy-paste fix for anything that is wrong. Uses macOS `sips`,
# falling back to ImageMagick `magick` on other platforms.

set -euo pipefail

img="${1:-}"
[ -n "$img" ] || { echo "usage: validate-source.sh <image>" >&2; exit 1; }

fails=0
warns=0
pass() { printf 'PASS  %s\n' "$1"; }
warn() { printf 'WARN  %s\n' "$1"; warns=$((warns + 1)); }
fail() { printf 'FAIL  %s\n' "$1"; fails=$((fails + 1)); }

if [ ! -f "$img" ]; then
  fail "source image not found: $img"
  echo "RESULT: BLOCKED — 1 failure(s)."
  exit 1
fi

ext=$(printf '%s' "${img##*.}" | tr '[:upper:]' '[:lower:]')

# SVG: vector, no pixel checks apply. Tauri's CLI consumes it directly;
# everything else needs a 1024px raster first.
if [ "$ext" = "svg" ]; then
  pass "SVG source — 'tauri icon' can use it directly"
  warn "other targets need a raster: rsvg-convert -w 1024 -h 1024 '$img' -o source-1024.png  (or: magick -background none '$img' -resize 1024x1024 source-1024.png)"
  echo
  echo "RESULT: OK — 0 failure(s), $warns warning(s)."
  exit 0
fi

if command -v sips >/dev/null 2>&1; then
  info=$(sips -g pixelWidth -g pixelHeight -g hasAlpha -g space -g bitsPerSample -g format "$img" 2>/dev/null) \
    || { fail "unreadable image: $img"; echo "RESULT: BLOCKED — 1 failure(s)."; exit 1; }
  get() { printf '%s\n' "$info" | awk -v k="$1:" '$1 == k { print $2; exit }'; }
  w=$(get pixelWidth); h=$(get pixelHeight); alpha=$(get hasAlpha)
  space=$(get space); bits=$(get bitsPerSample); fmt=$(get format)
elif command -v magick >/dev/null 2>&1; then
  line=$(magick identify -format '%w %h %A %[colorspace] %z %m' "${img}[0]" 2>/dev/null) \
    || { fail "unreadable image: $img"; echo "RESULT: BLOCKED — 1 failure(s)."; exit 1; }
  read -r w h alpha space bits fmt <<<"$line"
  case "$alpha" in True|Blend|true) alpha=yes ;; *) alpha=no ;; esac
  fmt=$(printf '%s' "$fmt" | tr '[:upper:]' '[:lower:]')
else
  fail "no image inspector found — need macOS 'sips' or ImageMagick 7 ('brew install imagemagick')"
  echo "RESULT: BLOCKED — 1 failure(s)."
  exit 1
fi

# --- format ---
case "$fmt" in
  png) pass "format: png" ;;
  jpeg|jpg) warn "JPEG source (no alpha channel) — convert first: sips -s format png '$img' --out source.png" ;;
  *) warn "format '$fmt' — convert to PNG first: sips -s format png '$img' --out source.png" ;;
esac

# --- square aspect ---
if [ "$w" -eq "$h" ]; then
  pass "aspect ratio: square (${w}x${h})"
else
  fail "not square (${w}x${h}) — fix with ONE of:
        crop: sips --cropToHeightWidth <N> <N> '$img' --out source-square.png   (centre-crop, may cut artwork)
        pad:  swift <skill-dir>/scripts/appicon.swift pad '$img' source-square.png   (transparent letterbox, keeps everything)"
fi

# --- resolution ---
min=$((w < h ? w : h))
if [ "$min" -ge 1024 ]; then
  pass "resolution: ${min}px (>= 1024)"
elif [ "$min" -ge 512 ]; then
  warn "resolution ${min}px is below 1024 — the App Store requires 1024x1024, so output will be upscaled and soften. Prefer re-exporting the artwork at 1024px+."
else
  fail "resolution ${min}px is below 512 — too small to upscale acceptably. Re-export the artwork at 1024x1024 or larger."
fi

# --- alpha channel ---
if [ "$alpha" = "yes" ]; then
  pass "alpha channel: present (Tauri needs RGBA; it is stripped automatically for the iOS App Store icon)"
else
  warn "no alpha channel — fine for iOS/iPadOS full-bleed; Tauri and the macOS mask need RGBA. Any pass through scripts/appicon.swift re-encodes as RGBA."
fi

# --- colour space ---
case "$space" in
  RGB|sRGB|DisplayP3|P3) pass "colour space: $space" ;;
  *) warn "colour space '$space' — Apple wants sRGB or Display P3: sips --matchTo '/System/Library/ColorSync/Profiles/sRGB Profile.icc' '$img' --out source-srgb.png" ;;
esac

# --- bit depth ---
if [ "${bits:-8}" -eq 8 ] 2>/dev/null; then
  pass "bit depth: 8 bits/channel"
else
  warn "bit depth ${bits} bits/channel — Tauri wants 8-bit; any pass through scripts/appicon.swift re-encodes to 8-bit"
fi

echo
if [ "$fails" -gt 0 ]; then
  echo "RESULT: BLOCKED — $fails failure(s), $warns warning(s). Fix the failures above, then re-run."
  exit 1
fi
echo "RESULT: OK — 0 failure(s), $warns warning(s)."
