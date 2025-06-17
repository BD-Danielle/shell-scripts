#!/bin/bash

# 處理目標目錄
CSS_DIR="./css"

# 遍歷所有 CSS 文件
find "$CSS_DIR" -name "*.css" | while read -r file; do
    echo "Processing: $file"
    
    # 建立臨時文件
    temp_file="${file}.tmp"
    
    # 使用 sed 刪除包含前綴的整行
    # 1. 刪除包含 -webkit- 的行
    # 2. 刪除包含 -moz- 的行
    # 3. 刪除包含 : -webkit- 的行
    # 4. 刪除包含 : -moz- 的行
    # 5. 刪除連續的空行
    sed -E '
        /[^:]-webkit-/d;
        /[^:]-moz-/d;
        /: *-webkit-/d;
        /: *-moz-/d;
        /^[[:space:]]*$/d;
    ' "$file" > "$temp_file"
    
    # 檢查是否有變更
    if cmp -s "$file" "$temp_file"; then
        echo "No changes in: $file"
        rm "$temp_file"
    else
        # 替換原文件
        mv "$temp_file" "$file"
        echo "Removed prefixed lines from: $file"
    fi
done

echo "All CSS files have been processed."
