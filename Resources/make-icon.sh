#!/bin/bash
# Regenerates Resources/AppIcon.icns from docs/assets/meter-icon.svg.
#
# Not run by build.sh or CI — the .icns is committed, so a release build needs
# no SVG toolchain. Run this by hand when the source artwork changes.
# Needs rsvg-convert (brew install librsvg); sips and iconutil ship with macOS.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
src="$root/docs/assets/meter-icon.svg"
out="$root/Resources/AppIcon.icns"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

command -v rsvg-convert >/dev/null || {
  echo "need rsvg-convert: brew install librsvg" >&2
  exit 1
}

# The source is a complete 1024 canvas: the squircle (824pt at 100,100), its
# drop shadow and edge highlight are drawn in the artwork, so no mask is
# applied here.
iconset="$work/AppIcon.iconset"
mkdir -p "$iconset"
rsvg-convert -w 1024 -h 1024 "$src" -o "$work/icon_1024.png"

# The sizes Finder, the Dock, alerts and Get Info actually look for.
for spec in "16 16x16" "32 16x16@2x" "32 32x32" "64 32x32@2x" \
            "128 128x128" "256 128x128@2x" "256 256x256" "512 256x256@2x" \
            "512 512x512" "1024 512x512@2x"; do
  px="${spec%% *}"
  name="${spec##* }"
  sips -z "$px" "$px" "$work/icon_1024.png" --out "$iconset/icon_$name.png" >/dev/null
done

iconutil -c icns "$iconset" -o "$out"
echo "wrote: $out"
