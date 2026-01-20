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


# archlinux配置安全启动

## 理论基础

一、 什么是安全启动？  
安全启动 (Secure Boot)是主板 UEFI 固件里的一项安全功能。  

它的唯一目的是在操作系统（Arch / Windows）启动之前，阻止任何“不受信任”的代码运行。这主要是为了防御在开机阶段就加载的恶意软件（如 Rootkit）。  

理论依据：它的工作原理非常简单：UEFI 固中内置了一个“可信签名数据库”。当你开机时，UEFI 会像个“保安”一样，检查要加载的第一个启动文件（Bootloader）有没有“可信的签名”。  
默认情况下，UEFI 只信任一个签名：微软 (Microsoft) 的。  

如果启动文件（比如 `grubx664.efi`）没有微软签名，UEFI 会拒绝加载它，启动过程当场中止。  



二、 Arch Linux 的解决方案  

整套方案，核心理论就是**“信任接力”。我们利用一个微软信任的程序，来“引荐”我们自己的程序  
`shimx64.efi` 是一个由微软官方签名的小型引导程序,它有微软签名，所以“保安”(UEFI) 会允许它启动,shim 启动后的唯一任务，就是去加载下一个程序（也就是我们的 GRUB）。  


MOK (我们自己的“签名”)  
MOK (Machine Owner Key) 是我们自己创建的一对“签名密钥”（公钥/私钥）。  
`shim` 也不是什么都加载。它只会加载那些被“它信任的密钥”签过的文件。  
我们把 MOK 的“公钥”注册（Enroll）到主板里，`shim` 就会“认识”它。从此，`shim` 就会信任任何被我们 MOK“私钥”签过的文件。  
总结：`UEFI(信任) -> 微软(签名) -> shim(信任) -> MOK(签名) -> 我们的GRUB`。这条信任链就通了。  


独立的 GRUB  
信任链是通了，但 `shim` 只会验证 `grubx64.efi` 这一个文件。但常规的 GRUB 启动时，需要从磁盘上读取几十个零散的模块（比如 `fat.mod`, `btrfs.mod`）和配置文件 (`grub.cfg`)。`shim` 无法验证这几十个文件。  
解决方案：我们不能用常规的 GRUB。我们必须用 `grub-mkimage` 命令，手动创建一个“独立自主”的 `grubx64.efi`。  
理论：  
打包模块:  
我们把所有未来可能用到的驱动模块（`fat`, `part_gpt`, `btrfs` 等）提前打包并嵌入到 `grubx64.efi`文件内部。  

硬编码配置：  
我们把一个迷你的“启动脚本”（即 `grub-pre.cfg`）也硬编码进 `grubx64.efi` 的“大脑”里。  
这个“大脑”（`grub-pre.cfg`）的唯一任务，就是加载它“后备箱”里打包的正确驱动（比如 `insmod fat`），然后用正确的路径（比如 `set prefix=($root)/grub`），去找到那个真正的菜单 (`grub.cfg`)。  


`pacman` 钩子  
这个信任链必须全程维护。`grubx64.efi` 需要 MOK 签名，`vmlinuz-linux` (内核) 也同样需要 MOK 签名。  
pacman -Syu` 会用未签名的新内核覆盖掉旧的已签名内核。  
`pacman` 钩子 (Hook) 是一个自动化脚本。它在更新后，立即自动重签。  
内核钩子：  
监视 `linux-zen` 包。一旦更新，立刻自动运行 `sbsign` 命令，用你的 MOK 私钥给新的 `vmlinuz-linux-zen` 签名。  

GRUB 钩子：  
监视 `grub` 包。一旦更新，立刻自动运行 `update-sb-grub-efi.sh`，重新生成那个“独立管家” `grubx64.efi` 并自动签名。  

总结成一句话： 我们利用微软签名的 `shim`，来加载一个我们自己 MOK 签名的、内置了驱动和路径（`insmod fat`）的独立`grubx664.efi`，这个 `grub` 再去加载同样被 MOK 签名的内核，最后用 `pacman` 钩子让这个签名过程自动化。  

## 配置过程

### 1.GRUB 侧的配置

首先，安装相应的软件包：shim-signed（AUR 包），sbsigntools，mokutil。  

使用 OpenSSL 生成一对安全启动签名密钥，记得妥善保管。  

```bash
sudo mkdir /etc/secureboot/keys

# Generate key pair
KEYPAIR_PATH='/etc/secureboot/keys'
sudo openssl req -newkey rsa:4096 -nodes -keyout "$KEYPAIR_PATH/MOK.key" -new -x509 -sha256 -days 3650 -subj "/CN=My Arch Linux Machine Owner Key/" -out "$KEYPAIR_PATH/MOK.crt"
sudo openssl x509 -outform DER -in "$KEYPAIR_PATH/MOK.crt" -out "$KEYPAIR_PATH/MOK.cer"

