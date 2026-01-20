
#!/bin/bash

# 1. 
OUTPUTS=$(wpctl status | awk '/Sinks:/ {flag=1; next} /Sources:/ {flag=0} flag && NF > 1 {match($0, /([0-9]+)\.\s(.+?)\s+\[vol:/, arr); if (arr[1]) print arr[1] " " arr[2]}')

# 2. 
CHOSEN_DESCRIPTION=$(echo "$OUTPUTS" | cut -d' ' -f2- | fuzzel --dmenu -p "快捷选择音频输出: ")

# 3. 
[ -z "$CHOSEN_DESCRIPTION" ] && exit

# 4. 
CHOSEN_ID=$(echo "$OUTPUTS" | grep -F "$CHOSEN_DESCRIPTION" | awk '{print $1}')

# 5. 
wpctl set-default "$CHOSEN_ID"
