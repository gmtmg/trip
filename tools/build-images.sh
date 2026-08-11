#!/usr/bin/env bash
# 元画像(assets/)からWeb用のWebPを生成する。
# 元画像は一切変更しない。差し替えたら再実行するだけでよい。
#   bash tools/build-images.sh
#
# 注意: 元画像はリポジトリに含めていない(.gitignore)。
#       クローンしただけでは動かないので、実行前に assets/ へ元画像を置くこと。
#       サイトの表示に必要なのは生成済みの assets/web/ だけ。
set -euo pipefail

cd "$(dirname "$0")/.."
SRC=assets
OUT=assets/web
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$OUT"

# 出力名 | 元ファイル | 長辺px | cwebp品質
JOBS="
logo|trip-logo.png|420|82
hero-tacos|1786440132227.png|1200|80
tacos-red|1786440123530.png|900|80
cactus|1786440068491.png|620|84
kitchen|1786440078311.png|1500|76
bar|1786440097503.png|1600|74
mezcal|vibe-3b.png|1000|76
lighters|1786440092280.png|1000|76
plate-tacos|menu-tacos.png|1000|78
nachos|1786440152996.jpg|900|76
yakisoba|1786440146847.jpg|900|78
appetizer|1786454941702.jpg|1000|76
"

dim() {  # dim <file> -> "幅 高さ"
  sips -g pixelWidth -g pixelHeight "$1" 2>/dev/null |
    awk '/pixelWidth/{w=$2}/pixelHeight/{h=$2}END{print w, h}'
}

fail=0

# NOTE: ループ本体の sips / cwebp には </dev/null を付けること。
# 付けないと JOBS を流し込んでいる標準入力を食ってしまい、
# 特定の1件だけ縦横比が壊れる、といった再現しにくい事故が起きる。
while IFS='|' read -r name src max q; do
  [ -z "${name:-}" ] && continue
  in="$SRC/$src"
  [ -f "$in" ] || { echo "!! 元画像が見つかりません: $in"; fail=1; continue; }

  # 長辺基準でリサイズ。透過を保つためPNGを経由してからWebPへ
  sips -s format png --resampleHeightWidthMax "$max" "$in" --out "$TMP/$name.png" \
    >/dev/null </dev/null
  cwebp -quiet -m 6 -q "$q" -alpha_q 92 "$TMP/$name.png" -o "$OUT/$name.webp" </dev/null

  # 縦横比が元画像とずれていないか検算する
  read -r sw sh <<< "$(dim "$in")"
  read -r ow oh <<< "$(dim "$TMP/$name.png")"
  ratio_ok=$(awk -v a="$sw" -v b="$sh" -v c="$ow" -v d="$oh" \
    'BEGIN{ print ( (a/b) > (c/d)*0.99 && (a/b) < (c/d)*1.01 ) ? 1 : 0 }')

  if [ "$ratio_ok" = "1" ]; then
    mark="OK"
  else
    mark="!! 縦横比ずれ ${sw}x${sh} -> ${ow}x${oh}"
    fail=1
  fi

  printf '  %-13s %5sx%-5s %7s -> %7s  %s\n' \
    "$name" "$ow" "$oh" \
    "$(du -h "$in" | cut -f1)" "$(du -h "$OUT/$name.webp" | cut -f1)" "$mark"
done <<EOF
$JOBS
EOF

# NOTE: SNS用サムネイル assets/web/og.jpg はここでは作らない。
#       tools/og-image.html を撮影して作るので tools/build-og.sh を使うこと。
#       （以前ここで元画像から生成していたため、実行するたびに
#         せっかく作ったサムネイルが上書きされてしまっていた）

echo
echo "合計: $(du -sh "$OUT" | cut -f1)"
[ "$fail" = "0" ] || { echo "問題のある画像があります"; exit 1; }
