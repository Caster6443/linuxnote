#!/usr/bin/env python3
import re
import pathlib
import shutil
from urllib.parse import quote

# ================= 配置 =================
TARGET_FILE = "Linux_Desktop.md"
IMG_DIR = "_resources/linux笔记"
# ========================================

def fix_content(text):
    # 1. 修复图片链接：![[...] ] -> ![basename](path)
    def img_repl(m):
        inner = m.group(1).split('|')[0].strip()
        file_name = inner.split('/')[-1]
        safe_path = quote(f"{IMG_DIR}/{file_name}")
        return f"![{file_name}]({safe_path})"
    text = re.sub(r'!\[\[([^\]]+)\]\]', img_repl, text)

    # 2. 核心：强制补齐空行（解决“挤成一团”的关键）
    # 规则：在每个标题 # 之前，如果不是文件开头且没空行，就补一个空行
    text = re.sub(r'([^\n])\n(#+ )', r'\1\n\n\2', text)
    # 规则：在代码块 ``` 之前和之后，确保都有空行隔离
    text = re.sub(r'([^\n])\n(```)', r'\1\n\n\2', text)
    text = re.sub(r'(```)\n([^\n])', r'\1\n\n\2', text)

    # 3. 针对 Desktop 笔记特定的“散装字符”修复
    mangled = {
        "Z s h": "Zsh",
        "自 动 建 议 插 件": "自动建议插件",
        "语 法 高 亮": "语法高亮",
        "自 动 补 全": "自动补全",
        "提 示 符": "提示符",
        "开 机 自 启 动": "开机自启动",
        "快 捷 键": "快捷键"
    }
    for old, new in mangled.items():
        text = text.replace(old, new)

    # 4. 清洗不可见字符（零宽空格等污染）
    text = text.replace('\u200b', '')
    
    return text

def main():
    p = pathlib.Path(TARGET_FILE)
    if not p.exists():
        print(f"错误：没找到 {TARGET_FILE}，请确认脚本运行位置。")
        return

    # --- 步骤 1: 创建备份 ---
    backup_file = p.with_suffix(".md.bak")
    shutil.copy(p, backup_file)
    print(f"[已备份] 原始文件已存为: {backup_file.name}")

    # --- 步骤 2: 读取并修复 ---
    try:
        content = p.read_text(encoding="utf-8")
        fixed_content = fix_content(content)
        
        # --- 步骤 3: 写回原文件 ---
        p.write_text(fixed_content, encoding="utf-8")
        print(f"[已修复] {TARGET_FILE} 排版已更新。")
        print("提示：如果效果不理想，可以手动用 .bak 文件覆盖回来。")
    except Exception as e:
        print(f"处理失败: {e}")

if __name__ == "__main__":
    main()
