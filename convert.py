#!/usr/bin/env python3
import re
import pathlib
from urllib.parse import quote

# 配置：你的图片存放路径（相对于 md 的路径）
RESOURCE_DIR = "_resources/linux笔记"

def fix_markdown(file_path):
    txt = file_path.read_text(encoding="utf-8")
    
    # 1. 转换图片: ![[.../img.png|300]] -> ![img.png](_resources/linux笔记/img.png)
    # 强制修正路径到你的 _resources 目录下
    def img_repl(m):
        content = m.group(1).split('|')[0].strip()
        file_name = content.split('/')[-1]
        new_path = f"{RESOURCE_DIR}/{file_name}"
        # quote 会处理中文路径和空格，防止 Git 预览失效
        return f"![{file_name}]({quote(new_path)})"
    
    txt = re.sub(r'!\[\[([^\]]+)\]\]', img_repl, txt)

    # 2. 修复代码块结束后的空行问题（解决“挤成一团”）
    # 如果 ``` 后面紧跟文字，强行插入两个换行
    txt = re.sub(r'(```\n)(?!\n)', r'\1\n', txt)
    txt = re.sub(r'([^\n])\n(```)', r'\1\n\n\2', txt)

    # 3. 修复 Desktop 笔记里那些散开的标题字符 (Z s h -> Zsh)
    # 这是一个针对性修复，你可以根据需要添加更多词
    mangled_words = {
        "Z s h": "Zsh",
        "自 动 建 议 插 件": "自动建议插件",
        "激 活": "激活",
        "提 示 符": "提示符",
        "自 动 补 全": "自动补全",
        "语 法 高 亮": "语法高亮"
    }
    for old, new in mangled_words.items():
        txt = txt.replace(old, new)

    # 4. 修复标题格式：确保 # 后面有空格，且标题前后有空行
    txt = re.sub(r'([^\n])\n(#+)', r'\1\n\n\2', txt)

    # 保存修复后的文件（直接覆盖原文件，或者你可以改名输出）
    file_path.write_text(txt, encoding="utf-8")
    print(f"已修复并转好图片链接: {file_path.name}")

# 批量处理目录下所有 md
for p in pathlib.Path(".").glob("*.md"):
    if ".converted" in p.name: continue
    fix_markdown(p)
