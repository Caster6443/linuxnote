




# wordpress 重置密码
注册时邮箱和密码都是乱填的，所以无法登录

进入后端数据库，查询相关表信息并修改即可

```plsql
[root@web02 ~]# mysql -h 192.168.120.150 -ucaster -p000000
#这里搞的是远程数据库
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 31
Server version: 10.5.27-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> show databases;
+--------------------+
| Database           |
+--------------------+
| information_schema |
| mysql              |
| performance_schema |
| wordpress          |
+--------------------+
4 rows in set (0.021 sec)
MariaDB [(none)]> use wordpress;
Reading table information for completion of table and column names
You can turn off this feature to get a quicker startup with -A

Database changed
MariaDB [wordpress]> show tables;
+-----------------------+
| Tables_in_wordpress   |
+-----------------------+
| wp_commentmeta        |
| wp_comments           |
| wp_links              |
| wp_options            |
| wp_postmeta           |
| wp_posts              |
| wp_term_relationships |
| wp_term_taxonomy      |
| wp_termmeta           |
| wp_terms              |
| wp_usermeta           |
| wp_users              |
+-----------------------+
12 rows in set (0.001 sec)
MariaDB [wordpress]> select * from wp_users;
+----+------------+------------------------------------+---------------+------------+----------------------+---------------------+---------------------+-------------+--------------+
| ID | user_login | user_pass                          | user_nicename | user_email | user_url             | user_registered     | user_activation_key | user_status | display_name |
+----+------------+------------------------------------+---------------+------------+----------------------+---------------------+---------------------+-------------+--------------+
|  1 | awdxa      | $P$Bz.Bif9F.CYW0iJiQTWwT67jMt2t5q/ | awdxa         | xaw@qq.com | http://php.alice.com | 2025-09-01 09:51:26 |                     |           0 | awdxa        |
+----+------------+------------------------------------+---------------+------------+----------------------+---------------------+---------------------+-------------+--------------+
1 row in set (0.001 sec)
#可以看到awdxa就是我乱填的用户名，后面还有邮箱，密码被md5加密了
MariaDB [wordpress]> UPDATE wp_users SET user_pass = MD5('000000') WHERE user_login = 'awdxa';
Query OK, 1 row affected (0.024 sec)
Rows matched: 1  Changed: 1  Warnings: 0

MariaDB [wordpress]> 
#把密码改成了000000，回到主页登录就行了
```












# ssh报错kex_exchange_identification
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










# mysql8.0 安装后配置

与 8.4 不同，使用 mysql -u root -p 直接进入数据库（注意不是 mysqld），密码输入直接回车，因为默认是空密码,进入数据库，为了安全起见，还是设置一下 root 密码，在数据库中执行以下代码

ALTER USER 'root'@'localhost' IDENTIFIED BY '新密码'; FLUSH PRIVILEGES;










# Mysql 密码插件报错：未加载
```plsql
mysql> alter user  zabbix@localhost identified with mysql_native_password by 'Zabbix@123';
ERROR 1524 (HY000): Plugin 'mysql_native_password' is not loaded
```

MySQL 8.4(截至 2024 年的最新 LTS 版本)中引入的一个主要变化是，默认情况下不再启用 “MySQL Native Password” 插件。

此更改会影响使用 MySQL 数据库和 mysql_native_password 身份验证插件的 PHP 和其他应用。由于默认情况下不再加载 mysql_native_password 插件，因此导致 PHP PDO/MySQLi 连接失败。

当尝试使用不再加载的 mysql_native_password 插件连接到数据库时，PDO/MySQLi 抛出 MySQL 返回的错误

解决方案：重新启用mysql_native_password

在 mysql 配置文件的 [mysqld] 下面添加如下配置，配置文件的位置参考我使用的 orcle_linux8.6，路径是/etc/my.cnf

```plain
# Enable mysql_native_password plugin
[mysqld]
mysql_native_password=ON
```

重启 mysqld 后生效












# 如何安全删除双系统
以在 windows 下删除另一 ubuntu 系统为例

在磁盘管理中将对应系统分区格式化后，可以看到一个分区名为 EFI 系统分区

![[_resources/linux笔记/1ebd4602ede2f4062dc73293762d7a59_MD5.png]]

