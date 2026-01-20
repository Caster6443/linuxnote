
#!/bin/bash

HOUR=$(date "+%H")
TIME=$(date "+%H:%M")
TOOLTIP=$(LC_TIME=zh_CN.UTF-8 date "+%Y年%m月%d日 %A")
ICON=""

printf '{"text": "%s %s", "tooltip": "%s"}\n' "$ICON" "$TIME" "$TOOLTIP"
