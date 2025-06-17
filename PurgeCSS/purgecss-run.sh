#!/bin/bash

# =============================
# PurgeCSS 多頁面支援 + 跨平台版
# 自動掃描所有 HTML 作為內容來源
# by cyl@iMac
# npm i -D @fullhuman/postcss-purgecss
# 使用方法：
# Mac/Linux: chmod +x purgecss-run.sh && ./purgecss-run.sh
# Windows: 使用 Git Bash 或 WSL 執行
# =============================

# 檢測作業系統類型
OS_TYPE="unknown"
case "$(uname -s)" in
    Darwin*)    OS_TYPE="MacOS";;
    Linux*)     OS_TYPE="Linux";;
    MINGW*)     OS_TYPE="Windows";;
    CYGWIN*)    OS_TYPE="Windows";;
esac

echo "檢測到作業系統: $OS_TYPE"

set -euo pipefail

START_TIME=$(date +%s)

# 處理目標目錄
CSS_DIR="./css"
BACKUP_DIR="./css/backup/$(date +%Y%m%d_%H%M%S)"
PURGECSS_DIR="./css/purge"

# 顯示腳本功能說明
echo "=============================="
echo "PurgeCSS 自動化腳本 - 跨平台版"
echo "功能："
echo "1. 自動掃描 HTML 和 JS 檔案作為內容來源"
echo "2. 使用 PurgeCSS 清理未使用的 CSS"
echo "3. 自動備份原始檔案"
echo "=============================="

# 詢問用戶選擇輸出模式
while true; do
    echo "請選擇輸出模式："
    echo "1) 建立新檔案到 purge 目錄"
    echo "2) 覆蓋原始檔案（自動備份）"
    read -p "請輸入選項 (1 或 2): " choice
    case $choice in
        [1-2]) break;;
        *) echo "錯誤：請輸入 1 或 2";;
    esac
done

# 創建必要的目錄
mkdir -p "$BACKUP_DIR"
mkdir -p "$PURGECSS_DIR"

echo "📦 備份原始 CSS..."
if cp -r "$CSS_DIR"/*.css "$BACKUP_DIR/" 2>/dev/null; then
    echo "✓ 備份已建立: $BACKUP_DIR"
else
    echo "⚠️ 警告：沒有找到可備份的 CSS 檔案"
    exit 1
fi

# ======== 🔍 自動收集所有 HTML 檔案（支援子目錄） ========
echo "🔍 尋找所有 HTML 檔案..."
HTML_FILES=$(find . -type f -name "*.html")
HTML_COUNT=$(echo "$HTML_FILES" | wc -l)
echo "共找到 $HTML_COUNT 個 HTML 檔案"

# ======== 🚀 執行 PurgeCSS ========
echo "🚀 執行 PurgeCSS（內容掃描多頁）..."

# 準備 HTML 和 JS 文件列表
echo "準備內容文件清單..."
CONTENT_FILES=()
# 添加所有 HTML 文件
while IFS= read -r file; do
    [ -n "$file" ] && CONTENT_FILES+=("$file")
done <<< "$HTML_FILES"
# 添加所有 JS 文件
while IFS= read -r file; do
    [ -n "$file" ] && CONTENT_FILES+=("$file")
done < <(find . -type f -name "*.js")

# 構建內容文件參數
CONTENT_ARGS=""
for file in "${CONTENT_FILES[@]}"; do
    CONTENT_ARGS="$CONTENT_ARGS --content $file"
done

echo "開始處理 CSS 文件..."
for css_file in "$CSS_DIR"/*.css; do
    if [ -f "$css_file" ]; then
        base_name=$(basename "$css_file")
        echo "處理: $base_name"
        
        if [ "$choice" = "1" ]; then
            # 輸出到新目錄
            npx purgecss \
                --css "$css_file" \
                $CONTENT_ARGS \
                --safelist "/^nav-/" "modal-open" "active" "/-hover$/" \
                --output "$PURGECSS_DIR"
            OUTPUT_DIR="$PURGECSS_DIR"
        else
            # 覆蓋原始檔案
            npx purgecss \
                --css "$css_file" \
                $CONTENT_ARGS \
                --safelist "/^nav-/" "modal-open" "active" "/-hover$/" \
                --output "$CSS_DIR"
            OUTPUT_DIR="$CSS_DIR"
        fi
    fi
done

# ======== 📊 檔案大小統計函式（跨平台 stat） ========
get_size() {
    if [[ "$OS_TYPE" == "MacOS" ]]; then
        stat -f %z "$1"
    else
        stat -c %s "$1"
    fi
}

# ======== 📏 比較檔案大小 ========
echo "📊 檔案大小總結："
orig_total=0
purged_total=0

for file in "$BACKUP_DIR"/*.css; do
    [ -f "$file" ] || continue
    base_name=$(basename "$file")
    purged_file="$OUTPUT_DIR/$base_name"
    
    if [ -f "$purged_file" ]; then
        orig_size=$(get_size "$file")
        purged_size=$(get_size "$purged_file")
        orig_total=$((orig_total + orig_size))
        purged_total=$((purged_total + purged_size))
        
        # 計算節省百分比
        saved_percent=$(( (orig_size - purged_size) * 100 / orig_size ))
        echo "📄 $base_name:"
        echo "   原始: $(numfmt --to=iec-i --suffix=B $orig_size)"
        echo "   處理後: $(numfmt --to=iec-i --suffix=B $purged_size) (節省 $saved_percent%)"
    fi
done

echo "=============="
echo "📦 原始 CSS 總大小：$(numfmt --to=iec-i --suffix=B $orig_total)"
echo "🧼 處理後 CSS 總大小：$(numfmt --to=iec-i --suffix=B $purged_total)"
saved_total_percent=$(( (orig_total - purged_total) * 100 / orig_total ))
echo "💹 總節省空間：$(numfmt --to=iec-i --suffix=B $((orig_total - purged_total))) ($saved_total_percent%)"

END_TIME=$(date +%s)
DURATION=$((END_TIME - START_TIME))

# 根據作業系統顯示完成訊息
case "$OS_TYPE" in
    "Windows")
        echo "✅ 處理完成！耗時 ${DURATION} 秒"
        echo "請使用 Windows 檔案總管查看結果：${OUTPUT_DIR#./}";;
    "MacOS")
        echo "✅ 處理完成！耗時 ${DURATION} 秒"
        echo "請使用 Finder 查看結果：${OUTPUT_DIR#./}";;
    "Linux")
        echo "✅ 處理完成！耗時 ${DURATION} 秒"
        echo "請使用檔案管理器查看結果：${OUTPUT_DIR#./}";;
    *)
        echo "✅ 處理完成！耗時 ${DURATION} 秒"
        echo "結果位置：${OUTPUT_DIR#./}";;
esac

echo "耗時 $((END_TIME - START_TIME)) 秒"
echo "備份檔案位置: $BACKUP_DIR"
if [ "$choice" = "1" ]; then
    echo "新檔案已建立於: $PURGECSS_DIR"
else
    echo "原始檔案已更新，原檔案已備份"
fi