该分区内残留着 ubuntu 相关文件，需要删除，windows 删除需要将该分区分配并进入才能删除，这里使用第三方工具Hasleo EasyUEFI

![[_resources/linux笔记/57f4d55a16245b62cc7add65a5a55bc2_MD5.png]]

进入 EFI 系统分区资源管理器

![[_resources/linux笔记/36174541391b4e0c4d33bfe69edf70cc_MD5.png]]

选中对应 EFI分区并打开

![[_resources/linux笔记/cb53c5f495444dd3ee4ce199a0f7865f_MD5.png]]

打开后 EFI 文件夹会有一个 ubntu 相关的文件，删除即可，这里已经删除了

至此完成安全删除系统

后续是我手贱把 D 盘的 EFI 系统分区删除了，导致整个 D 盘被格式化，被迫重装了系统哈哈,

我不想重装系统的



最后做个总结，在某一硬盘安装系统时，该硬盘上会出现一个独立的 EFI 系统分区，该分区删除会导致整个硬盘资源定位丢失，就像被格式化了一样(也或者是硬盘分区位置在 EFI 系统分区左边的分区这样，因为 windows 有这个概念)，所以做系统最好单独用一块硬盘来做，在一块已使用的硬盘上分区用来做系统很不安全















# 关于虚拟机未读取到网卡配置文件中的静态网络配置信息

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














# 以ftp配置yum源无法连接
报错:![[_resources/linux笔记/74be754693f3b8ea2a35eaeaff007871_MD5.png]]

解决方案：

vi /etc/selinux/config

将文件内selinux参数修改为disabled

原因：
controller(通过ftp提供yum源的主机)禁用了防火墙firewalld，但未禁用selinux







# 关于数据库调优-my.cnf配置详解

![[_resources/linux笔记/7a3e8731c537b0aa65c421cbd92242ef_MD5.png]]

lower_case_table_names =1 //数据库支持大小写
innodb_buffer_pool_size = 4G //设置数据库缓存（缓冲区）大小为4G innodb_log_buffer_size = 64MB //设置数据库的log buffer即redo日志缓冲为64MB 
innodb_log_file_size = 256MB //设置数据库的redo log即redo日志大小为256MB 
innodb_log_files_in_group = 2 //数据库的redo log文件组即redo日志的个数配置为2

systemctl restart mariadb







# 关于不进入数据库命令行界面而实现交互

可参考该命令mysql -uroot -proot -e " create database djangoblog;"

另外还可以直接进入指定数据库mysql -uroot -proot djangoblog



# 关于 redis的配置文件部分参数

bind 127.0.0.1

该参数表示只允许本地连接，若要开启远程连接则需要注释该参数或将127.0.0.1修改为0.0.0.0

protected-mode yes

字面意思，开启保护模式，若要关闭保护模式只需将yes修改为no

which和find

which只能用来查找命令，而不能用来查找文件，find用来查找文件

find的模糊查询使用*来实现，例如通过find / -name ‘_filename_’来实现在根目录下查找名称包含filename字段的文件








# 如何在不通外网且不支持 ntfs格式U盘 的系统配置本地源
当因为需要使用的本地镜像过大而FAT32格式不支持时


红帽9为例，红帽9(centos7)支持FAT32格式的U盘，可以先把U盘格式化为FAT32格式（windows11一般不允许格式化为该格式，可以使用软件格式化,这里使用的是DiskGenius,在图吧工具箱有收录)，然后下载ntfs-3g（<font style="color:#DF2A3F;">该组件可以让红帽9系统能够识别并使用NTFS格式的移动硬盘，可以使用yum install --downloadonly --downloaddir 本地保存目录 ntfs-3g来保存安装包和相关依赖</font>),该插件一般在epel源里，然后在系统上安装该插件，拔出U盘后就可以重新格式化为NTFS格式，然后就可以放进需要挂载的镜像，再次插入时，该系统已经可以支持识别该格式的移动硬盘了






# 网卡激活报错:未被NetworkManager托管
设备:vmware虚拟机rh9.2

原图
![[_resources/linux笔记/62bfcb336d9ed3efbd8ca3daa6e5e033_MD5.png]]


