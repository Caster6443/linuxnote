
#!/usr/bin/env bash

# 选区截图到临时文件，打开 swappy 编辑。swappy 退出后，检测并通知保存的文件（优先 ~/Pictures/Screenshots）
DST_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DST_DIR"

TMP="/tmp/swappy_screenshot_$$.png"
TS="/tmp/swappy_ts_$$"
date +%s > "$TS"

# take region
if ! grim -g "$(slurp)" "$TMP"; then
  notify-send -a "Swappy" "Selection failed" --hint=int:transient:1
  rm -f "$TMP" "$TS"
  exit 1
fi

# run swappy and wait until it exits
swappy -f "$TMP"

# find newest file in DST_DIR modified after TS
NEW=$(find "$DST_DIR" -type f -newer "$TS" -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk 'NR==1{print $2}')

if [ -n "$NEW" ]; then
  notify-send -a "Swappy" "Saved: $(basename "$NEW")" --hint=int:transient:1
else
  # fallback: find any new file in home that looks like screenshot or swappy-saved
  NEW2=$(find "$HOME" -type f -newer "$TS" \( -iname '*swappy*' -o -iname '*screenshot*' -o -iname '*.png' -o -iname '*.jpg' \) 2>/dev/null | head -n1)
  if [ -n "$NEW2" ]; then
    notify-send -a "Swappy" "Saved (other location): $(basename "$NEW2")" --hint=int:transient:1
  else
    notify-send -a "Swappy" "No new file detected (maybe saved to a custom path)" --hint=int:transient:1
  fi
fi

# cleanup
rm -f "$TMP" "$TS"
exit 0
