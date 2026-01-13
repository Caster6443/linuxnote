
# linux基础知识

## ldd命令

不同的文件执行起来有不同的函数库依赖，这些函数库通常保存在lib64目录下，可使用ldd命令查看相关的依赖

例：![[_resources/linux笔记/944a6e02d4ce24ebf02f5b2f3ca1e114_MD5.png]]

想要使用bash则需要确保拥有lib下的各个函数库文件

没有依赖库但想要使用bash则会报错如下

![[_resources/linux笔记/87727257087262a186f7eebb6995744f_MD5.png]]


## sed命令

-i参数：

sed命令对文件内容的增删改查都是在内存空间中进行的，并不直接影响到文件内容，若想实现对文件内容的直接修改需要加上-i参数

-n参数：

由于sed命令的默认机制，即使某行文本未被匹配，也会被打印到终端上，因此在不想显示不匹配文本内容时，需要-n参数来取消sed命令的默认输出





## awk命令

awk常见的内建变量：

FS：列分割符。指定每行文本的字段分隔符，默认为空格或制表位。与"-F"作用相同

NF：当前处理的行的字段个数。

NR：当前处理的行的行号（序数）。

$0：当前处理的行的整行内容。

$n：当前处理行的第n个字段（第n列）。

FILENAME：被处理的文件名。

RS：行分隔符。awk从文件上读取资料时,将根据RS的定义把读取的资料切割成许多条记录,而awk一次仅读入一条记录,以进行处理。预设值是’\n’

在使用awk命令的过程中,可以使用逻辑操作符“&&”表示“与”、“||”表示“或”、“!”表示“非”；还可以进行简单的数学运算，如+、-、*、/、%、^分别表示加、减、乘、除、取余和乘方

[root@master ~]# awk '(NR%2)=0 {print}' test.txt 打印所有偶数行

第二行

第四行

也可以使用正则表达式

![[_resources/linux笔记/01d58b0c95d05afd4079b03dd508cc4e_MD5.png]]

其他的内建变量的使用示例

![[_resources/linux笔记/77fd632d9cffa87c49ac40ffdbb3825a_MD5.png]]

该命令用于统计以字符 ‘行’ 结尾的行数量

在这里将x初始化后统计以字符 ‘行’结尾的行，检测到目标字符后使x自增，最后打印x的值

注意：BEGIN模式表示，在处理指定的文本之前，需要先执行BEGIN模式中指定的动作；awk再处理指定的文本，之后再执行END模式中指定的动作，END{}语句块中，往往会放入打印结果等语句

等同于 grep -c "/bin/bash$" /etc/passwd

-F参数的使用

![[_resources/linux笔记/13d1232062bae2b5368670376d4444ee_MD5.png]]

该命令筛选出了该文件的所有行的第一列，而区分列的规范由” ”里的内容指定，在这里是以:起作分隔不同行的作用,{}里面可以指定一行的多个列，用 , 分隔开

当字段为数字时，也可以用数学运算符起到筛选的作用

例如/etc/passwork在以:作为分隔符时，第三个字段是数字，这里就可以做筛选

![[_resources/linux笔记/f10da89e0b07e0eda8c4d28b216cd874_MD5.png]]

在这里筛选出了第三个字段小于10的字符串（给$3<10打个括号更美观一些）

awk -F ":" '!($3<200){print}' /etc/passwd #输出第3个字段的值不小于200的行

/////////////////////////////////////////////////////////////////////////////////

![[_resources/linux笔记/980aab50b5441793b7c27a3d46a2ea57_MD5.png]]

报错原因：这个镜像是坏的

斗学网容器云赛卷实验的chinaskills_cloud_iaas.iso文件是坏的，从服务器的linux主机上拷贝了一个正常镜像给云主机,但该镜像缺少kubeeasy的可执行命令文件

![[_resources/linux笔记/2db0fb5f00d481e8383307df88bbd46f_MD5.png]]





## find命令
-name
指定名字，精确查询，也可以使用通配符和正则进行模糊查询

和-i一起使用组成-iname可忽略大小写

 -type
指定搜索的文件类型，普通文件f,目录文件d,软连接l


 -perm
根据权限搜索(数字表示法)

查找特殊权限时，例如sgid权限，可以通过-perm -2000查找

也可以通过字符表示-perm -g+s


 -user
根据文件所有者搜索


-group
根据文件的组所有者搜索


-size
根据文件大小查找

+xxM  查找大于xxM的文件

-xxM   查找小于xx


-mtime
根据修改时间查找文件

+7表示  找出7天之前的文件(修改时间是7天之前)

-7表示  最近7天内的文件


找出/etc/目录下以.conf结尾的，7天之前的文件

find /etc/ -type f -name "*.conf" -mtime +7


 -exec
表示find找出文件后要执行的命令

find /oldboy/find/ -type f -name '*.txt' -exec ls -lh {} \;

{} 表示前面find命令找出的文件,作占位符使用

\;是该选项的固定格式,表示命令结束



## chattr 命令
写这个是因为有个 b 把我搭的网站给黑了，还给他的 ssh 密钥设置了 chattr 属性留了后门，这种东西，普通云服务的查杀功能是不起作用的，只能是自己找然后去除属性后删除，不过也怪我图方便，懒得登录网站进控制台，想直接打开终端 ssh 上去，所以公网开放了 22 端口

Linux chattr 命令用于改变文件或目录的属性，这些属性可以控制文件系统的行为，提供更高级的文件管理功能。

语法: chattr [选项] [+/-/=属性] 文件或目录

常用选项
-R: 递归处理目录及其子目录
-V: 显示详细信息
-v: 显示版本信息

属性模式
+: 添加属性
-: 移除属性
= : 设置为指定属性

```
常用属性
a     仅追加：文件只能追加内容，不能删除或修改已有内容（需 root 权限）。
i     不可变：文件不能被删除、修改、重命名或创建硬链接（需 root 权限）。
A     不更新文件的最后访问时间（atime）。
c     文件在磁盘上自动压缩（部分文件系统支持）。
s     安全删除：文件被删除时，其数据会被清零（不可恢复）。
u     文件被删除后，其内容仍可恢复（与 s 相反）。
d     文件在 dump 备份时会被跳过。
```



## tee命令
在处理输入输出流时功能类似T型管

一方面它会通过标准输入读取

另一方面它会将标准输入重定向到指定文件(默认是覆盖重定向，加-a选项是追加重定向)

在这个过程中间，它还会将标准输入输出到标准输出(一般是当前shell)






## tar命令
tar的功能是归档和解归档而不是压缩或解压缩,但可以加参数实现
后缀是.tar
```
-c 创建新包
-v 显示过程
-f 指定待处理文件，该参数要放到最后
-x 提取文件
-z 使用gzip过滤(使用该参数可以通过gzip实现压缩文件的创建和解压缩，格式是gzip,后缀加.gz)
-j, 通过 bzip2 过滤归档(同上,压缩文件格式是bzip2，后缀加.bz2)
-J 通过xz过滤归档(同上,后缀加.xz)
 -C 指定解压位置
```



## yum/rpm命令

yum 解决依赖关系问题，自动下载软件包。yum是基于C/S架构，像ftp，http，file一样；关于yum为什么能解决依赖关系：所有的Yum 源里面都有repodata，它里面是有XML格式文件, 用于储存元数据，记录软件包之间的依赖关系。

