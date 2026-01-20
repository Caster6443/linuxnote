
#!/usr/bin/env bash

# Fullscreen quick screenshot -> save to ~/Pictures/Screenshots, COPY TO CLIPBOARD, and notify

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/screenshot_$(date '+%Y%m%d_%H%M%S').png"

# Fullscreen using grim (no slurp)
if grim "$FILE"; then
  # 将生成的图片文件输入给 wl-copy
  wl-copy < "$FILE"

  # 通知文案提示已复制
  notify-send -a "Screenshot" "Saved & Copied: $(basename "$FILE")" --hint=int:transient:1
  exit 0
else
  notify-send -a "Screenshot" "Failed to take fullscreen screenshot" --hint=int:transient:1
  [ -f "$FILE" ] && rm -f "$FILE"
  exit 1
fi
