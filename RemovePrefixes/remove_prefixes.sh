#!/bin/bash
# =============================
# RemovePrefix 多頁面支援 + 跨平台版
# 自動掃描所有 ./css 作為內容來源
# by cyl@iMac
# 使用方法：
# Mac/Linux: chmod +x remove_prefixes.sh && ./remove_prefixes.sh
# Windows: 使用 Git Bash 或 WSL 執行
# =============================

# 設定環境變量以處理特殊字符
export LC_ALL=C

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
        # MacOS 的 sed 命令處理前綴轉換
        LC_ALL=C sed -E \
            -e '/(input-placeholder|::-webkit-input-placeholder|:-moz-placeholder|:-ms-input-placeholder)/b' \
            -e '/-webkit-appearance: *none/b' \
            -e 's/^([[:space:]]*)-webkit-border-radius:/\1border-radius:/g' \
            -e 's/^([[:space:]]*)-moz-border-radius:/\1border-radius:/g' \
            -e 's/^([[:space:]]*)-webkit-box-sizing:/\1box-sizing:/g' \
            -e 's/^([[:space:]]*)-moz-box-sizing:/\1box-sizing:/g' \
            -e 's/^([[:space:]]*)-webkit-transform:/\1transform:/g' \
            -e 's/^([[:space:]]*)-moz-transform:/\1transform:/g' \
            -e 's/^([[:space:]]*)-webkit-transition:/\1transition:/g' \
            -e 's/^([[:space:]]*)-moz-transition:/\1transition:/g' \
            -e 's/^([[:space:]]*)-webkit-animation:/\1animation:/g' \
            -e 's/^([[:space:]]*)-moz-animation:/\1animation:/g' \
            -e 's/^([[:space:]]*)-ms-animation:/\1animation:/g' \
            "$file" | \
        LC_ALL=C awk '
            # 保存前一行的内容和属性名称
            function get_prop(line) {
                if (match(line, /:[^;]+/))
                    return substr(line, 1, RSTART)
                return line
            }
            
            NR > 1 { 
                # 获取当前行和前一行的属性名
                curr_prop = get_prop($0)
                prev_prop = get_prop(prev)
                
                # 如果两行的属性名相同，跳过当前行
                if (curr_prop == prev_prop)
                    next
                
                # 如果不是连续的空行，打印前一行
                if (!(prev ~ /^[[:space:]]*$/ && $0 ~ /^[[:space:]]*$/))
                    print prev
            }
            # 保存当前行
            { prev = $0 }
            # 打印最后一行
            END { 
                if (NR > 0) 
                    print prev 
            }
        ' > "$temp_file"
    elif [ "$OS_TYPE" = "Linux" ]; then
        # Linux 的 sed 命令使用相同的規則
        LC_ALL=C sed -E '
            # 保留 input-placeholder 相關的選擇器
            /input-placeholder/b

            # 保留只有單一前綴屬性的情況（不轉換為標準屬性）
            # 使用 N 指令讀取下一行進行檢查
            /-[a-z]*-/{
                N
                /.*\{[[:space:]]*-[a-z]*-[^}]*\}/!b
                /-[a-z]*-.*-[a-z]*-/!b
            }

            # 保留 -webkit-appearance: none 的特殊情況
            /-webkit-appearance: *none/b

            # 處理帶有標準版本的情況
            /border-radius:/{
                /-[a-z]*-border-radius:/d
            }
            /box-sizing:/{
                /-[a-z]*-box-sizing:/d
            }
            /transform:/{
                /-[a-z]*-transform:/d
            }
            /transition:/{
                /-[a-z]*-transition:/d
            }
            /animation:/{
                /-[a-z]*-animation:/d
            }

            # 處理只有前綴版本的情況
            s/^([^-}]*)-webkit-border-radius:/\1border-radius:/g
            s/^([^-}]*)-moz-border-radius:/\1border-radius:/g
            s/^([^-}]*)-webkit-box-sizing:/\1box-sizing:/g
            s/^([^-}]*)-moz-box-sizing:/\1box-sizing:/g
            s/^([^-}]*)-webkit-transform:/\1transform:/g
            s/^([^-}]*)-moz-transform:/\1transform:/g
            s/^([^-}]*)-webkit-transition:/\1transition:/g
            s/^([^-}]*)-moz-transition:/\1transition:/g
            s/^([^-}]*)-webkit-animation:/\1animation:/g
            s/^([^-}]*)-moz-animation:/\1animation:/g

            # 移除其他前綴屬性（排除已處理的屬性和 webkit-appearance）
            /[^-:]{1}[^:]*-webkit-(?!appearance)[^i][^n]/d
            /[^-:]{1}[^:]*-moz-[^i][^n]/d
            /[^-:]{1}[^:]*-ms-[^i][^n]/d

            # 移除重複的轉換後的屬性
            /^.*border-radius:.*border-radius:/d
            /^.*box-sizing:.*box-sizing:/d
            /^.*transform:.*transform:/d
            /^.*transition:.*transition:/d
            /^.*animation:.*animation:/d

            # 移除空行
            /^[[:space:]]*$/d
        ' "$file" > "$temp_file"
    else
        # Linux/Windows 的 sed 命令使用相同的處理邏輯
        LC_ALL=C sed -E '
            # 保留特殊情況
            /(input-placeholder|::-webkit-input-placeholder|:-moz-placeholder|:-ms-input-placeholder)/b
            /-webkit-appearance: *none/b

            # 移除重複的標準屬性行（只保留第一個）
            /border-radius:.*border-radius:/d
            /box-sizing:.*box-sizing:/d
            /transform:.*transform:/d
            /transition:.*transition:/d
            /animation:.*animation:/d

            # 移除標準版本之前的所有前綴版本
            /[^-]border-radius:/{
                i=""
                :a
                $!N
                /\n[^}]*/!{
                    P
                    D
                }
                /.*\n.*-[a-z]+-border-radius:/d
                /\n[^}]/ba
                P
                D
            }

            # 轉換單一前綴為標準版本
            s/^([[:space:]]*)-webkit-box-sizing:/\1box-sizing:/
            s/^([[:space:]]*)-moz-box-sizing:/\1box-sizing:/
            s/^([[:space:]]*)-ms-box-sizing:/\1box-sizing:/
            s/^([[:space:]]*)-webkit-transform:/\1transform:/
            s/^([[:space:]]*)-moz-transform:/\1transform:/
            s/^([[:space:]]*)-ms-transform:/\1transform:/
            s/^([[:space:]]*)-webkit-transition:/\1transition:/
            s/^([[:space:]]*)-moz-transition:/\1transition:/
            s/^([[:space:]]*)-ms-transition:/\1transition:/
            s/^([[:space:]]*)-webkit-animation:/\1animation:/
            s/^([[:space:]]*)-moz-animation:/\1animation:/
            s/^([[:space:]]*)-ms-animation:/\1animation:/

            # 移除空行但保留縮排
            /^[[:space:]]*$/d
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