yum install --downloadonly --downloaddir=/xx/xxx/xx/
只下载软件但不安装
有时候需要将高版本的依赖降级到低版本，降级命令如下
yum downgrade <package_name> 
降级，对于有依赖的，yum不会自动降级，需要手动降级依赖项


### yum本地安装
`yum -y localinstall`
后面跟rpm安装包名，例：
`yum -y localinstall dir/*.rpm`
指定安装了该文件夹下所有的rpm包


### yum 查找指定命令的所在软件包
以查找 zcat 命令的软件包为例

```bash
[root@localhost ~]# yum provides zcat
上次元数据过期检查：0:12:24 前，执行于 2025年08月07日 星期四 16时09分17秒。
gzip-1.12-1.el9.x86_64 : The GNU data compression program
仓库        ：@System
匹配来源：
文件名    ：/usr/bin/zcat
提供    : /bin/zcat

gzip-1.12-1.el9.x86_64 : The GNU data compression program
仓库        ：baseos
匹配来源：
文件名    ：/usr/bin/zcat
提供    : /bin/zcat
```

### 查看某个服务的所有配置文件路径
以 nginx 为例

```bash
[root@rocky ~]# rpm -qc nginx
/etc/logrotate.d/nginx
/etc/nginx/conf.d/default.conf
/etc/nginx/fastcgi_params
/etc/nginx/mime.types
/etc/nginx/nginx.conf
/etc/nginx/scgi_params
/etc/nginx/uwsgi_params
```

还可以查看所有相关文件（不止配置文件）

```bash
[root@rocky ~]# rpm -ql nginx
/etc/logrotate.d/nginx
/etc/nginx
/etc/nginx/conf.d
/etc/nginx/conf.d/default.conf
/etc/nginx/fastcgi_params
/etc/nginx/mime.types
/etc/nginx/modules
/etc/nginx/nginx.conf
/etc/nginx/scgi_params
/etc/nginx/uwsgi_params
/usr/lib/.build-id
/usr/lib/.build-id/2f
/usr/lib/.build-id/2f/1aebf1c44110efa44f0ddc88a30c3c35bec25c
/usr/lib/.build-id/42
/usr/lib/.build-id/42/201aa568b3c7e88fcc8b2734bcf8ea7899a847
/usr/lib/systemd/system/nginx-debug.service
/usr/lib/systemd/system/nginx.service
/usr/lib64/nginx
/usr/lib64/nginx/modules
/usr/libexec/initscripts/legacy-actions/nginx
/usr/libexec/initscripts/legacy-actions/nginx/check-reload
/usr/libexec/initscripts/legacy-actions/nginx/upgrade
/usr/sbin/nginx
/usr/sbin/nginx-debug
/usr/share/doc/nginx-1.24.0
/usr/share/doc/nginx-1.24.0/COPYRIGHT
/usr/share/man/man8/nginx.8.gz
/usr/share/nginx
/usr/share/nginx/html
/usr/share/nginx/html/50x.html
/usr/share/nginx/html/index.html
/var/cache/nginx
/var/log/nginx
[root@rocky ~]# 
```



### Linux RPM包统一命名规则
 RPM 二进制包命名的一般格式如下： 包名-版本号-发布次数-发行商-Linux平台-适合的硬件平台-包扩展名

有些 rpm 包用于生成软件源，它们的格式一般如下:

1. 后缀关键词：
-release (最常见)
-repo(次常见)
-repository (较少见)
-yum(罕见)

架构标识：
.noarch.rpm(99% 的源配置包都是 noarch 架构)
命名模式：
<软件名>-<功能词>-<系统版本>.noarch.rpm







## alisa命令别名
以docker为例
![[_resources/linux笔记/55b91cf1ca8373b5e6b33246b327e1f7_MD5.png]]




## 正则表达式

.

表示匹配任意的单个字符，可以与 * 搭配为 .* 表示匹配任意的多个任意字符

例如可以用正则表达式 ^.*hhh 来表示以任意的多个任意字符开头且以hhh结尾的字符串

&

用例： /^hhh/@&/ 此处&的作用是指代前文中^后的匹配字符串hhh，这个正则的作用是将以hhh开头的字符串的hhh更改为了@hhh，总之就是&具有指代’匹配字符串’的作用

\

转义字符

&和\的示例(以sed命令示例)

![[_resources/linux笔记/215f862977ebe34f865d059a684c4d22_MD5.png]]




## ipvs

启动ipvs的要求：

k8s版本 >= v1.11

使用ipvs需要安装相应的工具来处理”yum install ipset ipvsadm -y“

确保 ipvs已经加载内核模块， ip_vs、ip_vs_rr、ip_vs_wrr、ip_vs_sh、

nf_conntrack_ipv4。如果这些内核模块不加载，当kube-proxy启动后，会退回到iptables模式。

yum -y install epel-release






## 命令替换

用来重组命令行，先完成引号里的命令行，然后将其结果替换出来，再重组成新的命令行

shell中命令替换符有两种 与 $()

反单引号适用于任何类unix平台，他的适用性比较高。$符号却不是。





## linux常用的系统环境变量

PATH：决定了系统在哪些目录中查找可执行文件。当你输入一个命令时，系统会在PATH中定义的目录中查找该命令的可执行文件。

HOME：指定当前用户的主目录路径。

USER：当前用户的用户名。

SHELL：指定当前用户默认使用的shell。

LANG：指定系统的默认语言。

LD_LIBRARY_PATH：指定系统在哪些目录中查找共享库文件。

TERM：指定当前终端的类型。

PS1：定义命令行提示符的格式。

PS2：定义多行命令的提示符的格式。

使用env命令显示当前用户的所有环境变量

使用set命令查看所有本地定义的环境变量

进程树pstree命令的安装包是psmisc


## 关于echo $PATH的回显释义

![[_resources/linux笔记/91238653c6e8e6603e279c474409f9ab_MD5.png]]


## 关于逻辑卷调整的-r参数

-r 参数确保在扩展或收缩逻辑卷时，其上的文件系统也会自动调整大小以匹配新的空间。避免了手动操作文件系统的步骤和风险。

操作类型对比：

扩展逻辑卷： 无 -r 参数：只扩展LV空间，需手动运行 resize2fs 有 -r 参数：自动扩展LV空间+文件系统一步完成

收缩逻辑卷： 无 -r 参数：需先手动收缩文件系统，再收缩LV 有 -r 参数：自动先收缩文件系统，再收缩LV空间

文件系统必须支持在线调整：

- 支持：ext2/3/4, XFS（仅扩展）, Btrfs
    
- 不支持：NTFS, FAT32 等
    
- XFS 文件系统只能扩展不能收缩
    

常见不支持 -r 选项的文件系统：

NTFS： 扩容支持：在线/离线 收缩支持：离线 工具：ntfsresize

FAT32/VFAT： 扩容支持：离线 收缩支持：离线 工具：fatresize

ReiserFS： 扩容支持：离线 收缩支持：复杂且风险高 工具：resize_reiserfs

ZFS： 扩容支持：在线 收缩支持：在线 工具：zfs set

APFS： 扩容支持：在线 收缩支持：在线 工具：macOS 磁盘工具

加密LUKS： 扩容支持：需先调整加密层 收缩支持：高风险 工具：cryptsetup + fs工具

扩容不支持-r选项的文件系统的逻辑卷

