
#!/bin/bash

config_file="/tmp/cava_waybar_config"

#Cava 配置
echo "
[general]
bars = 10
[input]
method = pulse
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
bar_delimiter = ;
" > "$config_file"

#后台状态监控
status_file="/tmp/cava_waybar_status"

(
    while :; do
        # 同时检测 Playing 和 Paused
        # 只要不是 Stopped 或 No players，我们都认为它是“活跃”的
        status=$(playerctl status 2>/dev/null)
        
        if [[ "$status" == "Playing" ]] || [[ "$status" == "Paused" ]]; then
            info=$(playerctl metadata --format '{{status_icon}} {{artist}} - {{title}}' 2>/dev/null)
            # 写入状态: 1=活跃
            echo "1" > "$status_file"
            echo "$info" | sed 's/"/'\''/g' >> "$status_file"
        else
            # Stopped 或无播放器: 0=隐藏
            echo "0" > "$status_file"
        fi
        sleep 1
    done
) &

bg_pid=$!
trap "kill $bg_pid; exit" EXIT

#主循环
char_zero=$(printf '\u2581') # 下八分之一块 (基准线)
dict="s/;//g;s/0/$char_zero/g;s/1/▂/g;s/2/▃/g;s/3/▄/g;s/4/▅/g;s/5/▆/g;s/6/▇/g;s/7/█/g;"

cava -p "$config_file" | while read -r line; do
    if [ -f "$status_file" ]; then
        mapfile -t state < "$status_file"
        is_active="${state[0]}"
        song_info="${state[1]}"
    else
        is_active="0"
    fi

    if [ "$is_active" == "1" ]; then
        # 播放时: 显示跳动的波形
        # 暂停时: Cava 会自动输出全0，这里会被替换成基准线 (__________)
        # 这样就有了一个可以点击的区域
        visualizer=$(echo "$line" | sed "$dict")
        echo "{\"text\": \"$visualizer\", \"tooltip\": \"$song_info\"}"
    else
        # 停止时: 隐藏
        echo "{\"text\": \"\", \"tooltip\": \"\"}"
    fi
done
