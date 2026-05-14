
#!/bin/bash

# Magisk 包名修改脚本
# 用法: ./change_package_name.sh [新包名]
# 示例: ./change_package_name.sh com.yourname.magisk

set -e  # 遇到错误立即退出

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 检查参数
if [ $# -eq 0 ]; then
    echo -e "${RED}错误：请提供新的包名${NC}"
    echo "用法: $0 <新的包名>"
    echo "示例: $0 com.yourname.magisk"
    exit 1
fi

OLD_PKG="com.topjohnwu.magisk"
NEW_PKG="$1"

# 验证包名格式
if ! [[ $NEW_PKG =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]]; then
    echo -e "${RED}错误：包名格式不正确${NC}"
    echo "包名必须包含至少两个部分，只能使用小写字母、数字、下划线和点号"
    echo "且不能以数字开头"
    exit 1
fi

echo -e "${GREEN}开始修改 Magisk 包名...${NC}"
echo "旧包名: $OLD_PKG"
echo "新包名: $NEW_PKG"
echo -e "${YELLOW}注意：Stub 包名会自动修改为 ${NEW_PKG}.stub${NC}"
echo ""

# 备份原文件（可选）
BACKUP_DIR="backup_$(date +%Y%m%d_%H%M%S)"
echo "创建备份目录: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# 需要修改的文件列表
FILES_TO_MODIFY=(
    "app/build.gradle.kts"
    "app/stub/build.gradle.kts"
    "app/core/build.gradle.kts"
    "app/core/src/main/AndroidManifest.xml"
    "app/core/src/main/java/com/topjohnwu/magisk/Config.kt"
    "app/core/src/main/java/com/topjohnwu/magisk/MagiskApp.kt"
    "app/stub/src/main/AndroidManifest.xml"
    "native/src/magisk.cpp"
    "native/src/core/magisk.cpp"
    "native/src/core/module.cpp"
    "scripts/build.py"
)

# 函数：修改文件中的包名
modify_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo "处理: $file"
        # 备份原文件
        cp "$file" "$BACKUP_DIR/$(basename $file).bak"
        # 替换主包名
        sed -i "s/$OLD_PKG/$NEW_PKG/g" "$file"
        # 替换 stub 包名
        sed -i "s/${OLD_PKG}.stub/${NEW_PKG}.stub/g" "$file"
    else
        echo -e "${YELLOW}警告: 文件不存在 - $file${NC}"
    fi
}

# 递归查找并修改所有 .kt, .java, .cpp, .xml, .kts 文件
modify_all_source() {
    echo "扫描并修改所有源代码文件..."
    
    # 查找所有相关类型的文件
    find . -type f \( \
        -name "*.kt" -o \
        -name "*.kts" -o \
        -name "*.java" -o \
        -name "*.cpp" -o \
        -name "*.c" -o \
        -name "*.h" -o \
        -name "*.xml" -o \
        -name "*.gradle" -o \
        -name "*.properties" -o \
        -name "*.py" \
    \) ! -path "./.git/*" ! -path "./$BACKUP_DIR/*" | while read -r file; do
        
        # 检查文件是否包含旧包名
        if grep -q "$OLD_PKG" "$file" 2>/dev/null; then
            echo "修改: $file"
            cp "$file" "$BACKUP_DIR/$(basename $file).bak"
            sed -i "s/$OLD_PKG/$NEW_PKG/g" "$file"
            sed -i "s/${OLD_PKG}.stub/${NEW_PKG}.stub/g" "$file"
        fi
    done
}

# 执行修改
echo "开始修改配置文件..."
for file in "${FILES_TO_MODIFY[@]}"; do
    modify_file "$file"
done

echo ""
modify_all_source

# 特殊处理：修改目录结构（如果需要）
rename_directories() {
    echo ""
    echo "处理目录结构..."
    
    # 修改 Java/Kotlin 源文件目录
    OLD_PATH="app/core/src/main/java/com/topjohnwu/magisk"
    NEW_PATH=$(echo "$OLD_PATH" | sed "s|$OLD_PKG|$NEW_PKG|g" | tr '.' '/')
    
    if [ -d "$OLD_PATH" ]; then
        # 创建新的目录结构
        mkdir -p "$(dirname "$NEW_PATH")"
        mv "$OLD_PATH" "$NEW_PATH" 2>/dev/null || true
        echo "移动目录: $OLD_PATH -> $NEW_PATH"
    fi
    
    # 清理空目录
    find app/core/src/main/java/com -type d -empty -delete 2>/dev/null || true
}

# 询问是否修改目录结构
echo ""
echo -e "${YELLOW}是否要修改源代码目录结构？(y/n)${NC}"
echo "注意：这可能会影响 Git 历史，建议仅在本地编译时使用"
read -r answer
if [[ "$answer" == "y" ]] || [[ "$answer" == "Y" ]]; then
    rename_directories
fi

# 创建 GitHub Actions 使用的配置文件
create_action_config() {
    cat > ".github/pkg_config.sh" << EOF
#!/bin/bash
# 自动生成的包名配置文件
export MAGISK_PACKAGE="$NEW_PKG"
export MAGISK_STUB_PACKAGE="${NEW_PKG}.stub"
EOF
    chmod +x ".github/pkg_config.sh"
    echo "创建配置文件: .github/pkg_config.sh"
}

create_action_config

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}包名修改完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo "旧包名: $OLD_PKG"
echo "新包名: $NEW_PKG"
echo ""
echo "下一步："
echo "1. 检查修改结果: git diff"
echo "2. 提交修改: git add . && git commit -m 'Change package name to $NEW_PKG'"
echo "3. 推送到 GitHub: git push origin master"
echo "4. 触发 Actions 编译"
echo ""
echo -e "${YELLOW}备份文件保存在: $BACKUP_DIR${NC}"
