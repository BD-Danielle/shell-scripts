#!/bin/bash
# =============================
# RemovePrefix 多頁面支援 + 跨平台版
# 自動掃描所有 ./css 作為內容來源
# by cyl@iMac
# 使用方法：
# Mac/Linux: chmod +x remove_prefixes.sh && ./remove_prefixes.sh
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

# 詢問用戶輸入 CSS 目錄
echo "請輸入 CSS 目錄路徑 (直接按 Enter 使用預設值: ./css)："
read -p "> " input_css_dir
CSS_DIR=${input_css_dir:-"./css"}

# 移除路徑末尾的斜線
CSS_DIR=${CSS_DIR%/}

# 檢查目錄是否存在
if [ ! -d "$CSS_DIR" ]; then
    echo "⚠️ 警告：目錄 '$CSS_DIR' 不存在"
    read -p "是否要建立此目錄？(y/n) " create_dir
    if [[ $create_dir =~ ^[Yy]$ ]]; then
        mkdir -p "$CSS_DIR"
        echo "✓ 已建立目錄：$CSS_DIR"
    else
        echo "❌ 取消操作"
        exit 1
    fi
fi

# 設定其他目錄
BACKUP_DIR="$CSS_DIR/backup/$(date +%Y%m%d_%H%M%S)"
PREFIXES_DIR="$CSS_DIR/prefixes"

# 創建必要的目錄
mkdir -p "$BACKUP_DIR"
mkdir -p "$PREFIXES_DIR"

# 詢問用戶是否要覆蓋原始檔案
echo "請選擇操作模式："
echo "1) 建立新檔案到 prefixes 目錄"
echo "2) 覆蓋原始檔案（會先建立備份）"
read -p "請輸入選項 (1 或 2): " choice

# 遍歷所有 CSS 文件
find "$CSS_DIR" -name "*.css" | while read -r file; do
    echo "Processing: $file"
    
    # 創建備份
    cp "$file" "$BACKUP_DIR/$(basename "$file")"
    echo "備份已建立: $BACKUP_DIR/$(basename "$file")"
    
    # 建立臨時文件
    temp_file="${file}.tmp"
     # 根據作業系統選擇適當的 sed 命令
    if [ "$OS_TYPE" = "MacOS" ]; then
        # MacOS 的 sed 命令需要特別處理
        sed -E '
            # 移除屬性前綴
            /[^:]-webkit-/d;
            /[^:]-moz-/d;
            /[^:].*-ms.*:/d;              # 移除任何包含 -ms 的屬性名稱
            # 移除屬性值前綴
            /: *-webkit-/d;
            /: *-moz-/d;
            # 移除屬性值後綴包含 -ms 的行
            /:[^;{}]*-ms.*[;{}]/d;
            # 移除空行
            /^[[:space:]]*$/d;
        ' "$file" > "$temp_file"
    elif [ "$OS_TYPE" = "Linux" ]; then
        # Linux 的 sed 命令
        sed -E '
            # 移除屬性前綴
            /[^:]-webkit-/d;
            /[^:]-moz-/d;
            /[^:].*-ms.*:/d;              # 移除任何包含 -ms 的屬性名稱
            # 移除屬性值前綴
            /: *-webkit-/d;
            /: *-moz-/d;
            # 移除屬性值後綴包含 -ms 的行
            /:[^;{}]*-ms.*[;{}]/d;
            # 移除空行
            /^[[:space:]]*$/d;
        ' "$file" > "$temp_file"
    else
        # Windows 的 sed 命令 (假設使用 Git Bash 或 WSL)
        sed -E '
            # 移除屬性前綴
            /[^:]-webkit-/d;
            /[^:]-moz-/d;
            /[^:].*-ms.*:/d;              # 移除任何包含 -ms 的屬性名稱
            # 移除屬性值前綴
            /: *-webkit-/d;
            /: *-moz-/d;
            # 移除屬性值後綴包含 -ms 的行
            /:[^;{}]*-ms.*[;{}]/d;
            # 移除空行
            /^[[:space:]]*$/d;
        ' "$file" > "$temp_file"
    fi
    
    # 根據作業系統使用適當的比較命令
    if [ "$OS_TYPE" = "Windows" ]; then
        # Windows 環境使用 fc 命令
        if fc "$file" "$temp_file" > /dev/null 2>&1; then
            echo "No changes in: $file"
            rm "$temp_file"
        else
            echo "Changes detected in: $file"
            if [ "$choice" = "1" ]; then
                # 建立新檔案到 prefixes 目錄
                new_file="$PREFIXES_DIR/$(basename "$file")"
                mv "$temp_file" "$new_file"
                echo "建立新檔案: $new_file"
            else
                # 覆蓋原始檔案
                mv "$temp_file" "$file"
                echo "已更新: $file"
            fi
        fi
    else
        # Mac/Linux 環境使用 cmp 命令
        if cmp -s "$file" "$temp_file"; then
            echo "No changes in: $file"
            rm "$temp_file"
        else
            if [ "$choice" = "1" ]; then
                # 建立新檔案到 prefixes 目錄
                new_file="$PREFIXES_DIR/$(basename "$file")"
                mv "$temp_file" "$new_file"
                echo "建立新檔案: $new_file"
            else
                # 覆蓋原始檔案
                mv "$temp_file" "$file"
                echo "已更新: $file"
            fi
        fi
    fi
done

# 根據作業系統顯示適當的完成訊息
case "$OS_TYPE" in
    "Windows")
        echo "✅ 處理完成！請使用 Windows 檔案總管查看結果";;
    "MacOS")
        echo "✅ 處理完成！請使用 Finder 查看結果";;
    "Linux")
        echo "✅ 處理完成！請使用檔案管理器查看結果";;
    *)
        echo "✅ 處理完成！";;
esac
echo "備份檔案位置: $BACKUP_DIR"
if [ "$choice" = "1" ]; then
    echo "新檔案已建立於: $PREFIXES_DIR"
else
    echo "原始檔案已更新，原檔案已備份"
fi