```

现在，我们来编写具有 GRUB EFI 生成和自动签名脚本。  

```bash
> sudo mkdir -pv /etc/secureboot/libs/
> cat /etc/secureboot/libs/mok_sign.sh
mok_sign() {
    KEYPAIR_PATH='/etc/secureboot/keys'
    # sign if not already done so.
    if ! /usr/bin/sbverify --list "$1" 2>/dev/null | /usr/bin/grep -q "signature certificates"; then
        printf 'Signing %s...\n' "$1"
        sudo sbsign --key "$KEYPAIR_PATH/MOK.key" --cert "$KEYPAIR_PATH/MOK.crt" --output "$1" "$1"
    else
        printf 'Skip sign: %s\n' "$1"
    fi
}

```

然后在/etc/secureboot 这个文件夹下，新建 update-sb-grub-efi.sh 文件内容如下  

```bash
 #! /bin/bash
 
set -u
 
BASIC_MODULES="all_video boot btrfs cat chain configfile echo efifwsetup efinet ext2 fat
 font gettext gfxmenu gfxterm gfxterm_background gzio halt help hfsplus iso9660 jpeg 
 keystatus loadenv loopback linux ls lsefi lsefimmap lsefisystab lssal memdisk minicmd
 normal ntfs part_apple part_msdos part_gpt password_pbkdf2 png probe read reboot regexp
 search search_fs_uuid search_fs_file search_label sleep smbios squash4 test true video videoinfo
 xfs zfs zstd zfscrypt zfsinfo cpuid play tpm usb tar"
 
GRUB_MODULES="$BASIC_MODULES cryptodisk crypto gcry_arcfour gcry_blowfish gcry_camellia
 gcry_cast5 gcry_crc gcry_des gcry_dsa gcry_idea gcry_md4 gcry_md5 gcry_rfc2268 gcry_rijndael
 gcry_rmd160 gcry_rsa gcry_seed gcry_serpent gcry_sha1 gcry_sha256 gcry_sha512 gcry_tiger 
 gcry_twofish gcry_whirlpool luks lvm mdraid09 mdraid1x raid5rec raid6rec"
 
SCRIPT_PATH="$(dirname "$(realpath $0)")"
 
sudo grub-mkimage -c "$SCRIPT_PATH/grub-sb-stub/grub-pre.cfg" \
    -o /boot/efi/EFI/arch/grubx64.efi -O x86_64-efi \
    --sbat "$SCRIPT_PATH/grub-sbat.csv" \
    -m "$SCRIPT_PATH/grub-sb-stub/memdisk.tar" \
    $GRUB_MODULES
 
source "$(dirname "$0")/libs/mok_sign.sh"
 
mok_sign /boot/EFI/ARCH/grubx64.efi

#这里的实际路径要检查一下自己的系统的EFI分区挂载的的具体路径

```

复制 /usr/share/grub/sbat.csv 到 /etc/secureboot/grub-sbat.csv，并可对文件做部分修改，以避免出现 SBAT 问题。不过其实也没啥好改的  

真想改的话，就把倒数两行的 grub,4 和 grub.arch,4 中的 4 改成 5  

```bash
❯ cat /etc/secureboot/grub-sbat.csv        
sbat,1,SBAT Version,sbat,1,https://github.com/rhboot/shim/blob/main/SBAT.md
grub,4,Free Software Foundation,grub,2:2.14rc1-2,https//www.gnu.org/software/grub/
grub.arch,4,Arch Linux,grub,2:2.14rc1-2,https://archlinux.org/packages/core/x86_64/grub/

```

反正我是改成 5 了  

### 2.GRUB MemDisk 和预加载脚本

新建文件夹 /etc/secureboot/grub-sb-stub/memdisk，然后在里面新建 fonts 文件夹。将你需要的字体的 PF2 文 件（比如 /usr/share/grub/unicode.pf2）复制到 fonts 文件夹中。  

```bash
sudo mkdir -pv /etc/secureboot/grub-sb-stub/memdisk/fonts
sudo cp /usr/share/grub/unicode.pf2 /etc/secureboot/grub-sb-stub/memdisk/fonts/

```

随后修改当前路径到 /etc/secureboot/grub-sb-stub，执行 tar -cf memdisk.tar -C memdisk .。该命令会创建一个 memdisk，包含我们的字体文件数据，并给前面我们创建的签名脚本使用。  

```bash
cd /etc/secureboot/grub-sb-stub
tar -cf memdisk.tar -C memdisk .