解决方案:
1.修复主配置

sudo sed -i '/^\[main\]/a plugins=keyfile\nno-auto-default=*' \

/etc/NetworkManager/NetworkManager.conf


2.设置全局托管策略

sudo echo -e "\nunmanaged-devices=none" > \

/etc/NetworkManager/conf.d/manage-all.conf


3.完全重置状态

sudo systemctl stop NetworkManager

sudo rm -rf /var/lib/NetworkManager/*

sudo systemctl start NetworkManager


4.重建连接配置

sudo nmcli connection add type ethernet ifname ens160 \

con-name ens160-primary ipv4.method auto

sudo nmcli connection up ens160-primary




根本原因分析
NetworkManager配置缺陷： 
主配置文件/etc/NetworkManager/NetworkManager.conf缺少关键配置项 未启用keyfile插件导致设备管理功能异常 缺少全局设备托管策略

配置状态不完整
缺少必要配置项 
plugins=keyfile
no-auto-default=*

设备管理策略缺失： 没有明确声明unmanaged-devices=none，导致NetworkManager拒绝管理网络设备


# autofs配置文件解析
/etc/auto.master（主配置文件）
作用：定义挂载点的根目录和对应的映射文件。
格式： [挂载点根目录] [映射文件路径] [可选参数] 

映射文件（如 /etc/remote.misc）
作用：定义子目录如何挂载到远程共享。 常见格式： [子目录名] [挂载选项] [服务器:共享路径]




# NFS（Network File System）总结与分析
1.NFS 概述 定义：
NFS 是一种允许通过网络共享文件系统的协议，使得不同机器上的文件系统能够像本地文件系统一样被访问。 工作原理：客户端通过网络请求访问 NFS 服务器上共享的目录，服务器根据权限提供访问。

2.NFS 架构 客户端-服务器模式：
NFS 使用客户端和服务器的模型，客户端通过网络访问服务器提供的共享目录。 协议：NFS 是基于 RPC（远程过程调用）协议的，客户端向服务器发起请求，服务器处理请求并返回响应。

3.NFS 服务器配置 共享目录：
通过 /etc/exports 文件配置，指定哪些目录可以共享、哪些客户端可以访问。 权限设置：通过配置选项控制客户端的读写权限、同步与否等.
示例配置：/hello 192.168.120.0/24(rw,sync,no_all_squash)   
/hello：共享的目录路径。
192.168.120.0/24：允许访问的客户端网络。
rw：读写权限。
sync：同步写入操作。
no_all_squash：禁用 UID/GID 映射，保持客户端原有权限。

4.NFS 客户端操作 挂载共享目录：
客户端使用 mount 命令挂载服务器共享的目录。
示例：mount -t nfs [nfs-server-ip]:/hello /mnt/hello 访问共享文件：挂载后，客户端就可以像访问本地文件一样访问远程共享目录中的文件。

5.NFS 文件操作 请求：
客户端向服务器发起文件操作请求（如读取、写入、删除文件等）。 响应：NFS 服务器处理请求后，返回操作结果或文件数据。 文件描述符：通过文件描述符在客户端和服务器之间传输文件操作的请求和响应。

6.权限管理 UID/GID 映射：
NFS 使用 UID 和 GID 来控制文件权限。默认情况下，客户端请求的 UID 和 GID 可能会映射为 nfsnobody 用户，除非使用 no_all_squash 禁用该映射，允许客户端保持原有的 UID/GID 权限。

7.同步与异步操作 同步 (sync)：
数据写入操作必须完成并确认后，才返回响应，确保数据一致性，但可能降低性能。 异步 (async)：写操作不等待确认立即返回，虽然性能更高，但可能导致数据不一致的风险。

8.NFS 协议版本 NFSv2：
较早的版本，基于 UDP 协议，不支持强大的安全性。 NFSv3：引入了基于 TCP 的传输，支持更大文件和更强的性能。 NFSv4：提供了更强的安全性、身份验证、支持锁机制等。它是目前使用的主要版本，支持更好的跨平台兼容性和性能。

9.NFS 服务的管理 启动和管理服务：
NFS 服务器通过 nfs-server 服务提供支持，可以使用 systemctl 命令来启动、停止和查看服务状态。
启动：systemctl start nfs-server
停止：systemctl stop nfs-server
状态：systemctl status nfs-server

10.NFS 常用端口 2049/TCP 和 UDP：
这是 NFS 的固定端口，主要用于文件系统操作（如读写、挂载等）。所有文件共享的操作都通过此端口进行。 111/TCP 和 UDP（portmapper 或 rpcbind）：portmapper 服务（在现代系统中通常是 rpcbind）运行在 111 端口，客户端首先通过此端口查询到 NFS 服务的实际端口号。 20048/TCP 和 UDP（nfsd）：用于 NFS 服务器的守护进程，处理客户端的文件操作请求。 32768-65535/TCP 和 UDP：这些端口用于 NFS 的其他相关服务（如锁管理等），它们是动态分配的。

防火墙配置：确保这些端口在防火墙上是开放的，否则客户端将无法访问 NFS 服务。
firewall-cmd --permanent --add-port=2049/tcp firewall-cmd --permanent --add-port=2049/udp firewall-cmd --permanent --add-port=111/tcp firewall-cmd --permanent --add-port=111/udp firewall-cmd --reload


11.NFS 优缺点 优点：
允许在不同操作系统之间共享文件。
支持分布式文件系统，方便大规模数据存储和共享。
配置简单，容易扩展。 缺点：
性能可能受到网络延迟和同步操作的影响。
安全性较差，需要额外的安全措施（如 NFSv4 的身份验证、加密）。
对于大型环境，可能需要额外的性能调优。

12.总结
NFS 是一个非常有效的协议，可以使得不同系统之间共享文件系统，适用于内部网络中资源共享。 配置和管理较为简单，但需要特别注意权限设置和性能优化。 在生产环境中，使用 NFSv4 可以获得更好的安全性和性能。 了解和配置端口、服务及防火墙是确保 NFS 正常运行的重要部分。




关于nfs配置文件/etc/exports的权限no_all_squash选项详解

no_all_squash：这是一个与 NFS 权限映射相关的选项。默认情况下，NFS 在进行客户端访问时，可能会将客户端的用户 ID（UID）和组 ID（GID）映射为 nfsnobody（一个权限非常低的用户）。no_all_squash 选项意味着禁用这种映射，而是使用客户端请求时的原始 UID 和 GID。这允许客户端以原用户的身份访问文件系统，而不是以 nfsnobody 用户的身份。




autofs使用nfs远程挂载实践


服务端和客户端都安装nfs服务yum -y install nfs-utils rpcbind，修改服务端的nfs配置文件/etc/exports,内容示例:
```
[root@server ~]# cat /etc/exports
/hello 192.168.120.0/24(rw,sync,no_all_squash)

```

这里指定了/hello作为远程目录,指定网段，后面的权限选项详解上面有写

客户端使用showmount -e 服务端ip可验证


```
[root@client hello]# showmount -e server 
Export list for server:
/hello 192.168.120.0/24

```

接下来修改客户端的autofs配置文件
```
[root@client hello]# cat /etc/auto.master | grep "^\/m"
/misc	/etc/auto.misc
/mountdir /etc/remote.misc
```


这里指定了客户端本地挂载目录是/mountdir,作为远程目录的父目录，映射文件是remote.misc(注:这里的命名没有任何的后缀要求，只要和auto.master中指定的映射文件名保持一致即可)

然后修改映射文件
```
[root@client hello]# cat /etc/remote.misc 
hello -rw server:/hello

```

格式是[子目录名] [挂载选项] [服务器:共享路径]

规范来说，这里应该指定挂载类型，但autofs会自动识别到nfs，所以就不写了

然后重启autofs服务

接下来需要访问挂载目录
```
[root@client mountdir]# cd /mountdir/hello
[root@client hello]# ls
nihaoa

```
服务端的hello目录会变成mountdir的子目录，使用cd访问/mountdir/hello触发autofs的自动挂载，注意，在访问之前，mountdir下面是空的，hello是tab不出来的，只有直接cd访问这个目前不存在的目录，才会触发autofs的自动挂载

至此成功实现了nfs和autofs的组合使用。




# 关于逻辑卷调整的-r参数

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
