1. 扩展逻辑卷 (扩展10G)
    

sudo lvextend -L +10G /dev/vg01/lv_data

2. 手动扩展文件系统
    

如果是 NTFS (需安装 ntfs-3g)： sudo ntfsresize /dev/vg01/lv_data # 离线操作需要卸载

如果是 FAT32： sudo fatresize -s +10G /dev/vg01/lv_data

如果是 ReiserFS： sudo resize_reiserfs /dev/vg01/lv_data

如果是加密卷 (LUKS)： sudo cryptsetup resize crypt_data # 先调整加密层 sudo ntfsresize /dev/mapper/crypt_data

缩容不支持-r选项的文件系统的逻辑卷(风险极高不建议使用)

1. 卸载文件系统
    

sudo umount /mnt/data

2. 检查文件系统 (以NTFS为例)
    

sudo ntfsfix /dev/vg01/lv_data

3. 收缩文件系统 (目标缩小到15G)
    

sudo ntfsresize -s 15G /dev/vg01/lv_data

4. 收缩逻辑卷 (必须精确匹配文件系统新大小)
    

sudo lvreduce -L 15G /dev/vg01/lv_data

5. 重新挂载
    

sudo mount /dev/vg01/lv_data /mnt/data

podman卷映射-v选项的z标签大小写区别

作用都是让selinux放通，但作用不同

小写z标签

表示共享挂载卷，共享宿主机的挂载卷，这样其它容器也能挂载并访问该挂载卷

大写Z标签

表示私有标签，使用该标签后，其它容器就不能通过挂载卷访问该宿主机目录，但这个标签会被覆盖，例如先后有两个容器都对一个宿主机目录做了挂载卷映射，都使用了私有标签Z,生效的是最后打标签的容器，第一个容器失去了通过挂载卷访问该目录的权限

如下

[root@server ~]# podman run -itd -v /podman-mapper-dir1:/dir1:Z --name first_centos centos:latest e48892657919c025d6004d237bd78ceb14bb0f7b540d1ba8b54ed9aa9cbbaecf 
[root@server ~]# podman run -itd -v /podman-mapper-dir1:/dir2:Z --name Second_centos centos:latest 03095b52384fc28a0073d9d3028d0378d53c8fb3a2a7f5a42bb8befb68c856da 
[root@server ~]# podman exec -it first_centos /bin/bash [root@e48892657919 /]# ls
afs bin boot dev dir1 etc home lib lib64 lost+found media mnt opt proc root run sbin srv sys tmp usr var 
[root@e48892657919 /]# cd dir1/ bash: cd: dir1/: Permission denied [root@e48892657919 ~]# exit 
[root@server ~]# podman exec -it Second_centos /bin/bash [root@03095b52384f /]# cd dir2/ 
[root@03095b52384f dir2]#








## namespance分类 
![[_resources/linux笔记/21d6eb1b235d93b35c05bff409736782_MD5.png]]






## 基于插入内核进程的直接生效流量转发

这个方法有意思，临时生效
```
配置网络
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables
echo 1 >/proc/sys/net/bridge/bridge-nf-call-ip6tables
echo """vm.swappiness = 0 net.bridge.bridge-nf-call-iptables = 1 net.ipv4.ip_forward = 1 net.bridge.bridge-nf-call-ip6tables = 1 """ > /etc/sysctl.conf
加载配置
sysctl -p
```


## 关于dm

dm是Device Mapper的缩写，Device Mapper 是 Linux 2.6 内核中提供的一种从逻辑设备到物理设备的映射框架机制，在该机制下，用户可以很方便的根据自己的需要制定实现存储资源的管理策略，当前比较流行的 Linux 下的逻辑卷管理器如 LVM2（Linux Volume Manager 2 version)、EVMS(Enterprise Volume Management System)、dmraid(Device Mapper Raid Tool)等都是基于该机制实现的。

dm-0 对应LVM的 VolGroup00-LogVol00 对应根目录/

dm-1 对应LVM的 VolGroup00-LogVol01 对应swap

