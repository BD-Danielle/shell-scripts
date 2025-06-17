#!/bin/bash

# =============================
# 壓縮 CSS 資料夾中所有檔案
# 使用 clean-css-cli
# by cyl@iMac
# npm install -g clean-css-cli
# chmod +x compress-css.sh
# 注意：此腳本會排除已經是 .min.css 的檔案
# 使用方法：在終端機中執行 ./compress-css.sh
# =============================

# 處理目標目錄
CSS_DIR="./css"

echo "🚀 開始壓縮 CSS 檔案（排除 .min.css）..."

# 遍歷所有 CSS 文件
for file in $CSS_DIR/*.css; do
    # 排除已是 .min.css 的檔案
    if [[ $file != *".min.css" ]]; then
        MINIFIED_FILE="${file%.*}.min.css"
        
        echo "🛠️  壓縮中：$file → $MINIFIED_FILE"
        
        # 壓縮處理
        cleancss -o "$MINIFIED_FILE" "$file"
        
        # 顯示壓縮結果大小
        ORIG_SIZE=$(stat -f%z "$file")
        MIN_SIZE=$(stat -f%z "$MINIFIED_FILE")
        echo "   📦 原始大小：$ORIG_SIZE bytes → 壓縮後：$MIN_SIZE bytes"
    fi
done

echo "✅ 所有 CSS 壓縮完成！"
