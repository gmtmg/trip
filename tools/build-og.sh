#!/usr/bin/env bash
# tools/og-image.html を 1200x630 で撮影し、SNS用サムネイル
# assets/web/og.jpg を作る。版面を編集したら再実行すること。
#   bash tools/build-og.sh
set -euo pipefail

cd "$(dirname "$0")/.."
CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
[ -x "$CHROME" ] || { echo "Google Chrome が見つかりません: $CHROME"; exit 1; }

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

# 2倍で撮ってから縮小する。等倍だと文字の輪郭が甘くなる
"$CHROME" \
  --headless \
  --disable-gpu \
  --hide-scrollbars \
  --force-device-scale-factor=2 \
  --window-size=1200,630 \
  --virtual-time-budget=8000 \
  --screenshot="$TMP/og@2x.png" \
  "file://$PWD/tools/og-image.html" >/dev/null 2>&1

[ -s "$TMP/og@2x.png" ] || { echo "撮影に失敗しました"; exit 1; }

# OGPはJPEG/PNGが無難（WebP非対応のクローラがいるため）
sips -s format jpeg -s formatOptions 88 --resampleWidth 1200 \
  "$TMP/og@2x.png" --out assets/web/og.jpg >/dev/null </dev/null

W=$(sips -g pixelWidth  assets/web/og.jpg | awk '/pixelWidth/{print $2}')
H=$(sips -g pixelHeight assets/web/og.jpg | awk '/pixelHeight/{print $2}')
echo "assets/web/og.jpg  ${W}x${H}  $(du -h assets/web/og.jpg | cut -f1)"
[ "$W" = "1200" ] && [ "$H" = "630" ] || { echo "!! 寸法が 1200x630 になっていません"; exit 1; }