```

创建文件 /etc/secureboot/grub-sb-stub/grub-pre.cfg，根据前面的脚本的配置的设置，这个 GRUB 脚本文件将在 GRUB 启动时立刻执行。  

```bash
insmod part_msdos
insmod part_gpt
insmod font
insmod fat
 
loadfont /fonts/unicode.pf2
 
search.fs_uuid 1B9C-667B root hd0,gpt1
set prefix=($root)/grub
configfile grub.cfg

```

上面的配置首先加载相应的模块，读取 memdisk 中的字体数据（如果不考虑复杂的 OpenGPG 签名加载方式，这是目前安全启动下 GRUB 读取字体的最好办法），之后通过 UUID 搜索包含 GRUB 配置文件的分区，并立刻读取其中的 grub.cfg 内容。因此，你必须将 search.fs_uuid 中的硬盘 UUID 换成包含 GRUB 配置文件的分区的真实 UUID。  

参考一下我的磁盘信息，  
`search.fs_uuid 1B9C-667B root hd0,gpt1`  

我选择这样填写，uuid 是我的 efi 分区，注意这里的 root 并不是指/分区，而是指 boot 分区，gpt1 则是因为 efi 分区的索引为 1  

![b3ade282afba90d071c64eae7e0094b2_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/b3ade282afba90d071c64eae7e0094b2_MD5.png)  



如果之后希望读取更多字体，只需要将相应的 PF2 文件复制到上面创建的 memdisk 中，并在 grub-pre.cfg 中使用 loadfont 命令加载，并重新生成 GRUB EFI 文件，即可正常显示对应字体。  

完成上述操作之后，回到 /etc/secureboot 文件夹，执行 update-sb-grub-efi.sh。不出意外的话你会看到下面两行输出，即代表没有问题：  

```bash
> sudo ./update-sb-grub-efi.sh
Signing /boot/EFI/ARCH/grubx64.efi...
Signing Unsigned original image

```

### 3. 内核签名

新建 /etc/initcpio/post/kernel-sbsign，内容如下，并同时使用 chmod +x 给予可执行权限。  

```bash

#!/usr/bin/env bash
 
kernel="$1"
[[ -n "$kernel" ]] || exit 0
 

# use already installed kernel if it exists
[[ ! -f "$KERNELDESTINATION" ]] || kernel="$KERNELDESTINATION"
 
keypairs=(/etc/secureboot/keys/MOK.key /etc/secureboot/keys/MOK.crt)
 
