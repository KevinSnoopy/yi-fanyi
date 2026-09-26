#!/usr/bin/env bash
# 下载 Web 端所需中文字体（CanvasKit 无法读系统字体，必须打包 asset）。
# 用法: bash tool/fetch_fonts.sh
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)/assets/fonts"
BASE="https://fastly.jsdelivr.net/gh/notofonts/noto-cjk@main/Sans/OTF/SimplifiedChinese"
FONTS=(Regular Medium Bold)

mkdir -p "$DIR"
for w in "${FONTS[@]}"; do
  f="$DIR/NotoSansCJKsc-$w.otf"
  if [ -f "$f" ]; then
    echo "skip $(basename "$f") (exists)"
    continue
  fi
  echo "downloading NotoSansCJKsc-$w.otf (~16MB) ..."
  curl -L --retry 3 --fail -o "$f" "$BASE/NotoSansCJKsc-$w.otf"
done
echo "done: $(ls "$DIR")"
