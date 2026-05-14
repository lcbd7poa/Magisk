#!/usr/bin/env python3
"""
Magisk 包名修改脚本 - Python 跨平台版本
用法: python3 change_package_name.py <新包名>
示例: python3 change_package_name.py com.yourname.magisk
"""

import os
import re
import sys
import shutil
from pathlib import Path
from datetime import datetime

# 颜色代码（可选）
class Colors:
    RED = '\033[91m'
    GREEN = '\033[92m'
    YELLOW = '\033[93m'
    NC = '\033[0m'  # No Color

def print_color(text, color=Colors.NC):
    """带颜色的打印"""
    if sys.stdout.isatty():
        print(f"{color}{text}{Colors.NC}")
    else:
        print(text)

def replace_in_file(file_path, old_pkg, new_pkg):
    """在文件中替换包名"""
    try:
        with open(file_path, 'r', encoding='utf-8', errors='ignore') as f:
            content = f.read()
        
        # 检查是否包含旧包名
        if old_pkg not in content and f"{old_pkg}.stub" not in content:
            return False
        
        # 替换包名
        new_content = content.replace(old_pkg, new_pkg)
        new_content = new_content.replace(f"{old_pkg}.stub", f"{new_pkg}.stub")
        
        # 写回文件
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(new_content)
        return True
    except Exception as e:
        print(f"  错误: {e}")
        return False

def main():
    # 检查参数
    if len(sys.argv) != 2:
        print_color("错误：请提供新的包名", Colors.RED)
        print(f"用法: {sys.argv[0]} <新包名>")
        print(f"示例: {sys.argv[0]} com.yourname.magisk")
        sys.exit(1)
    
    old_pkg = "com.topjohnwu.magisk"
    new_pkg = sys.argv[1]
    
    # 验证包名格式
    if not re.match(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$', new_pkg):
        print_color(f"错误：包名 '{new_pkg}' 格式不正确", Colors.RED)
        print("包名必须包含至少两个部分，只能使用小写字母、数字、下划线和点号")
        sys.exit(1)
    
    print_color(f"开始修改 Magisk 包名...", Colors.GREEN)
    print(f"旧包名: {old_pkg}")
    print(f"新包名: {new_pkg}")
    print(f"Stub 包名: {new_pkg}.stub")
    print()
    
    # 创建备份目录
    backup_dir = Path(f"backup_{datetime.now().strftime('%Y%m%d_%H%M%S')}")
    backup_dir.mkdir(exist_ok=True)
    print(f"备份目录: {backup_dir}")
    
    # 需要处理的文件扩展名
    extensions = ['.kt', '.kts', '.java', '.cpp', '.c', '.h', '.hpp', '.xml', '.gradle', '.properties', '.py']
    
    # 排除的目录
    exclude_dirs = {'.git', backup_dir.name, 'out', 'build'}
    
    modified_count = 0
    total_checked = 0
    
    # 遍历所有文件
    for root, dirs, files in os.walk('.'):
        # 排除不需要的目录
        dirs[:] = [d for d in dirs if d not in exclude_dirs]
        
        for file in files:
            file_path = Path(root) / file
            
            # 检查文件扩展名
            if file_path.suffix not in extensions and file not in ['build.gradle', 'AndroidManifest.xml']:
                continue
            
            total_checked += 1
            
            # 替换包名
            if replace_in_file(file_path, old_pkg, new_pkg):
                print(f"  修改: {file_path}")
                # 备份文件
                backup_path = backup_dir / f"{file_path.name}.bak"
                shutil.copy2(file_path, backup_path)
                modified_count += 1
    
    print()
    print_color("=" * 40, Colors.GREEN)
    print_color("包名修改完成！", Colors.GREEN)
    print_color("=" * 40, Colors.GREEN)
    print(f"检查文件数: {total_checked}")
    print(f"修改文件数: {modified_count}")
    print(f"旧包名: {old_pkg}")
    print(f"新包名: {new_pkg}")
    print()
    print("备份位置:", backup_dir)
    print()
    print("下一步:")
    print("  1. git add .")
    print(f"  2. git commit -m 'Change package name to {new_pkg}'")
    print("  3. git push origin master")

if __name__ == "__main__":
    main()
