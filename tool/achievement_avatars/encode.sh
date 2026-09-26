#!/bin/sh
# Encodes ./ach (from final.mjs) into ../../assets/achievements.
# Needs libwebp (brew install webp) for cwebp and img2webp.
set -e
OUT=../../assets/achievements
mkdir -p "$OUT"
cd ach
for f in *.png; do cwebp -quiet -q 82 "$f" -o "$OUT/${f%.png}.webp"; done
for d in *_win; do img2webp -loop 0 -d 67 -lossy -q 62 -m 6 "$d"/*.png -o "$OUT/$d.webp" >/dev/null; done