for (( i=0; i<${#keypairs[@]}; i+=2 )); do
    key="${keypairs[$i]}" cert="${keypairs[(( i + 1 ))]}"
    if ! sbverify --cert "$cert" "$kernel" &>/dev/null; then
        sbsign --key "$key" --cert "$cert" --output "$kernel" "$kernel"
    fi
done

```

之后，立刻使用 pacman 重新安装所有已经安装的内核，不仅可以给内核打上安全启动签名，还可以确认脚本的正确性。如果在重新安装内核时，确认有下面的输出，即算配置正确。  

```bash
==> Initcpio image generation successful
==> Running post hooks
  -> Running post hook: [kernel-sbsign]
Signing Unsigned original image
==> Post processing done

```

### 4.准备重启

在EFI 分区下，放入之前创建的签名密钥的 cer 文件。我将其放入到/boot/EFI/ARCH/keys/MOK.cer  

同时复制 Shim 相关的已签名 EFI，并添加相关的引导项  

```bash

# 复制cer文件
sudo mkdir /boot/EFI/ARCH/keys
sudo cp /etc/secureboot/keys/MOK.cer /boot/EFI/ARCH/keys
 

# 或使用mokutil进行签名导入
mokutil --import /etc/secureboot/keys/MOK.cer
 

# 复制mmx64.efi和shimx64.efi
sudo cp /usr/share/shim-signed/mmx64.efi /boot/EFI/ARCH/
sudo cp /usr/share/shim-signed/shimx64.efi //boot/EFI/ARCH/
 

# 添加Shim引导选项

# /dev/nvme0n1记得改为你的EFI分区所在硬盘对应的block文件

# --part后面的1记得改成EFI分区所在分区的位置(以1开始)
sudo efibootmgr --unicode --disk /dev/nvme0n1 --part 1 --create --label "arch-shim" --loader '\EFI\ARCH\shimx64.efi'

```

一切完成之后，重启，进入 UEFI 配置选项，打开安全启动，并经由 arch-shim 启动项启动 GRUB。  

在这个界面，找到并选中我们复制的 MOK.cer，并导入到 Machine Owner Key 列表中，重新启动，配置即可完成。  

![3336fc2cde1b2d0b9e23a4ecf5bb1b30_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/3336fc2cde1b2d0b9e23a4ecf5bb1b30_MD5.png)  

### 5. 自动更新 GRUB 的 EFI 文件和配置数据

首先，准备一下 update-grub 脚本。可以通过 AUR 包的形式安装（包名为 update-grub），也可以在 /usr/local/bin 下新建一个。文件的内容可以参考[这里](https://aur.archlinux.org/cgit/aur.git/tree/update-grub?h=update-grub)  
`yay -S update-grub`  

在 /etc/pacman.d/hooks 文件夹下（没有则新建），新建两个文件（pacman hooks）。  
/etc/pacman.d/hooks/1-update-grub-efi.hook，用于实时更新 GRUB EFI 文件  

```bash
[Trigger]
Operation=Install
Operation=Upgrade
Type=Package
Target=grub
 
[Action]
Description=Update GRUB UEFI binaries
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c '/etc/secureboot/update-sb-grub-efi.sh'

```

/etc/pacman.d/hooks/999-update-grub-cfg.hook，用于在适时的时候重新生成 /boot/grub/grub.cfg  

```bash
[Trigger]
Operation=Install
Operation=Upgrade
Operation=Remove
Type=Package
Target=grub
Target=linux
Target=linux-lts
Target=linux-zen
Target=linux-hardened
 
[Action]
Description=Update GRUB configuration file
When=PostTransaction
NeedsTargets
Exec=/bin/sh -c '/usr/bin/update-grub'
Depends=grub

```

重新安装 GRUB，看看是否有执行 pacman hook，如果成功执行则配置成功。  
注意看 1/5 和 3/5,钩子执行成功了  
![e958a4e711bd12a528ab5a5ce2093e19_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/e958a4e711bd12a528ab5a5ce2093e19_MD5.png)  



# KVM/QEMU虚拟机

1.安装qemu，图形界面， TPM，网络组件  
`sudo pacman -S qemu-full virt-manager swtpm dnsmasq`  

2.开启libvirtd系统服务  
`sudo systemctl enable --now libvirtd`  
我感觉没必要弄开机自启，我用这个频率并不高，不用的时候，这玩意的进程会阻挠系统快速关机  

3.开启NAT default网络  

```

sudo virsh net-start default
sudo virsh net-autostart default

```

4.添加组权限 需要登出  
`sudo usermod -a -G libvirt $(whoami)`  

5.可选：如果运行出现异常的话编辑配置文件提高权限  

```

sudo vim /etc/libvirt/qemu.conf
把user = "libvirt-qemu"改为user = "用户名"
把group = "libvirt-qemu"改为group = "libvirt"
取消这两行的注释
sudo systemctl restart libvirtd

```

有一个注意点，virtmanager默认的连接是系统范围的，如果需要用户范围的话需要左上角新增一个用户会话连接。  

## 嵌套虚拟化

临时生效  
`modprobe kvm_amd nested=1`  

永久生效  

```

sudo vim /etc/modprobe.d/kvm_amd.conf
写入
options kvm_amd nested=1

```

重新生成initramfs  
`sudo mkinitcpio -P`  

## KVM显卡直通

前置的win11虚拟机安装，virtio-win驱动安装不再赘述  
virtio-win驱动下载链接参考  
https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.285-1/virtio-win-0.1.285.iso  

1.确认iommu是否开启，有输出说明开启  
`sudo dmesg | grep -e DMAR -e IOMMU`  
现代设备通常都支持IOMMU且默认开启，BIOS里的选项通常为Intel VT-d、AMD-V或者IOMMU。如果没有的话搜索一下自己的cpu和主板型号看看是否支持。  
![0213e11d14c3c5017942db2882b877b0_MD5.jpg](_resources/linux%E7%AC%94%E8%AE%B0/0213e11d14c3c5017942db2882b877b0_MD5.jpg)  



2.获取显卡的硬件id，显卡所在group的所有设备的id都记下  

```

for d in /sys/kernel/iommu_groups/*/devices/*; do 
    n=${d#*/iommu_groups/*}; n=${n%%/*}
    printf 'IOMMU Group %s ' "$n"
    lspci -nns "${d##*/}"
done

```

这里获得了我的显卡所在组和对应id  
[[41c68fa8ab9ceef4adba6aa125d824f5_MD5.jpg|Open: Pasted image 20251213134113.png]]  
![41c68fa8ab9ceef4adba6aa125d824f5_MD5.jpg](_resources/linux%E7%AC%94%E8%AE%B0/41c68fa8ab9ceef4adba6aa125d824f5_MD5.jpg)  

3.隔离GPU  
`echo 'options vfio-pci ids=10de:28e0,10de:22be' | sudo tee /etc/modprobe.d/vfio.conf`  

4.编辑内核参数让vfio-pci抢先加载  
sudo vim /etc/mkinitcpio.conf  
MODULES=（）`里面写入`vfio_pci vfio vfio_iommu_type1  
`MODULES=(... vfio_pci vfio vfio_iommu_type1  ...)`  

另外还要确认HOOKS=()里面有modconf  
`HOOKS=(... modconf ...)`  

5.重新生成initramfs  
`sudo mkinitcpio -P`  

6.安装和配置ovmf  
`sudo pacman -S --needed edk2-ovmf`  
编辑配置文件  
`sudo vim /etc/libvirt/qemu.conf`  
搜索nvram，在合适的地方写入：  

```

nvram = [
"/usr/share/ovmf/x64/OVMF_CODE.fd:/usr/share/ovmf/x64/OVMF_VARS.fd"
]

```

7.重启电脑  
记得把显示器查到核显输出的口上。我的华硕天选4貌似有dp和hdmi两个独显插口  


8.添加显卡到虚拟机  
这里重启后可以看到N卡已经被独立出去了，在win11虚拟机配置中，添加pci硬件设备，选择被独立出的4060  
![62676cbb4a42c76b7f395b46c97e51ad_MD5.jpg](_resources/linux%E7%AC%94%E8%AE%B0/62676cbb4a42c76b7f395b46c97e51ad_MD5.jpg)  

开机后装上n卡驱动，在设备管理器上可以看到n卡成功安装使用了  
![099e5e3183ec6f56a47ff67d14f8f207_MD5.jpg](_resources/linux%E7%AC%94%E8%AE%B0/099e5e3183ec6f56a47ff67d14f8f207_MD5.jpg)  

### moonlight远程连接方案(不建议使用)

删除虚拟机的硬件的显示协议和QXL的显卡，然后添加鼠标和键盘，键盘随便拿了个外接键盘，鼠标就用我现在的雷柏，直通开机后，我直通进去的鼠标键盘就会被虚拟机独占了，所以我的笔记本可以使用自带键盘和触摸板  
![a5b461818005e59b7a9bd18f0bbef7cc_MD5.jpg](_resources/linux%E7%AC%94%E8%AE%B0/a5b461818005e59b7a9bd18f0bbef7cc_MD5.jpg)  

开机后显示输出会出现在外接显示器中，之后会尝试hdmi欺骗器，因为这个显示器分辨率不行，但是hdmi欺骗器还没送到，所以现在还是先用外接屏吧  

开机进入系统基础设置界面，按下shfit F10打开cmd，输入oobe\bypasssnro来跳过微软账号登录  
然后安装两个东西，sunshine和virtual display driver，这两个都是github上的项目，一个远程桌面一个虚拟桌面，按照官方文档配置就行了，sunshine打开后会进入一个网页开始基础配置然后可以在这个网页管理连接，然后linux端下载moonlight，这是远程桌面sunshine的客户端，打开后一般它会自动检测到kvm的虚拟桌面，  
然后右上角设置里调整分辨率，刷新率，码率，码率我设置的50,这个看个人网速吧，重点是并不是设置得高越好，码率这种东西，越高越接近设定的原生画质，但它会受到网络波动的影响，比如网速是90mbps，但这个90是平均值，如果我把码率也设置成90的话，如果网络突然波动到低于90mbps，就可能会有数据的丢包和传输速度的降低，从而导致串流的画面出现画面撕裂和掉帧的现象，所以这里我设定为50,属于是为了帧率牺牲了一些画面分辨率  

然后连接虚拟桌面，会提示让你虚拟机登录那个网页打开pin码设置进行连接，密码就是moonlight提供的pin码，设备名随便设置，先把虚拟桌面设置为主桌面，因为moonlight默认连接的是主桌面。然后连接成功就能进入桌面了，连接后虚拟桌面放着不管，它会自动下线的，如果出现这种情况其实挺难搞的，貌似是和windows的电源管理策略相关，所以我不想用这个了，退出桌面的快捷键是ctrl alt shift q，全屏/窗口 化切换的快捷键是ctrl alt shift x  
到了这里，就不需要给虚拟机接入设备了，因为操作都是通过串流画面交互的，我把接入的鼠标键盘设备都移除了。  

### looking glass画面串流方案

这个我觉得比日月组合(sunshine+moonlight)好用多了，不吃网速，虽然同样有虚拟桌面长时间不动后自动掉线的问题，但looking glass能拉回来，而且还支持无头模式（这个我不确定moonlight是否同样支持），也就是说我不需要买hdmi欺骗器了  

#### 写在前面的简略理论基础

1.关于 /dev/shm(Linux 的共享内存机制)  
在 Linux 系统中，为了满足不同程序之间高速交换数据的需求，同时避免频繁读写硬盘造成瓶颈，Linux 设计了一个特殊的机制—— `/dev/shm` 目录。  

**虚拟挂载，而非物理分割**：  
`/dev/shm` 挂载的 `tmpfs` 文件系统，并不像硬盘分区那样物理占用了内存的一半。它仅仅是向操作系统申请了一个 **“最高可用 50% 内存的记账额度”**。  

**动态分配机制**：  
在 Looking Glass 没运行（或没写入文件）时，`/dev/shm` 占用的物理内存实际上是 **0**。这部分内存完全开放给系统其他软件使用。只有当文件真正写入时，内核才会从物理内存池中动态抓取空闲的内存页来存储数据。  

**设备本质**：  
`/dev/shm` 虽位于设备目录 `/dev` 下，但它不是物理设备文件，而是一个**内存对象**的接口。它让用户能像操作普通磁盘文件一样（打开、读写、关闭），直接操作分散在 RAM 中的内存页。  
**本质**：它的挂载点虽然像个磁盘目录，但其文件系统格式为 `tmpfs`，背后的物理存储介质完全是 **内存 (RAM)**。  
**约束**：为了防止临时文件无限制地占满物理内存导致死机，Linux 默认将此目录的大小限制为物理总内存的 **50%**。这是一种**安全限额**——用多少占多少，但绝不允许超过这个上限（一旦超过会直接报错，不会溢出到其他区域）。  
**特性**：由于内存断电即失的物理特性，这个目录下的文件在重启后会自动消失，非常适合存放无需永久保存的临时数据。  

2.Systemd 临时文件管理 (systemd-tmpfiles)  
Linux 系统中专门用于在开机时**自动创建、恢复或清理**那些“断电即失”（易失性）文件的标准化管理机制。  

通过在/etc/tmpfiles.d/下书写配置文件（`.conf`）声明“我需要什么文件、什么权限”，系统开机时会自动帮你把这些文件“变”出来，无需人工干预或编写复杂脚本。  

主要针对内存挂载目录（如 `/dev/shm`、`/run`、`/tmp`）下的文件。这些文件在重启后会消失，但应用程序（如 Looking Glass）启动时又必须依赖它们。  




3.Looking Glass 的工作原理  
实际上还要更复杂一些，涉及到内存映射等一系列技术，我这里只谈我作为使用者能直接接触到的  

Looking Glass 利用了上述机制来实现“零延迟”的画面传输：  
**共享白板**：Looking Glass 在 `/dev/shm` 下创建了一个文件（也就是划定了一块内存区域）。这块区域成为了虚拟机（Host）和宿主机（Client）的**公共白板**。  
**流程**：  
1. 虚拟机内的显卡渲染好画面后，通过 IVSHMEM 驱动直接把画面数据“写”进这块内存。  
2. 宿主机的 Looking Glass 客户端直接从这块内存里“读”取数据并显示。  

**为什么用 `/dev/shm`**：  
**极速**：读写内存的速度远超硬盘。  
**共享**：它是极少数能让两个隔离的系统（Linux 和 Windows VM）同时访问的“虫洞”。  
**自动清理**：配合 `systemd-tmpfiles` 和 `tmpfs` 的特性，保证了每次重启后环境的干净，不会留下垃圾文件。  



win虚拟机内需要安装虚拟显示器：[Virtual-Display-Driver](https://github.com/VirtualDrivers/Virtual-Display-Driver)  

#### 开始实施

1.计算需要的共享内存大小, 具体可以看官方档案，我是2560x1440@165hz 非HDR，需要大小是64M  
2.设置共享内存设备 打开virt-manager，点击编辑 > 首选项，勾选启用xml编辑。 打开虚拟机配置，找到xml底部的 `</devices>`，在 `</devices>`的上面添加设备，size记得该成自己需要的，参考如下内容写入适当的位置：  

```

<devices>
    ...
  <shmem name='looking-glass'>
    <model type='ivshmem-plain'/>
    <size unit='M'>64</size> 
  </shmem>
</devices>

```

3.在终端中加入桌面用户到kvm组  
`sudo gpasswd -a $USER kvm`  
重启电脑后使用groups命令确认自己在kvm组里  

4.设置共享内存设备对应的文件的规则  
`sudo vim /etc/tmpfiles.d/10-looking-glass.conf`  
写入如下内容  
`f /dev/shm/looking-glass 0660 caster kvm -`  
`f` 代表定文件规则 `/dev/shm/looking-glass`是共享内存文件的路径 `0660` 设置所有者和所属组的读写权限 `caster` 设置所有者 `kvm` 设置所属组  

这个conf文件它定义了一个每次开机就仅执行一次的服务，生成的/dev/shm/looking-glass文件，就是这个划分的内存的入口  

本来是每次开机触发一次，但可以立刻手动创建这个文件  
`sudo systemd-tmpfiles --create /etc/tmpfiles.d/10-looking-glass.conf`  

4.回到虚拟机设置  
设置spice协议  
确认有spice显示协议，显卡设置为none  

键鼠传输  
添加virtio键盘和virtio鼠标（要在xml里面更改bus=“ps2”为bus=“virtio”）加上这个，外部鼠标键盘才能映射到虚拟机的串流画面上  

剪贴板同步（可选）  
确认有spice信道设备，没有的话添加，设备类型为spice  

声音传输  
确认有ich9声卡，点击概况，去到xml底部，在里面找到下面这段，确认type为spice，不是的话自己手动改  
`<audio id='1' type='spice'/>`  
配置结束大概是这样  
![52a72e57902a24011dcd312b0bdf4e83_MD5.jpg](_resources/linux%E7%AC%94%E8%AE%B0/52a72e57902a24011dcd312b0bdf4e83_MD5.jpg)  


5.开启虚拟机，安装looking glass 服务端  
浏览器搜索 looking glass，点击download，下载bleeding-edge的windows host binary，解压后双击exe安装  

6.linux安装客户端  
服务端和客户端的版本要匹配，bleeding-edge对应git包  
`yay -S looking-glass-git`  

桌面快捷方式打开lookingglass即可连接  

win11老是没事更新，对虚拟机会有很大问题，关闭了自动更新还不保险，同时也为了预防其他问题，我这里设置了一个虚拟机克隆用于日常使用  

写了个脚本用于切换显卡归属，没有内存大页的设置，因为我觉得我目前还没这个需求，谁知道呢，说不定过几天就搞内存大页，然后就要重新写这个脚本  

```

❯ cat /usr/local/bin/switch-gpu-owner 

#!/bin/bash

# 配置
VFIO_IDS="10de:28e0,10de:22be"
MKINIT="/etc/mkinitcpio.conf"
VFIO_CONF="/etc/modprobe.d/vfio.conf"

# 颜色
R=$(tput sgr0)
B=$(tput bold)
BLUE=$(tput setaf 4)
GREEN=$(tput setaf 2)
GRAY=$(tput setaf 8)
PURPLE=$(tput setaf 5)
RED=$(tput setaf 1)
CYAN=$(tput setaf 6)

I_NV="🐧"
I_VF="⚙️"

[ "$EUID" -ne 0 ] && printf "${RED}错误: 请使用 sudo${R}\n" && exit 1

clear

printf "${BLUE}╭────────────────────────────────╮${R}\n"
printf "${BLUE}│${R}          ${B}独显归属切换${R}          ${BLUE}│${R}\n"
printf "${BLUE}╰────────────────────────────────╯${R}\n\n"

if grep -q "vfio_pci" "$MKINIT"; then
    TARGET="HOST"
    printf "${GRAY}╭── 当前状态 ────────────────────╮${R}\n"
    printf "${GRAY}│  ${I_VF}  显卡直通                  │${R}\n" 
    printf "${GRAY}╰────────────────────────────────╯${R}\n"
    printf "                ${B}⬇️${R}\n"
    printf "${GREEN}╭── 即将切换 ────────────────────╮${R}\n"
    printf "${GREEN}│  ${I_NV}  linux主机使用             │${R}\n"
    printf "${GREEN}╰────────────────────────────────╯${R}\n"
else
    TARGET="VM"
    printf "${GRAY}╭── 当前状态 ────────────────────╮${R}\n"
    printf "${GRAY}│  ${I_NV}  linux主机使用             │${R}\n"
    printf "${GRAY}╰────────────────────────────────╯${R}\n"
    printf "                ${B}⬇️${R}\n"
    printf "${PURPLE}╭── 即将切换 ────────────────────╮${R}\n"
    printf "${PURPLE}│  ${I_VF}  显卡直通                  │${R}\n"
    printf "${PURPLE}╰────────────────────────────────╯${R}\n"
fi

printf "\n${B}确认切换? [y/N]: ${R}"
read CONFIRM
[[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]] && printf "\n${GRAY}取消。${R}\n" && exit 0

printf "\n${GRAY}────────────────────────────────${R}\n"
printf "${BLUE}正在修改配置...${R}\n"

if [ "$TARGET" == "HOST" ]; then
    truncate -s 0 "$VFIO_CONF"
    printf " ${GREEN}✔${R} 清空 ${CYAN}%s${R}\n" "$VFIO_CONF"
    
    sed -i 's/^MODULES=(.*)/MODULES=(amdgpu)/' "$MKINIT"
    printf " ${GREEN}✔${R} 修改 ${CYAN}%s${R}: MODULES=(amdgpu)\n" "$MKINIT"
else
    echo "options vfio-pci ids=$VFIO_IDS" > "$VFIO_CONF"
    echo "softdep nvidia pre: vfio-pci" >> "$VFIO_CONF"
    echo "softdep nouveau pre: vfio-pci" >> "$VFIO_CONF"
    printf " ${GREEN}✔${R} 写入 ${CYAN}%s${R}: 绑定 ID $VFIO_IDS\n" "$VFIO_CONF"
    
    sed -i 's/^MODULES=(.*)/MODULES=(vfio_pci vfio vfio_iommu_type1 amdgpu)/' "$MKINIT"
    printf " ${GREEN}✔${R} 修改 ${CYAN}%s${R}: MODULES=(vfio...)\n" "$MKINIT"
fi

printf "\n${BLUE}重建内核 (mkinitcpio)...${R}\n${GRAY}"

mkinitcpio -P
if [ $? -eq 0 ]; then
    printf "${R}\n${B}${GREEN}✅ 完成。${R} 请重启。\n"
    read -p "立即重启? [y/N]: " RB
    [[ "$RB" == "y" || "$RB" == "Y" ]] && reboot
else
    printf "${R}\n${RED}❌ 失败！请检查日志。${R}\n"
    exit 1
fi

```

## KVM虚拟机性能优化和伪装

从这里开始的配置就在克隆系统中进行  

### 禁用memballoon

[libvirt/QEMU Installation — Looking Glass B7 documentation](https://looking-glass.io/docs/B7/install_libvirt/#memballoon)  

memlbaloon的目的是提高内存的利用率，但是由于它会不停地“取走”和“归还”虚拟机内存，导致显卡 直通时虚拟机内存性能极差。  

将虚拟机xml里面的memballoon改为none，这将显著提高low帧。  

```

<memballoon model="none"/>

```

### 虚拟机镜像优化

原因是虚拟机的特性与btrfs的写时复制(COW)机制有一定冲突，在虚拟机内部，windows在qcow2镜像内部进行微小的块写入，但是每当qcow2文件发生修改，就会触发btrfs的COW，btrfs就会在物理硬盘上找个新位置重新写入该块，后果就是，一个原本逻辑上连续的100GB镜像文件，在物理上被拆成了几十万个不连续的碎片，碎片数量可以通过`sudo filefrag -v win11.qcow2`命令查看，这个问题会导致严重的性能损耗，  
**寻址压力**：内核必须维护几十万条映射记录。读取文件时，CPU 需要频繁查询 B-Tree 索引，造成系统负载波动  
**IO 随机化**：原本是顺序读取的操作，被强制变成了海量的随机读取，极大限制了 SSD 的吞吐能力。  

一般来说，只要使用chattr +C 命令给qcow2文件设置禁止写时复制就行了，但要在虚拟机刚开始用的时候设置，如果已经用了一段时间，则需要强制物理重写（数据搬家）  

1.由于 `chattr +C`（NOCOW 属性）只对新文件生效，我们必须采用“先设目录，后创文件”的策略。  
赋予存放镜像的目录 NOCOW 属性，让其下的新文件自动继承  
`sudo chattr +C /var/lib/libvirt/images`  

2.强制物理重写（数据搬家）  
`cd /var/lib/libvirt/images`  
创建一个标记为 +C 的空文件  
`sudo touch win11-fixed.qcow2`  
`sudo chattr +C win11-fixed.qcow2`  
强制物理拷贝，禁用 reflink (克隆)，--sparse=always 保证镜像文件中的空洞不被填满，节省物理空间  
`sudo cp --reflink=never --sparse=always win11-original.qcow2 win11-fixed.qcow2`  

3.深度整理（最后压实）  
即使重写后，受限于磁盘剩余空间的碎片化，可能仍有残余碎片。使用 Btrfs 专用的整理工具进行最后修复。  
告诉内核寻找至少 32MB 连续空间的“大地盘”进行整理  
`sudo btrfs filesystem defragment -v -t 32M win11-fixed.qcow2`  
然后把新创建的qocw2改名为旧的取代即可  

### 共享存储

首先确认启用了内存共享(Virtio-FS 强依赖共享内存)  
添加文件系统类型的硬件  
![3c515fd8863a183782d1c8f03217cd43_MD5.jpg](_resources/linux%E7%AC%94%E8%AE%B0/3c515fd8863a183782d1c8f03217cd43_MD5.jpg)  
就是这样，然后进入虚拟机内部，安装winfsp驱动，在github的项目地址下面找，后缀名msi，安装成功后，打开windows的服务管理，启动Virtio-FS Service服务，默认是手动启动的，但也可以设置自动启动，不过感觉有点小风险？启动成功后可以找到一个独立的盘，盘名就是设置的目标路径  