参考文章：linux dm-0 dm-1 设备映射 简介-CSDN博客 ([https://blog.csdn.net/whatday/article/details/106354092](https://blog.csdn.net/whatday/article/details/106354092))




## 关于vim搜索指定字符串和指定多行注释

在命令模式下（默认进入vim时就是命令模式，shift加：是末行模式）按下/可以进入搜索模式，输入指定字符串并回车进行查找，按下n跳转到下一个匹配字符串

指定多行注释是在末行模式中进行，格式是 起始行号,结束行号s/^/#/g
g是全局匹配，不加g仅替换每行的第一个匹配项


## 关于&和&&的使用

在dockerfile的CMD指令中需要指定一个前台运行的指令来保障容器的运行，例如在编写mysql的dockerfile用初始化脚本时使用mysqld --user=root来启动mysql，但该命令是前台运行会导致阻塞，所以需要&来而不是&&来衔接下一条指令，&的使用可以保证即使前一条指令未执行完毕也能够继续执行下一条指令，&&则必须要前一条指令执行成功才能继续执行下一条指令






## 如何设置ssh连接后执行指定可执行文件

基于.bashrc和ssh连接的特性

.bashrc在对应用户（这要看.bashrc文件在哪个用户的家目录下）在登录时可以设置一些自动执行的可执行文件

例如

if [ -n "$SSH_CONNECTION" ]; then /path/可执行文件 fi

上述命令实现了ssh连接后在cli执行指定的可执行文件,-n参数是限制仅"$SSH_CONNECTION" 一个判断条件

SSH_CONNECTION变量在ssh连接成功后会被自动赋值，内容格式为:

客户端IP 客户端端口 服务器IP 服务器端口

当没有ssh连接进程时，该变量为空值

基于这些原理，就可以设置指定用户ssh登录时自动执行指定的可执行文件







## 在linux系统的cli中如何实现字体属性设置

这里用C程序举例（使用echo时要加-e选项，参数要加双引号)

终端字体设置
\#include <stdio.h>
int main()
{ puts("\033[5;33m黄色字体,属性是闪烁\033[0m"); /*固定模板是\033[<属性代码>;<前景色代码>;<背景色代码>m 后接需要应用的文本 / 属性代码: 重置(恢复默认)-0 加粗(亮色)-1 淡色(暗色)-2 斜体-3 下划线-4 闪烁-5 反显(反白)-7 隐藏文字-8 前景色和对应代码: 黑色-30 红色-31 绿色-32 黄色-33 蓝色-34 洋红色(品红)-35 青色-36 白色-37 背景色和对应代码: 黑色-40 红色-41 绿色-42 黄色-43 蓝色-44 洋红色(品红)-45 青色-46 白色-47 */ 
return 0; 
}





## 使用ifconfig临时修改网卡配置

格式: ifconfig 网卡名 参数




## FQDN

"完全限定域名",实际上就是字面意思。本质上，它是互联网上计算机或主机的完整域名。它由几个不同的元素组成

它分为以下几个部分：

［hostname］.［domain］.［tld］

例如，以下是如何分解完全限定域名，www.WordPress 站群.com。The 第一部分(“www”)是主机名。第二部分(“WordPress 站群”)是域名。最后一部分(“com”)是 TLD(顶级域)

可以将完全限定域名视为地址。这个地址的目的是在 DNS 系统中指定位置。使用 FQDN，网站或其他线上实体的位置有都自己的唯一识别符号和位置。




## 私网ip地址范围
10.0.0.0-10.255.255.255

172.16.0.0-172.31.255.255

192.168.0.0-192.168.255.255




## 为什么空目录的硬链接索引值默认为2
一个是自身目录，另一个是特殊文件'.'，就是代表当前目录的'.'，它和".."是linux中的特殊文件，'.'是当前目录的特殊硬链接文件，".."是对当前目录的父目录的特殊硬链接文件，以此类推，当一个目录为空时,该目录只有一个'.'和自身，所以硬链接索引值为2，当该目录存在一个空的子文件夹时，又多了一个该子文件夹下的".."文件作为又一个硬链接


## 特殊重定向的使用
1>
1可以视为进程的默认出口，不加1和>也没区别

作用是仅将正确信息覆盖重定向到指定文件，错误信息会输出到终端,处理顺序是先清空后写入

2>
2可以视为进程的默认错误出口

仅将错误信息覆盖重定向到指定文件，不会在shell上显示



1>和2>的组合使用和变种
可以实现同时记录正常输出与错误输出
echo hello  >> hello.log	2>> hell.log

这个功能实现还有多种写法
echo hello   >> hello.log   2>&1


echo hello &>> hello.log
无论正确错误，都会追加重定向到指定文件，不在shell上显示

在定时任务中常用，同时记录正确和错误信息



## 使用管道非交互式修改用户密码
echo "000000" | passwd --stdin user



## linux的用户与组提权
有临时提权和永久提权，就是允许sudo的使用

临时提权
当前用户执行sudo命令,id命令查看当前权限

永久提权
修改/etc/sudoers文件第108行（可以通过visudo命令直接进入该配置文件）

格式是:     用户名  ALL=(ALL)       ALL

(其实在配置文件内部都有参考,包括组提权，参考wheel组）

sudo提权可以精确到具体命令
```bash
[root@server ~]# grep "^testuser" /etc/sudoers
testuser ALL=(ALL) /bin/cat
[root@server ~]# 
```

```bash
[testuser@server ~]$ sudo echo hello
对不起，用户 testuser 无权以 root 的身份在 server 上执行 /bin/echo hello。
[testuser@server root]$ sudo cat sudotest.txt
[sudo] testuser 的密码：
hello!
[testuser@server root]$ 
```

通过sudo -l命令可以查看当前用户有哪些sudo权限

```bash
[testuser@server root]$ sudo -l
匹配 %2$s 上 %1$s 的默认条目：
    !visiblepw, always_set_home, match_group_by_gid, always_query_group_plugin, env_reset, env_keep="COLORS DISPLAY HOSTNAME HISTSIZE KDEDIR LS_COLORS",
    env_keep+="MAIL PS1 PS2 QTDIR USERNAME LANG LC_ADDRESS LC_CTYPE", env_keep+="LC_COLLATE LC_IDENTIFICATION LC_MEASUREMENT LC_MESSAGES", env_keep+="LC_MONETARY
    LC_NAME LC_NUMERIC LC_PAPER LC_TELEPHONE", env_keep+="LC_TIME LC_ALL LANGUAGE LINGUAS _XKB_CHARSET XAUTHORITY", secure_path=/sbin\:/bin\:/usr/sbin\:/usr/bin

用户 testuser 可以在 server 上运行以下命令：
    (ALL) /bin/cat
[testuser@server root]$ 
```





## cron定时任务
/etc/crontab  计划任务列表配置文件

crontab -u 指定用户 -e 开始编辑定时任务

定时任务的格式是

分 时 日 月 周 待执行命令

用*代替指定时间段
 `* * * * * echo hello`

代表每分钟执行一次echo hello命令

可以加除号指定每xx时间段执行

*/3 * * * * echo hello

代表每三分钟执行一次echo hello

以此类推





## semanager port
用来管理端口安全上下文

-a添加规则

-t指定标签类型

-p指定协议tcp/udp

-l列出所有端口安全上下文






## 关于su和ssh特性
1. su 切换用户的环境问题  
使用 su wallah 从 root 切换到 wallah 用户。这种方式 不会完全重置环境变量（如 XDG_RUNTIME_DIR），会继承 root 的部分环境。  

2. SSH 登录的优势  
通过 ssh wallah@localhost 登录时：  
系统会创建全新的登录会话，完全初始化 wallah 用户的环境。  
自动设置正确的 XDG_RUNTIME_DIR（如 /run/user/1000，假设 wallah 的 UID=1000）。  
Podman 可正常访问运行时目录，因此认证成功。
3. 根本原因总结  
su 命令的缺陷：不加载目标用户的完整环境（尤其 systemd 相关的登录会话）。


##  systemd

在较新的linux系统上，都使用systemd 取代了init（红帽在 rhel7 之后使用 systemd），成为系统的第一个进程（PID 等于 1），其他进程都是它的子进程。systemd为系统启动和管理提供了完整的解决方案。它提供了一组命令。字母d是守护进程（daemon）的缩写

一、systemd 核心概念

1. 定义：systemd 是现代 Linux 系统的初始化系统 (Init System) 和服务管理器，是内核启动后运行的第一个进程（PID 1）。
    
2. 核心优势： 并行启动：通过精确的依赖管理和套接字激活等技术，最大化并行启动服务，极大提升开机速度。 统一管理：使用 systemctl 一个命令管理所有系统资源（服务、设备、挂载点等）。 强大功能：集成了日志管理 (journald)、定时任务 (timer)、资源隔离 (cgroups) 等功能。
    
3. 基本单元 (Unit)：systemd 管理的基本对象，通过单元文件定义。常见类型有： .service：定义一个后台服务。 .target：对单元进行分组，代表系统运行状态（类似“运行级别”）。 .socket：定义一个套接字，用于按需启动服务（Socket Activation）。 .timer：定义一个定时器，用于替代 cron。 .mount / .automount：管理文件系统挂载。
    

二、systemd 的两个层面：系统 vs 用户

systemd 同时在系统和用户两个层面运行，职责分明。

特性：系统层面 (System Level) / 用户层面 (User Level) 管理者：systemd (PID 1)，以 root 权限运行 / systemd --user，以普通用户权限运行 核心命令：sudo systemctl ... / systemctl --user ... 主要用途：管理整个系统的核心服务（如 Nginx, SSHD, 数据库） / 管理用户个人应用（如同步工具, 开发服务器, GUI 程序） 生命周期：从系统启动到系统关机 / 从用户首次登录到最后一次会话登出（除非开启 Linger） 日志查看：sudo journalctl ... / journalctl --user ...

三、单元文件加载路径与优先级

systemd 在固定的路径下按优先级顺序查找单元文件。高优先级目录中的同名文件会覆盖低优先级目录中的文件。

系统单元 (systemctl)

1. /etc/systemd/system/ (管理员配置，最高优先级) 系统管理员放置自定义配置或修改现有服务的地方。 systemctl enable 主要在此创建链接。
    
2. /run/systemd/system/ (运行时生成，中等优先级) 存放运行时动态创建的单元。
    
3. /usr/lib/systemd/system/ (软件包默认，最低优先级) 软件包安装时自带的默认单元文件。不应直接修改此目录下的文件。
    

用户单元 (systemctl --user)

1. ~/.config/systemd/user/ (用户自定义，最高优先级) 用户放置个人服务单元文件的首选位置。
    
2. /etc/systemd/user/ (管理员为用户配置，中等优先级) 管理员为所有用户提供的通用用户单元。
    
3. /usr/lib/systemd/user/ (软件包默认，最低优先级) 软件包为用户模式提供的默认单元文件。
    

四、核心工作机制

1. 启动流程： 内核启动 systemd (PID 1)。 systemd 读取 default.target 链接（通常指向 graphical.target 或 multi-user.target）。 递归解析目标的依赖关系（Wants=, Requires=, After= 等），构建依赖树。 将无依赖或依赖已满足的单元并行启动。 可视化工具：systemd-analyze plot > boot.svg 可生成启动过程图。
    
2. 用户服务逗留 (Linger)： 问题：默认情况下，用户登出后，其名下的所有服务都会被终止。 解决方案：为用户开启 Linger，使其 systemd --user 实例在开机时启动，并在用户登出后继续运行。 命令：sudo loginctl enable-linger <用户名>
    

五、常用命令速查表

注意：管理用户服务时，在所有命令中加入 --user 标志。

[服务管理] 启动服务：start (示例：sudo systemctl start nginx.service) 停止服务：stop (示例：sudo systemctl stop nginx.service) 重启服务：restart (示例：sudo systemctl restart nginx.service) 重载配置：reload (示例：sudo systemctl reload nginx.service) 查看状态：status (示例：systemctl --user status my-app.service)

[开机/登录自启] 设为自启：enable (示例：systemctl --user enable my-timer.timer) 禁止自启：disable (示例：sudo systemctl disable sshd.service) 检查自启状态：is-enabled (示例：systemctl is-enabled nginx.service)

[日志查看 (Journal)] 查看所有日志：journalctl (示例：journalctl) 按单元过滤：-u (示例：journalctl -u sshd) 实时跟踪：-f (示例：journalctl -f -u nginx) 按优先级过滤：-p (示例：journalctl -p err 查看错误及以上)

[系统与配置] 重载单元文件：daemon-reload (示例：systemctl --user daemon-reload) 查看默认目标：get-default (示例：systemctl get-default) 设定默认目标：set-default (示例：sudo systemctl set-default multi-user.target) 重启/关机：reboot / poweroff (示例：sudo systemctl reboot) 列出定时器：list-timers (示例：systemctl --user list-timers)







##  init

以前的Linux启动都是用init进程。启动服务：

`$ sudo /etc/init.d/apache2 start`
或者
`$ service apache2 start`

缺点：
启动时间长。init进程是串行启动，只有前一个进程启动完，才会启动下一个进程。 启动脚本复杂。init进程只是执行启动脚本，不管其他事情。脚本需要自己处理各种情况，这往往使得脚本变得很长。

以红帽系统为例，在 rhel7 之后使用 systemd 代替 init 启动


## linux文件特殊权限 suid、sgid、sticky

linux文件的三种特殊权限分别是：suid权限、sgid权限、sticky权限；其中suid权限作用于文件属主，sgid权限作用于属组上，sticky权限作用于other其他上。

一、SUID (Set User ID)

作用对象：可执行文件 功能：当用户执行该文件时，程序会以文件所有者的权限运行（而不是执行者的权限） 符号表示：s 或 S（位于所有者执行位） 数字表示：4（权限前缀）

特点：
仅对二进制可执行文件有效（脚本文件需依赖解释器，通常无效）
权限位显示：
rwsr-xr-x：有执行权限时显示小写 s
rwSr--r--：无执行权限时显示大写 S

经典应用：

ls -l /usr/bin/passwd 输出：-rwsr-xr-x 1 root root 59976 Nov 24 2022 /usr/bin/passwd

普通用户执行 passwd 时，临时获得 root 权限修改 /etc/shadow

设置方法：

符号法 chmod u+s filename

数字法（4755 = SUID + rwxr-xr-x） chmod 4755 filename

二、SGID (Set Group ID)

作用对象：可执行文件和目录 功能：

对文件：执行时以文件所属组的权限运行 对目录：在该目录下创建的新文件/目录继承父目录的所属组

符号表示：s 或 S（位于所属组执行位） 数字表示：2（权限前缀）

目录应用场景：

假设共享目录 /project 属于 dev-team 组：

sudo chmod g+s /project # 设置SGID sudo chgrp dev-team /project

用户A（主组为 groupA）在 /project 创建文件时：

touch /project/file.txt ls -l /project/file.txt 输出：-rw-r--r-- 1 userA dev-team 0 Jul 14 10:00 file.txt

文件自动属于 dev-team 组，而非用户的主组

设置方法：

符号法 chmod g+s directory

数字法（2775 = SGID + rwxrwsr-x） chmod 2775 directory

三、Sticky Bit (粘滞位)

作用对象：目录 功能：只允许文件所有者或root删除/重命名目录中的文件 符号表示：t 或 T（位于其他用户执行位） 数字表示：1（权限前缀）

经典应用：

ls -ld /tmp 输出：drwxrwxrwt 12 root root 4096 Jul 14 09:30 /tmp

所有用户可在 /tmp 创建文件 但只能删除自己创建的文件（防止用户随意删除他人文件）

设置方法：

符号法 chmod +t directory

数字法（1777 = Sticky + rwxrwxrwt） chmod 1777 directory

关于linux设置普通用户密码策略

系统用户不受该配置文件影响

配置文件和具体参数如下

[root@node1 ~]# grep ^PASS /etc/login.defs PASS_MAX_DAYS 25 PASS_MIN_DAYS 0 PASS_WARN_AGE 7

PASS_MAX_DAYS:用于设置普通用户的密码有效期 PASS_MIN_DAYS用于设置普通用户的密码修改最小间隔时间 PASS_WARN_AGE 7用于设置普通用户的密码过期前的警告提前期 单位都是天

另外还有 PASS_MIN_LEN用于设置密码最小长度，对root账户无效 使用chage -l user查看指定用户密码策略信息






## umask

umask 不是文件属性 错误理解："查看文件的 umask" 正确理解："查看当前会话的 umask 设置" umask 是 Shell 进程的环境变量，影响新创建的文件/目录

umask 的值是被“拒绝”的权限。数值越大，权限越严格

权限系统的底层逻辑：二进制位控制

Linux 文件权限的本质是 9 个二进制位（对应 rwxrwxrwx）：

rwx rwx rwx → 用户(u) 组(g) 其他(o) 111 111 111 = 777 (八进制)

每个权限位：
1 = 启用权限
0 = 禁用权限

umask 是反向掩码： 它的二进制位表示 需要强制关闭的权限（1=关闭，0=保留）。

关键认知： 权限值（如 755）是人类可读的八进制抽象，而 umask 是操作系统内核直接处理的二进制掩码。

计算公式： 最终权限 = 最大权限 & (~umask) （& 表示按位与，~ 表示按位取反）

按位与是指在二进制中，两个对应位置有一个为0就取0，取反就是字面意思

至于进制换算有个通用公式，参考下面这个十进制拆解 123 = 1 * 10^2 + 2 * 10^1 + 3 * 10^0

不加参数会显示当前用户的权限值
[root@node1 ~]# umask 0022

第一个 0 表示是 8 进制，后面的三位数字用 8 进制表示
加上-S选项会以字符形式显示权限
[root@node1 ~]# umask -S u=rwx,g=rx,o=rx
通常目录文件的默认权限是777(rwxrwxrwx)，普通文件的默认权限是666(rw-rw-rw-)

在此基础上受umask的影响 umask为0022(第一位是特殊权限位)3 那么以022为例 0表示文件所属者权限不变，2代表对应所有者权限减2(即w权限) 那么022对应的目录权限就是755（rwxr-xr-x）,文件就是644（rw-r--r--）

可以通过在指定用户的.bashrc文件内写入umask xxxx并source声明设置环境变量




## linux各种引号的作用


1.单引号' ' 单引号里面的内容会原封不动输出，全都视为普通字符进行处理

2.双引号" " 和双引号类似，但它会对双引号里面的特殊符号进行解析，不过对于花括号{}(通配符)没有解析

3.不加引号 和双引号类似，额外支持通配符（匹配文件）*.log {1..10}

4.反引号 优先执行，先执行反引号里面的命令，相较于$()，两者作用相同，但反引号在类unix平台适用性更高









## 文件属性inode和block

ls加-i选项可查看inode号

inode号准确地说是inode索引节点,inode号码类似于身份证号码,通过inode号码可以找到文件的内容.

inode inode是一个空间，inode号是空间的位置,类似于身份证,inode空间存放: inode空间中存放的是 文件属性信息 ,文件大小,修改时间,权限,所有者 inode空间中存放block的位置(指向文件实体的指针) 这里不存放文件名.

block块(数据块): 存放数据






## 管道的一些特性
 管道无法将接收的数据流转化为后续命令的参数，如果一定要使用管道，可以在管道后面加上xargs，把前面命令传递过来的字符串转换为后面命令可以识别的参数
[root@server ~]# mkdir -pv testdir 
[root@server ~]# touch testdir/{1,2,3}.ddd 
[root@server ~]# find testdir/ -name "*.ddd" |xargs ls -lh -rw-r--r--. 1 root root 0 7月 16 14:59 testdir/1.ddd -rw-r--r--. 1 root root 0 7月 16 14:59 testdir/2.ddd -rw-r--r--. 1 root root 0 7月 16 14:59 testdir/3.ddd
[root@server ~]# find testdir/ -name "*.txt" |xargs cp -t matchfile_dir/ [root@server ~]# ls matchfile_dir/ 10.txt 1.txt 2.txt 3.txt 4.txt 5.txt 6.txt 7.txt 8.txt 9.txt 
[root@server ~]#

有时管道会将某些命令的标准输出视为错误输出不予传递

如图，从 curl -v 的标准输出中过滤关键词 Date 失败

![[_resources/linux笔记/5868337d1d74cb62f25fbe671bfdafe5_MD5.png]]

只需要在管道符后面加上一个&即可

![[_resources/linux笔记/5291b5bebf2a0dff8ef97421fd6e7130_MD5.png]]

linux的/etc/skel目录

该目录下方存放着所有新用户的家目录模板




## 异常进程分类

僵尸进程 僵尸进程是当子进程比父进程先结束，而父进程又没有回收子进程，释放子进程占用的资源，此时子进程将成为一个僵尸进程。 由于各种原因导致某个进程挂掉了，但是进程本身仍然存在，还占用着系统资源

这里用ai写了一个linux僵尸进程的C程序模拟

[root@server ~]# gcc -o zombine code/zombine.c 
[root@server ~]# ./zombine [Parent] PID 2378 running [Parent] Created child PID 2379 [Parent] Sleeping for 60 seconds without calling wait()... [Child] PID 2379 started [Child] Exiting immediately...

此时前台阻塞中，再开一个bash进程来操作

```
[root@server ~]# ps aux | grep zombine
root 2378 0.0 0.0 2628 928 pts/0 S+ 16:22 0:00 ./zombine root 2379 0.0 0.0 0 0 pts/0 Z+ 16:22 0:00 [zombine]  root 2381 0.0 0.1 221680 2448 pts/1 S+ 16:22 0:00 grep --color=auto zombine [root@server ~]# pstree -p | grep 2378 |-sshd(988)-+-sshd(2094)---sshd(2130)---bash(2140)---zombine(2378)---zombine(2379) 
```

查询到僵尸进程后通过pid查看对应进程树 僵尸进程是由于父进程进入异常状态(这里的父进程用sleep函数模拟异常状态)无法正常回收子进程，导致子进程一直占用资源，通过进程树得知异常父进程的pid是2378 只能通过杀死父进程来杀死僵尸进程

```
[root@server ~]# kill -9 2378
[root@server ~]# ./zombine
[Parent] PID 2401 running 
[Parent] Created child PID 2378
[Parent] Sleeping for 60 seconds without calling wait()... 
[Child] PID 2379 started 
[Child] Exiting immediately... 已杀死 
[root@server ~]#

```
孤儿进程 孤儿进程指的是在其父进程执行完成或被终止后仍继续运行的一类进程。 孤儿进程会被系统直接接管.(systemd进程)

还是用C代码演示孤儿进程

```
[root@server ~]# ./orphan
[Parent] PID 2471 created child PID 2472
[Parent] Exiting now 
[Child] PID 2472 started (PPID=1) 
[root@server ~]# 
[Orphan] PID 2472 now has PPID=1 (init process) 
[Orphan] Running for 60 seconds...
[root@server ~]# ps aux | grep orphan root 2472 0.0 0.0 2628 88 pts/1 S 16:46 0:00 ./orphan root 2482 0.0 0.1 221680 2448 pts/0 S+ 16:46 0:00 grep --color=auto orphan 
[root@server ~]# pstree -p | grep 2472 |-orphan(2472)
```

这里可以看到该进程被系统接管,直接kill -9杀掉就行






## linux 调用历史命令
有两种方式
1.使用 history 命令查看执行过的命令，输入对应历史命令的序号，前面加上！即可快速执行该命令
![[_resources/linux笔记/0a9ff3e23f5be961b7f6d8b4d9a2621e_MD5.png]]

2.直接使用 ！
使用  '!关键字'  可以快速查找并执行 最后一次执行的 以该关键字开头的命令
![[_resources/linux笔记/4b6f5fca635758aa4ed26d1ddc0094b2_MD5.png]]
没用的小知识又增加了




# http 协议原理总结
![[_resources/linux笔记/109d66a9732bed4014db20be12c68878_MD5.png]]



## HTTP 状态码格式规范

|范围|类别|含义|常见例子|
|---|---|---|---|
|1xx|信息响应|请求已被接收，继续处理。
|2xx|成功|请求已成功被服务器接收、理解并接受。
|3xx|重定向|需要客户端采取进一步的操作才能完成请求。
|4xx|客户端错误|请求本身有问题（如语法错误、无法实现等）。
|5xx|服务器错误|服务器处理有效请求时失败。














# EFI 系统分区

EFI 系统分区 (ESP) 是操作系统启动的关键组件，尤其是在使用 UEFI启动模式的电脑上（现代电脑基本都是 UEFI）。

## EFI 系统分区是什么？

1. 核心定义：EFI 系统分区（ESP）是一个小型、隐藏的 FAT32 格式分区，它是 UEFI 固件启动操作系统所必需的。
    
2. 作用类比: 你可以把它想象成电脑启动过程中的 “引导文件仓库”*或 “启动导航地图”。UEFI 固件（取代传统 BIOS 的现代固件）在开机时，会首先查找并读取这个分区里的文件，才能知道如何加载哪个操作系统。
    
3. 位置： 它通常位于磁盘的最开始部分（但并非绝对），大小一般在 100MB - 550MB*之间（Windows 默认创建 100MB，某些 Linux 发行版或工具可能创建更大一些）。
    
4. 文件系统：FAT32。这是 UEFI 规范强制要求的，因为 UEFI 固件本身内置了读取 FAT32 文件系统的能力。
    
5. 标识： 在磁盘管理工具（如 Windows 磁盘管理、DiskGenius、GParted、Linux 的 `fdisk -l` 或 `lsblk -f`）中，它的分区类型标识通常是：
    EFI System Partition
    ESP
GPT 分区表下的类型代码: C12A7328-F81F-11D2-BA4B-00A0C93EC93B
        

## EFI 系统分区里有什么？

1. 引导加载程序：
    Windows: \EFI\Microsoft\Boot\bootmgfw.efi (主 Windows 引导管理器) 以及 \EFI\Microsoft\Boot\BCD(启动配置数据库，告诉引导管理器有哪些 Windows 可以启动)。Linux (常见发行版): \EFI\ubuntu\grubx64.efi 或 \EFI\ubuntu\shimx64.efi(Ubuntu/Debian), \EFI\fedora\grubx64.efi 或 \EFI\fedora\shimx64.efi (Fedora), \EFI\arch\grubx64.efi (Arch) 等等。还可能包含内核 vmlinuz-xxx 和初始内存盘 initramfs-xxx.img（如果使用 GRUB 等直接从 ESP 加载）。
        
2. 固件应用程序： UEFI 固件本身或硬件制造商（如主板厂商、显卡厂商）提供的工具，可能用于固件更新、诊断等。
    
3. 引导管理器： 有时会安装第三方引导管理器，如rEFInd(\EFI\refind\refind_x64.efi)，它提供一个图形化界面让你选择要启动的操作系统或工具。
    
4. 驱动： 一些必要的 UEFI 驱动程序（`.efi` 文件），可能用于在操作系统加载前访问特定的硬件（如某些 RAID 卡、特殊文件系统）。
















# TCP 三次握手原理


![[_resources/linux笔记/338cb5e208708cf7466e0de831fba7a5_MD5.png]]

```
TCB           传输控制块，打开后服务器/客户端进入监听(LISTEN)状态
SYN=1      请求建立连接
seq            报文初始序列号，代表发送的第一个字节的序号
Ack=1       确认收到了客户端信息
ack            报文确认序号，代表希望收到的下一个数据的第一个字节的序号
```



## 第一次握手: 客户端—请求

1. 应用程序调用 `connect()` 系统调用。
    
2. 内核协议栈开始工作：
    
    - 创建TCB（传输控制块），初始化序列号 `seq=x`，构建一个 `SYN=1` 的TCP报文段。
        
    - 将这个TCP报文段下交给IP层，IP层为其添加IP报头成为数据包，再下交给数据链路层。
        
    - 数据链路层为该数据包添加帧头和帧尾将它封装为一个完整的数据帧。
        
3. 数据链路层将数据帧排入发送队列，套接字的状态从 `CLOSED` 更新为 `SYN-SENT`（状态转换是“将SYN报文成功交付给下层协议（即本地协议栈）”的结果，而不是“数据帧被网卡物理发送到链路上”的结果。），最后由网卡驱动程序将数据帧发送到网络链路上。




## 第二次握手: 服务器—确认
服务器设置 ACK=1，表示确认应答

设置 ack=x+1，表示已收到客户端 x 之前的数据，希望下次数据从 x+1 开始

设置 SYN=1，表示握手报文，并发送给客户端

设置发送的数据包序列号 seq=y

此时服务器处于同步已接收 SYN-RCVD 状态



## 第三次握手: 客户端—确认服务器的确认
设置 ACK=1，表示确认应答
设置 ack=y+1，表示收到服务器发来的序列号为 seq=y 的数据包，希望下次数据从 y+1 开始
设置 seq=x+1，表示接着上一个数据包 seq=x 继续发送


至此三次握手结束，连接建立



# DNS 解析流程
DNS端口因为使用的是udp，所以是53号端口
本地主机名是 rocky.linux.com

在浏览器的 url 栏中输入域名 rocky.linux.com 时，有多个流程，当前流程失败就走下一个流程

![[_resources/linux笔记/f310b68af89c66d83487d5c9b5a03840_MD5.jpg]]









# 报文、数据包 、帧的关系

这是一个关于网络分层模型的问题。

报文 (Segment)： 这是传输层（TCP层） 的协议数据单元（PDU）。它包含TCP头（源/目的端口、序列号、确认号、标志位SYN/ACK等）和可选的应用层数据。在三次握手期间，SYN和ACK报文不携带任何应用层数据，它们的“数据”部分长度为0。 数据包 (Packet)： 这通常指的是网络层（IP层） 的协议数据单元。一个TCP报文在发送前，会被封装到一个IP数据包中。IP数据包由IP头（源/目的IP地址）和“载荷”组成，这个“载荷”就是整个TCP报文。 帧 (Frame)： 再往下，IP数据包又会被数据链路层封装成“帧”，添加MAC地址等信息，最后变成比特流由物理层发送出去。

它们的关系是层层封装的： [ 帧头 | IP头 | TCP头 (SYN=1) | (数据) | 帧尾 ]





# cookie 与 session 详解

一、核心概念

Session（会话）：服务器端用来跟踪用户状态的一种机制。服务器为每个用户创建一个唯一的会话，并存储相关数据（如用户ID、登录状态）。 Session ID：一个唯一、随机、不可预测的字符串，是Session的“钥匙”。服务器通过它来找到对应用户的Session数据。 Cookie：浏览器端的一种小型数据存储机制。Session ID 通常通过 Cookie 在浏览器和服务器之间传递。这是连接客户端和服务器端会话的桥梁。cookie 是键值对类型数据，它的值就是 Session ID

二、 Web会话（Session）建立流程

第一步：首次访问，建立匿名会话

1. 【客户端动作】浏览器 向服务器发起一个HTTP请求（例如 GET /login.php）。
    

- 此时，由于是首次访问，浏览器的 http 请求头（Request Headers）中不包含该网站的Session Cookie。
    

2. 【服务端动作】服务器 接收到请求。
    

- 服务器解析请求头，发现没有名为 PHPSESSID（或其他自定义名称）的Cookie。
    
- 服务器生成一个新的、唯一的Session ID（例如 sess_abc123）。
    
- 服务器在内存或文件系统中创建一个新的Session文件，文件名通常与Session ID关联（例如 sess_abc123）。此时该文件是空的或只包含初始信息。
    

3. 【服务端响应】服务器 发送HTTP响应（Response）给浏览器。
    

- 在响应头（Response Headers） 中，包含一个 Set-Cookie 指令： Set-Cookie: PHPSESSID=sess_abc123; path=/; HttpOnly
    
- 这个指令的含义是：“浏览器，请为我这个网站保存一个键为 PHPSESSID，值为 sess_abc123 的Cookie。”
    

set-cookie 那一行，可以看到 id 与上面服务器本地创建的文件一致

4. 【客户端动作】浏览器 接收到服务器的响应。
    

- 浏览器解析响应头，看到 Set-Cookie 指令。
    
- 浏览器遵照指令，在自己的Cookie存储空间中创建或更新这个Cookie（键值对：PHPSESSID: sess_abc123）。
    

至此，会话通道建立完成。 浏览器拥有了Session ID，并承诺在后续所有对该网站的请求中自动携带它。

第二步：登录认证，提升会话权限（安全再生）

1. 【客户端动作】浏览器 提交登录表单（例如 POST /login.php）。
    

- 在发送这个请求时，浏览器自动在请求头中携带之前保存的Cookie： Cookie: PHPSESSID=sess_abc123
    
- 表单数据（用户名、密码）放在请求体（Request Body）中。
    

2. 【服务端动作】服务器 接收到登录请求。
    

- 服务器从请求头中获取 Cookie: PHPSESSID=sess_abc123，从而知道这是哪个会话。
    
- 服务器从请求体中获取用户名和密码并进行验证。
    
- 验证成功后，为了安全，服务器执行“会话再生”： a. 销毁旧的Session文件 sess_abc123。 b. 生成一个全新的Session ID（例如 sess_def456）。 c. 创建新的Session文件 sess_def456，并将用户的登录状态（如 user_id: 1）等重要信息写入其中。
    

3. 【服务端响应】服务器 发送登录成功的响应（通常是302重定向）。
    

- 在响应头中，再次使用 Set-Cookie 指令： Set-Cookie: PHPSESSID=sess_def456; path=/; HttpOnly
    
- 这个指令的含义是：“浏览器，你之前持有的 sess_abc123 已经作废，请立刻更新为这个新的 sess_def456。”
    

4. 【客户端动作】浏览器 接收到响应。
    

- 浏览器看到新的 Set-Cookie 指令，立即用新的值（sess_def456）覆盖本地存储的旧Cookie值。
    

第三步：登录后访问，使用认证会话

1. 【客户端动作】浏览器 访问登录后的页面（例如 GET /dashboard.php）。
    

- 在请求头中，浏览器自动携带的是更新后的、有效的Cookie： Cookie: PHPSESSID=sess_def456
    

2. 【服务端动作】服务器 接收到请求。
    

- 从Cookie中获取到 sess_def456，找到对应的Session文件。
    
- 读取文件内容，确认用户已认证，然后返回受保护的页面内容。




# 常见问题

## ssh报错kex_exchange_identification
[[_resources/linux笔记/ad9ec2e60c1b667abd430f21d04cd9dc_MD5.jpg|Open: Pasted image 20251222202418.png]]
![[_resources/linux笔记/ad9ec2e60c1b667abd430f21d04cd9dc_MD5.jpg]]
虚拟机内部的sshd服务报错是
[[_resources/linux笔记/6cfa3dbdb7e58c1692e3035740d16cf3_MD5.jpg|Open: Pasted image 20251222202505.png]]
![[_resources/linux笔记/6cfa3dbdb7e58c1692e3035740d16cf3_MD5.jpg]]
SSH 为了安全，使用了一种叫 **Privilege Separation（权限分离）** 的技术
- 它会启动一个拥有 root 权限的主进程。
    
- 还会启动一个没有任何权限的子进程来处理网络数据（防止黑客溢出攻击）。
    
- 这两个进程需要交换数据，就依赖于 `/run/sshd` 这个目录。
    
- 如果这个目录不存在，或者权限不对（比如不是 root 拥有），SSH 会认为“环境不安全”，为了防止被劫持，它宁可直接自杀（fatal error）也不启动。

解决方案
1.创建目录
`sudo mkdir -p /run/sshd`

2.设置权限（必须是 755，即 rwxr-xr-x）
`sudo chmod 0755 /run/sshd`

3.设置属主（必须属于 root）
`sudo chown root:root /run/sshd`

4.重启sshd服务
`sudo systemctl restart sshd`

永久修复（可选）
1.新建一个临时文件配置
`sudo vim /etc/tmpfiles.d/sshd.conf`
写入以下内容
`d /run/sshd 0755 root root`






## 命令行变为bash-5.1$

原因: 用户家目录下面的配置文件没了这两个: ~/.bashrc，~/.bash_profile

解决: /etc/skel目录下方存放着所有新用户的家目录模板,将缺失文件复制到指定用户的家目录

[root@server ~]# su testuser bash-5.1$ cp /etc/skel/.bash* ~/ bash-5.1$ bash [testuser@server root]$ cd ~ 
[testuser@server ~]$






## centos7虚拟机强制重启后无法因无法挂载到系统而进入紧急模式

![[_resources/linux笔记/d3c4ccd82df00fadf72ecaeccf298f63_MD5.png]]

![[_resources/linux笔记/675a64bc9f80cf73c9e88af566904b64_MD5.png]] 因服务器无端重启，导致无法挂载系统

解决方案：使用xfs_repair工具修复

执行xfs_repair -v -L /dev/dm-0命令

命令详解：

-v：

这个参数表示启用详细模式（verbose mode），会显示更多的诊断信息和操作细节。

-L：

这个参数用于指定一个日志文件，xfs_repair 会将修复过程中的详细信息记录到这个文件中。

/dev/dm-0：

这是要修复的 XFS 文件系统的设备路径。在这个例子中，/dev/dm-0 表示一个使用设备映射（device-mapper）的逻辑卷。





## NetworkManager与network冲突问题

![[_resources/linux笔记/bc77c767c2a42758bf93c8dd27ce79b7_MD5.png]]

使用ip a命令时发现网卡未读取到网卡配置文件中的静态网络配置信息，查看网卡配置没有错误，使用systemctl restart network报错
job for network.service failed

解决方案：
```
systemctl stop NetworkManager
systemctl disable NetworkManager
systemctl restart network
systemctl status network
```

原因:

在CentOS系统上，目前有NetworkManager和network
两种网络管理工具。如果两种都配置会引起冲突，而且NetworkManager在网络断开的时候，会清理路由，如果一些自定义的路由，没有加入到NetworkManager的配置文件中，路由就被清理掉，网络连接后需要自定义添加上去。（补充：NetworkManager有一个图形化配置网络的功能，对应指令是：nmtui）(后续补充：在centos9stream版本中网络配置主工具改为了NetworkManager)












## 网卡激活报错:未被NetworkManager托管
设备:vmware虚拟机rh9.2

原图
![[_resources/linux笔记/62bfcb336d9ed3efbd8ca3daa6e5e033_MD5.png]]


解决方案:
1.修复主配置
`sudo sed -i '/^\[main\]/a plugins=keyfile\nno-auto-default=*' \`
`/etc/NetworkManager/NetworkManager.conf`


2.设置全局托管策略
`sudo echo -e "\nunmanaged-devices=none" > \`
`/etc/NetworkManager/conf.d/manage-all.conf`


3.完全重置状态
`sudo systemctl stop NetworkManager`
`sudo rm -rf /var/lib/NetworkManager/*`
`sudo systemctl start NetworkManager`


4.重建连接配置
`sudo nmcli connection add type ethernet ifname ens160 \`
`con-name ens160-primary ipv4.method auto`
`sudo nmcli connection up ens160-primary`



根本原因分析
NetworkManager配置缺陷： 
主配置文件/etc/NetworkManager/NetworkManager.conf缺少关键配置项 未启用keyfile插件导致设备管理功能异常 缺少全局设备托管策略

配置状态不完整
缺少必要配置项 
plugins=keyfile
no-auto-default=*

设备管理策略缺失： 没有明确声明unmanaged-devices=none，导致NetworkManager拒绝管理网络设备








