# Hyprland

大多数的配置都是通过修改 hyprland 的配置文件~/.config/hypr/hyprland.conf实现的  

## 设置命令开机自启动

进入该配置文件，在 exec-once 开头的那一块区域写入  
exec-once=需要开机自动执行的命令  

比如我在使用mpvpaper 这个视频壁纸项目  
我就把它提供的设置播放视频壁纸的命令写进了配置文件里设置开机自启  
exec-once=mpvpaper -o "--loop-file" eDP-1 Downloads/【哲风壁纸】剪影-多重影像.mp4 &  
其实这个写哪里应该是无所谓，但还是美观一些吧  

## 设置快捷键

也是在这个配置文件里修改  
关键字是 bind 开头的行  

```
$mainMod = SUPER # Sets "Windows" key as main modifier
$control = ctrl # by myself

#by myself
bind = $control, t, exec, $terminal
bind = $mainMod, F2,exec,pkill waybar || true && waybar #restart waybar  

# Example binds, see https://wiki.hypr.land/Configuring/Binds/ for more

#bind = $mainMod, T, exec, $terminal
bind = $mainMod, C, killactive,
bind = $mainMod, M, exit,
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, V, togglefloating,
bind = $mainMod, R, exec, $menu
bind = $mainMod, P, pseudo, # dwindle
bind = $mainMod, J, togglesplit, # dwindle

```

可以看到，这个快捷键设置其实就是自定义变量的值为某个键位，然后在 bind 里引用该变量并与其他变量和键位组合使用（后续使用发现一些常见键位并不需要赋值给变量，比如 CTRL 、SHIFT、F10 之类的直接写也能识别）  

比如我自定义的 ctrl + t 打开 konsole（$terminal 也在这个配置文件里修改，默认是 kitty，我改成 konsole 了）  
然后在 bind 里引用该变量  
`$control = ctrl # by myself`  
`bind = $control, t, exec, $terminal`  

另一个是重启任务栏waybar 的快捷键，我设置成了 super + F2,命令逻辑比较简单就不解释了  
ctrl + ; 也是个快捷键，快捷打开剪切板，上次帮人家做作业，学校官网不准粘贴，我无意中粘贴成功了，或许当时按的就是这个键位，以后有机会再试试吧  

这个配置文件还有很多功能，环境变量之类的我还没用到  
`$terminal = konsole`  
`$fileManager = thunar`  
`$menu = fuzzel`  
这三个变量，终端，文件管理器，菜单都被我改成这些了，因为默认的不太习惯,当然修改之前对应的包都要装上


关于桌面快捷键的事，虽然配置文件的 bind 的注释里都写清楚用途，但我还是记录一下常用的默认配置和我的自定义的快捷键配置  

```
super + e				打开 thunar 文件管理器
super + c				关闭当前窗口
super + 数字键		    切换到指定数字的工作区
super + v				切换窗口状态，在浮动和平铺状态中切换
super + r				打开应用列表
super + 左键拖动	     	移动窗口（当窗口处于平铺状态时）
super + 右键拖动		    拉伸窗口（当窗口处于平铺状态时）
super + 鼠标滚轮		    快捷切换工作区
super + q				关闭 waybar
super + F2			    重启 waybar
super + s				快速最小化当前桌面窗口，再次使用就会回来
```

关于这个 super + s 快捷键，我是这样理解的，所有的工作区都是桌面的不同区域，而 super s 则是把当前使用的桌面上的所有窗口收进下面的抽屉里，再次按下就会当前使用的桌面上展开，也就是从抽屉里拿出来放上  


