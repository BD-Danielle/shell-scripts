#!/bin/bash

# =============================
# PurgeCSS 多頁面支援 + 跨平台版
# 自動掃描所有 HTML 作為內容來源
# by cyl@iMac
# npm i -D @fullhuman/postcss-purgecss
# chmod +x purgecss-run.sh
# 使用方法：在終端機中執行 ./purgecss-run.sh
# =============================

set -euo pipefail

START_TIME=$(date +%s)

echo "📁 準備輸出與備份資料夾..."
mkdir -p dist
mkdir -p backup

echo "📦 備份原始 CSS 至 backup/..."
cp -r css/*.css backup/ 2>/dev/null || echo "⚠️ 沒有可備份的 CSS 檔案"

echo "🧹 清除 dist/ 舊檔案..."
rm -rf dist/*

# ======== 🔍 自動收集所有 HTML 檔案（支援子目錄） ========
echo "🔍 尋找所有 HTML 檔案..."
HTML_FILES=$(find . -type f -name "*.html")
echo "共找到 $(echo "$HTML_FILES" | wc -l) 個 HTML 檔案"

# ======== 🚀 執行 PurgeCSS ========
echo "🚀 執行 PurgeCSS（內容掃描多頁）..."
npx purgecss \
  --css css/**/*.css \
  --content $HTML_FILES **/*.js \
  --safelist /^nav-/ modal-open active /-hover$/ \
  --output dist/

# ======== 📊 檔案大小統計函式（跨平台 stat） ========
get_size() {
  if [[ "$(uname)" == "Darwin" ]]; then
    stat -f %z "$1"
  else
    stat -c %s "$1"
  fi
}

# ======== 📏 比較檔案大小總量 ========
echo "📊 檔案大小總結："
orig_total=0
min_total=0

for file in css/*.css; do
  [[ "$file" == *.min.css ]] && continue
  min_file="dist/$(basename "$file")"
  [ -f "$min_file" ] || continue
  orig=$(get_size "$file")
  min=$(get_size "$min_file")
  orig_total=$((orig_total + orig))
  min_total=$((min_total + min))
done

echo "📦 原始 CSS 總大小：$orig_total bytes"
echo "🧼 精簡後 CSS 總大小：$min_total bytes"

END_TIME=$(date +%s)
echo "✅ 完成！耗時 $((END_TIME - START_TIME)) 秒。結果輸出至 dist/"