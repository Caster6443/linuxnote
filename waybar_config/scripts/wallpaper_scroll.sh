
#!/usr/bin/env bash

CONF="$HOME/.config/hypr/hyprland.conf"
MONITOR="eDP-1"
DIR="$HOME/Pictures/anime/wallpapers"
INDEX_FILE="$HOME/.cache/current_wallpaper_index"

mkdir -p "$(dirname "$INDEX_FILE")"

# Generate file list
mapfile -t FILES < <(find "$DIR" -type f \( -iname "*.jpg" -o -iname "*.png" -o -iname "*.jpeg" -o -iname "*.webp" -o -iname "*.mp4" -o -iname "*.mkv" \) | sort -V)

[ ${#FILES[@]} -eq 0 ] && notify-send "壁纸目录为空" && exit

# Load last index or initialize
if [ -f "$INDEX_FILE" ]; then
    INDEX=$(cat "$INDEX_FILE")
else
    INDEX=0
fi

# Adjust index
if [ "$1" = "next" ]; then
    INDEX=$(( (INDEX + 1) % ${#FILES[@]} ))
elif [ "$1" = "prev" ]; then
    INDEX=$(( (INDEX - 1 + ${#FILES[@]}) % ${#FILES[@]} ))
fi

# Save current index
echo "$INDEX" > "$INDEX_FILE"

WP="${FILES[$INDEX]}"

# Kill old mpvpaper
pkill -9 mpvpaper 2>/dev/null

# Apply wallpaper
mpvpaper "$MONITOR" "$WP" -o "--loop-file --no-audio --panscan=1 --profile=low-latency" &

notify-send "壁纸切换" "$(basename "$WP")"

# Escape wallpaper path for sed
ESCAPED_WP=$(printf '%s\n' "$WP" | sed 's/[\/&]/\\&/g')

# Update Hyprland autostart safely
if grep -q "mpvpaper" "$CONF"; then
    sed -i "s|exec-once *= *mpvpaper.*|exec-once = mpvpaper $MONITOR $ESCAPED_WP -o \"--loop-file --no-audio --panscan=1 --profile=low-latency\"|" "$CONF"
else
    sed -i "/### AUTOSTART ###/a exec-once = mpvpaper $MONITOR $ESCAPED_WP -o \"--loop-file --no-audio --panscan=1 --profile=low-latency\"" "$CONF"
fi
