#!/usr/bin/env python3
import re
import pathlib
from urllib.parse import quote

# 遍历当前目录下所有的 .md 文件
for p in pathlib.Path(".").glob("*.md"):
    if p.suffix == ".converted.md": continue # 跳过已转换的文件
    
    txt = p.read_text(encoding="utf-8")

    # 1. 转换图片: ![[path/to/img.png|alt]] -> ![alt](path/to/img.png)
    def img_repl(m):
        content = m.group(1)
        parts = content.split('|')
        path = parts[0].strip()
        # 提取文件名作为 Alt 文本
        alt = parts[-1].split('/')[-1] if len(parts) > 1 else path.split('/')[-1]
        # 对路径进行编码，防止空格导致链接断开
        safe_path = quote(path)
        return f"![{alt}]({safe_path})"

    txt = re.sub(r'!\[\[([^\]]+)\]\]', img_repl, txt)

    # 2. 转换普通 WikiLink
    def link_repl(m):
        inner = m.group(1)
        path, alias = inner.split("|", 1) if "|" in inner else (inner, inner)
        path, alias = path.strip(), alias.strip()
        
        path_out = path if re.search(r'\.\w+$', path) else path + ".md"
        return f"[{alias}]({quote(path_out)})"

    txt = re.sub(r'\[\[([^\]]+)\]\]', link_repl, txt)

    # 3. 转换 Callouts (:::info)
    txt = re.sub(r'::: *(\w+)\s*\n(.*?)\n:::', 
                 lambda m: f"\n> **{m.group(1).capitalize()}:**\n> " + m.group(2).strip().replace("\n", "\n> ") + "\n", 
                 txt, flags=re.S)

    # 输出新文件，或者直接覆盖源文件（建议先输出新文件测试）
    output_path = p.with_suffix(".converted.md")
    output_path.write_text(txt, encoding="utf-8")
    print(f"已处理: {p.name} -> {output_path.name}")
