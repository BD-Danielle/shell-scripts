#!/bin/bash

# =============================
# 壓縮 CSS 資料夾中所有檔案
# 使用 clean-css-cli
# by cyl@iMac
# npm install -g clean-css-cli
# chmod +x compress-css.sh
# 注意：此腳本會排除已經是 .min.css 的檔案
# 使用方法：
# Mac/Linux: chmod +x compress-css.sh && ./compress-css.sh
# Windows: 使用 Git Bash 或 WSL 執行
# =============================

# 定義輔助函數
get_size() {
    if [[ "$OS_TYPE" == "MacOS" ]]; then
        stat -f%z "$1"
    else
        stat -c%s "$1"
    fi
}

format_bytes() {
    local bytes=$1
    if ((bytes < 1024)); then
        echo "${bytes} B"
    elif ((bytes < 1048576)); then
        echo "$(( (bytes + 51) / 1024 )).$(( ((bytes % 1024) * 10 + 51) / 1024 )) KiB"
    elif ((bytes < 1073741824)); then
        echo "$(( (bytes + 524288) / 1048576 )).$(( ((bytes % 1048576) * 10 + 524288) / 1048576 )) MiB"
    else
        echo "$(( (bytes + 536870912) / 1073741824 )).$(( ((bytes % 1073741824) * 10 + 536870912) / 1073741824 )) GiB"
    fi
}

# 檢測作業系統類型
OS_TYPE="unknown"
case "$(uname -s)" in
    Darwin*)    OS_TYPE="MacOS";;
    Linux*)     OS_TYPE="Linux";;
    MINGW*)     OS_TYPE="Windows";;
    CYGWIN*)    OS_TYPE="Windows";;
esac

echo "檢測到作業系統: $OS_TYPE"

# 處理目標目錄
CSS_DIR="./css"
BACKUP_DIR="./css/backup/$(date +%Y%m%d_%H%M%S)"
MINIFY_DIR="./css/minify"

# 顯示腳本功能說明
echo "=============================="
echo "CSS 壓縮腳本 - 跨平台版"
echo "功能："
echo "1. 自動壓縮 CSS 檔案（排除 .min.css）"
echo "2. 自動備份原始檔案"
echo "3. 支援選擇輸出位置"
echo "=============================="

# 詢問用戶選擇輸出模式
while true; do
    echo "請選擇輸出模式："
    echo "1) 建立新檔案到 minify 目錄"
    echo "2) 在原目錄建立 .min.css 檔案"
    read -p "請輸入選項 (1 或 2): " choice
    case $choice in
        [1-2]) break;;
        *) echo "錯誤：請輸入 1 或 2";;
    esac
done

# 創建必要的目錄
mkdir -p "$BACKUP_DIR"
mkdir -p "$MINIFY_DIR"

echo "📦 備份原始 CSS..."
if cp -r "$CSS_DIR"/*.css "$BACKUP_DIR/" 2>/dev/null; then
    echo "✓ 備份已建立: $BACKUP_DIR"
else
    echo "⚠️ 警告：沒有找到可備份的 CSS 檔案"
    exit 1
fi

echo "🚀 開始壓縮 CSS 檔案（排除 .min.css）..."

# 初始化總計變數
total_original=0
total_minified=0
processed_files=0

# 遍歷所有 CSS 文件
for file in "$CSS_DIR"/*.css; do
    # 排除已是 .min.css 的檔案
    if [[ $file != *".min.css" ]] && [ -f "$file" ]; then
        base_name=$(basename "$file")
        file_name="${base_name%.*}"
        
        if [ "$choice" = "1" ]; then
            # 輸出到 minify 目錄
            MINIFIED_FILE="$MINIFY_DIR/${file_name}.min.css"
        else
            # 輸出到原目錄
            MINIFIED_FILE="$CSS_DIR/${file_name}.min.css"
        fi
        
        echo "🛠️  壓縮中：$base_name"
        
        # 壓縮處理
        cleancss -o "$MINIFIED_FILE" "$file"
        
        # 計算檔案大小
        ORIG_SIZE=$(get_size "$file")
        MIN_SIZE=$(get_size "$MINIFIED_FILE")
        SAVED_PERCENT=$(( (ORIG_SIZE - MIN_SIZE) * 100 / ORIG_SIZE ))
        
        # 更新總計
        total_original=$((total_original + ORIG_SIZE))
        total_minified=$((total_minified + MIN_SIZE))
        processed_files=$((processed_files + 1))
        
        # 顯示單個檔案結果
        echo "   📄 ${file_name}.css:"
        echo "      原始：$(format_bytes $ORIG_SIZE)"
        echo "      壓縮：$(format_bytes $MIN_SIZE) (節省 $SAVED_PERCENT%)"
    fi
done

# 顯示總結
echo "=============================="
echo "📊 壓縮總結："
echo "處理檔案數：$processed_files"
if [ $processed_files -gt 0 ]; then
    total_saved=$((total_original - total_minified))
    total_saved_percent=$((total_saved * 100 / total_original))
    echo "📦 原始總大小：$(format_bytes $total_original)"
    echo "🗜️  壓縮後總大小：$(format_bytes $total_minified)"
    echo "💹 節省空間：$(format_bytes $total_saved) ($total_saved_percent%)"
fi

# 根據作業系統顯示完成訊息
case "$OS_TYPE" in
    "Windows")
        echo "✅ 處理完成！"
        echo "請使用 Windows 檔案總管查看結果";;
    "MacOS")
        echo "✅ 處理完成！"
        echo "請使用 Finder 查看結果";;
    "Linux")
        echo "✅ 處理完成！"
        echo "請使用檔案管理器查看結果";;
    *)
        echo "✅ 處理完成！";;
esac

echo "備份檔案位置: $BACKUP_DIR"
if [ "$choice" = "1" ]; then
    echo "壓縮檔案已建立於: $MINIFY_DIR"
else
    echo "壓縮檔案已建立在原目錄中"
fi
