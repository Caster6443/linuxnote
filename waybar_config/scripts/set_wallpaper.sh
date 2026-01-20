
#!/usr/bin/env bash

CONF="$HOME/.config/hypr/hyprland.conf"
MONITOR="eDP-1"

# File chooser
WP=$(zenity --file-selection --title="选择壁纸（支持图片/视频）")
[ -z "$WP" ] && exit 0

# Escape for sed
ESCAPED_WP=$(printf '%s\n' "$WP" | sed 's/[\/&]/\\&/g')

# Kill existing mpvpaper
pkill -9 mpvpaper 2>/dev/null

# mpvpaper 自动识别图片/视频，并自适应缩放不变形
mpvpaper "$MONITOR" "$WP" -o "--loop-file --no-audio --panscan=1 --profile=low-latency" &

notify-send "壁纸已应用" "$(basename "$WP")"

########################################

# Update autostart safely (no deletion)

########################################

# 1. 如果已有 mpvpaper 行 → 替换
if grep -q "mpvpaper" "$CONF"; then
    sed -i "s|exec-once *= *mpvpaper.*|exec-once = mpvpaper $MONITOR $ESCAPED_WP -o \"--loop-file --no-audio --panscan=1 --profile=low-latency\"|" "$CONF"

# 2. 否则追加到 AUTOSTART 部分下
else
    sed -i "/### AUTOSTART ###/a exec-once = mpvpaper $MONITOR $ESCAPED_WP -o \"--loop-file --no-audio --panscan=1 --profile=low-latency\"" "$CONF"
fi
