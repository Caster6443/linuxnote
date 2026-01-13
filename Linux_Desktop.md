# 混合显卡黑屏问题
具体表现在开机时，有几率在启动加载全部完成后会黑屏卡住，原因显示管理器有概率会提前在显卡驱动加载前启动

这个有两种解决方案
一个是在mkinit 中配置 A 卡优先加载
![[_resources/linux笔记/3d4acfcc17d6def5939c834ae1bd67cb_MD5.png]]
就是在 MODULES 里指定加载顺序即可，当然还需要sudo mkinitcpio -P重新加载一下配置

另一个方案是把登录管理器的自启动服务添加一个 sleep 2延迟2秒启动







# wine 字体缺失
具体表现是某些字符会显示为“口”字的状态，通常是字体缺失导致的
使用 Winetricks 自动安装字体
winetricks是一个辅助脚本，专门用来给 Wine 安装各种依赖库和字体。

安装 Winetricks

```plain
sudo pacman -S winetricks
```

使用 Winetricks 安装 CJK 字体包：
winetricks有一个专门的包叫 cjkfonts，它会自动下载并安装 Windows 上最常用的中日韩字体（包括 msgothic,msmincho等）到你的 Wine 环境中。
继续在终端运行：

```plain
winetricks cjkfonts
```

  
后续调优（可选）  
安装 Arch Linux 系统的 CJK 字体
这个方案是在_Linux 系统层面_安装一套完整的高质量 CJK 字体。Wine (通过 Fontconfig) 理论上也能检测到并使用它们。
安装 Noto CJK 字体包： `noto-fonts-cjk` 是 Google 和 Adobe 合作的开源字体，质量非常高，涵盖了中日韩所有字符。
在终端运行：
```plain
sudo pacman -S noto-fonts-cjk
```

刷新字体缓存（通常 pacman 会自动做，但手动做一次没坏处）：
```plain
fc-cache -fv
```

```
sudo pacman -S adobe-source-han-serif-cn-fonts wqy-zenhei          #安装几个开源中文字体 一般装上文泉驿就能解决大多wine应用中文方块的问题
sudo pacman -S noto-fonts-cjk noto-fonts-emoji noto-fonts-extra    #安装谷歌开源字体及表情
```

我感觉没球用，不如群友打包的字体包，直接塞上就用



# arch 配置 FTP 服务
给我的 kvm_win7 传文件用

安装软件
sudo pacman -S python-pyftpdlib

然后在需要共享的文件目录下运行
python -m pyftpdlib
具体端口号和进程等信息会自动显示












# Waydroid
## 11/4
## Waydroid 初始配置
安装 waydroid 并初始化
sudo pacman -S waydroid
sudo waydroid init
//如果需要使用谷歌服务，可以指定带有谷歌服务的镜像
sudo waydroid init -s GAPPS


原生 Waydroid 是 x86 架构的，想使用 arm 架构应用比如安装运行 apk 需要安装翻译层
安装waydroid-script
yay -S waydroid-script-git

waydroid-scripts 项目提供了 waydroid-extras 命令来安装翻译层
libhoudini 用于英特尔
libndk       用于 AMD

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

yay -S waydroid-helper

这个应用功能比较齐全了，值得一提的是，在设置按键映射时，会出现一个窗口，然后在窗口里设置映射键位，这里并不是说明上说的，把映射键位放在对应按键上就行，而是根据这个窗口与 waydroid 的缩放比例，放到对应的位置，要使用映射时，需要先鼠标聚焦到映射的窗口

类似这样，我映射了游戏的方向键，因为这个 b 游戏的方向键只支持滑动操作，可以看到，我的方向键在窗口中的位置是等比例缩小游戏窗口和方向键的对应位置，我需要使用映射时必须把鼠标聚焦到左下角的映射窗口

![[_resources/linux笔记/a7e2f3ce98025b7463ef958137883955_MD5.png]]



这个助手还提供其他功能，比如伪装成指定机型，获取设备 id，之类的常见需求









