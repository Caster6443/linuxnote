import os
import re

# 配置你的文件名
TARGET_FILE = 'Linux_Desktop.md'

def fix_markdown_formatting(file_path):
    # 1. 读取文件
    if not os.path.exists(file_path):
        print(f"错误: 找不到文件 {file_path}")
        return

    with open(file_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    new_lines = []
    in_code_block = False  # 标记是否在代码块中

    print(f"正在处理: {file_path} ...")

    for i, line in enumerate(lines):
        stripped_line = line.strip()
        
        # --- A. 处理代码块状态 ---
        # 如果检测到 ```，切换代码块状态
        if stripped_line.startswith('```'):
            in_code_block = not in_code_block
            new_lines.append(line)
            continue
        
        # 如果当前在代码块内部，直接保留原样，不做任何修改
        if in_code_block:
            new_lines.append(line)
            continue

        # --- B. 处理标题 (解决标题不渲染的问题) ---
        # 正则匹配以 # 开头，后跟一个空格的行 (例如 "# 标题" 或 "## 标题")
        if re.match(r'^#{1,6}\s', line):
            # 检查上一行是否已经是空行
            if new_lines and new_lines[-1].strip() != "":
                # 如果上一行有内容，插入一个空换行符
                new_lines.append("\n")
            new_lines.append(line)
            continue

        # --- C. 处理普通文本 (解决挤成一行的问题) ---
        # 如果是普通文本行（不为空），在行尾添加两个空格
        if stripped_line:
            # 去掉原有的换行符，加上 "  " 再换行
            clean_content = line.rstrip('\r\n')
            new_lines.append(clean_content + "  \n")
        else:
            # 如果原本就是空行，保留
            new_lines.append(line)

    # 2. 备份原文件 (防止意外)
    backup_name = file_path + ".bak"
    with open(backup_name, 'w', encoding='utf-8') as f:
        f.writelines(lines)
    print(f"已备份原文件为: {backup_name}")

    # 3. 写入修复后的内容
    with open(file_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    print("✅ 处理完成！行尾已补全空格，标题前已补全空行。")
    print("现在可以 git push 上去看看效果了。")

if __name__ == "__main__":
    fix_markdown_formatting(TARGET_FILE)