hyprland 自己也有 wiki，肯定是比 archwiki 在这方面更详细的，可以多看看  
[https://wiki.hypr.land/](https://wiki.hypr.land/)  

## 剪切板方案

`sudo pacman -S --needed wl-clipboard`  
`yay -S cliphist`  
然后在 hyprland 配置文件里写入  

```
exec-once = wl-paste --type text --watch cliphist store # Stores only text data
exec-once = wl-paste --type image --watch cliphist store # Stores only image data

#绑定调用剪切板的快捷键
bind = $mainMod, x, exec, cliphist list | fuzzel --dmenu --with-nth 2 | cliphist decode | wl-copy

#如果用的文件管理器是 fuzzel 的话
```

如果是其他文件管理器，对应的键位绑定配置就去看 hyprland 的 wiki [https://wiki.hypr.land/Useful-Utilities/Clipboard-Managers/](https://wiki.hypr.land/Useful-Utilities/Clipboard-Managers/)  
  
  

## 截图录屏方案

安装这三个包  
`sudo pacman -S grim slurp wf-recorder`

然后在 hyprland 配置文件里绑定快捷键  

```

# 区域截图：同时保存到图片目录和剪贴板
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" | tee ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png | wl-copy

# 全屏截图：同时保存到图片目录和剪贴板  
bind = $mainMod,q,exec, grim | tee ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png | wl-copy

# 录屏快捷键  
bind = $mainMod SHIFT, v, exec, wf-recorder -g "$(slurp)" -f "$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4"
bind = $mainMod CTRL, v, exec, pkill -SIGINT wf-recorder  # 停止录制

```

## waybar 美化

参考的别人的美化风格，整体配置比较模块化，总体文件结构如图  

![e5bef4dea6e712828b69b69bad2ee1b3_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/e5bef4dea6e712828b69b69bad2ee1b3_MD5.png)  

一个个介绍吧  


center-test.jsonc 是我用来临时检测我的 arch 图标有没有居中，用 waybar -c ~/.config/waybar/center-test.jsonc 测试，会在当前的 bar 下面再显示出一个临时的居中 arch 图标，以此来检测上面的 arch 图标有没有居中  
waybar_config/center-test.jsonc  


colors.css 用于声明各种颜色变量以供调用  
关于这个，konsole 支持鼠标指针放颜色代码上去可以预览颜色，很方便我修改  
waybar_config/color.css


config.jsonc 是整体框架，模块定义在别的文件里写  
waybar_config/config.jsonc  





modules-dividers.jsonc 定义了各种图形，用于不同模块之间的图形衔接，在 css 中具体调色  
waybar_config/modules-dividers.jsonc  


modules.jsonc 里是各种模块的定义，注释已经很清楚了  
waybar_config/modules.jsonc  


style.css 包含了模块和连接符的美化  
比如custom/left_div#9 连接符，它的左右颜色是根据 color 和 background-color 决定的  
waybar_config/style.css  



script 里面都是模块调用的脚本  
scripts/cava.sh 是音频可视化调用的脚本文件  


metadata.sh 辅助音频可视化，实现悬停显示正在播放的音频名称





get-clock.sh 就是简单的悬停获取时间的脚本， 时钟模块调用的  


下面两个是截屏调用的脚本，因为脚本在 hyprland 快捷键里早就有使用，所以我就拿来复用了  
screenshot_edit.sh


screenshot_quick.sh




set_wallpaper.sh 快捷切换壁纸脚本，和下面的脚本结合使用


wallpaper_scroll.sh  
壁纸目录应当存放在$HOME/Pictures/anime/wallpapers 下  




wf-recorder.sh 录屏菜单脚本

switch-audio-output.sh 快捷选择音频输出设备  


桌面美化效果预览如下  

![3714b46c5aee50f0520ab81ef0acdbb1_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/3714b46c5aee50f0520ab81ef0acdbb1_MD5.png)  

有个小瑕疵，就是那个控制息屏的模块，它的两个状态切换的图标大小是不一样的，当前是启用息屏，中间的图标正好居中，我切换到另一个状态，图标就小了一点，中间的图标就会往左移动一些，但我也懒得改了，不过修改也简单，改成大小一致的图标就行，但我还没找到合适的，另一个方案是用 css 的 padding 字段，严格控制该字符的边距就行了，但我暂时也不改了  

过一段时间或许会去试试 niri，感觉挺不错的  


好的，已经叛逃到 niri 了，hyprland 真的回不去了，同时 waybar 也做了部分优化和为了适配 niri 的部分微调，因此这段配置，能用吧，至少作为 hyprland 的 bar 是可以的，但还是有待优化，之后单独列出 niri 的相关块，或许会顺便优化一下这里的部分通用代码逻辑吧，比如滚动切换壁纸使用 pkill 是很浪费性能的，明明 mpvpaper 就支持直接覆盖，不过还是等我后续修改吧  

好了，waybar也不用了，用的noctalia-shell,似乎dms更加完善，潜力更高，但它的动画效果目前是不如noctalia的，所以还是用着noctalia吧，但我认为它们的可定制性还是不如waybar，但仔细想想，waybar如果功能做得比较多了，内存占用就会更大，这时就更需要系统性的配置调优，那我为啥不直接用人家专门开发的桌面shell，主要还是现在的自己不懂开发，忙着备考也没时间学，但我会去学的。  

## 禁用触控板

使用hyprctl devices 命令查看设备  

```bash
❯ hyprctl devices                                                  
mice:
Mouse at 55abfcd826a0:
rapoo-rapoo-gaming-device
default speed: 0.00000
scroll factor: -1.00
Mouse at 55abfde531e0:
rapoo-rapoo-gaming-device-keyboard-1
default speed: 0.00000
scroll factor: -1.00
Mouse at 55abfde52e30:
asuf1204:00-2808:0202-mouse
default speed: 0.00000
scroll factor: -1.00
Mouse at 55abfe365130:
asuf1204:00-2808:0202-touchpad
default speed: 0.00000
scroll factor: -1.00


```

可以看到触控板设备名为asuf1204:00-2808:0202-touchpad  
hyprctl keyword 'device[asuf1204:00-2808:0202-touchpad]:enabled' 'false'这条命令可以关闭触控板，设置为 true 就打开  

那就可以写个 shell 脚本再通过 bind 绑定键位  

```bash

#!/usr/bin/env bash

# 你提供的正确设备名称和语法！
DEVICE_TOUCHPAD="asuf1204:00-2808:0202-touchpad"

# 状态文件
STATE_FILE="/tmp/hypr_touchpad.state"

if [ -f "$STATE_FILE" ]; then
    # --- 状态文件存在，说明触控板当前是【禁用】的 ---
    # --- 目标：【启用】它 ---
    hyprctl keyword "device[$DEVICE_TOUCHPAD]:enabled" 'true'
    
    notify-send "Touchpad" "已启用 ✅" -u low
    rm "$STATE_FILE"
else
    # --- 状态文件不存在，说明触控板当前是【启用】的 ---
    # --- 目标：【禁用】它 ---
    
    hyprctl keyword "device[$DEVICE_TOUCHPAD]:enabled" 'false'
    
    notify-send "Touchpad" "已禁用 ⛔" -u low
    touch "$STATE_FILE"
fi


```

加上执行权限  
`sudo chmod +x ~/.config/hypr/scripts/toggle_touchpad.sh`  

在 hyprland 配置文件上绑定键位 ctrl+f10  

```bash

# 切换触控板 (Ctrl + F10)
bind = CTRL, F10, exec, ~/.config/hypr/scripts/toggle_touchpad.sh

```

## 浮动窗口间隙设置

在使用时注意到我的 waybar 和浮动窗口之间有一段空白，不太美观  
这个空白大小是可以修改的，还是在那个 hyprland 配置文件里  

```bash

# https://wiki.hypr.land/Configuring/Variables/#general
general {
    gaps_in = 5
    gaps_out = 0,10,10,10
    就是gaps_out这个变量，它可以设定浮动窗口四周的空白保留区域的像素大小，只设定一个值就是只保
留上部分区域的空白像素大小，多个值就要之间加上逗号    
    border_size = 2

    # https://wiki.hypr.land/Configuring/Variables/#variable-types for info about colors
    col.active_border = rgba(33ccffee) rgba(00ff99ee) 45deg
    col.inactive_border = rgba(595959aa)

    # Set to true enable resizing windows by clicking and dragging on borders and gaps
    resize_on_border = false

    # Please see https://wiki.hypr.land/Configuring/Tearing/ before you turn this on
    allow_tearing = false

    layout = dwindle
}


```

这个变量同样可以在 hyprland 的 wiki 里查到，还是吃了英语不好的亏  

本来想把四周全设置 0 的，但我又想想，没有四周留白和平铺模式有啥区别，那不就成了不能动的窗口吗？所以我故意除了顶部全都设置了10像素的留白空间，这样才知道我用的是浮动窗口模式（其实平铺模式会和 waybar 重叠，通过这个也能看出来😅）  

## 视频壁纸方案

项目名 mpvpaper  

项目地址 [https://github.com/GhostNaN/mpvpaper](https://github.com/GhostNaN/mpvpaper)  
这个项目要求三个前置软件包  
sudo pacman -S --needed ninja meson mpv  
然后克隆构建和安装  

```

git clone --single-branch [https://github.com/GhostNaN/mpvpaper](https://github.com/GhostNaN/mpvpaper)
cd mpvpaper
meson setup build --prefix=/usr/local
ninja -C build
ninja -C build install

```

使用方法  
`mpvpaper DP-2 /path/to/video`  
DP-2 是显示器名字，也就是说可以指定显示器播放，自己的显示器名字用 hyprctl monitors all查看所有 hyprland 检测到的显示器信息，懒得看就直接用 ALL 代替所有显示器  

笔记本内置屏幕名字一般是 eDP-1,我的就是  
但这个只能播放一次，需要循环播放就需要使用命令  
例如这样的  
`mpvpaper -o "--loop-file" eDP-1 Downloads/【哲风壁纸】剪影-多重影像.mp4`  
这个命令是前台运行，所以可以在尾巴加上&，但是这样关闭终端就会杀死进程，另一种方法是加上& disown，这样即使关闭终端也不会杀死进程，不过如果要写进 exec-once 里只需要单用一个&就足够了  
`mpvpaper -o "--loop-file" eDP-1 Downloads/【哲风壁纸】剪影-多重影像.mp4 &`  
这个命令就可以写进 hyprland 的 exec-once 设置开机自启  

  
  

## 截屏翻译方案

主要使用 Crow Translate 这个程序  
1.安装主程序  
`yay -S crow-translate`  

2.安装 Wayland/OCR 核心依赖  
tesseract 是引擎, slurp 是划词工具, portal 是 Wayland 门户  
`sudo pacman -S tesseract slurp xdg-desktop-portal-hyprland`  


3.安装 OCR 语言包  
我玩未来战用的，就装英韩中三个语言吧  
`sudo pacman -S tesseract-data-eng tesseract-data-kor tesseract-data-chi_sim`  


打开软件Crow Translate  
点右下角三个横线进入这个界面的这个设置  
![0a0a553e147730d9c419a9bde4feaf87_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/0a0a553e147730d9c419a9bde4feaf87_MD5.png)  
把安装的 OCR 语言包都勾选上  

再到这个选项  
![4a6cfd13a058ea72523797bb98fca63f_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/4a6cfd13a058ea72523797bb98fca63f_MD5.png)  

点一下最右边的按钮 Detect fastest  
URL 里面是翻译引擎，默认的早就失效了，需要按这个按钮刷新出新翻译引擎，不然用旧的会在翻译栏报 418 错误  

目前只能在程序主界面点击截图才能截图翻译，关于快捷键截图翻译，关于全局的那一片是灰色的不能用，目前猜测是因为我的 plasma 和 hyprland 的混合桌面环境导致的，也有可能是因为 hyprland 禁止绕过它配置快捷键，反正目前还不知道为啥，有待后续排查（我也懒得排查这玩意，不如多找找别的开源项目，排不排查再说吧）  

![2f595e1d4a2c51550e22cf213bcb7f00_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/2f595e1d4a2c51550e22cf213bcb7f00_MD5.png)  

另外在安装过程中，有个注意事项，不能在包管理器 pacman 工作的时候后台跑游戏，尤其是 steam 游戏，不然 hyprland 会卡死，忘记是为啥了，反正最好别这样搞  

# Waydroid

## Waydroid 初始配置

安装 waydroid 并初始化  
`sudo pacman -S waydroid`  
`sudo waydroid init`  
//如果需要使用谷歌服务，可以指定带有谷歌服务的镜像  
`sudo waydroid init -s GAPPS`  


原生 Waydroid 是 x86 架构的，想使用 arm 架构应用比如安装运行 apk 需要安装翻译层  
安装waydroid-script  
`yay -S waydroid-script-git`  

waydroid-scripts 项目提供了 waydroid-extras 命令来安装翻译层  
libhoudini 用于英特尔  
libndk 用于 AMD  

不过在某些程序无法运行时，两个都可以装上试试看  

我是 A 卡  
sudo waydroid-extras 跟着提示一步步走选择安装libndk就行了  

使用谷歌商店会出现此设备不能安装的情况，需要将设备 id 加入谷歌设备中  
这个项目同样提供了获取设备 id 和提供添加 id 的谷歌官网链接，也在 waydroid-extras 命令中  

后面发现了 waydroid 轮椅级别的服务工具，功能很全，貌似已经覆盖了上面的工具的所有功能，还是图形化的，叫waydroid-helper，可以用 pacman 直接安装  

## Waydroid 画面撕裂问题

具体表现形式是类似花屏和撕裂，不过只有黑色色调  

还是混合显卡的问题，是 waydroid 默认使用显卡和桌面环境使用的显卡不一致导致的，我的 plasma 桌面环境默认使用 N 卡（可以用watch -n 1 nvidia-smi 查看哪些进程在使用 N 卡，每秒实时刷新），waydroid 在使用 A 卡集显，需要切换 waydroid 的显卡使用策略，为此 GitHub 上有个项目提供解决方案脚本  

[https://github.com/Quackdoc/waydroid-scripts/](https://github.com/Quackdoc/waydroid-scripts/blob/main/waydroid-choose-gpu.sh)  

这个链接  

脚本内容是  

```bash
❯ cat waydroid-scripts/waydroid-choose-gpu.sh  

#!/usr/bin/env bash
set -eo pipefail

lspci="$(lspci -nn | grep '\[03')" # https://pci-ids.ucw.cz/read/PD/03

echo -e "Please enter the GPU number you want to pass to WayDroid:\n"
gpus=()
i=0
while IFS= read lspci; do
gpus+=("$lspci")
echo "  $((++i)). $lspci"
done < <(echo "$lspci")
echo ""
while [ -z "$gpuchoice" ]; do
read -erp ">> Number of GPU to pass to WayDroid (1-${#gpus[@]}): " ans
if [[ "$ans" =~ [0-9]+ && $ans -ge 1 && $ans -le ${#gpus[@]} ]]; then
gpuchoice="${gpus[$((ans-1))]%% *}" # e.g. "26:00.0"
fi
done

echo ""
echo "Confirm that these belong to your GPU:"
echo ""

ls -l /dev/dri/by-path/ | grep -i $gpuchoice

echo ""

card=$(ls -l /dev/dri/by-path/ | grep -i $gpuchoice | grep -o "card[0-9]")
rendernode=$(ls -l /dev/dri/by-path/ | grep -i $gpuchoice | grep -o "renderD[1-9][1-9][1-9]")

echo /dev/dri/$card
echo /dev/dri/$rendernode

cp /var/lib/waydroid/lxc/waydroid/config_nodes /var/lib/waydroid/lxc/waydroid/config_nodes_$(date +
%Y-%m-%d-%H:%M).bak
cp /var/lib/waydroid/waydroid.cfg /var/lib/waydroid/waydroid.cfg_$(date +%Y-%m-%d-%H:%M).bak

#lxc.mount.entry = /dev/dri dev/dri none bind,create=dir,optional 0 0
sed -i '/drm_device/d' /var/lib/waydroid/waydroid.cfg
sed -i "/^\[waydroid\]/a drm_device = /dev/dri/$rendernode" /var/lib/waydroid/waydroid.cfg
waydroid upgrade --offline

```

## waydroid 按键映射

之前无法解决 waydroid 没有滑动映射的问题，在 github 上看到了一个项目，还算能用，  

项目地址：[https://github.com/waydroid-helper/waydroid-helper/tree/main](https://github.com/waydroid-helper/waydroid-helper/tree/main)  

对于 archlinux 用户，直接从 aur 仓库安装即可  
`yay -S waydroid-helper`  

这个应用功能比较齐全了，值得一提的是，在设置按键映射时，会出现一个窗口，然后在窗口里设置映射键位，这里并不是说明上说的，把映射键位放在对应按键上就行，而是根据这个窗口与 waydroid 的缩放比例，放到对应的位置，要使用映射时，需要先鼠标聚焦到映射的窗口  

类似这样，我映射了游戏的方向键，因为这个 b 游戏的方向键只支持滑动操作，可以看到，我的方向键在窗口中的位置是等比例缩小游戏窗口和方向键的对应位置，我需要使用映射时必须把鼠标聚焦到左下角的映射窗口  

![a7e2f3ce98025b7463ef958137883955_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/a7e2f3ce98025b7463ef958137883955_MD5.png)  

这个助手还提供其他功能，比如伪装成指定机型，获取设备 id，之类的常见需求  