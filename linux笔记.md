




# 2024/9/20
## 关于虚拟机启用虚拟机引擎失败

工具：centos7虚拟机，VMware17pro

报错：模块“VPMC”启动失败，未能启动虚拟机

解决方案：在任务管理器中查看到本机CPU支持并已开启了虚拟化功能，而后在安全中心中关闭了内存完整性，成功解决（在此之前关闭了windows功能服务中的windows虚拟机监控程序平台，但并未排除报错，不知道有没有关联，不过hyprv和这个是必须关闭的）












# 9/22
## 关于虚拟机未读取到网卡配置文件中的静态网络配置信息

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










# 9/25
## 以ftp配置yum源无法连接
报错:![[_resources/linux笔记/74be754693f3b8ea2a35eaeaff007871_MD5.png]]

解决方案：

vi /etc/selinux/config

将文件内selinux参数修改为disabled

原因：
controller(通过ftp提供yum源的主机)禁用了防火墙firewalld，但未禁用selinux













# 9/27

在安装neutron时报错缺少libxslt-1.1.28-5.el7.x86_64，本机版本为libxslt-1.1.28-6.el7.x86_64，若使用yum erase卸载libxslt-1.1.28-6.el7.x86_64重新安装libxslt-1.1.28-5.el7.x86_64后需要重新安装nova服务（iaas-install-nova。。。）。（后续补充：这个报错是因为使用了7.9的镜像，实际上先电2.4应该使用7.5）

因为在卸载libxslt-1.1.28-6.el7.x86_64时也一并卸载了部分nova配置

补充：
在使用glance命令生成镜像时报错，大意是端口号被占用，配置文件错误，重装glance后解决报错，可知这个文件与glance配置也有关系，虽然在一切开始之前我就重新安装了libxslt-1.1.28-5.el7.x86_64版本，但还是报错说我版本没有变化，还是.6版本，不得已在配置过程中卸载重装了这个文件，在dashboard平台的报错弹窗（找不到镜像）也一并解决了












# 9/28

## 报错：无效的服务目录，compute

![[_resources/linux笔记/98bf11f74a0d0f17ba4b93b00a194aee_MD5.png]]



注：尝试使用成功案例的controller快照，compute节点则是直接重置，在compute节点配置过程中执行了chronyc sources -v和安装了nova和neturn，并未删除libxslt-1.1.28-6.el7.x86_64和下载libxslt-1.1.28-5.el7.x86_64，解决了该报错，所以出现此报错很可能是controller配置出现问题,

尝试重置了controller并重新配置，与上次不同的是执行了chronyc sources -v

进一步排查认为此报错是因为chronc这个时间同步指令未执行(后续补充：这个指令是验证，主要还是时间同步没做好)，或是因为把controller配置完毕后再配置compute（因为compute并没有重置，全程都在配置controller）

在使用glance制作镜像前先source /etc/keystone/admin-openrc.sh



想到一个思路，虽然我之前卸载又重装了不同版本的lib...，但有可能是因为我在安装nova和glance时自动升级了lib...的版本，而自动升级的原因可能与我在安装过程中全程连接外部网络有关(与外网无关，在安装neturn时还是报同样的错）



安装iaas-pre-host。。后时间服务器报错无法启动了，检查配置成功的镜像同样无法使用时间服务器,配置成功的镜像没有卸载libxslt-1.1.28-6.el7.x86_64

解决方案：先把controller节点的组件全部安装后再安装compute节点

安装过程如下：

Controller节点开始，安装iaas-pre-host。。，compute安装iaas-pre-host。。。，回到controller节点，安装mysql，keystone，glance，nova，neturn，neturn报错，卸载libxslt-1.1.28-6.el7.x86_64安装libxslt-1.1.28-5.el7.x86_64，重新安装nova，进入云平台后安装glance（这个先后顺序貌似没有区别，以防万一还是记录一下，后续修改）(后续补充：确实没区别，就是因为时间同步没做好),而后进入compute节点安装nova，neturn

，进入controller节点安装dashboard，整个过程电脑都是断网的（不知道和配置有没有关系），两个节点都修改nova配置文件，将libvirt类型修改为qemu并重启所有与openstack有关的所有组件：systemctl restart openstack*  至此云主机主要基础配置全部完成（这里配置成功是因为使用了正确配置的chrony.conf镜像）



真正原因是chrony.conf配置错误，controller和compute配置的应该是

server controller iburst

allow 192.168.100.0/24

和server controller iburst
















# 10/6
## 报错:无效的服务目录：network
Selinux配置为permis模式
不知道为什么平台又搭建成功了，报错也解决了
与之前操作有所不同的是我把selinux设置为permissive模式，在两个节点执行了systemctl start chronyd和systemctl enable chronyd,搭建过程中电脑全程联外网,
两台主机的时间同步是很重要的，偏差较大会直接影响平台的搭建

修改nova.conf文件的虚拟化类型似乎没必要？因为我上传的镜像的的硬盘格式和容器格式是qcow2和bare，这两者貌似都是被虚拟化类型kvm所支持的，我把搭建好的云主机虚拟化类型改回了kvm，并重启了openstack相关所有服务，结果是并没有影响，不过也有可能是因为这台云主机已经完成了第一次启动？我懒得从头再搭一遍了，以后再说吧(后续补充：确实没有影响，不需要把虚拟化类型修改为qemu)










# 10/11

放弃centos7.9改用7.5

7.5还是在compute安装iaas-pre。。。的时候报错时间服务无法启动

至少因为lib版本原因的报错解决了(经后续排查可知时间服务无法启动的原因是因为重复配置了时间服务配置文件参数，与镜像版本无关，由此可知先电openstack2.4适配的centos版本是7.5版本，2.2好像是7.2版本，但感觉主要还是看内核版本







# 12/10
##报错：新云主机创建失败：找不到有效主机

懒得截图了
初步排错认为是计算节点资源不足导致，尝试添加一个新计算节点

openstack compute service list --service nova-compute

该命令用于在控制节点获取计算节点的主机名和服务ID

确实是计算资源不够用，添加新计算节点后解决了报错

解决过程：和普通的计算节点一样的配置，把先电的环境配置文件参数修改为对应节点就行，用上面的命令查看计算节点状态，openstack compute service set --enable 计算节点主机名 nova-compute

如果计算节点没有启用的话尝试使用这条命令




## 搭建ceph

三个节点

Node1，2，3

全部配置免密ssh和主机映射，yum源采用ftp使用controller的本地源

先电2.4没有ceph-deploy，node1新增阿里ceph源

ceph-deploy install --no-adjust-repos ceph-node1 ceph-node2 ceph-node3

在为三个节点安装ceph时，遇到报错无法下载密钥文件，通过添加--no-adjust-repos参数跳过了密钥下载，不知道有没有影响

出现此报错多半是yum源地址有问题

Ceph安装错了位置，全部重置









# 10/15

## 关于 controller 和 compute 节点在安装完脚本后时间服务器无法启动

报错： Job for chronyd.service failed because the control process exited with error code. See "systemctl status chronyd.service" and "journalctl -xe" for details.

解决方案： 使用系统给出的提示使用 journalctl -xe（这个命令将显示扩展的系统日志，包括最近的错误和警告信息）并使用管道与 grep 结合筛选出与 chronyd 相关的日志信息，结果如图：

![[_resources/linux笔记/01636d741ab699a12996cde9498ad736_MD5.png]]

在 chronyd[814] 第二条可以看到，是 chrony.conf 文件第七行的配置出现错误，系统无法解析该指令，打开 chrony.conf 文件可以看到第七行的 server controller iburst 被重复了一遍：

Server controller iburst server controller iburst

删除掉重复的那一句后报错成功解决

报错原因： 在编辑先电 /etc/xiandian/openrc.sh 脚本的时候有一栏 chrony 时钟服务器的配置，由于我在刷脚本前早已配置完时间服务器相关配置，所以在刷脚本时又给 chrony.conf 文件又配置了一次，导致指令错误，无法被系统识别

///////////////////////////////////////

关于两个节点成功配置了时间服务器却无法时间同步：

报错原因： 两个节点所使用的时区不同

解决方案： timedatectl 可以查看当前时间具体信息，包括时区等，使用 timedatectl list-timezones 列出所有可选时区，使用 timedatectl set-timezone 时区名 来修改时区，建议使用 UTC（全称为协调世界时（Coordinated Universal Time），是一种基于原子时的时间标准，它被设计为与地球自转时间（世界时1）基本一致。UTC 不受地理区域的限制，是一个全球性的时间标准，用于全球各地的官方时间。

UTC 本身不是一个时区，而是一个时间标准，但所有的时区都是相对于 UTC 来定义的。UTC 通常被用作参考点，以“UTC偏移量”的形式来表示不同时区的时间）

/////////////////////////////////////////

自己尝试编写了一个 ceph 的 repo 文件

[ceph]

name=Ceph

baseurl=https://mirrors.aliyun.com/ceph/rpm-octopus/el7/x86_64/

enabled=1

gpgcheck=1

gpgkey=https://download.ceph.com/keys/release.asc

使用 rpm --import https://mirrors.aliyun.com/ceph/keys/release.asc 导入 ceph 的 gpg 密钥,前提是先用 curl 下载密钥文件

















# 10/16

## ceph源配置的官方repo文件

[Ceph]

name=Ceph packages for $basearch

baseurl=[http://download.ceph.com/rpm-nautilus/el7/$basearch](http://download.ceph.com/rpm-nautilus/el7/$basearch)

enabled=1

gpgcheck=1

type=rpm-md

gpgkey=[https://download.ceph.com/keys/release.asc](https://download.ceph.com/keys/release.asc)

priority=1

[Ceph-noarch]

name=Ceph noarch packages

baseurl=[http://download.ceph.com/rpm-nautilus/el7/noarch](http://download.ceph.com/rpm-nautilus/el7/noarch)

enabled=1

gpgcheck=1

type=rpm-md

gpgkey=[https://download.ceph.com/keys/release.asc](https://download.ceph.com/keys/release.asc)

priority=1

[ceph-source]

name=Ceph source packages

baseurl=[http://download.ceph.com/rpm-nautilus/el7/SRPMS](http://download.ceph.com/rpm-nautilus/el7/SRPMS)

enabled=1

gpgcheck=1

type=rpm-md

gpgkey=[https://download.ceph.com/keys/release.asc](https://download.ceph.com/keys/release.asc)

priority=1

但是网络连接很差，修改为阿里云的ceph源，[即将配置文件中出现的download.ceph.com全部修改为mirrors.aliyun.com/ceph即可](https://www.google.com/search?q=https://%E5%8D%B3%E5%B0%86%E9%85%8D%E7%BD%AE%E6%96%87%E4%BB%B6%E4%B8%AD%E5%87%BA%E7%8E%B0%E7%9A%84download.ceph.com%E5%85%A8%E9%83%A8%E4%BF%AE%E6%94%B9%E4%B8%BAmirrors.aliyun.com/ceph%E5%8D%B3%E5%8F%AF)

执行yum -y install ceph ceph-radosgw遇到的报错

![[_resources/linux笔记/783df5932e4e96aac58bce37adddb368_MD5.png]]

报错原因是阿里云提供的centos源的epel仓库源配置有问题，导致无法启用

解决方案：手动添加一个epel源，这里在阿里云找到了epel源Wget -O /etc/yum.repos.d/epel.repo [https://mirrors.aliyun.com/repo/epel-7.repo](https://mirrors.aliyun.com/repo/epel-7.repo)





# 10/17

受主机内存和云平台资源限制，从云主机改用为VM虚拟机

//////////////////////////////////////

关于ceph-deploy new报错

![[_resources/linux笔记/809b3e0389f8e2463704220d5b877df3_MD5.png]]

报错原因：ceph-deploy 工具在尝试启动时遇到了问题。具体来说，是在尝试导入 pkg_resources 模块时出错了。这个模块是 setuptools 包的一部分，在 Python 中用于包管理和资源获取，即没有安装setuptools

解决方案：yum install -y python-setuptools

创建pool命令
ceph osd pool create <pool名> <pg值> <pg备份值>








# 10/19

## 关于数据库调优-my.cnf配置详解

![[_resources/linux笔记/7a3e8731c537b0aa65c421cbd92242ef_MD5.png]]

lower_case_table_names =1 //数据库支持大小写
innodb_buffer_pool_size = 4G //设置数据库缓存（缓冲区）大小为4G innodb_log_buffer_size = 64MB //设置数据库的log buffer即redo日志缓冲为64MB 
innodb_log_file_size = 256MB //设置数据库的redo log即redo日志大小为256MB 
innodb_log_files_in_group = 2 //数据库的redo log文件组即redo日志的个数配置为2

systemctl restart mariadb










# 10/20

## 关于openstack组件调优

在平时使用OpenStack平台的时候，当同时启动大量虚拟机时，会出现排队现象，导致虚拟机启动超时从而获取不到IP地址而报错失败，请使用自行搭建的OpenStack平台。修改nova相关配置文件，使 虚拟机可以在启动完成后获取IP地址，不会因为超时而报错。

vim /etc/nova/nova.conf

找到如下这行

vif_plugging_is_fatal=true

将改行的注释去掉，并将true改为false，修改完之后如下：

vif_plugging_is_fatal=false

保存退出nova.conf，最后重启nova服务，也可以重启所有服务

openstack-service restart

//////////////////////////////////////////////////////////////////////

使用自行搭建的OpenStack私有云平台，优化KVM的I/O调度算法，将默认的模式修改为none模式。

必须用云主机优化，因为虚拟机没有none模式

查看当前使用的调度算法

cat /sys/block/vda/queue/scheduler

kyber none

可以看到当前的I/O调度算法mq-deadline，如果当前全是用的SSD硬盘，那么是显然none算法更合适，修改算法为none

echo none > /sys/block/vda/queue/scheduler

cat /sys/block/vda/queue/scheduler

mq-deadline kyber

可以看到当前的I/O调度算法为none模式

////////////////////////////////////////////////////////////////////////

Linux 服务器大并发时，往往需要预先调优 Linux 参数。默认情况下，Linux 最大文件 句柄数为 1024 个。当你的服务器在大并发达到极限时，就会报出“too many open files”。 创建一台云主机，修改相关配置，将控制节点的最大文件句柄数永久修改为 65535。

永久生效

cat /etc/security/limits.conf
soft nofile 65535   
hard nofile 65535

注：_指所有用户及组，若单指某一用户或某一组，可将_更改为username或@groupname来指定某一用户或组



echo "000000"| passwd --stdin root

可以避免passwd的交互界面直接设定密码














# 10/26

改用了centos7.9做实验

虚拟机ping不通外网，为8号虚拟网卡配置了静态ip解决了问题

还是报了一个老报错，安装neutron时的libxslt-1.1.28-6.el7.x86_64版本问题

好消息是compute节点也报了这个错，以前没有过

云平台报错了：错误：Invalid service catalog service: compute







# 10/27

由于compute节点也报了lib的版本错误，而此时controller节点的neutron服务已经部署完毕，或许该尝试两个节点同步部署nova服务并更改lib版本，但还是感觉问题出在neutron的几种网络模式的选择上

在使用openstack指令时报错

![[_resources/linux笔记/c9c64d62cd96874445eea152f3d1ae2f_MD5.png]]

提示需要生效环境变量

即source生效/etc/xiandian/openrc.sh和/etc/keystone/admin-openrc.sh 两个脚本

解决了，原因是服务重复了，删除一个就好，类似的报错都可以从这方面入手

总结一下

云平台报错：错误：Invalid service catalog service: identity

解决方案：openstack service list发现keystone（也就是identity）重复出现，使用openstack service delete 加对应ID删除重复服务并systemctl restart httpd.service memcached.service重启服务

报错原因：重复安装了keystone，由此可知关于lib版本的报错解决并不仅仅是卸载重装这么简单，还需要删除掉对应的多余服务，貌似先电2.2无法识别多余且不可用的服务，2.4没有发现

搭建成功了，关于neutron的网络模式还是需要研究一下










# 10/30

## 关于在创建实例时会报错无可用域

这种情况属于是compute节点服务未启动

glance上传的镜像一般储存在/var/lib/glance/images/目录下

在使用glance上传镜像时--file参数也可用反向重定向符‘<’代替

端口和端点

在计算机网络中，“端点”（endpoint）和“端口”（port）是两个相关但不同的概念：

端口（Port）：

端口是网络通信中用于区分不同服务或进程的逻辑概念。在TCP/IP协议栈中，端口号是一个16位的数字，其取值范围从0到65535。

端口号用于识别主机上的特定进程或网络服务，例如，HTTP服务通常监听端口80，而HTTPS服务监听端口443。

在网络通信中，端口号与IP地址结合使用，以确保数据能够正确地发送到目标主机上的特定服务。

端点（Endpoint）：

端点指的是网络中通信的起点和终点。在实际应用中，端点可以是一个设备（如计算机、手机、服务器等）、一个网络接口，或者是运行在设备上的一个应用程序。

端点不仅包括端口号，还包括设备的IP地址，有时甚至包括传输层协议（如TCP或UDP）。因此，端点提供了一个完整的网络通信路径，用于标识和定位网络中的特定通信实体。

例如，一个完整的端点可以表示为 <IP地址>:<端口号>，如 192.168.1.100:8080，其中 192.168.1.100 是IP地址，8080 是端口号。

总结来说，端口是端点的一部分，用于区分同一设备上的不同服务，而端点是一个更广泛的概念，包括了IP地址和端口号，用于在网络中唯一标识一个通信实体。端口号是端点地址的一部分，端点地址则包含了IP地址和端口号，有时还包括协议类型。





## 关于openstack各组件功能细分

OpenStack是一个由多个组件组成的开源云计算平台，每个组件负责处理特定的任务。以下是一些主要OpenStack组件及其子组件的细分：

Nova（计算）：

```
1. nova-api：处理API请求。
2. nova-scheduler：负责虚拟机实例的调度。
3. nova-conductor：轻量级服务，处理一些数据库操作。
4. nova-compute：负责管理虚拟机实例的生命周期。
5. nova-consoleauth：处理VNC控制台的认证。
6. nova-novncproxy：处理VNC控制台访问的代理。
```

Neutron（网络）：

```
1. neutron-server：处理网络服务的API请求。
2. neutron-agent：包括多种类型的代理，如l3-agent、dhcp-agent、metadata-agent等，负责网络配置和管理。
```

Cinder（块存储）：

```
1. cinder-api：处理块存储API请求。
2. cinder-scheduler：负责卷的调度。
3. cinder-volume：负责管理后端存储，处理卷的创建、删除和附加等操作。
```


Swift（对象存储）：

```
1. swift-proxy：处理客户端请求和转发到存储节点。
2. swift-account、swift-container、swift-object：存储节点服务，分别管理账户、容器和对象。
```

Keystone（身份服务）：

```
1. keystone：提供身份认证、令牌生成和管理服务。
```


Glance（镜像服务）：

```
1. glance-api：处理镜像服务的API请求。
2. glance-registry：管理镜像元数据。
```


Heat（编排）：

```
1. heat-api：处理编排服务的API请求。
2. heat-api-cfn：处理AWS CloudFormation模板。
3. heat-engine：负责执行堆栈操作。
```

Ceilometer（计费和监控）：

```
1. ceilometer-api：提供监控数据的API接口。
2. ceilometer-collector：负责收集监控数据。
3. ceilometer-agent：运行在计算节点上，收集和上报实例的监控数据。
```

Horizon（Dashboard）：

```
1. horizon：OpenStack的Web界面，提供用户界面访问OpenStack服务。
```

Ironic（裸机服务）：

```
1. ironic-api：处理裸机服务的API请求。
2. ironic-conductor：负责管理裸机硬件的生命周期。
```

这些是OpenStack中一些主要组件及其子组件的细分。每个组件都有其特定的职责，它们协同工作以提供完整的云计算服务。随着OpenStack的不断发展，可能会有新的组件和服务被引入。









# 11/2

## 开始学习Docker

Docker pull的源需要更改，好像要注册一个阿里云镜像站的账号，如果想使用阿里云镜像源的话

关于docker pull的源配置在/etc/docker/daemon.json文件里，配置完成后使用systemctl daemon-reload和systemctl restart docker后使用docker info可以查看源信息





# 11/3

## 国内的docker可用镜像源

"[https://docker.m.daocloud.io](https://docker.m.daocloud.io)",

"[https://noohub.ru](https://noohub.ru)",

"[https://huecker.io](https://huecker.io)",

"[https://dockerhub.timeweb.cloud](https://dockerhub.timeweb.cloud)",

"[https://docker.rainbond.cc](https://docker.rainbond.cc)"



## 报错：访问容器tomcat时网页404

报错原因：使用的tomcat镜像默认是最小的镜像，它把所有不必要的都剔除掉了。保证最小可运行的环境。

解决方案：在tomcat目录下有一个webapps.dist目录，这个目录下有所需要的文件，也就是webapps目录所需要的文件，将这个文件中的内容全部拷贝到webapps下。

即执行cp -r webapps.dist/* webapps命令

Docker镜像都是只读的，当容器启动时，一个新的可写层被加载到镜像的顶部，这一次就是我们通常说的容器层，容器之下的都叫镜像层。

（此处知识点涉及到UnionFS（联合文件系统））




# 11/12

## 查看函数库依赖

不同的文件执行起来有不同的函数库依赖，这些函数库通常保存在lib64目录下，可使用ldd命令查看相关的依赖

例：![[_resources/linux笔记/944a6e02d4ce24ebf02f5b2f3ca1e114_MD5.png]]

想要使用bash则需要确保拥有lib下的各个函数库文件

没有依赖库但想要使用bash则会报错如下

![[_resources/linux笔记/87727257087262a186f7eebb6995744f_MD5.png]]

/////////////////////////////////////////////////////////////////////////////////////////

Linux内核支持两个功能，与容器技术的实现有关![[_resources/linux笔记/3b85d5e8cae5347d129ebc2f31c83d82_MD5.png]]![[_resources/linux笔记/da20e5f18dfa2c93587542109c98d9f3_MD5.png]]

////////////////////////////////////////////////////////////////////////////////////////////////

## 关于docker命令补全问题

默认是无法补全的，但可以通过以下命令实现

yum install -y bash-completion

source /usr/share/bash-completion/bash_completion










# 11/14
## docker基础操作
![[_resources/linux笔记/980d7f13d37fe9f7c8c54cb6f58d42b0_MD5.png]]

![[_resources/linux笔记/1ef38c4dc170e22e61598a8ebb9ded8c_MD5.png]]

////////////////////////////////////////////////////////////////////////////////////

## 关于命令别名的设置
以docker为例

![[_resources/linux笔记/55b91cf1ca8373b5e6b33246b327e1f7_MD5.png]]











# 11/15
## docker重启策略
![[_resources/linux笔记/748481c4d7486e57390d4e2d6bc72716_MD5.png]]

注：该图是关于docker container run --restart命令的策略参数

在模拟容器异常退出时可使用pstree -p 查看进程树及对应pid（centos7.5没有安装该命令，执行yum install -y psmisc)以杀死指定容器进程，该命令之所以能够模拟容器异常退出是因为该命令属于宿主机指令干预，而非容器内部指令操作









# 11/19
## ip a 回显解析

ip a显示的网卡名中@左右的名称表示两个网卡之间有关联，以容器为例




## 关于docker容器的五种网络模式及其解析

![[_resources/linux笔记/06fa053890ac3a042bc04e540bf4bba0_MD5.png]]

![[_resources/linux笔记/7aec3570ad6c6c00e111637a90f7b172_MD5.png]]

![[_resources/linux笔记/9509aa2a3a3b7ae049504f49d4a0a50d_MD5.png]]

![[_resources/linux笔记/7f020773142aaa0ac61b9f0796d39729_MD5.png]]

![[_resources/linux笔记/f26491c8e5c187be7a4f7af11b8ea515_MD5.png]]

## 关于docker私有仓库在push时报错：需要使用https协议
如下图
在daemon.json配置文件中"insecure-registries":是指采用http协议来进行镜像的上传与下载

![[_resources/linux笔记/3e9aa21c7c4497c1d9885b76d893a456_MD5.png]]

Registry仓库指定的挂载卷位置与端口：/var/lib/registry 5000













# 11/20

## 关于容器部署mysql

可参考以下指令格式

docker run -d -p 3310:3306 -v /home/mysql/conf:/etc/mysql/conf.d -v /home/mysql/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --name mysql01 mysql:5.7

////////////////////////////////////////////////////////////////////////////////

目前对构建上下文的理解是对所构建的容器所处的环境的打包

数据卷的挂载默认是以读写的方式

可指定挂载方式，例如在容器被挂载的目录后面加:ro 即只读 :rw 可读写(默认)

若要创建一个容器，指定它的数据卷挂载与另一容器一致（即与另一容器共享数据卷），则需要’ --volumes-from 被共享的容器名 ’ 参数来实现











# 11/21

## 关于dockerfile命令解析

![[_resources/linux笔记/ac715b24bf24720805fd9d0f147f733a_MD5.png]]

![[_resources/linux笔记/8a27da6bfff71225f0dfa133b6b71859_MD5.png]]








# 11/26

## 关于docker容器编排工具docker compose

Compose v2

目前 Docker 官方用 GO 语言 重写 了 Docker Compose，并将其作为了 docker cli 的子命令，称为 Compose V2。你可以参照官方文档安装，然后将熟悉的 docker-compose 命令替换为 docker compose，即可使用 Docker Compose。

截止至2024/9/29的centos7,docker-compose指令的使用需要手动安装docker compose










# 11/27

在docker-compose.yml文件的编写中,build参数的使用对象，也就是构建环境中的构建镜像所用文件要严格遵守dockerfile命名规范，即只能将其命名为D(d)ockerfile，否则在构建过程中会因为找不到该文件而报错

另外在docker compose config的使用中，config后面在没有追加选项的情况下，应当填写docker-compose.file文件所处环境（即所处目录），docker-compose的容器编排配置文件也应当固定为dockers-compose.yml

这两点存疑，可能是因为构建上下文或版本的问题，又或者是在没有指定文件名的情况下会遵循这个规则












# 11/28

## 关于sed命令

-i参数：

sed命令对文件内容的增删改查都是在内存空间中进行的，并不直接影响到文件内容，若想实现对文件内容的直接修改需要加上-i参数

-n参数：

由于sed命令的默认机制，即使某行文本未被匹配，也会被打印到终端上，因此在不想显示不匹配文本内容时，需要-n参数来取消sed命令的默认输出




## 关于正则表达式

.

表示匹配任意的单个字符，可以与 * 搭配为 .* 表示匹配任意的多个任意字符

例如可以用正则表达式 ^.*hhh 来表示以任意的多个任意字符开头且以hhh结尾的字符串

&

用例： /^hhh/@&/ 此处&的作用是指代前文中^后的匹配字符串hhh，这个正则的作用是将以hhh开头的字符串的hhh更改为了@hhh，总之就是&具有指代’匹配字符串’的作用

\

转义字符

&和\的示例(以sed命令示例)

![[_resources/linux笔记/215f862977ebe34f865d059a684c4d22_MD5.png]]




## 关于ipvs

启动ipvs的要求：

k8s版本 >= v1.11

使用ipvs需要安装相应的工具来处理”yum install ipset ipvsadm -y“

确保 ipvs已经加载内核模块， ip_vs、ip_vs_rr、ip_vs_wrr、ip_vs_sh、

nf_conntrack_ipv4。如果这些内核模块不加载，当kube-proxy启动后，会退回到iptables模式。

yum -y install epel-release







# 11/30

## k8s在1.24版本不原生支持docker

K8s三个组件kubeadm kubectl kubelet还有k8s使用的版本都是1.14.1，docker安装的版本是18.09.6










## 关于命令替换

用来重组命令行，先完成引号里的命令行，然后将其结果替换出来，再重组成新的命令行

shell中命令替换符有两种 与 $()

反单引号适用于任何类unix平台，他的适用性比较高。$符号却不是。





## 关于linux常用的系统环境变量

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








# 12/3

## k8s提示certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")

原因：这是在重新创建集群之前，原来集群的rm -rf $HOME/.kube文件没有删除，所以导致了认证失去作用。

![[_resources/linux笔记/71995472fa51dff02d4369e65b179492_MD5.png]]

解决方法1：

1、删除这个路径下的文件

rm -rf $HOME/.kube

2、重新执行命令

mkdir -p $HOME/.kube

sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config

sudo chown (id−u):(id -g) $HOME/.kube/config

3、重新查看节点

[root@master ~]# kubectl get nodes

解决方法2：

echo export KUBECONFIG=/etc/kubernetes/kubelet.conf >> ~/.bashrc

source ~/.bashrc

另外，以下报错也是出于该原因

![[_resources/linux笔记/b1265d27c6c54feb86ad6fc6dc4d1acc_MD5.png]]

火狐浏览器的K8s网页乱码，用本地服务器的chrome浏览器解决了问题









# 12/5

## 关于awk命令

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












# 12/6

## 关于echo $PATH的回显释义

![[_resources/linux笔记/91238653c6e8e6603e279c474409f9ab_MD5.png]]

////////////////////////////////////////////////////////////////////////

在github上找到了kubeeasy的命令文件kubeeasy-v1.3.0，将它移动到了/usr/bin目录下添加可执行权限并删除了版本号以供执行，不删版本号的话命令行就变成kubeeasy-v1.3.0了,命令行这个说法有失偏颇，在一切皆文件的linux中，它应该叫可执行文件。关于这个可联想到斗学网教程上iptables在写完规则后也是执行了/usr/sbin/iptables-save这个文件来保存配置信息，也就是说不加这个可执行文件的路径，单输入一个iptables-save ，shell也能够找到这个文件并执行

Kubeeasy本地保留了一份在D:\云计算技能大赛\镜像资源







## 关于yum命令

yum 解决依赖关系问题，自动下载软件包。yum是基于C/S架构，像ftp，http，file一样；关于yum为什么能解决依赖关系：所有的Yum 源里面都有repodata，它里面是有XML格式文件，里面有说明需要什么包。

yum install --downloadonly --downloaddir=/xx/xxx/xx/
只下载软件但不安装
有时候需要将高版本的依赖降级到低版本，降级命令如下
yum downgrade <package_name> 
降级，对于有依赖的，yum不会自动降级，需要手动降级依赖项





## Linux-headers的安装

sudo yum -y install kernel-headers //安装kernel-headers

sudo yum -y install kernel-devel //安装kernel-devel











# 12/7

docker-compose和Helm的安装部署嵌套在Harbor安装部署包内，安装Harbor的同时，也安装了docker-compose以及Helm

/////////////////////////////////////////////////////////////////////////////

## 关于namespance分类 
![[_resources/linux笔记/21d6eb1b235d93b35c05bff409736782_MD5.png]]







# 12/8

## 关于centos7虚拟机强制重启后无法因无法挂载到系统而进入紧急模式

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




## 关于dm

dm是Device Mapper的缩写，Device Mapper 是 Linux 2.6 内核中提供的一种从逻辑设备到物理设备的映射框架机制，在该机制下，用户可以很方便的根据自己的需要制定实现存储资源的管理策略，当前比较流行的 Linux 下的逻辑卷管理器如 LVM2（Linux Volume Manager 2 version)、EVMS(Enterprise Volume Management System)、dmraid(Device Mapper Raid Tool)等都是基于该机制实现的。

dm-0 对应LVM的 VolGroup00-LogVol00 对应根目录/

dm-1 对应LVM的 VolGroup00-LogVol01 对应swap

参考文章：linux dm-0 dm-1 设备映射 简介-CSDN博客 ([https://blog.csdn.net/whatday/article/details/106354092](https://blog.csdn.net/whatday/article/details/106354092))

## docker containerd.io

是Docker容器运行时的核心组件之一，它负责管理和运行容器。它提供了容器的生命周期管理、镜像管理、网络管理等功能







## 关于K8S的命名空间

命名空间namespace是K8S中“组”的概念，提供同一服务的Pod应该被放置同一命名空间下，而不是混杂在一起。K8S可以用命名空间来做权限控制和资源隔离。如果不指定的话，Pod将被放置在默认的命名空间default下。





## 关于kubectl get

kubectl get可以列出K8S中所有资源，还可以使用别的参数获取其它资源列表信息，如get svc（查看服务）、get rs（查看副本控制器）、get deploy（查看部署）等。

如果想要查看更多信息，指定-o wide参数即可，语法如下：

kubectl get <资源> -n <命名空间> -o wide

加上这个参数之后就可以看到资源的IP和所在节点。


在kubeeasy部署过程中通过查看日志来跟踪k8s安装进度

tail -f /var/log/kubeinstall.log










# 12/9

## 关于kubectl命令行的补全

与docker一样，都需要安装bash-completion

source <(kubectl completion bash)

在bash中设置当前shell的自动补全，要先安装bash-completion包。

echo "source <(kubectl completion bash)" >> ~/.bashrc




## 关于kubectl管理pod

注意：如果不指定-n 命名空间，会默认查看default命名空间里的pod，创建pod的时候不指定命名空间，只会将pod创建在default命名空间里

在查看pod时可以使用参数查看kubectl get pod --show-labels=true它的标签，该参数在kubectl get --help能够查到，不过是--show-labels=flase的形式 ，因为它旨在表明kubectl get pod这条命令默认是隐藏标签的，所以当使用该参数时要把flase改成true

该命令可以与kubectl describe po -l 结合使用，因为使用这个命令查看pod具体信息时需要指定它的标签




## 关于namespace自动注入sidecar

Istio 作为重要的 ServiceMesh 框架，已经被越来越多的公司所使用。在 Istio 体系中，应用容器的出入流量都需要经过 Sidecar 的拦截和处理。默认地，Istio sidecar 自动注入是通过给 namespace 打 istio-injection=enabled 或 istio-injection=disabled 标签，来确定是否在该命名空间执行自动注入。

示例：kubectl label ns exam istio-injection=enabled

注：ns是指代命名空间，在kubectl create ns中也是这个作用，该命名空间名字叫exam




## 关于helm

Helm 的 Release 是 Helm 这个 Kubernetes 包管理工具的概念，而不是 Kubernetes 自身的概念。

Helm Release：

在 Helm 中，一个 Release 是指一个包（Chart）的单个部署实例。当你使用 Helm 安装一个 Chart 时，Helm 会创建一个 Release 来跟踪这个部署的状态和历史。

每个 Release 都有一个唯一的标识符，通常是一个名字和一个版本号。

Release 包含了 Chart 的配置信息、部署的 Kubernetes 资源对象以及部署过程中的状态信息。

你可以对同一个 Chart 创建多个 Release，每个 Release 可以有不同的配置和升级历史。






## 关于k8s各组件版本问题 [https://github.com/kubernetes/kubernetes/blob/v1.22.1/build/dependencies.yaml](https://github.com/kubernetes/kubernetes/blob/v1.22.1/build/dependencies.yaml)

将该链接的版本号那一栏改为想要查询的k8s版本从而查看对应的组件版本信息














# 12/10
systemctl enable --now containerd # enable --now 等于 enable + start

FTP服务器vsftpd的默认根目录(/var/ftp/pub)

http的安装包是httpd，配置文件在/etc/httpd/conf/httpd.conf，若要修改默认访问目录，则需要将119和131行的目录修改为指定目录即可









# 11/12

## 关于缺少br_netfilter模块

![[_resources/linux笔记/aedaa60f7fd1b1bdc2504d549bd805d7_MD5.png]]

使用的是7.2镜像

解决方案：

yum install bridge-utils -y

echo br_netfilter > /etc/modules-load.d/br_netfilter.conf

reboot

modprobe br_netfilter













# 12/12

## 关于Harbor

Harbor介绍

（一）Harbor镜像仓库简介

Harbor是由VMware公司开源的企业级的Docker Registry管理项目，Harbor主要提供Dcoker Registry管理UI，提供的功能包括：基于角色访问的控制权限管理(RBAC)、AD/LDAP集成、日志审核、管理界面、自我注册、镜像复制和中文支持等。Harbor的目标是帮助用户迅速搭建一个企业级的Docker registry服务。它以Docker公司开源的registry为基础。

Harbor除了提供友好的Web UI界面，角色和用户权限管理，用户操作审计等功能外，它还整合了K8s的插件(Add-ons)仓库，即Helm通过chart方式下载、管理、安装K8S插件，而chartmuseum可以提供存储chart数据的仓库。

注:helm就相当于k8s的yum



在23版本，docker-compose被插件化作为docker的一部分，也就是说在安装23及以后版本的docker时，也一并安装了docker-compose






## 关于yum本地安装

yum -y localinstall

后面跟rpm安装包名，例：

yum -y localinstall dir/*.rpm

指定安装了该文件夹下所有的rpm包





## 关于tar命令指定解压位置

tar xf xxx.tgz -C /dir/

才发现我一直搞错了，tar 命令的-C 不是指定目录

-C 的唯一意思就是：“在执行下一步操作之前，先切换（Change）目录”。

（2025/11/16）





# 12/15

## 关于vim搜索指定字符串和指定多行注释

在命令模式下（默认进入vim时就是命令模式，shift加：是末行模式）按下/可以进入搜索模式，输入指定字符串并回车进行查找，按下n跳转到下一个匹配字符串

指定多行注释是在末行模式中进行，格式是 起始行号,结束行号s/^/#/g









# 12/17

## 关于dockerfile构建上下文

编写dockerfile时在写宿主机文件路径时需要注意构建上下文问题，例

docker build -t tag:6 -f /path/Dockerfile .

在这里指定了构建上下文为当前目录环境，则在编写dockerfile时书写宿主机文件路径时需要使用相对路径且文件与dockerfile处于同一文件夹（？），例如在COPY的使用上





## 关于docker容器保留前台进程以维持容器运行

由于容器会检测内部pid为1的进程是否存在而判断容器是否在运行，所以为保持容器正常运行，需要指定一个前台进程。

主要是在dockerfile中指定容器运行后执行命令的CMD,一般该参数用于创建一个前台进程，例如在memcached（内存缓存数据库）的dockefile编写中，最后一条CMD是memcached -u root来创建该容器的前台进程(#使用root用户前台启动memcached)





## 关于不进入数据库命令行界面而实现交互

可参考该命令mysql -uroot -proot -e " create database djangoblog;"

另外还可以直接进入指定数据库mysql -uroot -proot djangoblog








# 12/18
## 关于mariadb的容器化部署

mysql -uroot -proot -e "grant all privileges on _._ to root@'%' identified by 'root';"

这条SQL命令的作用是授予root用户远程连接数据库的权限。具体来说，这个命令做了以下几件事情：

grant all privileges on _._：这部分指定了授权的范围和权限级别。*.*代表所有数据库和表，all privileges表示授予所有可能的权限，包括SELECT、INSERT、UPDATE、DELETE、CREATE、DROP等。

to root@'%'：这部分指定了授权的用户和其允许连接的主机。root是用户名，'%'表示从任何主机。这意味着任何主机上的root用户都将能够连接到MariaDB服务器。

identified by 'root'：这部分为root用户设置了密码，这里是'root'。

总的来说，这条命令允许任何主机上的root用户使用密码root连接到MariaDB服务器，并拥有对所有数据库和表的完全访问权限。

是为了其他容器能够连接

mysqld --user=root用于启动mysql作为容器中CMD的前台进程

关于nginx容器化部署

nginx -g "daemon off;"

这条命令会启动 Nginx，并且由于 daemon off; 的设置，Nginx 会保持在前台运行，而不是转到后台。用于nginx容器的CMD前台进程







## 关于Harbor仓库的私有仓库搭建

可以用注释相关配置实现免证书搭建
如果没有申请证书，需要隐藏https
https:
https port for harbor, default is 443
port: 443

同时可以与daemon.json的参数 "insecure-registries": ["0.0.0.0/0"]配合使用，该配置表示docker使用http协议访问任何镜像仓库位置









# 12/21

## 关于docker compose命令的路径要求

![[_resources/linux笔记/f1a0a333246e3f12c0ece763cd038c3c_MD5.png]]

在执行docker compose命令时要求当前目录下有docker-compose.yml这个文件，因为Docker Compose 需要一个 YAML 文件来定义服务、网络和卷等配置，这个文件通常以 docker-compose.yml 或 docker-compose.yaml 命名。







## 基于插入内核进程的直接生效流量转发

这个方法有意思，但非持久化
配置网络
echo 1 > /proc/sys/net/bridge/bridge-nf-call-iptables

echo 1 >/proc/sys/net/bridge/bridge-nf-call-ip6tables

echo """

vm.swappiness = 0

net.bridge.bridge-nf-call-iptables = 1

net.ipv4.ip_forward = 1

net.bridge.bridge-nf-call-ip6tables = 1

""" > /etc/sysctl.conf
加载配置
sysctl -p








# 12/22

## 关于kubeadm拉取镜像及初始化报错mageService" , error: exit status 1 To see the stack trace of this error execute with --v=5 or higher

![[_resources/linux笔记/254071198a2abdf0a9d4a9a1dbedd729_MD5.png]]

原因是containerd的配置文件写错了，在修改cgroup驱动时，将systemd_cgroup = false修改为了true，但实际上应该修改Systemd_cgroup = false为true，两者都存在于配置文件中，只是首字符大小写不一样，集群初始化也没再报错无法通信cri，但我没有执行crictl config runtime-point unix:///var/run/containerd/containerd.sock






## 关于k8s使用国内镜像源

![[_resources/linux笔记/26a11ad2910c607d57cc46cc4d688773_MD5.png]]

这里使用的是阿里云的镜像仓库





## 半本地部署k8s-v1.25.9集群总结

K8s镜像源在这里使用阿里云的镜像仓库，下一次使用harbor仓库实现本地拉取镜像，应该只是指定标签的问题，还有另一个更为简便的方法，就是用ctr创建一个命名空间名为k8s.io（ctr ns create k8s.io），再把需要的镜像导入进去（ctr -n k8s.io image import k8s/k8s-images.tar），由于镜像命名是aliyun的，所以在初始化时要指定阿里云镜像仓库（--image-repository [registry.aliyuncs.com/google_containers](https://www.google.com/search?q=https://registry.aliyuncs.com/google_containers)）离线包有harbor-offline-installer-v2.11.2.tgz k8s-1.25.9.tar.gz

1. 基础环境配置
    

解压两个安装包，配置阿里云的基础源和docker源（docker是非必须，镜像管理的功能被ctr代替了，但harbor部署还需要它，而基础源可以用7.9镜像代替，都可以实现本地部署），k8s的包解压后的配置文件都拷贝到对应位置

禁用防火墙和selinux，swap分区，配置流量转发，设置主机名映射，时间同步

/////////////////////////////////////////////////////

2.部署k8s

安装docker并修改cgroup驱动（docker理论上是非必须的，因为k8s在1.24就取消了docker作为容器运行时）,安装containerd和k8s三组件，生成containerd默认配置文件，修改沙盒指定版本，修改cgroup驱动（注:修改的是System开头的，注意首字母是否大写，且两者的位置也不一样)，设置cri，重启containerd和kubelet，至此的步骤两个节点都需要执行

然后在master节点开始初始化k8s集群，为节省部署时间，可以先拉取镜像kubeadm config images pull --kubernetes-version 1.25.9 --image-repository [registry.cn-hangzhou.aliyuncs.com/google_containers](https://www.google.com/search?q=https://registry.cn-hangzhou.aliyuncs.com/google_containers)，初始化完成后部署flannle网络，并在node节点执行加入命令，最后用kubectl get nodes 检查集群状态,后续的图形化部署由于是非必须所以暂时不指定

K8s初始化时会在命名空间中搜索是否有需要的本地镜像，找不到再去外网寻找，所以在k8s使用本地镜像时需要将镜像用ctr导入到命名空间中，因此猜想k8s从外网拉取镜像时也是先拉到命名空间中再使用的，而使用的镜像包可以用docker commit生成，ctr暂时不知道是使用什么命令生成

kubeadm config images list

使用这条命令可以查看初始化需要的镜像，然后也可以通过改标签的方式让k8s以为本地的镜像是官方镜像

kubeadm config images list --config kubeadm.conf查看初始化所需镜像





# 12/23

containerd 相比于docker , 多了namespace概念, 每个image和container 都会在各自的namespace下可见, 目前k8s会使用k8s.io 作为命名空间,因此在使用ctr命令时一般要使用-n参数指定命名空间

![[_resources/linux笔记/f2789c5a4edcd83ff6976d3bb2efef22_MD5.png]]



## 关于使用kubectl命令行创建网络报错8080端口或许被占用

![[_resources/linux笔记/77c7f534c0997bf20d15cb3d7a24a0bc_MD5.png]]

可能的原因是在完成集群初始化后没有将k8s的配置文件admin.conf拷贝到当前用户家目录下并更名为config，因为k8s要读取该配置文件




## 关于k8s的coredns一直处于创建中的状态

![[_resources/linux笔记/2bc2cf73efbe037270af208e41a03b20_MD5.png]]

使用kubectl describe pod coredns-c676cc86f-hfp7q -n kube-system查看详细信息发现缺少对应文件/run/flannel/subnet.env文件(该文件一般是自动生成的）

![[_resources/linux笔记/4af6d086348e0af5fe643310f1844485_MD5.png]]

于是手动创建一个，配置如下

![[_resources/linux笔记/5f193d69cfb466b4150dd3ce2279131c_MD5.png]]

对应的集群初始化时指定的参数--pod-network-cidr 192.168.0.0/16

再次查看pod状态

![[_resources/linux笔记/688a26357a93a290dd6929cce72bfbe0_MD5.png]]

成功运行





## 关于flannel的运行状态

日志信息原图找不回了，大概意思是某个ip加端口ping不通，发现是防火墙没关

而后又有新的报错

![[_resources/linux笔记/9fb0923404b84d4ce394295521861ed6_MD5.png]]

经Al解析得知是因为找不到名为eth0的接口，因为本地的网卡名为ens33，在kube-flannel.yml配置文件中将iface=eth0参数修改为iface=ens33（不修改的话也可以仿openstack搭建前在虚拟机开机时添加参数net.ifnames=0 devbiosname=0,将网卡设置为eth0），且该配置文件中的另一个参数Network要指定为集群初始化时--pod-network-cidr的参数

而后kubeadm reset

再重启配置flannel网络

至此成功搭建了一个完整可用的k8s集群

![[_resources/linux笔记/11c6ee141827d60d80dcb69fe6d3485c_MD5.png]]

![[_resources/linux笔记/dce208538ddc7ad50aca9a7b05cd167a_MD5.png]]







## k8s本地部署总结

Docker-ce和docker-compose，containerd的安装，Harbor仓库的部署，k8s的搭建，黑体为两个节点都需要配置，红体为master节点，蓝体为node节点所需配置

基础环境的配置

//////////////////////////////////////////////////////////////////

防火墙，selinux，swap分区禁用，基础yum源和docker源的配置，设置主机名映射，配置时间同步，开启路由转发和ipvs所需模块的加载（因为flannel需要调用这些内核模块），安装docker，containerd等，修改docker的cgroup驱动为systemd，配置docker镜像拉取使用协议支持http，修改containerd的沙盒为指定的镜像，启用Systemd作为cgroup驱动

Harbor仓库的搭建

/////////////////////////////////////////////////////////

修改harbor仓库的配置文件，建议端口修改为5000，禁用https协议，做好后用prepare脚本检查，而后使用安装脚本部署Harbor仓库

K8s集群初始化

/////////////////////////////////////////////////////////////

用ctr导入k8s初始化所需镜像到k8s.io命名空间中，而后开始集群的初始化，因为给出的镜像是打了aliyun网址的标签，[所以要指定镜像拉取网址为registry.aliyuncs.com/google_containerd](https://www.google.com/search?q=https://%E6%89%80%E4%BB%A5%E8%A6%81%E6%8C%87%E5%AE%9A%E9%95%9C%E5%83%8F%E6%8B%89%E5%8F%96%E7%BD%91%E5%9D%80%E4%B8%BAregistry.aliyuncs.com/google_containerd) ,即使这个网址不可用，初始化完成后在当前用户家目录下创建.kube目录，并将k8s的配置文件admin.conf移动到该目录更名为conf，而后node节点加入集群，修改kube-flannel.yml配置文件，修改Network的参数为初始化时--pod-network-cidr所指定的参数，还要修改iface的参数为本地的网卡名，由于本地主机只有一张名为ens33的网卡，则将默认的eth0修改为ens33，/run/flannel/subnet.env文件有时不会自动生成（操作顺序正确的话，该文件是会自动生成的），没有的话要手动编写一个，配置参考如下

![[_resources/linux笔记/5f193d69cfb466b4150dd3ce2279131c_MD5.png]]

该配置也是和--pod-network-cidr所指定的参数相对应的

而后部署flannel并检查pod状态









# 12/28
## 关于 redis的配置文件部分参数

bind 127.0.0.1

该参数表示只允许本地连接，若要开启远程连接则需要注释该参数或将127.0.0.1修改为0.0.0.0

protected-mode yes

字面意思，开启保护模式，若要关闭保护模式只需将yes修改为no

which和find

which只能用来查找命令，而不能用来查找文件，find用来查找文件

find的模糊查询使用*来实现，例如通过find / -name ‘_filename_’来实现在根目录下查找名称包含filename字段的文件






# 12/29

## K8s基础架构

![[_resources/linux笔记/602080906e00f1d43df2af815e15f692_MD5.png]]













# 1/5

## 关于k8s资源清单部分顶级字段

![[_resources/linux笔记/b1716fecba8988e8d7a93c340ec2d52b_MD5.png]]

![[_resources/linux笔记/1ba0145f8d5bc1f6702540c0979e5377_MD5.png]]






## 关于&和&&的使用

在dockerfile的CMD指令中需要指定一个前台运行的指令来保障容器的运行，例如在编写mysql的dockerfile用初始化脚本时使用mysqld --user=root来启动mysql，但该命令是前台运行会导致阻塞，所以需要&来而不是&&来衔接下一条指令，&的使用可以保证即使前一条指令未执行完毕也能够继续执行下一条指令，&&则必须要前一条指令执行成功才能继续执行下一条指令

镜像下载策略有哪些

[root@k8s231.oldboyedu.com pods]# cat 06-nginx-imagePullPolicy.yaml

apiVersion: v1 kind: Pod metadata: name: linux85-web-imagepullpolicy-001 spec: nodeName: k8s233.oldboyedu.com containers:

- name: nginx image: [harbor.oldboyedu.com/web/linux85-web:v0.1](https://www.google.com/search?q=https://harbor.oldboyedu.com/web/linux85-web:v0.1)
    
指定镜像的下载策略，有效值为: Always, Never, IfNotPresent
Always:
    # 默认值，表示始终拉取最新的镜像。
IfNotPresent:
    如果本地有镜像，则不去远程仓库拉取镜像，若本地没有，才会去远程仓库拉取镜像。
Never:
    如果本地有镜像则尝试启动，若本地没有镜像，也不会去远程仓库拉取镜像。
imagePullPolicy: Always
imagePullPolicy: IfNotPresent
imagePullPolicy: Never

/////////////////////////////////////////////////////////

心累，再也不和混子搞团队赛了




















# 2025/6/23

本来打算记录C语言的学习，但是显得笔记太杂了就不记了，用我的的.c文件代替笔记












# 7/1
接下来开始备考RHCE，所以重拾我的linux学习笔记


## 关于NAT虚拟机能ping通宿主机但宿主机不能ping通虚拟机

虚拟机可以通外网，测试了ssh服务没有问题，然后查看宿主机的虚拟网卡发现虚拟网卡8没有设置网关




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










# 7/2

## 使用ifconfig临时修改网卡配置(重启失效)

格式: ifconfig 网卡名 参数




## FQDN

"完全限定域名",实际上就是字面意思。本质上，它是互联网上计算机或主机的完整域名。它由几个不同的元素组成

它分为以下几个部分：

［hostname］.［domain］.［tld］

例如，以下是如何分解完全限定域名，www.WordPress 站群.com。The 第一部分(“www”)是主机名。第二部分(“WordPress 站群”)是域名。最后一部分(“com”)是 TLD(顶级域)

可以将完全限定域名视为地址。这个地址的目的是在 DNS 系统中指定位置。使用 FQDN，网站或其他线上实体的位置有都自己的唯一识别符号和位置。










# 7/3
## 私网ip地址范围
10.0.0.0-10.255.255.255

172.16.0.0-172.31.255.255

192.168.0.0-192.168.255.255



## repodata
用于储存元数据，记录软件包之间的依赖关系











# 7/4
## DNS端口
因为使用的是udp，所以是53号端口



## vim的全局替换属性g
不加g仅替换每行的第一个匹配项



## 如何在不通外网且不支持 ntfs格式U盘 的系统配置本地源
当因为需要使用的本地镜像过大而FAT32格式不支持时


红帽9为例，红帽9(centos7)支持FAT32格式的U盘，可以先把U盘格式化为FAT32格式（windows11一般不允许格式化为该格式，可以使用软件格式化,这里使用的是DiskGenius,在图吧工具箱有收录)，然后下载ntfs-3g（<font style="color:#DF2A3F;">该组件可以让红帽9系统能够识别并使用NTFS格式的移动硬盘，可以使用yum install --downloadonly --downloaddir 本地保存目录 ntfs-3g来保存安装包和相关依赖</font>),该插件一般在epel源里，然后在系统上安装该插件，拔出U盘后就可以重新格式化为NTFS格式，然后就可以放进需要挂载的镜像，再次插入时，该系统已经可以支持识别该格式的移动硬盘了








# 7/5
## 为什么空目录的硬链接索引值默认为2
一个是自身目录，另一个是特殊文件'.'，就是代表当前目录的'.'，它和".."是linux中的特殊文件，'.'是当前目录的特殊硬链接文件，".."是对当前目录的父目录的特殊硬链接文件，以此类推，当一个目录为空时,该目录只有一个'.'和自身，所以硬链接索引值为2，当该目录存在一个空的子文件夹时，又多了一个该子文件夹下的".."文件作为又一个硬链接






## nginx和httpd的默认端口
nginx和httpd都默认使用80端口，两个服务都部署时，就要考虑端口冲突问题











# 7/7
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



## tee命令
在处理输入输出流时功能类似T型管

一方面它会通过标准输入读取

另一方面它会将标准输入重定向到指定文件(默认是覆盖重定向，加-a选项是追加重定向)

在这个过程中间，它还会将标准输入输出到标准输出(一般是当前shell)






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







# 7/8
## semanager（待补充）
用于管理selinux的安全上下文



## semanager port
用来管理端口安全上下文

-a添加规则

-t指定标签类型

-p指定协议tcp/udp

-l列出所有端口安全上下文











# 7/10
## find的一些参数使用
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



## tar命令
tar的功能是归档和解归档而不是压缩或解压缩,但可以加参数实现

后缀是.tar

-c 创建新包

-v 显示过程

-f 指定待处理文件，该参数要放到最后

-x 提取文件

-z 使用gzip过滤(使用该参数可以通过gzip实现压缩文件的创建和解压缩，格式是gzip,后缀加.gz)

-j, 通过 bzip2 过滤归档(同上,压缩文件格式是bzip2，后缀加.bz2)

-J 通过xz过滤归档(同上,后缀加.xz)



## http和nginx的网页默认访问根目录
http是/var/www/html

nginx是/usr/share/html



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













# 7/11
## 网卡激活报错:未被NetworkManager托管
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


## autofs配置文件解析
/etc/auto.master（主配置文件）
作用：定义挂载点的根目录和对应的映射文件。
格式： [挂载点根目录] [映射文件路径] [可选参数] 

映射文件（如 /etc/remote.misc）
作用：定义子目录如何挂载到远程共享。 常见格式： [子目录名] [挂载选项] [服务器:共享路径]



## 关于 systemd

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







## 关于 init

以前的Linux启动都是用init进程。启动服务：

$ sudo /etc/init.d/apache2 start

或者

$ service apache2 start

缺点：

启动时间长。init进程是串行启动，只有前一个进程启动完，才会启动下一个进程。 启动脚本复杂。init进程只是执行启动脚本，不管其他事情。脚本需要自己处理各种情况，这往往使得脚本变得很长。

以红帽系统为例，在 rhel7 之后使用 systemd 代替 init 启动



# 7/13

## NFS（Network File System）总结与分析
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











## 关于docker/podman的挂载卷映射与selinux安全上下文
如果在做挂载卷映射时没有给容器挂载目录打标签，就会被selinux拦截

参考命令如下,要加个z
podman run -d -v /hello:/fine:z centos:latest













# 7/14

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






## 关于umask

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













# 7/15

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





## linux各种引号的作用


1.单引号' ' 单引号里面的内容会原封不动输出，全都视为普通字符进行处理

2.双引号" " 和双引号类似，但它会对双引号里面的特殊符号进行解析，不过对于花括号{}(通配符)没有解析

3.不加引号 和双引号类似，额外支持通配符（匹配文件）*.log {1..10}

4.反引号 优先执行，先执行反引号里面的命令，相较于$()，两者作用相同，但反引号在类unix平台适用性更高









# 7/16

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



## 故障案例：命令行变为bash-5.1$

原因: 用户家目录下面的配置文件没了这两个: ~/.bashrc，~/.bash_profile

解决: /etc/skel目录下方存放着所有新用户的家目录模板,将缺失文件复制到指定用户的家目录

[root@server ~]# su testuser bash-5.1$ cp /etc/skel/.bash* ~/ bash-5.1$ bash [testuser@server root]$ cd ~ 
[testuser@server ~]$





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










# 7/17

## Ansible 的主要组件

控制节点（Control Node）： Ansible 的运行所在的机器。控制节点发出指令，通过 SSH 连接到目标主机执行任务。

被管理节点（Managed Nodes）： 需要被管理和配置的目标主机。

库存（Inventory）： 一个定义了所有被管理节点的文件。库存文件通常是一个简单的 INI 文件，也可以是动态生成的。

模块（Modules）： Ansible 的工作单元，执行特定任务的脚本。模块可以管理文件、安装软件包、执行命令等。

剧本（Playbooks）： Ansible 的配置、部署和编排的文件，使用 YAML 编写。剧本由一个或多个剧本（Play）组成，每个剧本定义了在一组主机上执行的任务。

角色（Roles）： 角色是剧本的一种组织方式，用于将任务、变量和文件结构化。角色使得剧本更易读、可维护和可重用。

/etc/ansible/hosts文件

这是ansible的默认库存文件

当ansible-playbook开始运行剧本时，默认先查找这个库存文件，但可以通过-i选项指定自定义库存文件(通常以.ini文件结尾)

Adhoc

Ansible 的 ad-hoc 命令是一种快速、临时执行任务的方式，无需编写完整的 Playbook。它适用于执行一次性任务、进行快速测试或在多台主机上同步执行简单命令。这种方法非常灵活，能够利用 Ansible 的模块库来完成各种任务。

Ansible ad-hoc 命令语法解析

ansible [pattern] -i [inventory] -m [module] -a "[module options]" [--become]

pattern选项 指定要操作的主机或主机组的模式。

常见的 pattern 语法

[root@server ansible]# cat node.ini [node] node1 node2 [root@server ansible]#

由于主机密钥检查问题暂时没有好的解决办法，这里的举例使用 在 ansible 的配置文件中禁用 ansible 的密钥检查

[defaults] host_key_checking = False

1. 全量匹配 all 或 *：选择所有主机
    

ansible all -m ping

2. 单主机/主机组
    

-i：指定库存文件的位置。

-m：指定要使用的模块（例如 ping, shell, copy 等）。

-a：指定模块的参数。

--become：使用 sudo 提权执行命令（需要适当的权限配置）。

pipx的安装

python3 -m pip install --user pipx

python3 -m pipx ensurepath






# 7/18

## ansible 模块
ansible-doc -l

列出 ansible-core 的模块列表，不加 l 可以查看指定模块

setup 模块 在 剧本执行前,ansible 会自动调用 setup 模块采集目标清单的 fact(事实信息集合)（可禁用自动调用，在剧本的属性中添加gather_facts: no），采集到的 fact 使用该模块的内置变量以键值对的形式存储，格式为 json 格式，剧本调用 setup 模块的内置变量的子属性时，使用' . '来连接父属性和子属性，这个格式使用的是 嵌套字典的形式，例如内置变量 ansible_devices,它的子属性有 vda，vda 的子属性有 size，那么调用 size 变量就需要使用嵌套字典表示 : ansible_devices.vda.size，等价于 python 的嵌套字典语法 ansible_devices['vda']['size'](https://www.google.com/search?q=%E4%B8%8D%E6%98%AF%E5%A4%9A%E7%BB%B4%E6%95%B0%E7%BB%84%EF%BC%8C%E6%98%AF%E5%AD%97%E5%85%B8%E5%B5%8C%E5%A5%97)

- name: get vda_info lineinfile: path: /root/hwreport.txt regexp: "disk_vda_size" line: "{{ ansible_devices.vda.size | default ('none') }}"
    

查看指定模块的使用帮助 ansible-navigator doc 模块名 -m stdout

比 ansible-doc 更完善













# 7/21
## （！待补充）命名空间实践
在主机 server 上打开两个 ssh 连接操作









# 7/23
## ansible-playbook 中 loop 的使用
在重复的，仅操作对象不同的任务中，可以使用 loop 简化，loop 的缩进层级和模块同一级

有多个使用方式

1.配合 vars 字段使用
```yaml
---
- name: test loop
  hosts: dev
  vars:
    testvar:
      - who are you
      - who am i
  tasks:
    - name: test loop
      debug:
        msg: "{{ item }}"
      loop: "{{ testvar }}"
```



2.配合 vars_files 字段使用
```yaml
---
- name: test loop
  hosts: dev
  vars_files:
    - test_var.yml
  tasks:
    - name: test loop
      debug:
        msg: "{{ item }}"
      loop:
          - "{{ ase }}"
          - "{{ bae }}"
```

这里指定了变量文件，下面是变量文件内容

```yaml
ase:
  - hello
  - fine

bae:
  - nihao
  - xiexie
```





## ansible-playbook 中 when 语句的使用
作判断语句的作用，有多种用法

1.简单的布尔值判断使用
```bash
[greg@control ansible]$ cat test_when.yml 
---
- name: test when
  hosts: dev
  vars:
    hhh: true
  tasks:
    - name: zhen or jia
      debug:
        msg: hello
      when: hhh is true


[greg@control ansible]$ ansible-navigator run test_when.yml -m stdout

PLAY [test when] *****************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************
ok: [node1]

TASK [zhen or jia] ***************************************************************************************************************
ok: [node1] => {
    "msg": "hello"
}

PLAY RECAP ***********************************************************************************************************************
node1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[greg@control ansible]$ 
```



2.与事实变量结合使用
以 setup 采集到的事实变量 ansible_distribution 为例，该变量一般会存储系统类型，redhat，debian 之类的

```bash
[greg@control ansible]$ cat test_when.yml 
---
- name: test when
  hosts: dev
  vars:
    os_info:
      - RedHat
      - Debian
      - CentOS

  tasks:
    - name: test
      debug:
        msg: "I am {{ ansible_distribution }}"
      when: "'ansible_distribution' in os_info"


[greg@control ansible]$ ansible-navigator run test_when.yml -m stdout

PLAY [test when] *****************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************
ok: [node1]

TASK [test] **********************************************************************************************************************
ok: [node1] => {
    "msg": "I am RedHat"
}

PLAY RECAP ***********************************************************************************************************************
node1                      : ok=2    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[greg@control ansible]$ 
```



3.结合 block 使用
block 可以将指定的任务块交给一个 when 语句来判断，block 和 when 的缩进要对齐

```bash
[greg@control ansible]$ cat test_when.yml 
---
- name: test when
  hosts: dev
  vars:
    os_info:
      - RedHat
      - Debian
      - CentOS

  tasks:
    - name: test block
      block:
        - name: test 
          debug:
            msg: "{{ ansible_distribution }}:{{ inventory_hostname }} will install vsftpd"

        - name: install vsftpd  
          yum:
            name: vsftpd
            state: present
          
      when: "'ansible_distribution' in os_info"

[greg@control ansible]$ ansible-navigator run test_when.yml -m stdout

PLAY [test when] *****************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************
ok: [node1]

TASK [test] **********************************************************************************************************************
ok: [node1] => {
    "msg": "RedHat:node1 will install vsftpd"
}

TASK [install vsftpd] ************************************************************************************************************
ok: [node1]

PLAY RECAP ***********************************************************************************************************************
node1                      : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```



4.结合 loop 使用
这里结合了事实变量，采集目标主机信息，当目标主机的挂载目录是根且可用空间大于 300000 字节（大概 300MB）时安装 mariadb

```bash
[greg@control ansible]$ cat when_loop.yml 
---
- name: hello
  hosts: node5
  tasks:
    - name: Install mariadb  
      yum:
        name: mariadb
        state: present
      when: item.mount == "/" and item.size_available > 3000000000 #字节
      loop: "{{ ansible_mounts }}"
[greg@control ansible]$ ansible-navigator run when_loop.yml -m stdout 

PLAY [hello] *********************************************************************************************************************

TASK [Gathering Facts] ***********************************************************************************************************
ok: [node5]

TASK [Install mariadb] ***********************************************************************************************************
changed: [node5] => (item={'mount': '/', 'device': '/dev/vda4', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 9990811648, 'size_available': 8175906816, 'block_size': 4096, 'block_total': 2439163, 'block_available': 1996071, 'block_used': 443092, 'inode_total': 4883392, 'inode_available': 4834578, 'inode_used': 48814, 'uuid': 'fb535add-9799-4a27-b8bc-e8259f39a767'})
skipping: [node5] => (item={'mount': '/boot', 'device': '/dev/vda3', 'fstype': 'xfs', 'options': 'rw,seclabel,relatime,attr2,inode64,logbufs=8,logbsize=32k,noquota', 'size_total': 518684672, 'size_available': 350957568, 'block_size': 4096, 'block_total': 126632, 'block_available': 85683, 'block_used': 40949, 'inode_total': 256000, 'inode_available': 255693, 'inode_used': 307, 'uuid': '5e75a2b9-1367-4cc8-bb38-4d6abc3964b8'}) 
skipping: [node5] => (item={'mount': '/boot/efi', 'device': '/dev/vda2', 'fstype': 'vfat', 'options': 'rw,relatime,fmask=0077,dmask=0077,codepage=437,iocharset=ascii,shortname=winnt,errors=remount-ro', 'size_total': 209489920, 'size_available': 202170368, 'block_size': 4096, 'block_total': 51145, 'block_available': 49358, 'block_used': 1787, 'inode_total': 0, 'inode_available': 0, 'inode_used': 0, 'uuid': '7B77-95E7'}) 

PLAY RECAP ***********************************************************************************************************************
node5                      : ok=2    changed=1    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   
```













# 7/24

## ansible 的集合（Collection）

定位：Ansible 的功能单元包（模块/角色/插件等的容器） 命名格式：<命名空间>.<集合名>

这里的命名空间是指命名规范，官方是 ansible，社区的是 community 之类的，不是实质上的功能，也不是指 linux 内核的 namespace，例如 ansible.builtin.yum # 核心团队维护的包管理模块

这里也能解释模块的完全名称的格式: 命名空间.集合名.模块名





## 集合中的角色 role

Ansible 角色本质上就是 预配置的、参数化的、可重用的自动化模块，通过标准化目录封装完整工作单元（任务流+资源+配置），开发者像调用函数一样声明式使用，通过变量传递参数实现定制化，完美符合 "模块化即插即用" 的设计哲学。

角色的主任务储存在 tasks 子目录下，一般名为 main.yml

为什么能用 yum 安装角色？

在 Red Hat 生态系统（RHEL、CentOS、Fedora）中，yum/dnf 能直接安装 Ansible 系统角色，这源于 Red Hat 的官方集成策略，核心原因如下：

标准化封装： Red Hat 将精选的 Ansible 角色（如 rhel-system-roles 系列）打包为 RPM 格式，纳入官方仓库：

```plain
# 查看可用系统角色包
yum search rhel-system-roles
```

集中管理： 这些角色由 Red Hat 工程师维护，通过标准软件仓库分发（如 BaseOS/AppStream）。

底层机制：

```bash
# 实际是通过 ansible-galaxy 工具安装
ansible-galaxy install geerlingguy.nginx
```

技术实现原理

RPM 包结构： 每个角色包包含：

- 角色文件（tasks, templates, defaults 等）
    
- 元数据（meta/main.yml 声明兼容性）
    
- 文档（README.md）

```bash
# 查看角色包内容
rpm -ql rhel-system-roles.network
```

依赖管理： 自动解决 Ansible 版本依赖（如要求 ansible-core >= 2.12）



## ansible-galaxy 的使用

Ansible Galaxy 是一个由 Ansible 社区维护的在线平台，旨在帮助用户查找、下载和管理 Ansible 角色和集合。它类似于一个“应用商店”，为自动化运维提供了丰富的资源库。

主要功能

1. 角色和集合的查找与下载
    

- 用户可以通过 Galaxy 网站或命令行工具 ansible-galaxy 搜索、下载和安装社区开发的角色和集合。
    
- 角色（Roles）是一组任务的集合，通常用于自动化特定的任务或配置。
    
- 集合（Collections）是更全面的包，可能包含多个剧本、角色、模块和插件。
    

2. 管理和维护
    

- 可以使用 ansible-galaxy 命令行工具来管理本地安装的角色和集合，包括列出、卸载、更新等操作。
    

3. 发布和贡献
    

- 用户可以创建自己的角色和集合，并将其发布到 Galaxy 平台，供其他人使用和贡献。


安装角色或集合

```bash
ansible-galaxy install <role_name>
ansible-galaxy collection install <collection_name>
```

```bash
ansible-galaxy install geerlingguy.apache
```


列出已安装的角色或集合

```bash
ansible-galaxy list
```


搜索角色或集合

```bash
ansible-galaxy search <keyword>
```


查看角色或集合的详细信息

```bash
ansible-galaxy info <role_name>
ansible-galaxy collection info <collection_name>
```


从 requirements 文件安装多个角色或集合并指定安装目录

```bash
ansible-galaxy install -r requirements.yml -p /path/dir
```

文件中可以列出多个角色或集合及其版本信息。

```bash
[greg@control ansible]$ cat roles/requirements.yml 
---
- name: balancer
  src: http://classroom/materials/haproxy.tar

- name: phpinfo
  src: http://classroom/materials/phpinfo.tar
```

使用 yml 文件安装集合,参数加上collection 指定安装类型是集合 

```yaml
---
collections:
- name: http://classroom/materials/redhat-insights-1.0.7.tar.gz
- name: http://classroom/materials/community-general-5.5.0.tar.gz
- name: http://classroom/materials/redhat-rhel_system_roles-1.19.3.tar.gz
```



初始化一个自定义角色模板
```bash
[greg@control ansible]$ ansible-galaxy init roles/apache
- Role roles/apache was created successfully
[greg@control ansible]$ vim roles/apache/
defaults/    handlers/    README.md    templates/   .travis.yml  
files/       meta/        tasks/       tests/       vars/        
```





# 7/25
## block和rescue、always联合使用
block中的任务都成功，rescue中的任务不执行
block中的任务出现失败（failed），rescue中的任务执行block中的任务不管怎么样，always中的任务总是执行

```bash
[greg@control ansible]$ cat test_block_resume_always.yml 
---
- name: test
  hosts: dev
  tasks:
    - name: block_test
      block:
        - name: rescue_test
          debug:
            msg: "{{ hello }}"
          
      rescue: 
        - name: debug mission is fail
          debug:
            msg: "hello!neiga:)"
      
      always:
        - name: i will print
          debug:
            msg: "i am beiliya:("

[greg@control ansible]$ ansible-navigator run test_block_resume_always.yml -m stdout

PLAY [test] ************************************************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************************************
ok: [node1]

TASK [rescue_test] *****************************************************************************************************************************************************************
fatal: [node1]: FAILED! => {"msg": "The task includes an option with an undefined variable. The error was: 'hello' is undefined\n\nThe error appears to be in '/home/greg/ansible/test
_block_resume_always.yml': line 7, column 11, but may\nbe elsewhere in the file depending on the exact syntax problem.\n\nThe offending line appears to be:\n\n      block:\n     - na
me: rescue_test\n          ^ here\n"}

TASK [debug mission is fail] *******************************************************************************************************************************************************
ok: [node1] => {
    "msg": "hello!neiga:)"
}

TASK [i will print] ****************************************************************************************************************************************************************
ok: [node1] => {
    "msg": "i am beiliya:("
}

PLAY RECAP *************************************************************************************************************************************************************************
node1                      : ok=3    changed=0    unreachable=0    failed=0    skipped=0    rescued=1    ignored=0   

[greg@control ansible]$ 

```

把 rescue 那一块删掉后执行

```bash
[greg@control ansible]$ ansible-navigator run test_block_resume_always.yml -m stdout 

PLAY [test] ************************************************************************************************************************************************************************

TASK [Gathering Facts] *************************************************************************************************************************************************************
ok: [node1]

TASK [rescue_test] *****************************************************************************************************************************************************************
fatal: [node1]: FAILED! => {"msg": "The task includes an option with an undefined variabl
e. The error was: 'hello' is undefined\n\nThe error appears to be in '/home/greg/ansible
/test_block_resume_always.yml': line 7, column 11, but may\nbe elsewhere in the file depe
nding on the exact syntax problem.\n\nThe offending line appears to be:\n\n      block:
n        - name: rescue_test\n          ^ here\n"}

TASK [i will print] ****************************************************************************************************************************************************************
ok: [node1] => {
    "msg": "i am beiliya:("
}

PLAY RECAP *************************************************************************************************************************************************************************
node1                      : ok=2    changed=0    unreachable=0    failed=1    skipped=0    rescued=0    ignored=0   

Please review the log for errors.
[greg@control ansible]$ 
```











# 7/26
## 如何安全删除双系统
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



## EFI 系统分区

EFI 系统分区 (ESP) 是操作系统启动的关键组件，尤其是在使用 UEFI启动模式的电脑上（现代电脑基本都是 UEFI）。

### EFI 系统分区是什么？

1. 核心定义：EFI 系统分区（ESP）是一个小型、隐藏的 FAT32 格式分区，它是 UEFI 固件启动操作系统所必需的。
    
2. 作用类比: 你可以把它想象成电脑启动过程中的 “引导文件仓库”*或 “启动导航地图”。UEFI 固件（取代传统 BIOS 的现代固件）在开机时，会首先查找并读取这个分区里的文件，才能知道如何加载哪个操作系统。
    
3. 位置： 它通常位于磁盘的最开始部分（但并非绝对），大小一般在 100MB - 550MB*之间（Windows 默认创建 100MB，某些 Linux 发行版或工具可能创建更大一些）。
    
4. 文件系统：FAT32。这是 UEFI 规范强制要求的，因为 UEFI 固件本身内置了读取 FAT32 文件系统的能力。
    
5. 标识： 在磁盘管理工具（如 Windows 磁盘管理、DiskGenius、GParted、Linux 的 `fdisk -l` 或 `lsblk -f`）中，它的分区类型标识通常是：
    EFI System Partition
    ESP
GPT 分区表下的类型代码: C12A7328-F81F-11D2-BA4B-00A0C93EC93B
        

### EFI 系统分区里有什么？

1. 引导加载程序：
    Windows: \EFI\Microsoft\Boot\bootmgfw.efi (主 Windows 引导管理器) 以及 \EFI\Microsoft\Boot\BCD(启动配置数据库，告诉引导管理器有哪些 Windows 可以启动)。Linux (常见发行版): \EFI\ubuntu\grubx64.efi 或 \EFI\ubuntu\shimx64.efi(Ubuntu/Debian), \EFI\fedora\grubx64.efi 或 \EFI\fedora\shimx64.efi (Fedora), \EFI\arch\grubx64.efi (Arch) 等等。还可能包含内核 vmlinuz-xxx 和初始内存盘 initramfs-xxx.img（如果使用 GRUB 等直接从 ESP 加载）。
        
2. 固件应用程序： UEFI 固件本身或硬件制造商（如主板厂商、显卡厂商）提供的工具，可能用于固件更新、诊断等。
    
3. 引导管理器： 有时会安装第三方引导管理器，如rEFInd(\EFI\refind\refind_x64.efi)，它提供一个图形化界面让你选择要启动的操作系统或工具。
    
4. 驱动： 一些必要的 UEFI 驱动程序（`.efi` 文件），可能用于在操作系统加载前访问特定的硬件（如某些 RAID 卡、特殊文件系统）。














# 8/7

## Linux RPM包统一命名规则
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









## yum 查找指定命令的所在软件包
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

[root@localhost ~]# 
```





## Oracle_linux8.6 部署 zabbix6.0
首先需要禁用防火墙和 selinux(可以不禁用，但需要额外配置)

```plain
rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/8/x86_64/zabbix-release-latest-6.0.el8.noarch.rpm
```

zabbix 有个特殊的 rpm 包zabbix-release-latest-6.0.el8.noarch.rpm（这是 6.0 的），安装后会生成 zabbix 源(一般是名为zabbix.repo和zabbix-agent2-plugins.repo 的两个文件)，默认是官方源路径，如果需要修改成别的镜像站的源，手动 vim 修改对应链接即可

默认 zabbix 源配置文件参考如下

```bash
[zabbix]
name=Zabbix Official Repository - $basearch
baseurl=https://repo.zabbix.com/zabbix/6.0/rhel/8/$basearch/
enabled=1
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX-A14FE591

[zabbix-non-supported]
name=Zabbix Official Repository (non-supported) - $basearch
baseurl=https://repo.zabbix.com/non-supported/rhel/8/$basearch/
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX
gpgcheck=1

[zabbix-unstable]
name=Zabbix Official Repository (unstable) - $basearch
baseurl=https://repo.zabbix.com/zabbix/5.5/rhel/8/$basearch/
enabled=0
gpgcheck=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX-A14FE591
```

```bash
[zabbix-agent2-plugins]
name=Zabbix Official Repository (Agent2 Plugins) - $basearch
baseurl=https://repo.zabbix.com/zabbix-agent2-plugins/1/rhel/8/$basearch/
enabled=1
gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-ZABBIX
gpgcheck=1
```

这里的$basearch 变量会根据自身系统架构自动被赋值



官方的 yum 源太慢了，这里换成清华的

```bash
[root@localhost ~]# sed -i 's#https://repo.zabbix.com#https://mirrors.tuna.tsinghua.edu.cn/zabbix#g'  /etc/yum.repos.d/zabbix.repo
[root@localhost ~]# sed -i 's#https://repo.zabbix.com#https://mirrors.tuna.tsinghua.edu.cn/zabbix#g'  /etc/yum.repos.d/zabbix-agent2-plugins.repo
```



开始安装组件
[root@localhost ~]# dnf -y  install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent


创建初始数据库

zabbix6.0 要求 mysql 数据库的 版本是 8.0.x，但问题在于 MYSQL8.0 不再被长期维护，甲骨文官网的 mysql软件源不再提供 mysql80，转而提供 mysql84(即 8.4.x 版本)，所以这里使用 8.4(后面还需要改配置

这里需要自行到甲骨文官网获取 mysql 的 rpm 包或获取 mysql 的软件源安装包，这里选择了使用 mysql 的 yum 源 rpm 包（在官网的[https://dev.mysql.com/downloads/](https://dev.mysql.com/downloads/)版块获取，里面还有 apt 源等等)

下载后传到主机上，然后安装该 rpm 包

```bash
[root@localhost ~]# rpm -Uvh mysql84-community-release-el8-2.noarch.rpm 
警告：mysql84-community-release-el8-2.noarch.rpm: 头V4 RSA/SHA256 Signature, 密钥 ID a8d3785c: NOKEY
Verifying...                          ################################# [100%]
准备中...                          ################################# [100%]
正在升级/安装...
   1:mysql84-community-release-el8-2  ################################# [100%]
   Warning: native mysql package from platform vendor seems to be enabled.
    Please consider to disable this before installing packages from repo.mysql.com.
    Run: yum module -y disable mysql
```



这里看到了警告信息，要求我们执行yum module -y disable mysql

因为涉及到软件源冲突问题，在红帽 8 及其衍生版本(包括正在使用的 Oracle linux 8)中的仓库自带系统维护的MySQL模块（默认启用）

安装包会启用MySQL官方源

两个源都提供mysql-server等同名包，导致包管理器无法确定优先级

因此需要禁用官方提供的 mysql 模块



然后安装并启动 mysql

```
yum -y install mysql-community-client mysql-community-server
systemctl enable --now mysqld.service
```


MySQL 从5.7 版本开始引入临时密码机制，查看该密码有多种方法,这里选择通过错误日志查找（最可靠)

```bash
[root@localhost ~]# grep 'temporary password' /var/log/mysqld.log
2025-08-07T14:51:09.525770Z 6 [Note] [MY-010454] [Server] A temporary password is generated for root@localhost: VPDgl,NKl51M
[root@localhost ~]# mysql -uroot -pVPDgl,NKl51M
mysql: [Warning] Using a password on the command line interface can be insecure.
Welcome to the MySQL monitor.  Commands end with ; or \g.
Your MySQL connection id is 8
Server version: 8.4.6

Copyright (c) 2000, 2025, Oracle and/or its affiliates.

Oracle is a registered trademark of Oracle Corporation and/or its
affiliates. Other names may be trademarks of their respective
owners.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

mysql> 
mysql> ALTER USER 'root'@'localhost' IDENTIFIED BY 'Mysql@123';
Query OK, 0 rows affected (0.00 sec)
#登录后立刻修改密码为Mysql@123
```

这里的临时密码就是VPDgl,NKl51M  ，默认用户是 root


在数据库主机上运行以下代码
```sql
mysql> create database zabbix character set utf8mb4 collate utf8mb4_bin;
mysql> create user zabbix@localhost identified by 'password';
mysql> grant all privileges on zabbix.* to zabbix@localhost;
mysql> set global log_bin_trust_function_creators = 1;
mysql> quit;
```


导入初始架构和数据，系统将提示您输入新创建的密码。
```
zcat /usr/share/zabbix-sql-scripts/mysql/server.sql.gz | mysql --default-character-set=utf8mb4 -uzabbix -p zabbix
```


禁用函数创建权限，防止普通用户创建可能破坏主从复制一致性的存储函数
mysql> set global log_bin_trust_function_creators = 0; 
mysql> quit;


编辑配置文件 /etc/zabbix/zabbix_server.conf

```bash
[root@localhost ~]# vim /etc/zabbix/zabbix_server.conf
[root@localhost ~]# grep "^DBPassword" /etc/zabbix/zabbix_server.conf 
DBPassword=Zabbix@123
```

最后启动Zabbix server和agent进程，并为它们设置开机自启：
```bash
[root@localhost ~]# systemctl restart zabbix-server zabbix-agent httpd php-fpm
[root@localhost ~]# systemctl enable zabbix-server zabbix-agent httpd php-fpm
Created symlink /etc/systemd/system/multi-user.target.wants/zabbix-server.service → /usr/lib/systemd/system/zabbix-server.service.
Created symlink /etc/systemd/system/multi-user.target.wants/zabbix-agent.service → /usr/lib/systemd/system/zabbix-agent.service.
Created symlink /etc/systemd/system/multi-user.target.wants/httpd.service → /usr/lib/systemd/system/httpd.service.
Created symlink /etc/systemd/system/multi-user.target.wants/php-fpm.service → /usr/lib/systemd/system/php-fpm.service.
[root@localhost ~]# 
```


然后访问 web 界面

[http://host/zabbix](http://host/zabbix)

![[_resources/linux笔记/f3ffa6d676413dd0de913d2ba13422fb_MD5.png]]

一直下一步，到连接数据库

![[_resources/linux笔记/4be80ac82facce3778f555ec69a55e3d_MD5.png]]

密码是 zabbix 数据库设置的密码 Zabbix@123

但是这里会报错，还是因为使用 的是 MYSQL8.4 的原因

![[_resources/linux笔记/eec629f74e45d220a94ce4023f43127e_MD5.png]]

简而言之是 zabbix6.0 的 web 界面检查密码时使用 mysql_native_password 插件，但该插件在 MLSQL8.4 被禁用了，使用了别的插件代替，所以即使在设置 zabbix 数据库密码时指定 mysql_native_password 插件，也会报错该插件未加载，这里的解决方案是通过修改 mysql 配置文件/etc/my.cnf，在 [mysqld] 下添加字段重新启用该插件

```bash
[root@localhost ~]# cat /etc/my.cnf
# For advice on how to change settings please see
# http://dev.mysql.com/doc/refman/8.4/en/server-configuration-defaults.html

[mysqld]
#
# Remove leading # and set to the amount of RAM for the most important data
# cache in MySQL. Start at 70% of total RAM for dedicated server, else 10%.
# innodb_buffer_pool_size = 128M
#
# Remove the leading "# " to disable binary logging
# Binary logging captures changes between backups and is enabled by
# default. It's default setting is log_bin=binlog
# disable_log_bin
#
# Remove leading # to set options mainly useful for reporting servers.
# The server defaults are faster for transactions and fast SELECTs.
# Adjust sizes as needed, experiment to find the optimal values.
# join_buffer_size = 128M
# sort_buffer_size = 2M
# read_rnd_buffer_size = 2M

datadir=/var/lib/mysql
socket=/var/lib/mysql/mysql.sock

log-error=/var/log/mysqld.log
pid-file=/var/run/mysqld/mysqld.pid

# Enable mysql_native_password plugin
[mysqld]
mysql_native_password=ON
```

重启 mysqld 后进入数据库再次修改密码，这次需要指定 mysql_native_password 插件
mysql> alter user  zabbix@localhost identified with mysql_native_password by 'Zabbix@123';
Query OK, 0 rows affected (0.01 sec)

成功解决，继续配置 web 界面



主机名随便，时区选上海

![[_resources/linux笔记/b9b344653d1d8d0b7d55b26b4f24ac2c_MD5.png]]

![[_resources/linux笔记/7dc6c47de5010cfd429d1cc7a538e9ef_MD5.png]]

![[_resources/linux笔记/60e757a51946fb339718e32538efea73_MD5.png]]

用户默认是 Admin  密码是 zabbix

![[_resources/linux笔记/803dbc0a17b995fcb131fdbd0f9f7e81_MD5.png]]

至此配置完成







## Mysql 密码插件报错：未加载
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









# 8/8
## Zabbix 基础架构
![[_resources/linux笔记/aec1d7088e442a64778f46e3a8b338a2_MD5.png]]

代理端是可选项

zabbix-agent 以进程的形式运行在主机的 10050 端口 



### 基础架构组件介绍
Zabbix Server
是 Zabbix 的核心组件，其功能为将 Agent 采集到的数据持久化 存储到数据库里。

数据库存储
存储所有由 Agent 采集到的数据，Zabbix 支持多种数据存储，例如: Mysql,Oracle,PostgreSQL,Elasticsearch 等。

Web 界面
Zabbix 提供了友好的 Web 界面方便我们操作，Web 界面的运行环境可以是 Nginx+PHP或者Apache+PHP服务组成。Web界面也是ZabbixServer的一部分。

Proxy 代理端 
对于分布式环境，Zabbix 也提供了代理的方案，可以代替 Zabbie Server 收集 多个 Agent 的数据，然后在将收集到的数据汇总到 Zabbix Server，Proxy 可以 起到分担 Zabbix Server 负载的作用。

Agent 客户端
Zabbix Agent 被部署在需要监控主机上，用于采集监控数据并发送到 Zabbix Server 端。

Server 服务端

Zabbix Server 是 C 语言开发的 Zabbix 服务端，有着 强悍的采集和计算性能，而且资源使用率很低。主要的功能如下：

定时读取 Zabbix 数据库，同步 Zabbix UI 配置的信息到缓存，下发到 Zabbix Agent 或者 Zabbix Proxy。

关于这俩不同的采集进程，可以通过(ps -ef|grep zabbix 查看进程列表)

对于被动采集（主动和被动是从设备侧角度来看的）, Zabbix Server 会有专门的 Poller 线程去采集数据，可以定义特定的时间区间或者特定的频率。

对于主动采集，就是Agent或者设备主动上报数据，Zabbix Server 也会有专门的 Trapper 线程来接收数据，时间间隔或者频率取决于设备侧或者Agent上报配置。

接收到的历史数据（来自于 Agent、Proxy、设备侧），Zabbix Server 会缓存下来，进行告警表达式计算，进行动作触发，最终会同步到数据库的历史记录表，history开头的表。








# 8/9
## 欧拉系统安装 GUI
yum -y install dde 安装图形化

systemctl set-default graphical.target 设置开机默认启动图形化界面




## 欧拉部署zabbix7.0的版本依赖问题
欧拉的具体版本是 24.03-sp1

zabbix7.0 要求net-snmp-libs 版本要在1:5.9.1-x 以内（大概是这样，我部署的版本是1:5.9.1-17），但是欧拉官方镜像源的net-snmp-libs最旧的版本也是 1:5.9.2-x 的，所以这里我使用了 centos9stream 的 appstream 仓库,由于net-snmp-libs 还有相关依赖所以不能直接降级，卸载后重新安装注意相关依赖项的重新安装

如果版本不对，在启动 zabbix 相关服务时会报错如下图，附上具体的日志信息

![[_resources/linux笔记/8c5ee793907705df231ecf08121abc97_MD5.png]]

![[_resources/linux笔记/ee86c04f16e7858af1b61e373b6c7c25_MD5.png]]





## mysql8.0 安装后配置

与 8.4 不同，使用 mysql -u root -p 直接进入数据库（注意不是 mysqld），密码输入直接回车，因为默认是空密码,进入数据库，为了安全起见，还是设置一下 root 密码，在数据库中执行以下代码

ALTER USER 'root'@'localhost' IDENTIFIED BY '新密码'; FLUSH PRIVILEGES;









# 8/11
## zabbix 自定义监控
在 zabbix-server 端安装 zabbix-get 用于测试
```
[root@openEuler ~]# yum -y install zabbix-get
确保 agent 端配置文件 Include 一行正确配置
[root@oracle ~]# grep "^[a-Z]" /etc/zabbix/zabbix_agentd.conf 
PidFile=/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=192.168.120.140
ServerActive=192.168.120.140
Hostname=openEuler
Include=/etc/zabbix/zabbix_agentd.d/*.conf
```




在/etc/zabbix/zabbix_agentd.d/目录下书写.conf 文件

```
[root@oracle ~]# cat /etc/zabbix/zabbix_agentd.d/new_host.conf 
UserParameter=root.login,/usr/bin/who | awk '$1=="root"' | wc -l
```


在/usr/bin 目录下的命令一般是不用写绝对路径的，这里可写可不写，这条命令用于统计 root 远程登录的数量

书写格式是UserParameter=键.值,命令行

保存退出后重启 agent

然后在 zabbix-server 端测试

```bash
[root@openEuler ~]# zabbix_get -s 192.168.120.130 -k root.login
3
```

这里是 3 是因为我使用 root 账户开了三个 ssh 连接

也可以在客户端测试

```bash
[root@oracle ~]# zabbix_agentd -t root.login
root.login                                    [t|1]
```



然后登录 zabbix-UI 将自定义键值与监控关联

![[_resources/linux笔记/8770e3d967c92a2a82d906e896a7b746_MD5.png]]

进入对应 agent 端的监控项并创建监控项

![[_resources/linux笔记/ea38b37a3a65ccaece89bdaaf62a6c9f_MD5.png]]

键值写刚刚自定义的监控项，信息类型是命令行的结果的数据类型,ip 是对应 agent 客户端的 ip

在添加前可以先测试

![[_resources/linux笔记/6a201890c13a52ff5bdaaced81cb38b9_MD5.png]]

上面的"获取值"相当于在 zabbix-server 端的命令行中使用 zabbix_get 测试

下面的"获取值并进行测试"是在测试 php（即网页端） 能否调用该键值

测试完成后就可以添加作为自定义监控项在 zabbix-UI 中使用

最后还需要为该监控项配置触发器，路径是：告警-主机-触发器-新建触发器

![[_resources/linux笔记/8721c9deafcdf3ab14fbdaeaf25d40be_MD5.png]]

问题表达式点击"添加"可选择监控项，在"功能"选择需要使用的函数

![[_resources/linux笔记/b7a5f50ab3acd6f566cc0501aecefbcc_MD5.png]]

"结果"是 监控项的数据结果，这里设置检测的结果大于 6 就触发问题表达式

![[_resources/linux笔记/7cf92c4b4ca70edd6949a47750242af5_MD5.png]]

如果需要恢复表达式，也可以添加，和问题表达式一样的操作流程

![[_resources/linux笔记/058cb0a7f70940f62de2e2fc498e7842_MD5.png]]

至此完成配置并添加，完成了一个自定义监控项的简单流程













# 8/12
## 书写触发器问题表达式案例 swap
这里直接使用官方提供的监控项，可以使用 zabbix-agent2 -p 查看所有官方提供的监控项和使用方法，更具体需要查看官网的 zabbix 使用文档



条件 1: swap 总大小大于 0（系统有 swap 分区）

条件 2: swap 当前使用的大小大于 0（没有可以直接使用的官方监控项，这里调整为当前 swap 空闲率小于 100）



1.找出满足要求的键值

system.swap.size[,total]  取出 swap 总数

last(/rocky/system.swap.size[,userd])   swap 使用大小



条件 swap 总大小大于 0

last(/rocky/system.swap.size[,total])>0



条件 swap 当前使用的大小小于 0（没有可以直接使用的官方监控项，这里调整为当前 swap 空闲率小于 100）

last(/rocky/system.swap.size[,pfree])<100



表示并且

-a = and

-o = or 

完整表达式

last(/rocky/system.swap.size[,total])>0 and last(/rocky/system.swap.size[,userd]) >0





## 部署支持参数的自定义监控项
在 rocky 节点操作,指定目录下书写.conf 文件
```
UserParmeter=user.login[*],lastlog -u "$1" | awk 'NR==2{print $$3}'
```

`[*]` 表示该键值支持传参，`$1` 是参数，多个参数就继续写 `$2`, `$3`....

在 awk 中的 `$$3` 是为了防止 awk 中的 `$3` 被识别为键值的参数，两者没有关联

重启 zabbix-agent2 后 在 server 端验证

[root@openEuler ~]# zabbix_get -s 192.168.120.129 -k user.login[root]

192.168.120.1

验证成功后进入 zabbix-ui 为 rocky 添加监控项

![[_resources/linux笔记/fe46350bc8ae679e02db5c9b89169724_MD5.png]]

在实际使用时需要指定参数，这里指定为 root

然后为该监控项配置触发器

![[_resources/linux笔记/c1cc4bef793487fb821d898843a02cee_MD5.png]]

这里的问题表达式的条件是：最后一条监控项的数据和倒数第二条的数据不等

添加后使用 server 主机 ssh 测试

![[_resources/linux笔记/6203e5b8bb903e5cb03b093a271bcae9_MD5.png]]

触发了告警,至此完成了一个简单的自定义参数监控项，该监控项逻辑处理有待完善
















# 8/13
## podman 指定镜像仓库位置
在/etc/containers/registries.conf配置文件中书写

```
unqualified-search-registries = ["utility.lab.example.com"]
[[registry]]
insecure = true
blocked = false
location = "utility.lab.example.com"
```


第一行指定了 podman 的默认仓库位置，也就是当 podman pull 时，如果不加对应镜像仓库的位置，只有一个镜像名时，会从这个指定的默认仓库拉取镜像

即执行podman pull nginx 时

实际上会执行 podman pull utility.lab.example.com/nginx:latest

insecure 则指定了允许通过 http 协议

blocked 指定是否禁用该仓库，设置 true 即可禁用

location 是指定了仓库地址



在用于指定不同的仓库地址和相关配置时

[[registry]] 作为主仓库标题，[[registry.mirror]] 作为备用仓库标题，当主仓库拉取失败时，按顺序向下面的备用仓库拉取镜像













# 8/14
## zabbix7.0 更换 apache 为 nginx 流程
系统是欧拉 24.03sp1，相关源已配置

1.卸载 httpd 并安装 nginx
```
yum -y remove httpd
yum -y install nginx
```


2.安装 zabbix 的 nginx 的相关配置文件

`yum -y install zabbix-nginx-conf`




3.修改/etc/php-fpm.d/zabbix.conf 和/etc/php-fpm.d/www.conf文件，将 用户与组更改为 nginx

![[_resources/linux笔记/c7a0dc281e1fafebc84b76cedb096137_MD5.png]]

![[_resources/linux笔记/a3fe1757247f03ca7910595c7a2e8944_MD5.png]]



4.修改 zabbix-UI 相关目录及文件的权限

![[_resources/linux笔记/8caa9f0411a06fc2cf60e32fb429176b_MD5.png]]

这里可以看到相关目录所有者和组都没有变更，nginx 用户没有权限访问

修改对应文件的所有者与组为 nginx

```
chown nginx:nginx /etc/zabbix/web/
chown nginx:nginx /etc/zabbix/web/zabbix.conf.php
```



最后重启相关服务
```
systemctl restart php-fpm.service
systemctl restart nginx.service
systemctl restart zabbix-server.service
```



与 apache 的访问路径不同，直接访问 zabbix-server 的 ip 即可

![[_resources/linux笔记/97252936acc64441117a4ba067e3c757_MD5.png]]

nginx 切换 apache 也是一样的逻辑与流程











# 8/15
## zabbix 自定义网站监控流程
以 baidu.com 为例

1.查看 dns 是否可用
ping 就可以，能 ping 通就表示 dns 可用，但 域名可以有多种，因此需要定义带参数的键值#check.ping[*],sh 脚本 "$1"  //$1 是域名，给脚本传参


2 .查看域名过期时间
check.domain[*],sh 脚本 "$1"   //$1 是域名

使用 whois 和 grep 过滤出域名过期时间，加上 awk 截取具体时间信息

```bash
[root@openEuler ~]# whois baidu.com | grep Expiry
   Registry Expiry Date: 2028-10-11T11:05:17Z
[root@openEuler ~]# whois baidu.com | grep Expiry | awk -F": |T" '{print $2}'
2028-10-11
```

使用 date 命令处理该输出

```bash
[root@openEuler ~]# date -d "`whois baidu.com | grep Expiry | awk -F": |T" '{print $2}'`"
2028年 10月 11日 星期三 00:00:00 CST
[root@openEuler ~]# date -d "`whois baidu.com | grep Expiry | awk -F": |T" '{print $2}'`" +%s
1854806400
//     +%s可以将时间转化成秒
```

使用 date +%s 同样可以将系统当前时间转换成秒,两者相减可得到域名剩余有效时间


3.查看 https 证书过期时间
check.ssl[*],sh 脚本 "$1"   //$1 是域名 https://...

使用 curl -v 获取证书信息

```bash
[root@openEuler ~]# curl -v https://baidu.com
*   Trying 182.61.244.181:443...
* Connected to baidu.com (182.61.244.181) port 443
* ALPN: curl offers h2,http/1.1
* TLSv1.3 (OUT), TLS handshake, Client hello (1):
*  CAfile: /etc/pki/tls/certs/ca-bundle.crt
*  CApath: none
* TLSv1.3 (IN), TLS handshake, Server hello (2):
* TLSv1.2 (IN), TLS handshake, Certificate (11):
* TLSv1.2 (IN), TLS handshake, Server key exchange (12):
* TLSv1.2 (IN), TLS handshake, Server finished (14):
* TLSv1.2 (OUT), TLS handshake, Client key exchange (16):
* TLSv1.2 (OUT), TLS change cipher, Change cipher spec (1):
* TLSv1.2 (OUT), TLS handshake, Finished (20):
* TLSv1.2 (IN), TLS handshake, Finished (20):
* SSL connection using TLSv1.2 / ECDHE-RSA-AES128-GCM-SHA256
* ALPN: server accepted http/1.1
* Server certificate:
*  subject: C=CN; ST=\U5317\U4EAC\U5E02; O=BeiJing Baidu Netcom Science Technology Co., Ltd; CN=www.baidu.cn
*  start date: Feb 12 00:00:00 2025 GMT
*  expire date: Mar  3 23:59:59 2026 GMT
*  subjectAltName: host "baidu.com" matched cert's "baidu.com"
*  issuer: C=US; O=DigiCert, Inc.; CN=DigiCert Secure Site Pro G2 TLS CN RSA4096 SHA256 2022 CA1
*  SSL certificate verify ok.
* using HTTP/1.1
> GET / HTTP/1.1
> Host: baidu.com
> User-Agent: curl/8.4.0
> Accept: */*
> 
< HTTP/1.1 302 Moved Temporarily
< Server: bfe/1.0.8.18
< Date: Fri, 15 Aug 2025 07:28:34 GMT
< Content-Type: text/html
< Content-Length: 161
< Connection: keep-alive
< Location: http://www.baidu.com/
< 
<html>
<head><title>302 Found</title></head>
<body bgcolor="white">
<center><h1>302 Found</h1></center>
<hr><center>bfe/1.0.8.18</center>
</body>
</html>
* Connection #0 to host baidu.com left intact

```

使用 grep 过滤并交给 awk 处理

```bash
[root@openEuler ~]# curl -v https://baidu.com |& grep "expire date"
*  expire date: Mar  3 23:59:59 2026 GMT
[root@openEuler ~]# curl -v https://baidu.com |& grep "expire date" | awk -F ": " '{print $2}'
Mar  3 23:59:59 2026 GMT
```

date 可识别该参数

```bash
[root@openEuler ~]# date -d "Mar  3 23:59:59 2026 GMT"
2026年 03月 04日 星期三 07:59:59 CST
[root@openEuler ~]# date -d "Mar  3 23:59:59 2026 GMT" +%F
2026-03-04
[root@openEuler ~]# date -d "Mar  3 23:59:59 2026 GMT" +%s
1772582399
[root@openEuler ~]# 
```

转换成秒后还是和上面一样的处理逻辑

















# 8/18
## http 协议原理总结
![[_resources/linux笔记/109d66a9732bed4014db20be12c68878_MD5.png]]









## 常见服务架构框架
1. LNMP: Linux Nginx MySQL PHP
2. LNMT: Linux Nginx MySQL Tomcat  (应用较多)
3. LAMP：Linux Apache MySQL PHP
4. LNMP:  Linux Nginx MySQL Python







## 查看某个服务的所有配置文件路径
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








## Nginx
### nginx 启动方式
有两种启动方式

1.被 systemctl 所管理

```
systemctl start nginx
systemctl stop nginx
```




2.不被 systemctl 管理，使用绝对路径运行

```bash
[root@rocky ~]# /usr/sbin/nginx
[root@rocky ~]# ss -tunlp | grep 80
tcp   LISTEN 0      128          0.0.0.0:22         0.0.0.0:*    users:(("sshd",pid=880,fd=3))                                                  
tcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=3980,fd=6),("nginx",pid=3979,fd=6),("nginx",pid=3978,fd=6))
tcp   LISTEN 0      128             [::]:22            [::]:*    users:(("sshd",pid=880,fd=4))                                                  
[root@rocky ~]# /usr/sbin/nginx -s stop
[root@rocky ~]# ss -tunlp | grep 80
tcp   LISTEN 0      128          0.0.0.0:22         0.0.0.0:*    users:(("sshd",pid=880,fd=3))         
tcp   LISTEN 0      128             [::]:22            [::]:*    users:(("sshd",pid=880,fd=4))         
[root@rocky ~]# 
[root@rocky ~]# /usr/sbin/nginx
[root@rocky ~]# ss -tunlp | grep 80
tcp   LISTEN 0      128          0.0.0.0:22         0.0.0.0:*    users:(("sshd",pid=880,fd=3))                                                  
tcp   LISTEN 0      511          0.0.0.0:80         0.0.0.0:*    users:(("nginx",pid=3980,fd=6),("nginx",pid=3979,fd=6),("nginx",pid=3978,fd=6))
tcp   LISTEN 0      128             [::]:22            [::]:*    users:(("sshd",pid=880,fd=4))                                                  
[root@rocky ~]# /usr/sbin/nginx -s stop
[root@rocky ~]# ss -tunlp | grep 80
tcp   LISTEN 0      128          0.0.0.0:22         0.0.0.0:*    users:(("sshd",pid=880,fd=3))         
tcp   LISTEN 0      128             [::]:22            [::]:*    users:(("sshd",pid=880,fd=4))         
[root@rocky ~]# /usr/sbin/nginx -s reload
```

两个管理方式不可混合使用,可执行文件 nginx 的路径默认被加入环境变量，绝对路径可加可不加







### nginx 配置文件详解
配置文件主要由指令，参数，上下文组成

```bash
[root@rocky nginx]# cat nginx.conf 
# 核心区块
user  nginx;           # 启动nginx的虚拟用户，默认在安装nginx后已经存在
worker_processes  auto;# 启动子进程的数量，auto是以cpu的内核数为准
                       # 也就是ps aux | grep nginx的子进程数量与lscpu的核心数相同
                       
error_log  /var/log/nginx/error.log notice; # 错误日志所在的日志
pid        /var/run/nginx.pid; # 进程PID所存放的目录

# 事件区块
events {
    worker_connections  1024; # 进程的最大连接数（使用tcp连接，默认1024,最大65536）
}

# http区块
http {
    include       /etc/nginx/mime.types;# 媒体类型
    default_type  application/octet-stream;# 默认如果媒体类型中不存在，则自动下载该页面

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';#定义nginx访问日志的格式
    # 可以自定义nginx访问日志格式，语法是 log_format xxx '变量名' ,调用时参考下面一行，在尾巴使用格式名xxx调用
    access_log  /var/log/nginx/access.log  main;# nginx的访问日志

    sendfile        on;# 文件高效传参
    #tcp_nopush     on;

    keepalive_timeout  65;# 长连接的超时时间

    #gzip  on;# 是否开启压缩

    include /etc/nginx/conf.d/*.conf;# 包含了conf.d目录下的所有的.conf  将*.conf的内容移动到了当前的文件中
# 三个区块是同级关系，http区块下面有server区块，server区块下面有location区块，在区块中配置模块时，作用效果也遵循包含关系

#下面的业务区块一般写在/etc/nginx/conf.d/里,虽然位置不同，但由于nginx.conf使用了include，所以相当于还是写
#在nginx.conf的server区块中
server {
        listen 80 #不加listen默认监听80端口,可以指定某个具体ip的端口
        server_name www.hello.com;#server_name的值可不写，用_代替

        location / {
        root /code/;
        index index.html;# 设置主页面的默认访问文件为index.html,指定多个时就会依次查找，即使不写也会自动查找index.html
        }
}
  # 一般用户通过浏览器访问www.hello.com  默认是www.hello.com/ 浏览器可以省略尾巴的/ ，从/开始，进入code目录查找
}
# 写完配置文件后可以使用nginx -t 检查语法
# 测试访问时还需要创建对应目录和index.html文件
# www.hello.com的公网域名肯定被人抢注了,可以利用本地解析优先DNS解析的特性，在hosts文件里写上www.hello.com的解析
# 如果访问网址错误，说明浏览器有这个网址的缓存，清一下本地缓存再访问

```





### nginx 配置多个业务
#### 1.使用多 IP 地址的方式
```bash
[root@rocky code]# ip add add 192.168.120.150/24 dev ens160
[root@rocky code]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens160: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc mq state UP group default qlen 1000
    link/ether 00:0c:29:c0:23:10 brd ff:ff:ff:ff:ff:ff
    altname enp3s0
    inet 192.168.120.129/24 brd 192.168.120.255 scope global dynamic noprefixroute ens160
       valid_lft 1013sec preferred_lft 1013sec
    inet 192.168.120.150/24 scope global secondary ens160
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fec0:2310/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
# 然后修改业务区段的listen具体端口
[root@rocky jump]# cat  /etc/nginx/conf.d/game.conf 
server {
        listen 192.168.120.150:81;
        server_name _;

        location / {
        root /code/;
        index index.htm;
        }
}

```



#### 2.使用多端口的方式
就是 listen 只加端口，省略了

#### 3.使用多域名的方式
```nginx
[root@rocky jump]# cat /etc/nginx/conf.d/*.conf
server {
  listen 80;
  server_name www.bird.com;

  location / {
    root /code/;
    index index.htm;
  }
}
server {
  listen 80;
  server_name www.jump.com;

  location / {
    root /jump/;
    index index.html;
  }
}
可以把两条写在一个conf文件中，查找顺序是从上到下，都查不到的话返回第一
个的状态码
可能会用到hosts解析，一条ip对应多个域名即可
```





### nginx 常用模块
#### 目录索引模块
该模块默认是不开启的

在配置文件中写入指令

autoindex on;

来开启目录索引模块

具体表现形式参考各大镜像站的资源列表

根据 nginx 的区块层级，写在不同层级有不同的效果



#### 密码登录验证模块


auth_basic # 描述信息 

auth_basic_user_file  # 指定用户和密码文件所在的路径  

密码文件需要使用htpasswd生成

1.安装httpd-tools 
[root@rocky ~]# yum -y install httpd-tools  

2.生成密码文件  
[root@rocky ~]# htpasswd -b -c /etc/nginx/auth_pass test 000000
Adding password for user test

3.在 location 区块中配置
```
auth_basic "abc";
auth_basic_user_file auth_pass;
```




#### IP 地址限制模块
在 location 区块里配置

限制方式: 先允许后拒绝
```
allow 192.168.120.129;
deny all; 
```

先拒绝后允许 
```
deny 10.0.0.1,10.0.0.253;
allow all;  
```

注：deny 允许多条 ip 写在一行，用 , 分隔，allow 放通多个 ip 只能写多行 allow





#### 状态模块
stub_status

配置:

```
location /nginx_status {       
stub_status;
}  
```

浏览器访问 www.ck.com/nginx_status

![[_resources/linux笔记/7f3cf656e7c39d9fa76a6233699144ca_MD5.png]]

Active connections # 当前活动的连接数

accepts # 已接收的总 TCP 连接数量

handled # 已处理的 TCP 连接数量

requests # 当前 http 请求数

Reading # 当前读取请求头数量

Writing # 当前响应的请求头数量

Waiting # 等待的请求数（处于 keepalive 的 tcp 连接），开启了 keepalive





#### 连接限制模块
limit_conn

请求限制

```nginx
http{   #http层，设置
        # Limit settings
        #该定义写在 conf.d 的 server 层外面也是一样的效果
        limit_conn_zone $remote_addr zone=conn_zone:10m;  #可以理解为将访问的远程 ip 放到一个名为 conn_zone 的地址池中，大小为 10m，在使用时就是调用该地址池做限制
            server{ #server层调用
              limit_conn conn_zone 1; #连接限制，限制同时最高1个连接
             }
    }
```



```nginx
limit_request
     # http标签段定义请求限制, rate限制速率，限制一秒钟最多一个IP请求
http {
    limit_req_zone $binary_remote_addr zone=req_zone:10m rate=1r/s;
 }
 server {
    listen 80;
    server_name module.oldboy.com;
    # 1r/s只接收一个请求,其余请求拒绝处理并返回错误码给客户端
    #limit_req zone=req_zone;
    # 请求超过1r/s,剩下的将被延迟处理,请求数超过burst定义的数量, 多余的请求返回503
    limit_req zone=req_zone burst=3 nodelay;
    location / {
        root /code;
        index index.html;
    }
 }
```



```nginx
返回的 503 状态码也可以通过定义
limit_req_status 478;
将 503 修改 为 478，写在调用下面
例:
limit_req_zone $binary_remote_addr zone=req_zone:10m rate=3r/s;
server {
        listen 80;
        server_name www.ck.com;
        location / {
        autoindex on;
        charset utf-8,gbk;
        root /cangku;
        limit_req zone=req_zone burst=3 nodelay;
        limit_req_status 478;
        error_page 478 /error.html #重定向 478 状态码页面
        }
        location /nginx_status {
        stub_status;
        }
}
```


重定向前#后面的 test 是因为之前的 location 写的 /test
![[_resources/linux笔记/9f843d783098a79efa5bd6791f926f7a_MD5.png]]



重定向后

![[_resources/linux笔记/cd30c2f44fed90ea99bc116c38efa2d4_MD5.png]]





#### 代理缓存区模块
nignx会把后端返回的内容先放到缓冲区当中，然后再返回给客户端，边收边传, 不是全部接收完再传给客户端

Syntax: proxy_buffering on | off;

Default: proxy_buffering on;

Context: http, server, location

 
设置nginx代理保存用户头信息的缓冲区大小

Syntax: proxy_buffer_size size;

Default: proxy_buffer_size 4k|8k;

Context: http, server, location

 

proxy_buffers 缓冲区

Syntax: proxy_buffers number size;

Default: proxy_buffers 8 4k|8k;

Context: http, server, location



控制是否打开后端响应内容的缓存区(on开启)

proxy_buffering on;

后端服务器的响应头会放到proxy_buffer_size当中

proxy_buffer_size 8k;

缓存区8个，每个缓存区8k大小

proxy_buffers 8 8k;





#### 代理连接超时
proxy_connect_timeout: Nginx 与后端服务器建立连接的超时时间。proxy_read_timeout: Nginx 等待后端服务器响应的超时时间。
proxy_send_timeout: Nginx 向后端服务器发送请求数据的超时时间。

作用区块都是 http，server，location，默认时间都是 60s





### location 和 root 的关系
location 是区块（或者叫上下文），root 是指令（或者理解为区块中的字段属性）

root 定义了文件查找的根，而 location 则指定了网页访问时的 url 的路径，实际上还是在 root 指定的根下的 location 指定的目录里查找，下面举例

```nginx
server {
        listen 80;
        server_name www.bird.com;

        location /download {
        root /package/;#设置根目录为/package/
        autoindex on;#以列表形式展示download内的资源
        }
}
这里访问www.bird.com/download/时，实际上在访问/packa
ge/downlad/里的内容
```

如何理解 location 和 root 之间的关系，可以这样理解:

location /dir{...}

对于/dir

一方面它是 url 的访问路径

另一方面，在 nginx 的文件查找过程中，它可以视为是由'/'和 "dir" 两部分组成，'/' 是什么，由 root 指令来定义（无论是局部的还是全局的 root），"dir" 则是具体的目录

比如 root 指令定义了 root /op

那么 nginx 的具体文件查找路径实际上就是/op/dir/      因为'/'被 root 定义为了/op（或者说替换）

root 可以写在 location 之外来定义全局根目录，但还是 location 内部的 root 定义的根目录优先级更高







### location 的匹配规则优先级
“统一不同文件路径的资源属性”，这正是 location 优先级机制要解决的核心问题之一，也是它最强大的用途。Nginx 的优先级规则，特别是正则匹配，允许你抛开“路径”这个属性，直接根据“类型”这个属性来制定规则。


在某个业务中，某个特定文件不会储存在统一的路径中，比如图片，有用户上传图片，网站主页图片，用户登录图片，这些不会储存在同一个文件夹，但会有一个需求，比如我想给所有图片文件设置一个月的浏览器缓存。这时就不可能使用 location 的精准匹配去一个个地匹配，然后在 location 区块里使用指令实现需求，那这时就会用到匹配规则优先级的概念，使用location ~* \.(gif|jpg|jpeg)${......}，我就可以实现对不同路径的 gif,jpg,jpeg 文件的统一管理，因为我有将某个特定特性的资源统一定义的需求



```nginx
#匹配优先级从上到下
#1.等号          =
#2.以开头        ^~
#3.区分大小写匹配 ~
#4.不区分大小写   ~*
#5.默认匹配       /
server {
  listen 80;
  server_name www.location.com;
  default_type text/html;
  location = / {
    return 200 "configuration A\n";
  }
  location / {
    return 200 "configuration B\n";
  }
  location /documents/ {
    return 200 "configuration C\n";
  }
  location ^~ /images/ {
    return 200 "configuration D\n";
  }
  location ~* \.(gif|jpg|jpeg)$ {
    return 200 "configuration E\n";
  }
}
```




### nginx 与 php 通信


在 LNMP 架构中，需要实现 nginx 与 php 的通信，通信方式主要有两种方式，通过 socket 和端口通信，在 php-fpm 的配置文件中，listen = 属性指定了通信方式，我使用的 php8.2 默认使用 socket 通信，listen 的配置是

listen = /run/php-fpm/www.sock

如果我想让 nginx 使用 socket 与 php 通信的话，就需要在 nginx 的配置文件中指定该套接字文件(缺点是不能跨主机通信,以及会涉及用户权限问题)

fastcgi_pass unix:/run/php-fpm/www.sock；

如果想让 nginx 使用端口(比如 9000 端口)与 php 通信，就需要修改 php 的配置
listen = 127.0.0.1:9000


使用套接字进行通信又涉及到一个权限问题，从而导致网页报告 502 Bad GateWay 错误，这是由于 nginx 无法与 php 建立通信导致的



在 wordpress 的搭建中，为了统一权限问题，可以使用一个统一用户进行管理，用户与组 id 定在 1000 之内表示这是一个系统用户，同时 useradd 时加上-M 选项 不创建家目录并且指定 shell 类型为禁止登录



在修改了 nginx 的用户和 php 的用户与组后，如果 nginx 和 php 是通过 socket 进行通信，则还需要修改指定的套接字文件相关的权限，虽然 php 直接指定了文件的位置，但 socket 文件是一个特殊的临时文件，仅在通信过程中使用，重启 php-fpm 则会销毁该文件并重新生成，所以这个文件不能用简单的 chown 来修改权限问题，不过 /etc/php-fpm.d/www.conf 文件提供了修改套接字文件权限问题的字段，修改至对应用户重启并生效

```bash
[root@rocky alice]# grep '^listen.acl' /etc/php-fpm.d/www.conf 
listen.acl_users = www
[root@rocky alice]# systemctl restart php-fpm.service 
[root@rocky alice]# ll /var/run/php-fpm/
总用量 4
-rw-r--r--  1 root root 4  9月  1 15:27 php-fpm.pid
srw-rw----+ 1 root root 0  9月  1 15:27 www.sock
#可以看到这里的套接字文件的所以者与组都没变，但这并不影响通信
```

如果想要修改套接字的所有者与所属组为 www 的话，需要修改

listen.owner = www

listen.group = www

但需要注释刚刚修改的那一行，因为listen.acl_users 配置是优先级最高的，会使这两行配置被忽略（该配置的注释里有详细说明）





# 8/21
## DNS 解析流程
本地主机名是 rocky.linux.com

在浏览器的 url 栏中输入域名 rocky.linux.com 时，有多个流程，当前流程失败就走下一个流程

![[_resources/linux笔记/f310b68af89c66d83487d5c9b5a03840_MD5.jpg]]







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

常用属性
|属性|说明|
|---|---|
|a|仅追加：文件只能追加内容，不能删除或修改已有内容（需 root 权限）。|
|i|不可变：文件不能被删除、修改、重命名或创建硬链接（需 root 权限）。|
|A|不更新文件的最后访问时间（atime）。|
|c|文件在磁盘上自动压缩（部分文件系统支持）。|
|s|安全删除：文件被删除时，其数据会被清零（不可恢复）。|
|u|文件被删除后，其内容仍可恢复（与 s 相反）。|
|d|文件在 dump 备份时会被跳过。|










## 云主机 Rocky9 部署 WordPress
腾讯云免费试用了一台云主机 Rocky9.4，拿来搭一个 WordPress，使用 LAMP 架构

1.安装并启用 httpd
```
dnf install httpd -y
systemctl enable --now httpd
```



2.放通防火墙

（云主机把防火墙和 selinux 的功能交给安全组管理，防火墙和 selinux 都被禁用了，所以这个不用执行，但还是记下来给普通主机参考）
```
firewall-cmd --add-service=http --permanent  
firewall-cmd --reload
```



3.创建数据库和用户(用户可以不创建，使用默认的 root 用户也行)
```
dnf -y install mariadb-server
systemctl enable  --now mariadb.service
mysql -uroot
```

进入数据库后
```
CREATE DATABASE mywordpress_db;
CREATE USER 'wp_foc'@'localhost' IDENTIFIED BY 'Pp123456';
GRANT ALL ON mywordpress_db.* TO 'wp_foc'@'localhost';
FLUSH PRIVILEGES;
```
这里设置了:

```
Database: mywordpress_db
User Name:wp_foc
Password:Pp123456
```



4.下载并提取 WordPress
```
dnf install wget unzip -y
wget https://wordpress.org/latest.zip
unzip latest.zip
mv wordpress /var/www/html/
```

5.修改用户，组和权限
```
chown -R apache:apache /var/www/html/wordpress
chmod -R 775 /var/www/html/wordpress
```



6.selinux 放通 httpd（还是不用执行，上面说了原因）

```plain
[root@VM-24-6-rockylinux ~]#semanage fcontext -a -t httpd_sys_rw_content_t "/var/www/html/wordpress(/.*)?"
[root@VM-24-6-rockylinux ~]#restorecon -Rv /var/www/html/wordpress
```


7.修改相关配置文件，填写数据库，密码，用户名
`vi /var/www/html/wordpress/wp-config.php`
修改内容如下
```
define( 'DB_NAME', 'mywordpress_db' );  
  /** Database username */  
define( 'DB_USER', 'wp_foc' );  
  /** Database password */  
define( 'DB_PASSWORD', 'Pp123456' );
```


8.重启 http 并访问 WordPress 主页
`systemctl restart httpd`

访问前看一下有没有安全组有没有放通 http 规则，不过一般都默认放通常用服务协议和端口

访问 url 参考[http://192.168.122.238/wordpress/wp-admin/install.php](http://192.168.122.238/wordpress/wp-admin/install.php)












# 8/22
## TCP 三次握手原理


![[_resources/linux笔记/338cb5e208708cf7466e0de831fba7a5_MD5.png]]

```
TCB           传输控制块，打开后服务器/客户端进入监听(LISTEN)状态
SYN=1      请求建立连接
seq            报文初始序列号，代表发送的第一个字节的序号
Ack=1       确认收到了客户端信息
ack            报文确认序号，代表希望收到的下一个数据的第一个字节的序号
```



### 第一次握手: 客户端—请求

1. 应用程序调用 `connect()` 系统调用。
    
2. 内核协议栈开始工作：
    
    - 创建TCB（传输控制块），初始化序列号 `seq=x`，构建一个 `SYN=1` 的TCP报文段。
        
    - 将这个TCP报文段下交给IP层，IP层为其添加IP报头成为数据包，再下交给数据链路层。
        
    - 数据链路层为该数据包添加帧头和帧尾将它封装为一个完整的数据帧。
        
3. 数据链路层将数据帧排入发送队列，套接字的状态从 `CLOSED` 更新为 `SYN-SENT`（状态转换是“将SYN报文成功交付给下层协议（即本地协议栈）”的结果，而不是“数据帧被网卡物理发送到链路上”的结果。），最后由网卡驱动程序将数据帧发送到网络链路上。




### 第二次握手: 服务器—确认
服务器设置 ACK=1，表示确认应答

设置 ack=x+1，表示已收到客户端 x 之前的数据，希望下次数据从 x+1 开始

设置 SYN=1，表示握手报文，并发送给客户端

设置发送的数据包序列号 seq=y

此时服务器处于同步已接收 SYN-RCVD 状态



### 第三次握手: 客户端—确认服务器的确认
设置 ACK=1，表示确认应答
设置 ack=y+1，表示收到服务器发来的序列号为 seq=y 的数据包，希望下次数据从 y+1 开始
设置 seq=x+1，表示接着上一个数据包 seq=x 继续发送


至此三次握手结束，连接建立







## 报文、数据包 、帧的关系

这是一个关于网络分层模型的问题。

报文 (Segment)： 这是传输层（TCP层） 的协议数据单元（PDU）。它包含TCP头（源/目的端口、序列号、确认号、标志位SYN/ACK等）和可选的应用层数据。在三次握手期间，SYN和ACK报文不携带任何应用层数据，它们的“数据”部分长度为0。 数据包 (Packet)： 这通常指的是网络层（IP层） 的协议数据单元。一个TCP报文在发送前，会被封装到一个IP数据包中。IP数据包由IP头（源/目的IP地址）和“载荷”组成，这个“载荷”就是整个TCP报文。 帧 (Frame)： 再往下，IP数据包又会被数据链路层封装成“帧”，添加MAC地址等信息，最后变成比特流由物理层发送出去。

它们的关系是层层封装的： [ 帧头 | IP头 | TCP头 (SYN=1) | (数据) | 帧尾 ]






# 8/30

## HTTP 状态码格式规范

|范围|类别|含义|常见例子|
|---|---|---|---|
|1xx|信息响应|请求已被接收，继续处理。
|2xx|成功|请求已成功被服务器接收、理解并接受。
|3xx|重定向|需要客户端采取进一步的操作才能完成请求。
|4xx|客户端错误|请求本身有问题（如语法错误、无法实现等）。
|5xx|服务器错误|服务器处理有效请求时失败。






# 9/1
## Rocky9.6 本地部署 wordpress
基于 LNMP 架构部署wordpress-6.7

php 和 mysql 版本如下

```plain
[root@rocky ~]# mysql --version
mysql  Ver 15.1 Distrib 10.5.27-MariaDB, for Linux (x86_64) using  EditLine wrapper
[root@rocky ~]# php -v
PHP 8.2.29 (cli) (built: Jul  1 2025 16:29:21) (NTS gcc x86_64)
Copyright (c) The PHP Group
Zend Engine v4.2.29, Copyright (c) Zend Technologies
    with Zend OPcache v8.2.29, Copyright (c), by Zend Technologies
```



1.安装 nginx

```plain
[root@rocky ~]# yum -y install nginx
[root@rocky ~]# nginx -v
nginx version: nginx/1.28.0
```



2.配置 php 源

这里选用了 remi 源（个人维护的 php 软件源站点），注意版本即可
安装 epel 源

```
dnf install [https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm](https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm) [https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-9.noarch.rpm](https://dl.fedoraproject.org/pub/epel/epel-next-release-latest-9.noarch.rpm)
```


安装 Remi 源

```
dnf -y install [http://rpms.remirepo.net/enterprise/remi-release-9.rpm](http://rpms.remirepo.net/enterprise/remi-release-9.rpm)
dnf -y install  dnf-utils
```


删除已有（可选）
`sudo dnf -y remove php php-fpm`


删除相关扩展包
sudo dnf -y remove php*

重置 PHP 模块列表
sudo dnf -y module list reset php

查看 PHP 版本
sudo dnf module list php

启用 PHP
sudo dnf -y module enable php:remi-8.2






3.安装 php，mariadb 及其必要组件
安装 php
`dnf -y install php php-fpm`

安装拓展
```
dnf install php-cli php-fpm php-curl php-mysqlnd php-gd php-opcache php-zip php-intl php-common php-bcmath php-imagick php-xmlrpc php-json php-readline php-memcached php-redis php-mbstring php-apcu php-xml php-dom php-redis php-memcached php-memcache
```



安装 mariadb

```bash
[root@rocky ~]# yum install -y mariadb-server
[root@rocky ~]# mysql --version
mysql  Ver 15.1 Distrib 10.5.27-MariaDB, for Linux (x86_64) using  EditLine wrapper
```



4.从 wordpress 官网下载源码包并解压到网站目录 alice

```bash
[root@rocky ~]# wget https://cn.wordpress.org/wordpress-6.7-zh_CN.tar.gz
--2025-09-01 16:58:28--  https://cn.wordpress.org/wordpress-6.7-zh_CN.tar.gz
正在解析主机 cn.wordpress.org (cn.wordpress.org)... 198.143.164.252
正在连接 cn.wordpress.org (cn.wordpress.org)|198.143.164.252|:443... 已连接。
已发出 HTTP 请求，正在等待回应... 200 OK
长度：33984379 (32M) [application/octet-stream]
正在保存至: “wordpress-6.7-zh_CN.tar.gz”

wordpress-6.7-zh_CN.tar.gz                100%[=====================================================================================>]  32.41M  7.99MB/s  用时 4.5s    

2025-09-01 16:58:34 (7.19 MB/s) - 已保存 “wordpress-6.7-zh_CN.tar.gz” [33984379/33984379])
[root@rocky ~]# tar xf wordpress-6.7-zh_CN.tar.gz -C /alice/
```



5.创建用户用于统一管理 nginx，php

避免繁杂的权限问题
```
[root@rocky ~]# groupadd -g 666 www  
[root@rocky ~]# useradd -u 666 -g 666 -M -s /sbin/nologin www
```



6.修改相关用户及权限

```bash
[root@rocky ~]# grep -w user /etc/nginx/nginx.conf
user  www;
[root@rocky ~]# egrep '^user|^group' /etc/php-fpm.d/www.conf 
user = www
group = www
[root@rocky ~]# chown www:www /alice/wordpress/
```



7.修改 php-fpm 监听端口

```bash
[root@rocky ~]# grep '^listen' /etc/php-fpm.d/www.conf 
listen = 127.0.0.1:9000
[root@rocky ~]# systemctl enable --now  php-fpm.service 
Created symlink /etc/systemd/system/multi-user.target.wants/php-fpm.service → /usr/lib/systemd/system/php-fpm.service.
[root@rocky ~]# netstat -tunlp | grep 9000
tcp        0      0 127.0.0.1:9000          0.0.0.0:*               LISTEN      6651/php-fpm: maste 
```



测试 nginx，php 连通性

```bash
[root@rocky ~]# cat /etc/nginx/conf.d/php.conf 
server {
        listen 80;
        server_name php.test.com;
        root /php;
        location / {
                index index.php index.html;
        }
        location ~ \.php$ {
                fastcgi_pass 127.0.0.1:9000;
                fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                include fastcgi_params;
        }
 }
[root@rocky ~]# cat /php/index.php 
<?php
     phpinfo();
?>
```

访问网站php.test.com 测试，在 hosts 文件里做好相关映射



7.书写网站配置文件

```bash
[root@rocky ~]# cat /etc/nginx/conf.d/wordpress.conf 
server {
        listen 80;
        server_name php.alice.com;
        root /alice/wordpress;
 
        location / {
                 index index.php index.html;
        }
        # 区分大小写，定义所有.php结尾的文件属性，使其能够连接php
        location ~ \.php$ {
                 fastcgi_pass 127.0.0.1:9000; #指定nginx连接php端口
                 fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                 # 为SCRIPT_FILENAME变量赋值，$document_root被赋值为上面root指定的/alice/wordpress
                 # $fastcgi_script_name被赋值为请求的uri
                 # uri是域名/后的内容，如www.qq.com/test.php，这里的uri就是/test.php
                 include fastcgi_params;# # 引入标准 FastCGI 参数文件，确保所有必要参数被设置
        }
}
```



8.初始化 mysql 设置密码
 `[root@rocky ~]# mysqladmin password '000000'`  



测试 MySQL 和 php 连通性 

```bash
[root@rocky ~]# cat /alice/mysql.php 
<?php
     $servername = "localhost";
     $username = "root";
     $password = "000000";

     $conn = mysqli_connect($servername, $username, $password);

     if (!$conn) {
	     die("Connection failed: " . mysqli_connect_error());
     }
     echo "php可以连接MySQL~";
?>
<img style='width:100%;height:100%;' src=images/hx.png>
```

访问 php.alice.com/mysql.php



9.创建 wordpress 所需数据库
 `[root@web01 wordpress]#mysql -uroot -p000000 -e "create database wordpress;"`  



10.修改 wordpress 配置文件

/alice/wordpress/wp-config-sample.php 是示例文件（很多 php 源码包都会这样设计，字段里带 sample）

先把这个文件重命名为wp-config.php

然后再修改指定的数据库位置，用户名密码等信息



11.访问 php.alice.com 即可







## wordpress 重置密码
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










# 9/2
## LNMP 架构拆分
### 一、数据库迁移
```
db01(Rocky9.6)    192.168.120.150
web01(Rocky9.6)  192.168.120.129
```

基础软件源配置省略

1.db01 部署 mariadb 服务
```
[root@db01 ~]# yum -y install mariadb-server
[root@db01 ~]# systemctl enable --now mariadb
```


2.web01 备份数据库并拷贝到 db01
```
[root@web01 ~]# mysqldump -uroot -p000000 -A > all.sql
[root@web01 ~]# scp all.sql 192.168.120.150:/root/
```


3.db01 导入数据库文件
```
[root@db01 ~]# mysql -uroot < all.sql
[root@db01 ~]# systemctl restart mariadb
```


4.设置数据库远程用户
```
[root@db01 ~]# mysqladmin -uroot password '000000'
[root@db01 ~]# mysql -uroot
```

进入数据库后执行
`grant all on *.* to caster@'%' identified by '000000';`
设置远程用户 caster 密码 000000 拥有全部权限


5.web01 远程连接数据库

```bash
[root@rocky ~]# systemctl stop mariadb
[root@rocky ~]# mysql -h 192.168.120.150 -uroot -p000000  # 先用root账户测试
ERROR 1045 (28000): Access denied for user 'root'@'192.168.120.129' (using password: YES)
[root@rocky ~]# mysql -h 192.168.120.150 -ucaster -p000000
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 5
Server version: 10.5.27-MariaDB MariaDB Server

Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

MariaDB [(none)]> 
```



6.修改 php 连接数据库配置文件
```
[root@web01 ~]# grep '^define' /alice/wordpress/wp-config.php 
define( 'DB_NAME', 'wordpress' );
define( 'DB_USER', 'caster' );
define( 'DB_PASSWORD', '000000' );
define( 'DB_HOST', '192.168.120.150' );
```





### 二、扩展 web 服务
```
web01 192.168.120.129
web02 192.168.120.151
db01 192.168.120.150
```



1.准备一台 web02

配置相关源，nginx 的源配置在官网找，有手册

php 的和上面的一样的源配置。使用 remi 源



2.创建虚拟用户 www
```
[root@web02 ~]# groupadd -g666 www
[root@web02 ~]# useradd -u 666 -g 666 -M -s /sbin/nologin www
```


3.web02 服务器部署 nginx

`[root@web02 ~]# yum install nginx -y`



4.web02 服务器部署 php
```
[root@web02 ~]# dnf -y install php php-fpm
[root@web02 ~]# dnf install php-cli php-fpm php-curl php-mysqlnd php-gd php-opcache php-zip php-intl php-common php-bcmath php-imagick php-xmlrpc php-json php-readline php-memcached php-redis php-mbstring php-apcu php-xml php-dom php-redis php-memcached php-memcache
```


5.nginx 配置无差异同步 web01
`[root@web02 ~]# rsync -avz --delete 192.168.120.129:/etc/nginx /etc/`


6.php 配置无差异同步 web01
`[root@web02 ~]# rsync -avz --delete 192.168.120.129:/etc/php-fpm.d/www.conf /etc/php-fpm.d/`



7.web01 将整个代码目录拷贝到 web02
```
[root@web01 ~]# tar czf code.tar.gz /alice/
[root@web01 ~]# scp code.tar.gz 192.168.120.151:/root/
[root@web02 ~]# tar zxf code.tar.gz -C /
```



8.启动 web02 的 php，nginx，禁用 web01 相关服务
```
[root@web02 ~]# systemctl enable --now nginx
[root@web02 ~]# systemctl enable --now php-fpm.service 
[root@web01 ~]# systemctl stop nginx.service 
[root@web01 ~]# systemctl disable nginx.service 
[root@web01 ~]# systemctl stop php-fpm.service 
[root@web01 ~]# systemctl disable php-fpm.service 
```



9.修改相关主机名映射，访问网站即可





### 三、配置 NFS 服务
```
web01 192.168.120.129   nfs客户端
web02 192.168.120.151   nfs客户端
nfs 192.168.120.152     nfs 服务端
```



1.准备一台 nfs 服务器

2.安装 nfs 服务
`[root@nfs ~]# yum -y install nfs-utils rpcbind`


3.配置 nfs 服务

创建相关用户与组
```
[root@nfs ~]# groupadd -g666 www
[root@nfs ~]# useradd -u 666 -g 666 -M -s /sbin/nologin www
```


创建本地远程目录/alice/wp 并修改所有者与所属组
```
[root@nfs ~]# mkdir -pv /alice/wp
[root@nfs ~]# chown -R www:www /alice/
[root@nfs ~]# cat /etc/exports
/alice/wp 192.168.120.0/24(rw,sync,all_squash,anonuid=666,anongid=666)
[root@nfs ~]# systemctl enable --now nfs-server.service
```

检查配置是否生效

```bash
[root@nfs ~]# cat /var/lib/nfs/etab 
/alice/wp	192.168.120.0/24(rw,sync,wdelay,hide,nocrossmnt,secure,root_squash,all_squash,no_subtree_check,secure_locks,acl,no_pnfs,anonuid=666,anongid=666,sec=sys,rw,secure,root_squash,all_squash) 
```



客户端挂载

1 客户端安装 nfs（不需要启动）

```bash
[root@web01 ~]# yum -y install nfs-utils
[root@web02 ~]# yum -y install nfs-utils
```



2.将 web01 和 web02 上本地磁盘上的图片推送到 nfs 服务端

wordpress 上传图片的目录是 wordpress/wp-content/uploads/

```bash
[root@web01 ~]# scp -r /alice/wordpress/wp-content/uploads/2025 192.168.120.152:/alice/wp/
[root@web01 ~]# scp -r /alice/wordpress/wp-content/uploads/2025/09/* 192.168.120.152:/alice/wp/2025/09/
```



3.开始挂载

```bash
[root@web01 ~]# showmount -e 192.168.120.152
Export list for 192.168.120.152:
/alice/wp 192.168.120.0/24
[root@web01 ~]# mount -t nfs 192.168.120.152:/alice/wp /alice/wordpress/wp-content/uploads/
[root@web01 ~]# df
文件系统                     1K-块    已用     可用 已用% 挂载点
devtmpfs                      4096       0     4096    0% /dev
tmpfs                       375032       0   375032    0% /dev/shm
tmpfs                       150016    4476   145540    3% /run
/dev/mapper/rl-root       49201152 6387592 42813560   13% /
/dev/nvme0n1p1              983040  611584   371456   63% /boot
tmpfs                        75004      52    74952    1% /run/user/42
tmpfs                        75004      36    74968    1% /run/user/0
192.168.120.152:/alice/wp 49201152 6023296 43177856   13% /alice/wordpress/wp-content/uploads
[root@web01 ~]# 
```



```bash
[root@web02 ~]# mount -t nfs 192.168.120.152:/alice/wp /alice/wordpress/wp-content/uploads/
[root@web02 ~]# df
文件系统                     1K-块    已用     可用 已用% 挂载点
devtmpfs                      4096       0     4096    0% /dev
tmpfs                       375024       0   375024    0% /dev/shm
tmpfs                       150012    4468   145544    3% /run
/dev/mapper/rl-root       49201152 6384584 42816568   13% /
/dev/nvme0n1p1              983040  611584   371456   63% /boot
tmpfs                        75004      52    74952    1% /run/user/42
tmpfs                        75004      36    74968    1% /run/user/0
192.168.120.152:/alice/wp 49201152 6023296 43177856   13% /alice/wordpress/wp-content/uploads
[root@web02 ~]# 
```



nfs 挂载可写进 fstab 里

```bash
192.168.120.152:/alice/wp /alice/wordpress/wp-content/uploads/  nfs   defaults      0 0
```

网站的图片上传文件大小受限制，可以修改配置文件调整大小限制
```
client_body_buffer_size 16k;
client_max_body_size 20m;
```
写在 http，server，location 区块都可以，写得越大，网站访问速度就越慢

同时还要修改 php 配置文件

```bash
[root@web02 ~]# egrep "upload_max_filesize|max_file_uploads|post_max_size" /etc/php.ini 
; Default Value: -1 (Sum of max_input_vars and max_file_uploads)
post_max_size = 20M
upload_max_filesize = 20M
max_file_uploads = 20
```

nginx，php-fpm 重启后生效



修改 hosts 映射为 web01，浏览器访问

![[_resources/linux笔记/be97a9f8ca9e0b1767a6726f0e9d1c6c_MD5.png]]

该图片是 web02 上传的，web01 可正常访问

这样就实现了无论从 web01 还是 02 上传图片，都不影响 网站图片 的整体访问











# 9/3
## Ngnix 反向代理
两台机器
```
rocky_nginx 192.168.120.153
web01 192.168.120.129
```



配置 web01 的静态页面

```bash
[root@web01 ~]# cat /etc/nginx/conf.d/static.conf 
server {
        listen 80;
        server_name www.static.com;
        
        location / {
        root /alice/test;
        index index.html;
        }
}
[root@web01 ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@web01 ~]# systemctl restart nginx
[root@web01 ~]# mkdir -p /alice/test
[root@web01 ~]# echo '<h1>web01 is here!</h1>' > /alice/test/index.html
hosts映射写在win11上面了

 
```



1.准备一台 nginx 反向代理服务器

`rocky9.6 192.168.120.153`
基于上面的 LNMP 架构拆分
软件源配置省略了


2.安装并配置 nginx

```bash
[root@nginx ~]# yum -y install nginx
[root@nginx ~]# cat /etc/nginx/conf.d/default.conf 
server {
        listen 80;
        server_name www.static.com;
        
        location / {
        proxy_pass http://192.168.120.129;
        }
}
[root@nginx ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@nginx ~]# systemctl restart nginx
```

win11 访问 www.static.com(域名映射的是 192.168.120.153)

![[_resources/linux笔记/ad1f3a640f9a46059c6c6e512e5207df_MD5.png]]

返回的却是这个(这个是其他 server 服务)

使用 WireShark 抓包分析得到下面两条

![[_resources/linux笔记/4a8460ea803585486720dece4c97fee1_MD5.png]]

192.168.120.1 访问.153 时，注意蓝色标注条目

Host: www.static.com\r\n

可以看到 host 头部域名正确

![[_resources/linux笔记/fb68b5c4f4dc1a5d5b04f2bc61ee9c87_MD5.png]]

然而在 153（rocky_nginx） 请求 129（web01） 时，host 头部变成了
Host: 192.168.120.129\r\n
头部信息（域名 www.static.com）被丢弃，协议也从 http1.1（长连接） 变成了 http1.0（短连接）



这时就需要给 nginx 配置加参数，使其携带头部信息

```bash
[root@nginx ~]# cat /etc/nginx/conf.d/default.conf 
server {
        listen 80;
        server_name www.static.com;
        
        location / {
        proxy_pass http://192.168.120.129;
        proxy_set_header Host $http_host; #要求在下一次转发保留头部信息
        proxy_http_version 1.1; #保留协议
        }
}
[root@nginx ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@nginx ~]# systemctl restart nginx
```

再次访问

![[_resources/linux笔记/ebcaf011778388591d7ab089a65df672_MD5.png]]



然后就涉及到一个问题，代理服务器访问 web01，web01 的 nginx 的 access 日志  保存的源 ip 是代理服务器的 ip 而不是客户端 ip，这没有意义

![[_resources/linux笔记/d1782f9d352ebf91850f52160198b97a_MD5.png]]



回到 nginx 反向代理服务器配置

```bash
[root@nginx ~]# cat /etc/nginx/conf.d/default.conf 
server {
        listen 80;
        server_name www.static.com;
        
        location / {
        proxy_pass http://192.168.120.129;
        proxy_set_header Host $http_host;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;# 添加这一条
        }
}
[root@nginx ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@nginx ~]# systemctl restart nginx
[root@nginx ~]# 
```

浏览器再次访问然后查看 web01 的访问日志，可以看到新增一条客户端访问的 ip

![[_resources/linux笔记/603a732955a5a5f3b6716d71d4691b7f_MD5.png]]

这里能够显示远程 ip 不仅仅是因为配置了这一条

还是因为早在 nginx.conf 里就定义了 access 的变量内容（标红的那一条）

```
log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
 '$status $body_bytes_sent "$http_referer" '
  '"$http_user_agent" "<font style="color:#DF2A3F;">$http_x_forwarded_for</font>"';
```



反向代理到这里还需要进行调优

在 nginx 反向代理服务器上配置(模块介绍见上面的 'nginx 常用模块')

```bash
[root@nginx ~]# cat /etc/nginx/conf.d/default.conf 
server {
        listen 80;
        server_name www.static.com;
        
        location / {
        proxy_pass http://192.168.120.129;
        proxy_set_header Host $http_host;
        proxy_http_version 1.1;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_connect_timeout 30;
        proxy_send_timeout 60;
        proxy_read_timeout 60;
        proxy_buffering on;
        proxy_buffer_size 32k;
        proxy_buffers 4 128k;
        }
}
[root@nginx ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@nginx ~]# systemctl restart nginx
```



这样写较为繁琐且观感不好，可以使用 include 指令将这些模块写到其他文件中

```bash
[root@nginx ~]# cat /etc/nginx/conf.d/default.conf 
server {
        listen 80;
        server_name www.static.com;
        
        location / {
        proxy_pass http://192.168.120.129;
        include proxy_params;
        }
}
[root@nginx ~]# cat /etc/nginx/proxy_params 
proxy_set_header Host $http_host;
proxy_http_version 1.1;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_connect_timeout 30;
proxy_send_timeout 60;
proxy_read_timeout 60;
proxy_buffering on;
proxy_buffer_size 32k;
proxy_buffers 4 128k;
[root@nginx ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@nginx ~]# systemctl restart nginx
[root@nginx ~]# 
```





## Nginx 负载均衡
从上面继续，添加一台 LNMP 拆分架构里的 web02，web02 部署静态页面过程省略
```
Rocky_nginx      192.168.120.153
web01               192.168.120.129
web02               192.168.120.151
```



修改反向代理服务器的 nginx 配置

```bash
[root@nginx ~]# cat /etc/nginx/conf.d/default.conf 
#定义一个名为webs的地址池
upstream webs {
      server 192.168.120.129;
      server 192.168.120.151;
}
server {
        listen 80;
        server_name www.static.com;
        
        location / {
        proxy_pass http://webs;#调用定义的地址池
        include proxy_params;
        }
}
[root@nginx ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@nginx ~]# systemctl restart nginx
[root@nginx ~]# vim /etc/hosts 
[root@nginx ~]# curl www.static.com
<h1>web01 is here!</h1>
[root@nginx ~]# curl www.static.com
<h1>web02 is here!</h1>
#负载均衡配置成功
```



把上面做的 wordpress 配置负载均衡也是一样的

```bash
[root@nginx ~]# cat /etc/nginx/conf.d/wordpress.conf 
server {
        listen 80;
        server_name php.alice.com;
        
        location / {
        proxy_pass http://webs;
        include proxy_params;
        }
}
[root@nginx ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@nginx ~]# 
```



在某一台 web 服务器因故障无法连接数据库时（停止 php-fpm 服务模拟故障），页面由于做了负载均衡，在刷新时会因为将请求转发到了故障的 web 服务器从而报 502 错误，这时就可以做一些优化

```bash
[root@nginx ~]# cat /etc/nginx/conf.d/default.conf 
upstream webs {
      server 192.168.120.129;
      server 192.168.120.151;
}
server {
        listen 80;
        server_name www.static.com;
        
        location / {
        proxy_pass http://webs;
        include proxy_params;
        }
}

server {
        listen 80;
        server_name php.alice.com;
        
        location / {
        proxy_pass http://webs;
        include proxy_params;
        proxy_next_upstream error timeout http_500 http_502 http_503 http_504;
        #添加该条，意思是只要页面报500，502，503，504这些错误，nginx就会将请求转发到upstream定义
        #的地址池中的其他服务器
        }
}
[root@nginx ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@nginx ~]# systemctl restart nginx
[root@nginx ~]# 
```





## Nginx 负载均衡调度算法
1. rr 轮询
2. 加权轮询
3. ip_hash   ip 哈希
4. url_hash  url 哈希
5. 最少链接数


1.rr 轮询

```bash
upstream webs {
      server 192.168.120.129;
      server 192.168.120.151;
}
#轮流访问
```



2.加权轮询

```bash
upstream webs {
      server 192.168.120.129 weight=5;#访问5次129后访问一次151
      server 192.168.120.151;
}
#服务器资源性能不同时可以使用
```



3.ip_hash

```bash
upstream webs {
      ip_hash;
      server 192.168.120.129;
      server 192.168.120.151;
}
#第一次访问的是哪个节点，就会一直访问该节点
缺点：导致负载均衡不均衡
优点：自动实现会话保持
```





## Nginx 负载均衡后端状态
down             当前的 server 暂时不参与负载均衡

backup          预留的备份服务器

max_fails       允许请求失败的次数      

fail_timeout   经过 max_fails 失败后，服务暂停时间

max_conns    限制最大的接收连接数

用法就是写在地址池的 server 尾巴那里;



















# 9/4
## linux 调用历史命令
有两种方式

1. 使用 history 命令查看执行过的命令，输入对应历史命令的序号，前面加上！即可快速执行该命令

![[_resources/linux笔记/0a9ff3e23f5be961b7f6d8b4d9a2621e_MD5.png]]



2.直接使用 ！

使用  '!关键字'  可以快速查找并执行 最后一次执行的 以该关键字开头的命令

![[_resources/linux笔记/4b6f5fca635758aa4ed26d1ddc0094b2_MD5.png]]

没用的小知识又增加了





## Nginx 编译安装
想要实现一个功能，但是 Nginx 没有默认没有此模块，需要编译安装的方式将新的模块编译进已安装的 nginx

这里需要安装 nginx_upstream_check  模块



在反向代理服务器上配置

Rockylinux9.6

主机名   nginx

ip          192.168.120.153



检查 nginx 默认模块

```bash
[root@nginx ~]# nginx -V
nginx version: nginx/1.28.0
built by gcc 11.5.0 20240719 (Red Hat 11.5.0-5) (GCC) 
built with OpenSSL 3.2.2 4 Jun 2024
TLS SNI support enabled
configure arguments: --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-http_v3_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --with-cc-opt='-O2 -flto=auto -ffat-lto-objects -fexceptions -g -grecord-gcc-switches -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -fstack-protector-strong -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -m64 -march=x86-64-v2 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -pie'
```



1.安装依赖

```bash
[root@nginx ~]# yum install -y gcc glibc gcc-c++ pcre-devel openssl-devel patch redhat-rpm-config.noarch zlib-devel
```



2.下载和已经安装的 Nginx 版本相同的源码

```bash
[root@nginx ~]# nginx -v
nginx version: nginx/1.28.0
[root@nginx ~]# wget https://nginx.org/download/nginx-1.28.0.tar.gz
--2025-09-04 14:47:59--  https://nginx.org/download/nginx-1.28.0.tar.gz
正在解析主机 nginx.org (nginx.org)... 52.58.199.22, 3.125.197.172, 2a05:d014:5c0:2601::6, ...
正在连接 nginx.org (nginx.org)|52.58.199.22|:443... 已连接。
已发出 HTTP 请求，正在等待回应... 200 OK
长度：1280111 (1.2M) [application/octet-stream]
正在保存至: “nginx-1.28.0.tar.gz”

nginx-1.28.0.tar.gz                       100%[=====================================================================================>]   1.22M  --.-KB/s  用时 0.01s   

2025-09-04 14:47:59 (82.7 MB/s) - 已保存 “nginx-1.28.0.tar.gz” [1280111/1280111])

[root@nginx ~]# 
```



下载第三方模块

是 github 上的[https://github.com/yaoweibin/nginx_upstream_check_module](https://github.com/yaoweibin/nginx_upstream_check_module)

下载到 windows 后传到虚拟机里

```bash
[root@nginx code]# tar -xf ../nginx-1.28.0.tar.gz
[root@nginx code]# unzip ../nginx_upstream_check_module-master.zip
#解压下载的源码包和模块
[root@nginx code]# ll
总用量 8
drwxr-xr-x 8  502 games 4096  4月 23 19:55 nginx-1.28.0
drwxr-xr-x 6 root root  4096 11月  6  2022 nginx_upstream_check_module-master
[root@nginx code]# cd nginx-1.28.0/
[root@nginx nginx-1.28.0]# patch -p1 < ../nginx_upstream_check_module-master/
CHANGES                                   check_1.2.6+.patch                        nginx-tests/
check_1.11.1+.patch                       check_1.5.12+.patch                       ngx_http_upstream_check_module.c
check_1.11.5+.patch                       check_1.7.2+.patch                        ngx_http_upstream_check_module.h
check_1.12.1+.patch                       check_1.7.5+.patch                        ngx_http_upstream_jvm_route_module.patch
check_1.14.0+.patch                       check_1.9.2+.patch                        README
check_1.16.1+.patch                       check.patch                               test/
check_1.20.1+.patch                       config                                    upstream_fair.patch
check_1.2.1.patch                         doc/                                      util/
check_1.2.2+.patch                        nginx-sticky-module.patch                 
[root@nginx nginx-1.28.0]# patch -p1 < ../nginx_upstream_check_module-master/check_1.20.1+.patch 
patching file src/http/modules/ngx_http_upstream_hash_module.c
Hunk #2 succeeded at 253 (offset 12 lines).
Hunk #3 succeeded at 639 (offset 68 lines).
patching file src/http/modules/ngx_http_upstream_ip_hash_module.c
Hunk #2 succeeded at 219 (offset 8 lines).
patching file src/http/modules/ngx_http_upstream_least_conn_module.c
Hunk #2 succeeded at 156 (offset 6 lines).
Hunk #3 succeeded at 221 (offset 6 lines).
patching file src/http/ngx_http_upstream_round_robin.c
Hunk #2 succeeded at 214 (offset 107 lines).
Hunk #3 succeeded at 349 (offset 163 lines).
Hunk #4 succeeded at 426 (offset 163 lines).
Hunk #5 succeeded at 554 (offset 171 lines).
Hunk #6 succeeded at 591 (offset 171 lines).
Hunk #7 succeeded at 665 with fuzz 2 (offset 177 lines).
Hunk #8 succeeded at 770 (offset 182 lines).
patching file src/http/ngx_http_upstream_round_robin.h
Hunk #1 succeeded at 55 (offset 17 lines).
[root@nginx nginx-1.28.0]# ./configure --prefix=/etc/nginx --sbin-path=/usr/sbin/nginx --modules-path=/usr/lib64/nginx/modules --conf-path=/etc/nginx/nginx.conf --error-log-path=/var/log/nginx/error.log --http-log-path=/var/log/nginx/access.log --pid-path=/var/run/nginx.pid --lock-path=/var/run/nginx.lock --http-client-body-temp-path=/var/cache/nginx/client_temp --http-proxy-temp-path=/var/cache/nginx/proxy_temp --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp --http-scgi-temp-path=/var/cache/nginx/scgi_temp --user=nginx --group=nginx --with-compat --with-file-aio --with-threads --with-http_addition_module --with-http_auth_request_module --with-http_dav_module --with-http_flv_module --with-http_gunzip_module --with-http_gzip_static_module --with-http_mp4_module --with-http_random_index_module --with-http_realip_module --with-http_secure_link_module --with-http_slice_module --with-http_ssl_module --with-http_stub_status_module --with-http_sub_module --with-http_v2_module --with-http_v3_module --with-mail --with-mail_ssl_module --with-stream --with-stream_realip_module --with-stream_ssl_module --with-stream_ssl_preread_module --add-module=/root/code/nginx_upstream_check_module-master --with-cc-opt='-O2 -flto=auto -ffat-lto-objects -fexceptions -g -grecord-gcc-switches -pipe -Wall -Werror=format-security -Wp,-D_FORTIFY_SOURCE=2 -Wp,-D_GLIBCXX_ASSERTIONS -specs=/usr/lib/rpm/redhat/redhat-hardened-cc1 -fstack-protector-strong -specs=/usr/lib/rpm/redhat/redhat-annobin-cc1 -m64 -march=x86-64-v2 -mtune=generic -fasynchronous-unwind-tables -fstack-clash-protection -fcf-protection -fPIC' --with-ld-opt='-Wl,-z,relro -Wl,-z,now -pie'
#将模块的父目录的绝对路径添加到--prefix中
```

添加划线的那一条

![[_resources/linux笔记/f6b299e7413c5f1125a76cf5259a0232_MD5.png]]



整个--prefix 是从 nginx -V 的回显结果里粘贴的

![[_resources/linux笔记/d68e85fa487f4dac1ed7501995761af9_MD5.png]]

把 --add-module 模块所在目录绝对路径添加进里面就好

从这个回显也能看出来，这个--prefix 指定了 nginx 的配置文件 nginx.conf，错误日志的位置等等，添加模块也不过是在里面指定了模块文件路径，有修改某个配置文件安装时指定路径的需求时，比如把 nginx.conf 安装到/opt/下面，也可以通过编译安装的方式修改或添加指定的路径。虽然 包管理器安装后也能修改配置文件路径，但远没有编译安装自由



3.make 编译

[root@nginx nginx-1.28.0]# make



4.编译安装 （支持覆盖安装）

[root@nginx nginx-1.28.0]# make install



5.查看模块安装情况

![[_resources/linux笔记/3005ff1d65778aee103839056b1b1171_MD5.png]]

可以看到模块成功安装了











# 9/5

## cookie 与 session 详解

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








## session 会话保持
以部署 phpmyadmin 业务为例，虚拟机统一使用 rocky9.6

nginx  

web01  

web02  

192.168.120.153

192.168.120.129

192.168.120.151

1.配置 nginx

```bash
[root@web01 admin]# cat /etc/nginx/conf.d/admin.conf 
server {
        listen 80;
        server_name www.admin.com;
        root /alice/admin;

        location / {
                    index index.php index.html;
        }

        location ~ \.php$ {
                           fastcgi_pass 127.0.0.1:9000;
                           fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
                           include fastcgi_params;
        }
}
[root@web01 admin]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@web01 admin]# systemctl restart nginx 
```



2.配置代码目录，下载代码包

从官网找到的代码包phpMyAdmin-5.2.2-all-languages.zip，用 xftp 传到/alice 目录下

```bash
[root@web01 ~]# cd /alice/
[root@web01 alice]# unzip phpMyAdmin-5.2.2-all-languages.zip
[root@web01 alice]# mv phpMyAdmin-5.2.2-all-languages admin
[root@web01 alice]# mv phpMyAdmin-5.2.2-all-languages.zip /root/
[root@web01 alice]# ll
总用量 24
drwxr-xr-x 12 root root 4096  9月  5 15:29 admin
drwxr-xr-x  2 www  www    20  9月  2 20:03 images
-rw-r--r--  1 www  www    25  9月  2 20:03 index.php
-rw-r--r--  1 www  www   335  9月  2 20:03 mysql.php
drwxr-xr-x  2 root root   24  9月  3 16:44 test
drwxr-xr-x  5 www  www  4096  9月  2 20:33 wordpress
[root@web01 alice]# chown -R www:www admin/
[root@web01 alice]# chown www:www /var/lib/php/session/
[root@web01 alice]# systemctl restart nginx
[root@web01 alice]# systemctl restart php-fpm.service 
```



3.配置数据库信息

```bash
[root@web01 alice]# cd admin/
[root@web01 admin]# cp config.sample.inc.php config.inc.php #带 sample 的是示例文件，不会生效
[root@web01 admin]# grep 192.168.120.150 config.inc.php 
$cfg['Servers'][$i]['host'] = '192.168.120.150';
```

win11 宿主机做好 hosts 映射 web01 的 IP 后访问 www.admin.com 测试



4. 快速部署WEB02 phpmyadmin业务

 1.scp配置文件  

```bash
[root@web02 ~]# scp 192.168.120.129:/etc/nginx/conf.d/admin.conf /etc/nginx/conf.d/
root@192.168.120.129's password: 
admin.conf                                                                                                        100%  411   546.8KB/s   00:00    
[root@web02 ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@web02 ~]# systemctl restart nginx
```



2.拷贝代码文件

```bash
[root@web02 ~]# scp 192.168.120.129:/root/phpMyAdmin-5.2.2-all-languages.zip /alice/
root@192.168.120.129's password: 
phpMyAdmin-5.2.2-all-languages.zip                                                                                100%   15MB 107.0MB/s   00:00    
[root@web02 ~]# cd /alice/
[root@web02 alice]# unzip phpMyAdmin-5.2.2-all-languages.zip 
[root@web02 alice]# mv phpMyAdmin-5.2.2-all-languages.zip /root/
[root@web02 alice]# mv phpMyAdmin-5.2.2-all-languages/ admin
[root@web02 alice]# cd admin/
[root@web02 admin]# cp config.sample.inc.php config.inc.php
[root@web02 admin]# vim config.inc.php 
[root@web02 admin]# grep '192.168.120.150' config.inc.php 
$cfg['Servers'][$i]['host'] = '192.168.120.150';
[root@web02 admin]# cd ..
[root@web02 alice]# ll
总用量 24
drwxr-xr-x 12 root root 4096  9月  5 15:29 admin
-rw-r--r--  1 root root 4810  9月  5 15:29 config.inc.php
drwxr-xr-x  2 www  www    20  9月  2 20:03 images
-rw-r--r--  1 www  www    25  9月  2 20:03 index.php
-rw-r--r--  1 www  www   335  9月  2 20:03 mysql.php
drwxr-xr-x  2 root root   24  9月  3 16:44 test
drwxr-xr-x  5 www  www  4096  9月  2 20:33 wordpress
[root@web02 alice]# chown -R www:www admin/
[root@web02 alice]# chown www:www /var/lib/php/session/
[root@web02 alice]# systemctl restart nginx
[root@web02 alice]# systemctl restart php-fpm.service 

```

同样通过 hosts 解析检查配置



5.nginx 负载均衡配置

```bash
[root@nginx ~]# cat /etc/nginx/conf.d/admin.conf 
upstream admin {
                server 192.168.120.129;
                server 192.168.120.151;
}

server {
        listen 80;
        server_name www.admin.com;

        location / {
                    proxy_pass http://admin;
                    include proxy_params;
        }
}
[root@nginx ~]# cat /etc/nginx/proxy_params 
proxy_set_header Host $http_host;
proxy_http_version 1.1;
proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
proxy_connect_timeout 30;
proxy_send_timeout 60;
proxy_read_timeout 60;
proxy_buffering on;
proxy_buffer_size 32k;
proxy_buffers 4 128k;
[root@nginx ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@nginx ~]# systemctl restart nginx
```



测试访问，主机 hosts 解析

192.168.120.153 www.admin.com

![[_resources/linux笔记/6d036eaa98a62b008ed93df3d0523d52_MD5.png]]

这里无法登录是因为没做会话保持，涉及到 cookie 和 session，之前有详解



6.phpmyadmin实现会话保持写入到redis

  这里在 db01 上做

1） 安装并配置 redis

```bash
[root@db01 ~]# yum -y install redis
[root@db01 ~]# grep 192.168.120.150 /etc/redis/redis.conf 
bind 127.0.0.1 192.168.120.150
[root@db01 ~]# systemctl enable --now redis
[root@db01 ~]# netstat -tunlp | grep redis
tcp        0      0 127.0.0.1:6379          0.0.0.0:*               LISTEN      2794/redis-server 1 
tcp        0      0 192.168.120.150:6379    0.0.0.0:*               LISTEN      2794/redis-server 1 
```



2） 配置php会话写入到redis中

<font style="color:#DF2A3F;">WEB01和WEB02都需要修改 </font>

修改/etc/php.ini  

```bash
[root@web01 admin]# vim /etc/php.ini 
[root@web01 admin]# egrep -n "192.168.120.150|redis" /etc/php.ini
1230:session.save_handler = redis
1263:session.save_path = "tcp://192.168.120.150:6379"
```



 注释/etc/php-fpm.d/www.conf 中的两行配置

```bash
[root@web01 admin]# tail -4  /etc/php-fpm.d/www.conf
;php_value[session.save_handler] = files
;php_value[session.save_path]    = /var/lib/php/session
php_value[soap.wsdl_cache_dir]  = /var/lib/php/wsdlcache
;php_value[opcache.file_cache]  = /var/lib/php/opcache
```



 两台 web 服务器修改完成后各自重启PHP-FPM进程

 systemctl restart php-fpm  



7.再次访问 www.admin.com

账号和密码是之前 mysql 授权的远程用户的账号密码

我设定的是 

账号 caster

密码 000000

![[_resources/linux笔记/33527651eac752f9e3669794a7db38f5_MD5.png]]

刷新两次可以看到每次的登录 ip 都不同

![[_resources/linux笔记/0a7c2ae40046efcd8b5088d8ada62cb4_MD5.png]]

![[_resources/linux笔记/a1fac794434f540b090c08edb9452f4b_MD5.png]]



 查看redis中的session数据  

```bash
[root@db01 ~]# redis-cli
127.0.0.1:6379> keys *
1) "PHPREDIS_SESSION:pp4fc5b21j46269632aqdevvjg"
127.0.0.1:6379> 
```



至此就完成了 session 会话保持，session 存储在了 redis 里















# 9/6
## 四层负载均衡配置
![[_resources/linux笔记/bb593528d3e66df5021fad1d3ee4bf78_MD5.png]]

画了个整体架构草图，相比上面的架构添加了 LB02 和 LB，LB01（原名 nginx）

1.通过访问负载均衡的 5555 端口，实际是后端的 web01 的 22 端口在提供服务

准备一台服务器 LB 192.168.120.141

1）安装 nginx

```bash
[root@LB ~]# #scp 192.168.120.153:/etc/yum.repos.d/nginx.repo /etc/yum.repos.d/
[root@LB ~]# yum -y install nginx
```



2）删除默认的七层配置（）

```bash
[root@LB ~]# rm -rf /etc/nginx/conf.d/*
```



 配置主配置文件在http区块外包含的语句  

```bash
[root@LB ~]# grep conf.c /etc/nginx/nginx.conf
include /etc/nginx/conf.c/*.conf;
```



 3)创建四层配置文件  

```bash
[root@LB nginx]# mkdir -pv conf.c
mkdir: 已创建目录 'conf.c'
[root@LB nginx]# cd conf.c/
[root@LB conf.c]# cat lb.conf 
stream {
        upstream web01 {
                 server 192.168.120.129:22;
        }
server {
        listen 5555;
        proxy_pass web01;
       }
}
[root@LB conf.c]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@LB conf.c]# systemctl restart nginx
```



打开一个 ssh 窗口，ssh 测试

```bash
[C:\~]$ ssh 192.168.120.141 5555

Connecting to 192.168.120.141:5555...
Connection established.
To escape to local shell, press 'Ctrl+Alt+]'.

Activate the web console with: systemctl enable --now cockpit.socket

Last login: Sat Sep  6 13:43:13 2025 from 192.168.120.1
[root@web01 ~]# ip a
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
    inet 127.0.0.1/8 scope host lo
       valid_lft forever preferred_lft forever
    inet6 ::1/128 scope host 
       valid_lft forever preferred_lft forever
2: ens160: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1500 qdisc fq_codel state UP group default qlen 1000
    link/ether 00:0c:29:c0:23:10 brd ff:ff:ff:ff:ff:ff
    altname enp3s0
    inet 192.168.120.129/24 brd 192.168.120.255 scope global noprefixroute ens160
       valid_lft forever preferred_lft forever
    inet6 fe80::20c:29ff:fec0:2310/64 scope link noprefixroute 
       valid_lft forever preferred_lft forever
[root@web01 ~]# 
```

可以看到成功转发到了 web01 的 22 端口

![[_resources/linux笔记/210fac57e84fe4f394f0dde91d337b59_MD5.png]]

抓包后可以看到 具体流程



2.通过访问负载均衡的 6666 端口，实际是后端的 mysql 的 3306 端口在提供服务

```bash
[root@LB conf.c]# cat lb.conf 
stream {
        upstream web01 {
                 server 192.168.120.129:22;
        }
        upstream db01 {
                 server 192.168.120.150:3306;
        }
server {
        listen 5555;
        proxy_pass web01;
       }

server {
        listen 6666;
        proxy_pass db01;
       }
}

[root@LB conf.c]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@LB conf.c]# systemctl restart nginx
```



在 web01 上测试

```bash
[root@web01 ~]# mysql -h 192.168.120.141 -P 6666 -ucaster -p000000
Welcome to the MariaDB monitor.  Commands end with ; or \g.
Your MariaDB connection id is 3
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
4 rows in set (0.034 sec)
```





## 四层转发七层
基于‘’四层负载均衡配置‘’的架构图

先配置 LB02

```bash
[root@LB02 ~]# scp 192.168.120.153:/etc/yum.repos.d/nginx.repo /etc/yum.repos.d/
[root@LB02 ~]# yum -y install nginx
[root@LB02 ~]# scp 192.168.120.153:/etc/nginx/conf.d/* /etc/nginx/conf.d/
The authenticity of host '192.168.120.153 (192.168.120.153)' can't be established.
ED25519 key fingerprint is SHA256:qM6PEbM6vEVWXh5pwCypNutWEk0Eel1PSmVcP7HiNAY.
This key is not known by any other names
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '192.168.120.153' (ED25519) to the list of known hosts.
root@192.168.120.153's password: 
admin.conf                                                                                                        100%  284   274.1KB/s   00:00    
default.conf                                                                                                      100%  504   515.7KB/s   00:00    
[root@LB02 ~]# scp 192.168.120.153:/etc/nginx/proxy_params /etc/nginx/
root@192.168.120.153's password: 
proxy_params                                                                                                      100%  256   250.9KB/s   00:00    
[root@LB02 ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@LB02 ~]# systemctl enable --now nginx
Created symlink /etc/systemd/system/multi-user.target.wants/nginx.service → /usr/lib/systemd/system/nginx.service.
```



配置 LB 四层

```bash
[root@LB conf.c]# mv lb.conf lb.conf.bak #不能同时存在两个stream字段
[root@LB conf.c]# cat web.conf 
stream {
        upstream webs {
                 server 192.168.120.153:80;
                 server 192.168.120.130:80;
        }

server {
        listen 80;
        proxy_pass webs;
       }
}
[root@LB conf.c]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@LB conf.c]# systemctl restart nginx
```



修改主机映射 hosts   192.168.120.141 php.alice.com

访问 php.alice.com

![[_resources/linux笔记/931b1a699d00f1ce51378f6ba7baaca5_MD5.png]]

配置成功















# 9/10
## tomcat 图片分离
延续上面的架构，仅使用 web02 实验

web02   192.168.120.151

[https://tomcat.apache.org/](https://tomcat.apache.org/)    #tomcat 的官网

1.web02 部署 tomecat

下载 tomcat 包

```bash
[root@web02 ~]# wget https://dlcdn.apache.org/tomcat/tomcat-10/v10.1.45/bin/apache-tomcat-10.1.45.tar.gz
[root@web02 ~]# tar xf apache-tomcat-10.1.45.tar.gz -C /usr/local/
[root@web02 ~]# ln -s /usr/local/apache-tomcat-10.1.45/ /usr/local/tomcat
```



安装 tomcat 运行环境

[root@web02 ~]#yum -y install java

运行java服务

[root@web02 ~]#/usr/local/tomcat/bin/startup.sh

检查端口tomcat 8080  



2.nginx实现代理tomcat进行图片拆分

1)web02配置反向代理到自身的8080端口

```bash
[root@web02 conf.d]#cat proxy8080.conf
upstream tom { 
              server 172.16.1.8:8080;
}
server {
        listen 80;
        server_name tomcat.rocky.com;
        location / {
                    proxy_pass http://tom;
        }
}  
[root@web02 conf.d]#nginx -t 
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@web02 conf.d]#systemctl restart nginx  
```

 2)hosts解析测试代理是否成功  

192.168.120.151 tomcat.rocky.com

3)通过配置Nginx反向代理的locatoin 将tomcat的图片拆分

```bash
[root@web02 conf.d]#vim proxy8080.conf
 upstream tom {
        server 192.168.120.151:8080;
        }
 server {
        listen 80;
        server_name tomcat.rocky.com;
        location / {
        proxy_pass http://tom;
        }
        # 如果访问.png.jpg...结尾的请求，则直接通过/alice/images/返回给用户
        location ~* .(png|jpg|svg|mp4|mp3)$ {
        root /alice/images;
        }
 }

[root@web02 conf.d]#nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@web02 conf.d]#systemctl restart nginx
```

将tomcat所有的图片复制一份到/alice/images

```bash
[root@web02 ~]#cd /usr/local/tomcat/webapps/ROOT
[root@web02 ROOT]#cp *.svg *.png /alice/images/
```

 

修改目录的属主属组为nginx的启动用户www

```bash
[root@web02 webapps]# chown -R www.www /alice/images/  
```

 

测试访问tomcat.rocky.com  



停止 tomcat 服务

[root@web02 ROOT]#/usr/local/tomcat/bin/shutdown.sh  







## 通过负载均衡实现动静分离
思路：分别在 web01 上部署静态业务资源，web02 上部署动态业务资源，通过七层负载均衡 LB01 调度整体使用，防止单点故障导致业务的整体瘫痪

LB01       192.168.120.153

web01    192.168.120.129

web02    192.168.120.151



1.web01 配置静态资源

```plain
[root@web01 ~]# vim /etc/nginx/conf.d/static.conf 
[root@web01 ~]# cat /etc/nginx/conf.d/static.conf 
server {
        listen 80;
        server_name www.static.com;
        
        location / {
        root /alice/test;
        index index.html;
        }
        
        location ~* .*\.(jpg|png|gif)$ {
                    root /alice/images;
        }
}
[root@web01 ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@web01 ~]# systemctl restart nginx
[root@web01 ~]# mkdir -pv /alice/images
[root@web01 ~]# ls /alice/images/
hx.png
```



2.web02 配置动态资源（使用 tomcat 代理）

```plain
[root@web02 ROOT]# cat test.jsp 
<%@ page language="java" import="java.util.*" pageEncoding="utf-8"%>
<HTML>
    <HEAD>
        <TITLE>rocky JSP Page</TITLE>
    </HEAD>
    <BODY>
        <%
           Random rand = new Random();
           out.println("<h1>生成随机数:<h1>");
           out.println(rand.nextInt(99)+100);
        %>
    </BODY>
</HTML>
[root@web02 ROOT]# #如果访问不到页面可以重启tomcat
[root@web02 ROOT]# #/usr/local/tomcat/bin/shutdown.sh 
[root@web02 ROOT]# #/usr/local/tomcat/bin/startup.sh 
```



3.LB01 配置负载均衡集成动态和静态页面  

```plain
[root@LB01 ~]# cat /etc/nginx/conf.d/test.conf 
upstream static {
         server 192.168.120.129;
}

upstream java {
         server 192.168.120.151:8080;
}

server {
        listen 80;
        server_name www.static.com;
        root /alice;
        index index.html;
        
        location ~* \.(jpg|png|gif)$ {
                    proxy_pass http://static;
                    proxy_set_header Host $http_host;
        }

        location ~ \.jsp {
                   proxy_pass http://java;
                   proxy_set_header Host $http_host;
        }
}
[root@LB01 ~]# cat /alice/index.html 
<html lang="en">
<head>
        <meta charset="UTF-8" />
        <title>测试ajax和跨域访问</title>
        <script src="http://libs.baidu.com/jquery/2.1.4/jquery.min.js"></script>
</head>
<script type="text/javascript">
$(document).ready(function(){
        $.ajax({
        type: "GET",
        url: "http://www.static.com/test.jsp",
        success: function(data){
                $("#get_data").html(data)
        },
        error: function() {
                alert("哎呦喂,失败了,回去检查你服务去~");
        }
        });
});
</script>
        <body>
               <h1>测试动静分离</h1>
               <img src="http://www.static.com/hx.png" height="600" width="1000">
               <div id="get_data"></div>
        </body>
</html>
[root@LB01 ~]# 
```



完成后重启 nginx，配置 hosts 解析

192.168.120.153 www.static.com

浏览器访问

![[_resources/linux笔记/2a3896318ad44a046a9bf09e86f79873_MD5.png]]



模拟动态业务挂掉了

```plain
[root@web02 ROOT]# /usr/local/tomcat/bin/shutdown.sh 
Using CATALINA_BASE:   /usr/local/tomcat
Using CATALINA_HOME:   /usr/local/tomcat
Using CATALINA_TMPDIR: /usr/local/tomcat/temp
Using JRE_HOME:        /usr
Using CLASSPATH:       /usr/local/tomcat/bin/bootstrap.jar:/usr/local/tomcat/bin/tomcat-juli.jar
Using CATALINA_OPTS:   
```

访问网站

![[_resources/linux笔记/d05a8dc4334bac00e8bbc13df88f3b90_MD5.png]]



模拟静态业务挂了，动态没挂

```plain
 [root@web02 ROOT]# /usr/local/tomcat/bin/startup.sh
Using CATALINA_BASE:   /usr/local/tomcat
Using CATALINA_HOME:   /usr/local/tomcat
Using CATALINA_TMPDIR: /usr/local/tomcat/temp
Using JRE_HOME:        /usr
Using CLASSPATH:       /usr/local/tomcat/bin/bootstrap.jar:/usr/local/tomcat/bin/tomcat-juli.jar
Using CATALINA_OPTS:   
Tomcat started.
```

```plain
[root@web01 ~]# mv /alice/images/hx.png /alice/images/rock.png
```



![[_resources/linux笔记/ea688788db969be1a905c59530fcb0b9_MD5.png]]























# 9/11
## rewrite 跳转规则
```plain
[root@web01 conf.d]# cat rewrite.conf 
server {
        listen 80;
        server_name test.rewrite.com;
        root /code/test/;
  
        location / {
        rewrite /1.html /2.html;
        rewrite /2.html /3.html;
        }
      
        location /2.html {
        rewrite /2.html /a.html;
        }
 
        location /3.html {
        rewrite /3.html /b.html;
        }
}

[root@web01 conf.d]# mkdir -pv /code/test
mkdir: 已创建目录 '/code/test'
[root@web01 conf.d]# echo 2.html > /code/test/2.html
[root@web01 conf.d]# echo 3.html > /code/test/3.html
[root@web01 conf.d]# echo a.html > /code/test/a.html
[root@web01 conf.d]# echo b.html > /code/test/b.html
[root@web01 conf.d]# vim /etc/hosts 
[root@web01 conf.d]# cat /etc/hosts 
127.0.0.1   localhost localhost.localdomain localhost4 localhost4.localdomain4
::1         localhost localhost.localdomain localhost6 localhost6.localdomain6
127.0.0.1 www.admin.com www.static.com php.alice.com test.rewrite.com
[root@web01 conf.d]# curl test.rewrite.com/1.html
b.html
[root@web01 conf.d]# curl test.rewrite.com/2.html
a.html
[root@web01 conf.d]# curl test.rewrite.com/3.html
b.html
```

rewrite 的跳转的机制是重新发起请求，例如访问 1.html 时，向下跳转到 3.html，然后重新发起请求，匹配到 3.html，最后返回 b.html



```plain
[root@web01 conf.d]# cat rewrite.conf 
server {
        listen 80;
        server_name test.rewrite.com;
        root /code/test/;
  
        location / {
        rewrite /1.html /2.html last;
        rewrite /2.html /3.html;
        }
      
        location /2.html {
        rewrite /2.html /a.html;
        }
 
        location /3.html {
        rewrite /3.html /b.html;
        }
}
[root@web01 conf.d]# curl test.rewrite.com/1.html
a.html
```

可以看待 last 标记的字段不再在同一区块继续向下匹配，而是重新发起请求访问 2.html



```plain
[root@web01 conf.d]# cat rewrite.conf 
server {
        listen 80;
        server_name test.rewrite.com;
        root /code/test/;
  
        location / {
        rewrite /1.html /2.html break;
        rewrite /2.html /3.html;
        }
      
        location /2.html {
        rewrite /2.html /a.html;
        }
 
        location /3.html {
        rewrite /3.html /b.html;
        }
}
[root@web01 conf.d]# curl test.rewrite.com/1.html
2.html
```

作用是不再发起请求



临时跳转 redirect

```plain
[root@web01 conf.d]# cat rewrite.conf 
server {
        listen 80;
        server_name test.rewrite.com;
        root /code;

        location /test {
                  rewrite ^(.*)* http://www.baidu.com redirect;
        }
}
[root@web01 conf.d]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@web01 conf.d]# systemctl restart nginx
```

修改相关映射后访问 test.rewrite.com/test，返回的是百度的页面

但每次跳转都需要访问原 web 服务器，然后再跳转，如果停止 nginx 服务， 则无法实现跳转

![[_resources/linux笔记/322a43611a5695b0880c533d4e2b01d1_MD5.png]]



永久跳转permanent

```plain
[root@web01 conf.d]# cat rewrite.conf 
server {
        listen 80;
        server_name test.rewrite.com;
        root /code;

        location /test {
                 #rewrite ^(.*)* http://www.baidu.com redirect;
                  rewrite ^(.*)* http://www.baidu.com permanent;
                 #return 301 http://www.static.com;
                 #return 302 http://www.baidu.com;
        }
}
```

第一次跳转之后,停止 nginx 服务，继续访问 test.rewrite.com 直接跳转到百度，但禁用缓存后仍然无法访问，所以说它是直接走的缓存，但在第一次跳转之后无需先访问 web 站点





301 永久跳转

```plain
[root@web01 conf.d]# cat rewrite.conf 
server {
        listen 80;
        server_name test.rewrite.com;
        root /code;

        location /test {
                 #rewrite ^(.*)* http://www.baidu.com redirect;
                 #rewrite ^(.*)* http://www.baidu.com permanent;
                 return 301 http://www.static.com;
                 #return 302 http://www.baidu.com;
        }
}
```

在第一次跳转之后，后续也是继续走的缓存



302 临时跳转

```plain
[root@web01 conf.d]# cat rewrite.conf 
server {
        listen 80;
        server_name test.rewrite.com;
        root /code;

        location /test {
                 #rewrite ^(.*)* http://www.baidu.com redirect;
                 #rewrite ^(.*)* http://www.baidu.com permanent;
                 #return 301 http://www.static.com;
                 return 302 http://www.baidu.com;
        }
}
```

还是和上面的临时跳转一样，每次都需要访问 web 服务器





### rewrite 跳转案例
```plain
[root@web01 conf.d]# cat rewrite.conf 
server {
        listen 80;
        server_name test.rewrite.com;
        root /rewrite;

        location /test {
                  rewrite (.*) /aaa/bbb/ccc/1.html redirect;
        }
}
[root@web01 conf.d]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@web01 conf.d]# systemctl restart nginx
[root@web01 conf.d]# mkdir -pv /rewrite/aaa/bbb/ccc
mkdir: 已创建目录 '/rewrite'
mkdir: 已创建目录 '/rewrite/aaa'
mkdir: 已创建目录 '/rewrite/aaa/bbb'
mkdir: 已创建目录 '/rewrite/aaa/bbb/ccc'
[root@web01 conf.d]# echo 'this is 1.html' > /rewrite/aaa/bbb/ccc/1.html
```

访问 test.rewrite.com/test....等以 test 开头的 url 都会跳转到 1.html 的位置

rewrite (.*) 和 ^(.*)$等价



后项引用

```plain
[root@web01 conf.d]# cat rewrite.conf 
server {
        listen 80;
        server_name test.rewrite.com;
        root /rewrite;

        location /2025 {
                 #rewrite (.*) /aaa/bbb/ccc/1.html redirect;
                 #rewrite ^(.*)$ /aaa/bbb/ccc/1.html redirect;
                 rewrite ^/2025/(.*)$ /2030/$1 redirect;
        }
}
[root@web01 conf.d]# mkdir -pv /rewrite/{2025,2030}
[root@web01 conf.d]# echo 'hello,this is 2030 dir' > /rewrite/2030/hello.html
[root@web01 conf.d]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@web01 conf.d]# systemctl restart nginx
[root@web01 conf.d]# curl test.rewrite.com/2030/hello.html
hello,this is 2030 dir
```

rewrite ^/2025/(.*)$ /2030/$1 redirect;

用户访问 test.rewrite.com/2025/hello.html 时

实际上是在访问test.rewrite.com/2030/hello.html

访问的 url 中的(.*)$虽然会匹配任意字符，但必须是后项目录中存在的文件$1













# 10/7
## 关于混合显卡与 linux 适配问题
我的电脑是 A 卡集显和 N 卡独显组合，系统新装了一个 archlinux,在使用插件 caffine （一款 linux 息屏时间控制工具 ）时，使用 caffine 导致我的系统丢失根分区挂载入进入紧急模式，解决方案是使用之前的系统 U 盘重新挂载，将桌面用户家目录里的.local/share/gnome-shell/extensions目录下面把caffeine相关字段的目录删除，该目录是 gnome 的软件商店安装插件扩展的插件储存位置，然而这个并不是 caffine 的问题，主要原因在于，华硕提供了显卡模式的切换工具 supergfxctl，使用 yay 安装,与插件商店的 GPU Supergfxctl Switch 组合使用可以实现在右上角菜单栏里切换显卡模式为集显，混合，和独显，当时是混合模式，导致了很严重的问题，具体表现在开机时，有几率在启动加载全部完成后会黑屏卡住，原因是 A 卡集显和 N 卡独显抢占显存资源，A 卡抢占失败时就会导致 GUI 加载错误，查看系统日志可以看到上次启动失败一直在循环报错 A 卡分配显存资源失败，显卡模式设置为独显即可解决，然而又触发了一个新问题，steam 使用独显启动游戏黑屏，因为 steam 默认策略使用集成显卡打开，archwiki 的方案是切换 wayland 到 x11 规范（比如 xorg），不过有个临时解决方案，使用集显运行 steam,涉及到一个软件 switcheroo-control，该软件可选择程序使用哪张显卡启动，右键显示选项，使用 pacman 安装。



最后排查完成了，我目前使用的是 GNOME49,而这个版本停止了 x11 的支持，还想用的话似乎需要编译安装，所以我重装系统换成了 KDE+wayland，混合显卡 的使用，无论是 GNOME 还是 KDE 都处理不好，因为系统会在 A 卡没还加载好的时候加载 GUI 服务，因此需要控制 GUI 和 A 卡配置加载的顺序，我的解决方案是写一个服务单元把 GUI 放在最后加载，但后续发现了更好的方案，在 mkinit 中配置 A 卡优先加载就可以了，

![[_resources/linux笔记/3d4acfcc17d6def5939c834ae1bd67cb_MD5.png]]

就是在 MODULES 里指定加载顺序即可，当然还需要sudo mkinitcpio -P重新加载一下配置,但用到最后还是觉得，把登录管理器的服务添加一个 sleep 2 似乎才是更好的选择（难说）





另外就是关于滚挂的问题，因为我 pacman -Syu 后我的 waydroid 出现程序无法运行和屏幕撕裂现象，所以我选择使用我的快照管理器 snapper 回退快照，但我猜测，可能是因为我更新 了内核的原因，导致快照回退失败，我的 boot 分区无法挂载，进入了紧急模式，查看日志说是不识别 EFI 分区的 vfat 类型文件系统，因此猜测是内核损坏导致的，所以尝试使用 pacman -S linux linux-headers 重新安装内核尝试，但又有 pacman 报错，大致意思就是读取数据库失败，数据库被锁定？具体我也忘记了，原因是我重启时不知道为什么 pacman 在运行状态，所以 pacman 就生成了一个叫 db.lck 的文件，它会锁定软件包数据库，用 find 找到后删除即可，内核重新安装成功后我也顺利进入系统，但 waydorid 问题等待排查（大概知道可能的问题了，waydroid 无法使用我的 A 卡只能回退到最垃圾的渲染模式，疑似是因为 mesa 更新导致的），用 arch 的这几个星期我也懒得写笔记了，有些东西用笔记真的不好描述，只能说想起来再补充吧











# 10/28
## wine 字体缺失
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



sudo pacman -S adobe-source-han-serif-cn-fonts wqy-zenhei                   #安装几个开源中文字体 一般装上文泉驿就能解决大多wine应用中文方块的问题

sudo pacman -S noto-fonts-cjk noto-fonts-emoji noto-fonts-extra             #安装谷歌开源字体及表情


我感觉没球用，不如群友打包的字体包，直接塞上就用




# 10/30
## arch 配置 FTP 服务
给我的 kvm_win7 传文件用

安装软件
sudo pacman -S python-pyftpdlib

然后在需要共享的文件目录下运行
python -m pyftpdlib
具体端口号和进程等信息会自动显示











# 11/4
## Waydroid 画面撕裂问题
具体表现形式是类似花屏和撕裂，不过只有黑色色调



还是混合显卡的问题，是 waydroid 默认使用显卡和桌面环境使用的显卡不一致导致的，我的 plasma 桌面环境默认使用 N 卡（可以用watch -n 1 nvidia-smi 查看哪些进程在使用 N 卡，每秒实时刷新），waydroid 在使用 A 卡集显，需要切换 waydroid 的显卡使用策略，为此 GitHub 上有个项目提供解决方案脚本

[https://github.com/Quackdoc/waydroid-scripts/](https://github.com/Quackdoc/waydroid-scripts/blob/main/waydroid-choose-gpu.sh)

这个链接

脚本内容是

```bash
░▒▓   ~   17:50   
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















## waydroid 按键映射
之前无法解决 waydroid 没有滑动映射的问题，在 github 上看到了一个项目，还算能用，

项目地址：[https://github.com/waydroid-helper/waydroid-helper/tree/main](https://github.com/waydroid-helper/waydroid-helper/tree/main)

对于 archlinux 用户，直接从 aur 仓库安装即可

yay -S waydroid-helper

这个应用功能比较齐全了，值得一提的是，在设置按键映射时，会出现一个窗口，然后在窗口里设置映射键位，这里并不是说明上说的，把映射键位放在对应按键上就行，而是根据这个窗口与 waydroid 的缩放比例，放到对应的位置，要使用映射时，需要先鼠标聚焦到映射的窗口

类似这样，我映射了游戏的方向键，因为这个 b 游戏的方向键只支持滑动操作，可以看到，我的方向键在窗口中的位置是等比例缩小游戏窗口和方向键的对应位置，我需要使用映射时必须把鼠标聚焦到左下角的映射窗口

![[_resources/linux笔记/a7e2f3ce98025b7463ef958137883955_MD5.png]]



这个助手还提供其他功能，比如伪装成指定机型，获取设备 id，之类的常见需求











# 11/6
## 在 wps 中使用 fcitx5 输入法
网上有个方案是在~/.pam_environment 中写入
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx
但貌似 wps 随着版本更新不再读取这个文件



所以需要在/usr/bin/wps 中的gOpt=下面一行添加如下内容即可
export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx5
export XMODIFIERS=@im=fcitx
  














# 11/7
## Hyprland
开始用 hyprland 了，目前体验还不错，但是配置过程有点繁琐，我懒得写怎么装了，就简单记录一下怎么用吧



大多数的配置都是通过修改 hyprland 的配置文件~/.config/hypr/hyprland.conf实现的

比如
### 设置命令开机自启动
进入该配置文件，在 exec-once 开头的那一块区域写入
exec-once=需要开机自动执行的命令

比如我在使用mpvpaper 这个视频壁纸项目
我就把它提供的设置播放视频壁纸的命令写进了配置文件里设置开机自启
exec-once=mpvpaper -o "--loop-file" eDP-1 Downloads/【哲风壁纸】剪影-多重影像.mp4 &
其实这个写哪里应该是无所谓，但还是美观一些吧




### 设置快捷键
也是在这个配置文件里修改

关键字是 bind 开头的行

```bash
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
$control = ctrl # by myself
bind = $control, t, exec, $terminal



另一个是重启任务栏waybar 的快捷键，我设置成了 super + F2,命令逻辑比较简单就不解释了

ctrl + ; 也是个快捷键，快捷打开剪切板，上次帮人家做作业，学校官网不准粘贴，我无意中粘贴成功了，或许当时按的就是这个键位，以后有机会再试试吧



这个配置文件还有很多功能，环境变量之类的我还没用到
$terminal = konsole
$fileManager = thunar
$menu = fuzzel
这三个变量，终端，文件管理器，菜单都被我改成这些了，因为默认的不太习惯,当然修改之前对应的包都要装上  


关于桌面快捷键的事，虽然配置文件的 bind 的注释里都写清楚用途，但我还是记录一下常用的默认配置和我的自定义的快捷键配置
```
super + e				打开 thunar 文件管理器
super + c				关闭当前窗口
super + 数字键		切换到指定数字的工作区
super + v				切换窗口状态，在浮动和平铺状态中切换
super + r				打开应用列表
super + 左键拖动		移动窗口（当窗口处于平铺状态时）
super + 右键拖动		拉伸窗口（当窗口处于平铺状态时）
super + 鼠标滚轮		快捷切换工作区
super + q				关闭 waybar
super + F2			重启 waybar
super + s				快速最小化当前桌面窗口，再次使用就会回来
```

关于这个 super + s 快捷键，我是这样理解的，所有的工作区都是桌面的不同区域，而 super s 则是把当前使用的桌面上的所有窗口收进下面的抽屉里，再次按下就会当前使用的桌面上展开，也就是从抽屉里拿出来放上


hyprland 自己也有 wiki，肯定是比 archwiki 在这方面更详细的，可以多看看

[https://wiki.hypr.land/](https://wiki.hypr.land/)









### waybar 美化
参考的别人的美化风格，整体配置比较模块化，总体文件结构如图

![[_resources/linux笔记/e5bef4dea6e712828b69b69bad2ee1b3_MD5.png]]

一个个介绍吧


center-test.jsonc 是我用来临时检测我的 arch 图标有没有居中，用 waybar -c ~/.config/waybar/center-test.jsonc 测试，会在当前的 bar 下面再显示出一个临时的居中 arch 图标，以此来检测上面的 arch 图标有没有居中  

```json
{
  //该模块用于生成一个临时的居中arch图标，当基准线用
  "layer": "overlay",
  "position": "top",
  "height": 30, 

  "exclusive": false, 

  "modules-left": [],   
  "modules-center": [
    "custom/applauncher"
  ],
  "modules-right": [], 

  // 
  "custom/applauncher": {
    "format": "󰣇",
    "font-size": 25,
    "padding": "0px 7px",
    // 
    "color": "red" 
  }
}
```



colors.css 用于声明各种颜色变量以供调用

关于这个，konsole 支持鼠标指针放颜色代码上去可以预览颜色，很方便我修改

```json
/* Css Colors */

    @define-color background #111418;

    @define-color error #ffb4ab;

    @define-color error_container #93000a;

    @define-color inverse_on_surface #2e3135;

    @define-color inverse_primary #36618e;

    @define-color inverse_surface #e1e2e8;

    @define-color on_background #e1e2e8;

    @define-color on_error #690005;

    @define-color on_error_container #ffdad6;

    @define-color on_primary #003259;

    @define-color on_primary_container #d1e4ff;

    @define-color on_primary_fixed #001d36;

    @define-color on_primary_fixed_variant #1a4975;

    @define-color on_secondary #253140;

    @define-color on_secondary_container #d7e3f8;

    @define-color on_secondary_fixed #101c2b;

    @define-color on_secondary_fixed_variant #3b4858;

    @define-color on_surface #e1e2e8;

    @define-color on_surface_variant #c3c6cf;

    @define-color on_tertiary #3b2948;

    @define-color on_tertiary_container #f3daff;

    @define-color on_tertiary_fixed #251431;

    @define-color on_tertiary_fixed_variant #523f5f;

    @define-color outline #8d9199;

    @define-color outline_variant #43474e;

    @define-color primary #a1cafd;

    @define-color primary_container #1a4975;

    @define-color primary_fixed #d1e4ff;

    @define-color primary_fixed_dim #a1cafd;

    @define-color scrim #000000;

    @define-color secondary #bbc7db;

    @define-color secondary_container #3b4858;

    @define-color secondary_fixed #d7e3f8;

    @define-color secondary_fixed_dim #bbc7db;

    @define-color shadow #000000;

    @define-color source_color #bbc4d3;

    @define-color surface #111418;

    @define-color surface_bright #36393e;

    @define-color surface_container #1d2024;

    @define-color surface_container_high #272a2f;

    @define-color surface_container_highest #32353a;

    @define-color surface_container_low #191c20;

    @define-color surface_container_lowest #0b0e13;

    @define-color surface_dim #111418;

    @define-color surface_tint #a1cafd;

    @define-color surface_variant #43474e;

    @define-color tertiary #d7bee4;

    @define-color tertiary_container #523f5f;

    @define-color tertiary_fixed #f3daff;

    @define-color tertiary_fixed_dim #d7bee4;
```



config.jsonc 是整体框架，模块定义在别的文件里写        

```json
{
    "include": [
        "modules.jsonc",
        "modules-dividers.jsonc"
    ],
    
    "position": "top",
    "fixed-center": true,
    "height": 30,
    "reload_style_on_change": true,

    "modules-left": [
        "hyprland/workspaces",//工作区
        "custom/right_div#5",
	      "custom/cava",//音频可视化
        "custom/right_div#6"
    ],
    
    "modules-center": [
	      "custom/left_div#99",
        "custom/clipboard",//剪切板
        "custom/emoji",//表情包
	      "custom/left_div#97",
        "custom/wfrec",//录屏
        "custom/screenshot",//截屏
        "custom/left_div#2",
        "idle_inhibitor",//常亮模块
        "custom/updates",//系统更新
        "power-profiles-daemon",//电源模式
        "custom/left_div#11",
        "custom/left_div#1",
        "custom/applauncher",//中心图标，支持打开fuzzel，快捷切换壁纸
        "custom/right_div#1",
        "custom/right_div#11",
        "clock",//时间
        "custom/right_div#2",
        "memory",//内存使用情况
        "temperature",//cpu温度
        "custom/right_div#3",
        "battery",//电量
        "custom/right_div#4"
    ],

    "modules-right": [
	"custom/left_div#98",
	"pulseaudio",//音频控制
  "backlight",//亮度调节
  "custom/left_div#96",
  "tray",//系统托盘
	"custom/left_inv#1",
  "group/powermenu"//电源操作菜单
    ]
}
```





modules-dividers.jsonc 定义了各种图形，用于不同模块之间的图形衔接，在 css 中具体调色

```json
{
	/*-------------------
		left dividers
	-------------------*/
	"custom/left_div#99": {
                "format": "",
                "tooltip": false //禁用指针悬停显示信息
        },

	"custom/left_div#98": {
                "format": "",
                "tooltip": false
        },

	"custom/left_div#97": {
                "format": "",
                "tooltip": false
        },

	"custom/left_div#96": {
                "format": "",
                "tooltip": false
        },

	"custom/left_div#1": {
		"format": "",
		"tooltip": false
	},
	"custom/left_div#10": {
		"format": "",
		"tooltip": false
	},
	"custom/left_div#11": {
		"format": "",
		"tooltip": false
	},
	"custom/left_div#2": {
		"format": "",
		"tooltip": false
	},
	"custom/left_div#3": {
		"format": "",
		"tooltip": false
	},
	"custom/left_div#4": {
		"format": "",
		"tooltip": false
	},
	"custom/left_div#5": {
		"format": "",
		"tooltip": false
	},
	"custom/left_div#6": {
		"format": "",
		"tooltip": false
	},
	"custom/left_div#7": {
		"format": "",
		"tooltip": false
	},
	"custom/left_div#8": {
		"format": "",
		"tooltip": false
	},
	"custom/left_div#9": {
		"format": "",
		"tooltip": false
	},
	"custom/left_inv#1": {
		"format": "",
		"tooltip": false
	},
	"custom/left_inv#2": {
		"format": "",
		"tooltip": false
	},
	/*--------------------
		right dividers
	--------------------*/
	"custom/right_div#1": {
		"format": "",
		"tooltip": false
	},
	"custom/right_div#11": {
		"format": "",
		"tooltip": false
	},
	"custom/right_div#2": {
		"format": "",
		"tooltip": false
	},
	"custom/right_div#3": {
		"format": "",
		"tooltip": false
	},
	"custom/right_div#4": {
		"format": "",
		"tooltip": false
	},
	"custom/right_div#5": {
		"format": "",
		"tooltip": false
	},
	"custom/right_div#6": {
		"format": "",
		"tooltip": false
	},
	"custom/right_inv#1": {
		"format": "",
		"tooltip": false
	}
}
```





modules.jsonc 里是各种模块的定义，注释已经很清楚了

```json
{
//工作区
  "hyprland/workspaces": {
    "format": "{icon}",
    "format-icons": {
      "active": "󰜋",
      "default": ""
    }
  },
//音频可视化
"custom/cava": {
    "exec": "~/.config/waybar/scripts/cava.sh",
    "format": "{}",
    "return-type": "json",
    "tooltip": true,
    "on-click": "playerctl --ignore-player=mpvpaper play-pause",
    "on-scroll-up": "playerctl --ignore-player=mpvpaper previous",
    "on-scroll-down": "playerctl --ignore-player=mpvpaper next"
  },

/* "custom/cava": {
    "tooltip": false,
    "format": "{}",
    "exec": "~/.config/waybar/scripts/cava.sh"
  },
*/
//系统托盘
  "tray": {
    "icon-size": 22,
    "spacing": 7
  },

//剪贴板历史
  "custom/clipboard": {
    "format": "📋",
    "on-click": "cliphist list | fuzzel --dmenu --with-nth 2 | cliphist decode | wl-copy",
    "tooltip": false
  },

//Emoji 选择器
  "custom/emoji": {
    "format": "😎",
    "on-click": "rofi -show emoji -modi emoji",
    "tooltip": false
  },

//截图模块
 "custom/screenshot": {
  "format": "",
  "tooltip-format": "左键: 全屏截图并保存 | 右键: 区域截图并编辑",
  "interval": 3600,
  "on-click": "~/.config/waybar/scripts/screenshot_quick.sh",
  "on-click-right": "~/.config/waybar/scripts/screenshot_edit.sh"
},

//录屏模块
  "custom/wfrec": {
    "format": "",
    "tooltip-format": "点击开始/停止录屏",
    "on-click": "/home/Caster/.config/waybar/scripts/wf-recorder.sh toggle &"
  },

//息屏管理 
  "idle_inhibitor": {
    "format": "{icon}",
    "format-icons": {
      "activated": "",
      "deactivated": ""
    },
    "tooltip-format-activated": "status: 禁止息屏",
    "tooltip-format-deactivated": "status: 启用息屏"
  },

//Arch 更新模块
  "custom/updates": {
    "format": "{icon}",
    "return-type": "json",
    "format-icons": {
      "has-updates": "",
      "updated": "󰏖"
    },
    "exec-if": "which waybar-module-pacman-updates",
    "exec": "waybar-module-pacman-updates --no-zero-output",
    "on-click": "kitty -e yay"
  },

//电源模式模块
  "power-profiles-daemon": {
    "format": "{icon}",
    "tooltip-format": "Performance mode:{profile}",
    "tooltip": true,
    "format-icons": {
      "performance": "󰂅",
      "balanced": "",
      "power-saver": ""
    }
  },

//logo+程序启动器+壁纸切换器
  "custom/applauncher": {
    "tooltip-format": "左键:程序菜单 | 右键:切换壁纸 |滚轮: 快捷切换壁纸",
    "format": "󰣇",
    "on-click": "fuzzel",
    "on-click-right": "~/.config/waybar/scripts/set_wallpaper.sh",
    "on-scroll-up": "~/.config/waybar/scripts/wallpaper_scroll.sh next",
    "on-scroll-down": "~/.config/waybar/scripts/wallpaper_scroll.sh prev"
  },

//Waybar 内置时钟模块
  "clock": {
    "format": " {:%H:%M}",
    "tooltip-format": "{:%Y年%m月%d日 %A}",
    "interval": 1
  },

//内存使用率 
  "memory": {
    "interval": 2,
    "format": "󰍛", 
    "format-alt": "󰍛",
    "on-click-right": "mode",
    "tooltip": true,
    "tooltip-format": "Memory: {used:0.1f}G / {total:0.1f}G ({swapUsed:0.1f}G Swap)"
  },

//CPU 温度
  "temperature": {
    "interval": 2,
    "thermal-zone": 0,
    "format": "", 
    "critical-threshold": 80,
    "format-critical": "CPU", 
    "tooltip": true,
    "tooltip-format": "CPU 温度: {temperatureC}°C"
  },


  "battery": {
    "interval": 2, 
    "states": {
      "critical": 20 
    },
    "format": "{icon} {capacity}%",
    "format-charging": "󰂄 {capacity}% ",
    "format-icons": ["󰂎", "󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"],
    "tooltip-format": "󰂍 {power} | {timeTo}" 
  },


//音频组
  "group/audio": {
    "orientation": "inherit",
    "drawer": {
      "transition-duration": 300,
      "transition-left-to-right": false
    },
    "modules": [
      "pulseaudio" 
    ]
  },

  "pulseaudio": {
    "format": "{icon}",
    "format-muted": "",
    "tooltip-format": "音量: {volume}%",
    "format-icons": {
      "headphone": "󰋋",
      "hands-free": "󰋋",
      "headset": "󰋋",
      "default": ["", "", ""]
    },

    "on-click": "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle",
    "on-click-right": "/home/Caster/.config/waybar/scripts/switch-audio-output.sh",
    "on-click-middle": "pavucontrol",
    "on-scroll-up": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+",
    "on-scroll-down": "wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"
  },

  "backlight": {
    "format": "{icon}",
    "tooltip-format": "亮度: {percent}%", 
    "format-icons": ["", "", "", "", "", "", "", "", ""],
    "tooltip": true,
    "on-scroll-up": "brightnessctl set 5%+",
    "on-scroll-down": "bash -c 'VAL=$(brightnessctl g); MAX=$(brightnessctl m); PCT=$((VAL * 100 / MAX)); if [ $PCT -lt 6 ]; then brightnessctl set 1%; else brightnessctl set 5%-; fi'"
  },

  "group/powermenu": {
    "orientation": "inherit",
    "drawer": {
      "transition-duration": 300,
      "transition-left-to-right": false
    },
    "modules": [
      "custom/wlogout",
      "custom/reboot",
      "custom/logout",
      "custom/lockscreen"
    ]
  },

  "custom/wlogout": {
    "tooltip": false,
    "format": "󰐥",
    "on-click": "systemctl poweroff"
  },

  "custom/reboot": {
    "tooltip": false,
    "format": "",
    "on-click": "systemctl reboot"
  },

  "custom/logout": {
    "format": "󰈆",
    "on-click": "hyprctl dispatch exit",
    "tooltip": false
  },

  "custom/lockscreen": {
    "tooltip": false,
    "format": "",
    "on-click": "hyprlock" 
  }
}
```



style.css 包含了模块和连接符的美化
比如custom/left_div#9 连接符，它的左右颜色是根据 color 和 background-color 决定的                    

```css
@import "colors.css"; 

/* --- 1. 全局和通用样式 --- */
/* * 这是一个“全局选择器”，它会影响 Waybar 中的 *所有* 元素。*/
* {
    border: none;             /* 移除所有元素的边框 */
    border-radius: 0;         /* 移除所有元素的圆角，强制使用直角 */
    font-family: "JetBrainsMono Nerd Font Propo"; /* 指定全局字体，Nerd Font 包含箭头图标 */
    font-size: 18px;          /* 设置基础字体大小 */
    opacity: 1;               /* 确保所有元素默认完全不透明 */
}

/* * 选中 Waybar 的主窗口本身 (整个 bar)*/
window#waybar {
    background: transparent;  /* 将 Waybar 栏的背景设置为透明，使其融入壁纸 */
    color: @on_surface;       /* 设置 bar 内所有文字的默认颜色 (来自 colors.css) */
}

/* * 选中“工具提示” (tooltip)，即鼠标悬停时弹出的信息框
 */
tooltip {
    background: @secondary_container; /* 设置提示框的背景色 */
    border: 3px solid @outline;       /* 设置提示框的边框 */
    opacity: 1;                       /* 确保提示框不透明 */
}

/* * 选中提示框 (tooltip) 内部的“标签” (label)，即提示框里的文字
 */
tooltip label {
    color: white;             /* 设置提示框内文字的颜色为白色 */
    font-size: 16px;          /* 为提示框文字设置一个稍小（16px）的字体 */
}

/*左侧模块*/

/* 工作区 */
#workspaces button {
    padding: 0px 10px;
    background: @surface_container;
    color: @tertiary;
}

#workspaces button:hover {
    background: @on_tertiary;
}

#workspaces button.focused:hover {
    background: @surface_bright;
}

#workspaces button.focused {
    background: @surface_container;
    color: @tertiary;
}

/* 音乐播放器 */
#custom-cava {
    padding: 0px 10px;
    background-color: @surface_bright;
    color: @on_surface;
    font-size: 16px;
}

/*中间模块*/
/* 群组选择器 (Group Selector): 在 CSS 中，当你用逗号 (,) 把多个选择器（比如 #custom-clipboard 和 #custom-emoji）列在一起时，这就叫“群组选择器”。
 * 它的意思是： “请把花括号 { ... } 里的所有样式，一模一样地应用到列表里的每一个元素上。”*/
#custom-clipboard,
#custom-emoji {
    background-color: @on_secondary;
    color: @on_surface;
    padding: 0px 7px;
}    

#custom-wfrec,
#custom-screenshot {
    background-color: @secondary_container;
    color: @on_surface;
    padding: 0 7px; 
}


/* 禁止熄屏, 更新, 电源模式 */
#idle_inhibitor,
#custom-updates,
#power-profiles-daemon {
    padding: 0px 6px;
    background-color: @secondary;
    color: @on_tertiary;
}

/* 更新 */
#custom-updates {
   /*color: @error;*/
   font-size: 22px;	
   color:@on_tertiary;
}

#custom-updates.has-updates {
    color: @error;
}

/* 电源模式特殊颜色 */
#power-profiles-daemon.performance {
    color: @on_error;
    font-size: 20px;
}
#power-profiles-daemon.balanced {
    color: @on_tertiary;
    font-size: 19px;
}
#power-profiles-daemon.power-saver {
    color: #1aa052;
    font-size: 19px;
}

/* 程序启动器 */
#custom-applauncher {
    font-size: 25px;
    padding: 0px 7px;
    margin: 0px;
    background-color: @primary;
    color: @on_primary;
}

/* 时钟 */
#clock {
    background-color: @secondary;
    color: @on_secondary;
    padding: 0px 7px; 
}

/* 时钟关联的日历 */
.calendar-drawer {
    background-color: @surface_container_high;
    border: 2px solid @outline;
    border-radius: 8px;
    margin-top: 5px;
    padding: 10px;
}

#calendar {
    padding: 5px;
}

#calendar.header {
    color: @primary;
    font-weight: bold;
}

#calendar.weekdays {
    color: @secondary;
    margin-bottom: 5px;
}

#calendar.day.today {
    color: @primary;
    font-weight: bold;
    text-decoration: underline;
}

#calendar.day.other-month {
    color: @outline;
}

#calendar.day.focused {
    background-color: @surface_bright;
    border-radius: 4px;
}

/* 内存 和 温度 */
#memory,
#temperature {
    background-color: @secondary_container;
    color: @on_secondary_container;
    padding: 0px 8px;
}

/* 电池 */
#battery {
    background-color: @on_secondary;
    color: @on_surface;
    padding: 0px 7px;
}

#battery.critical:not(.charging) {
    background-color: @error;
    color: @on_error;
    animation-name: blink;
    animation-duration: 0.5s;
    animation-timing-function: steps(12);
    animation-iteration-count: infinite;
    animation-direction: alternate;
    padding: 0px 7px;
}


/*右侧模块*/
#backlight {
    background-color: @secondary_container;
    color: @on_secondary_container;
    padding: 0px 7px;
}

#pulseaudio {
    padding: 0px 7px;
    background-color: @secondary_container;
    color: @on_secondary_container;
}

/* 系统托盘 */
#tray {
    padding: 0px 7px 0px 7px;
    font-size: 20px;
    background-color: @on_secondary;
    color: @on_surface;
}

/* 电源菜单组 */
#custom-wlogout,
#custom-reboot,
#custom-lockscreen,
#custom-logout {
    background-color: @surface_container;
    color: @error;
    padding: 0px 10px;
}

/* (wlogout 有特殊 padding) */
#custom-wlogout {
    padding: 0px 15px 0px 10px; 
}


/*分隔符模块*/
/* (按 config.jsonc 顺序) */

/* Left */
#custom-right_div.5 {
    background: @surface_bright;
    color: @surface_container;
    font-size: 25px;
    padding: 0px;
}
#custom-right_div.6 {
    color: @surface_bright;
    font-size: 25px;
    padding: 0px;
}

/* Center */
#custom-left_div.99 {
    color: @on_secondary;
    padding: 0px;
    font-size: 25px;
}
#custom-left_div.2 {
    background-color: @secondary_container;
    color: @secondary;
    padding: 0px 0px;
    font-size: 25px;
}
#custom-left_div.11,
#custom-right_div.11 {
    margin: 0px;
    padding: 0px;
    font-size: 25px;
}
#custom-left_div.11 {
    background-color: @secondary;
    color: @surface_container;
}
#custom-right_div.11 {
    background-color: @secondary;
    color: @surface_container;
}
#custom-left_div.1,
#custom-right_div.1 {
    padding: 0px;
    margin: 0px;
    font-size: 25px;
}
#custom-left_div.1 {
    background-color: @surface_container;
    color: @primary;
}
#custom-right_div.1 {
    background-color: @surface_container;
    color: @primary;
}
#custom-right_div.2 {
    background-color: @secondary_container;
    color: @secondary;
    padding: 0px 0px;
    font-size: 25px;
}
#custom-right_div.3 {
    background-color: @on_secondary;
    color: @secondary_container;
    padding: 0px;
    font-size: 25px;
}
#custom-right_div.4 {
    color: @on_secondary;
    padding: 0px;
    font-size: 25px;
}

/* Right */
#custom-left_div.98 {
    color: @secondary_container;
    padding: 0px;
    font-size: 25px;
}
#custom-left_div.10 {
    background-color: @secondary;
    color: @tertiary;
}
#custom-left_inv.1 {
    padding: 0px;
    margin: 0px;
    font-size: 25px;
    background-color: @surface_container;
    color: @on_secondary;
}

#custom-left_div.97 {
    background-color: @on_secondary;
    color: @secondary_container;
    padding: 0px;
    font-size: 25px;
}

#custom-left_div.96 {
    color: @on_secondary;
    background-color: @secondary_container;
    padding: 0px;
    font-size: 25px;
}
```





script 里面都是模块调用的脚本
scripts/cava.sh 是音频可视化调用的脚本文件

```bash
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
```



metadata.sh 辅助音频可视化，实现悬停显示正在播放的音频名称 

```bash
#!/bin/bash
playerctl metadata --format '{{status_icon}} {{artist}} - {{title}}' 2>/dev/null
```



这两个是对应的 cava 配置文件

```bash
## Configuration file for CAVA.
# Remove the ; to change parameters.


[general]

# Smoothing mode. Can be 'normal', 'scientific' or 'waves'. DEPRECATED as of 0.6.0
; mode = normal

# Accepts only non-negative values.
; framerate = 60

# 'autosens' will attempt to decrease sensitivity if the bars peak. 1 = on, 0 = off
# new as of 0.6.0 autosens of low values (dynamic range)
# 'overshoot' allows bars to overshoot (in % of terminal height) without initiating autosens. DEPRECATED as of 0.6.0
; autosens = 1
; overshoot = 20

# Manual sensitivity in %. If autosens is enabled, this will only be the initial value.
# 200 means double height. Accepts only non-negative values.
; sensitivity = 100

# The number of bars (0-512). 0 sets it to auto (fill up console).
# Bars' width and space between bars in number of characters.
; bars = 0
; bar_width = 2
; bar_spacing = 1
# bar_height is only used for output in "noritake" format
; bar_height = 32

# For SDL width and space between bars is in pixels, defaults are:
; bar_width = 20
; bar_spacing = 5

# sdl_glsl have these default values, they are only used to calculate max number of bars.
; bar_width = 1
; bar_spacing = 0

# ceter bars in terminal, if there is space.
; center_align = 1

# max height of bars in terminal, in percent of terminal height.
; max_height = 100


# Lower and higher cutoff frequencies for lowest and highest bars
# the bandwidth of the visualizer.
# Note: there is a minimum total bandwidth of 43Mhz x number of bars.
# Cava will automatically increase the higher cutoff if a too low band is specified.
; lower_cutoff_freq = 50
; higher_cutoff_freq = 10000


# Seconds with no input before cava goes to sleep mode. Cava will not perform FFT or drawing and
# only check for input once per second. Cava will wake up once input is detected. 0 = disable.
; sleep_timer = 0


[input]

# Audio capturing method. Possible methods are: 'fifo', 'portaudio', 'pipewire', 'alsa', 'pulse', 'sndio', 'oss', 'jack' or 'shmem'
# Defaults to 'oss', 'pipewire', 'sndio', 'jack', 'pulse', 'alsa', 'portaudio' or 'fifo', in that order, dependent on what support cava was built with.
# On Mac it defaults to 'portaudio' or 'fifo'
# On windows this is automatic and no input settings are needed.
#
# All input methods uses the same config variable 'source'
# to define where it should get the audio.
#
# For pulseaudio and pipewire 'source' will be the source. Default: 'auto', which uses the monitor source of the default sink
# (all pulseaudio sinks(outputs) have 'monitor' sources(inputs) associated with them).
#
# For pipewire 'source' will be the object name or object.serial of the device to capture from.
# Both input and output devices are supported. To capture the monitor source of a sink node, append '.monitor' to the sink's object name.
#
# For alsa 'source' will be the capture device.
# For fifo 'source' will be the path to fifo-file.
# For shmem 'source' will be /squeezelite-AA:BB:CC:DD:EE:FF where 'AA:BB:CC:DD:EE:FF' will be squeezelite's MAC address
#
# For sndio 'source' will be a raw recording audio descriptor or a monitoring sub-device, e.g. 'rsnd/2' or 'snd/1'. Default: 'default'.
# README.md contains further information on how to setup CAVA for sndio.
#
# For oss 'source' will be the path to a audio device, e.g. '/dev/dsp2'. Default: '/dev/dsp', i.e. the default audio device.
# README.md contains further information on how to setup CAVA for OSS on FreeBSD.
#
# For jack 'source' will be the name of the JACK server to connect to, e.g. 'foobar'. Default: 'default'.
# README.md contains further information on how to setup CAVA for JACK.
#
; method = pulse
; source = auto

; method = pipewire
; source = auto

; method = alsa
; source = hw:Loopback,1

; method = fifo
; source = /tmp/mpd.fifo

; method = shmem
; source = /squeezelite-AA:BB:CC:DD:EE:FF

; method = portaudio
; source = auto

; method = sndio
; source = default

; method = oss
; source = /dev/dsp

; method = jack
; source = default

# The options 'sample_rate', 'sample_bits', 'channels' and 'autoconnect' can be configured for some input methods:
#   sample_rate: fifo, pipewire, sndio, oss
#   sample_bits: fifo, pipewire, sndio, oss
#   channels:    sndio, oss, jack
#   autoconnect: jack
# Other methods ignore these settings.
# For pipewire, sample_rate will default to 48000, for all other input methods, sample_rate will default to 44100.
#
# For 'sndio' and 'oss' they are only preferred values, i.e. if the values are not supported
# by the chosen audio device, the device will use other supported values instead.
# Example: 48000, 32 and 2, but the device only supports 44100, 16 and 1, then it
# will use 44100, 16 and 1.
#
#
# The 'pipewire' input method has three options to control linking and mixing:
#   active: Force the node to always process. Useful for monitoring sources when no other application is active.
#   remix: Allow pipewire to remix audio channels to match cava's channel count. Useful for surround sound.
#   virtual: Set the node to virtual, to avoid recording notifications from the DE.
#
; sample_rate = 44100
; sample_bits = 16
; channels = 2
; autoconnect = 2
; active = 0
; remix = 1
; virtual = 1


[output]

# Output method. Can be 'ncurses', 'noncurses', 'raw', 'noritake', 'sdl'
# or 'sdl_glsl'.
# 'noncurses' (default) uses a buffer and cursor movements to only print
# changes from frame to frame in the terminal. Uses less resources and is less
# prone to tearing (vsync issues) than 'ncurses'.
#
# 'raw' is an 8 or 16 bit (configurable via the 'bit_format' option) data
# stream of the bar heights that can be used to send to other applications.
# 'raw' defaults to 1024 bars stereo (512 bars mono), which can be adjusted in the 'bars' option above.
#
# 'noritake' outputs a bitmap in the format expected by a Noritake VFD display
#  in graphic mode. It only support the 3000 series graphical VFDs for now.
#
# 'sdl' uses the Simple DirectMedia Layer to render in a graphical context.
# 'sdl_glsl' uses SDL to create an OpenGL context. Write your own shaders or
# use one of the predefined ones.
; method = noncurses

# Orientation of the visualization. Can be 'bottom', 'top', 'left', 'right' or
# 'horizontal'. Default is 'bottom'. 'left and 'right' are only supported on sdl
# and ncruses output. 'horizontal' (bars go up and down from center) is only supported
# on noncurses output.
# Note: many fonts have weird or missing glyphs for characters used in orientations
# other than 'bottom', which can make output not look right.
; orientation = bottom

# Visual channels. Can be 'stereo' or 'mono'.
# 'stereo' mirrors both channels with low frequencies in center.
# 'mono' outputs left to right lowest to highest frequencies.
# 'mono_option' set mono to either take input from 'left', 'right' or 'average'.
# set 'reverse' to 1 to display frequencies the other way around.
; channels = stereo
; mono_option = average
; reverse = 0

# Raw output target.
# On Linux, a fifo will be created if target does not exist.
# On Windows, a named pipe will be created if target does not exist.
; raw_target = /dev/stdout

# Raw data format. Can be 'binary' or 'ascii'.
; data_format = binary

# Binary bit format, can be '8bit' (0-255) or '16bit' (0-65530).
; bit_format = 16bit

# Ascii max value. In 'ascii' mode range will run from 0 to value specified here
; ascii_max_range = 1000

# Ascii delimiters. In ascii format each bar and frame is separated by a delimiters.
# Use decimal value in ascii table (i.e. 59 = ';' and 10 = '\n' (line feed)).
; bar_delimiter = 59
; frame_delimiter = 10

# sdl window size and position. -1,-1 is centered.
; sdl_width = 1024
; sdl_height = 512
; sdl_x = -1
; sdl_y= -1
; sdl_full_screen = 0

# set label on bars on the x-axis. Can be 'frequency' or 'none'. Default: 'none'
# 'frequency' displays the lower cut off frequency of the bar above.
# Only supported on ncurses and noncurses output.
; xaxis = none
 
# enable synchronized sync. 1 = on, 0 = off
# removes flickering in alacritty terminal emulator.
# defaults to off since the behaviour in other terminal emulators is unknown
; synchronized_sync = 0

# Shaders for sdl_glsl, located in $HOME/.config/cava/shaders
; vertex_shader = pass_through.vert
; fragment_shader = bar_spectrum.frag

; for glsl output mode, keep rendering even if no audio
; continuous_rendering = 0

# disable console blank (screen saver) in tty
# (Not supported on FreeBSD)
; disable_blanking = 0

# show a flat bar at the bottom of the screen when idle, 1 = on, 0 = off
; show_idle_bar_heads = 1

# show waveform instead of frequency spectrum, 1 = on, 0 = off
; waveform = 0

[color]

# Colors can be one of seven predefined: black, blue, cyan, green, magenta, red, white, yellow.
# Or defined by hex code '#xxxxxx' (hex code must be within ''). User defined colors requires
# a terminal that can change color definitions such as Gnome-terminal or rxvt.
# default is to keep current terminal color
; background = default
; foreground = default

# SDL and sdl_glsl only support hex code colors, these are the default:
; background = '#111111'
; foreground = '#33ffff'


# Gradient mode, only hex defined colors are supported,
# background must also be defined in hex or remain commented out. 1 = on, 0 = off.
# You can define as many as 8 different colors. They range from bottom to top of screen
; gradient = 0
; gradient_color_1 = '#59cc33'
; gradient_color_2 = '#80cc33'
; gradient_color_3 = '#a6cc33'
; gradient_color_4 = '#cccc33'
; gradient_color_5 = '#cca633'
; gradient_color_6 = '#cc8033'
; gradient_color_7 = '#cc5933'
; gradient_color_8 = '#cc3333'


# Horizontal is only supported on noncurses output.
# Only one color will be calculated per bar.
; horizontal_gradient = 0
; horizontal_gradient_color_1 = '#c45161'
; horizontal_gradient_color_2 = '#e094a0'
; horizontal_gradient_color_3 = '#f2b6c0'
; horizontal_gradient_color_4 = '#f2dde1'
; horizontal_gradient_color_5 = '#cbc7d8'
; horizontal_gradient_color_6 = '#8db7d2'
; horizontal_gradient_color_7 = '#5e62a9'
; horizontal_gradient_color_8 = '#434279'


# If both vertical and horizontal gradient is enabled, vertical will be blended in this direction.
# Can be 'up', 'down', 'left' or 'right'. 'up' means the vertical gradient will be blended in from
# bottom to top. I.e. the bottom will be only the horizontal
# and top will be only the color of the vertical gradient.
; blend_direction = 'up'

# use theme file instead of defining colors in this file
# themes are located in $HOME/.config/cava/themes
 theme = 'your-theme'


[smoothing]

# Percentage value for integral smoothing. Takes values from 0 - 100.
# Higher values means smoother, but less precise. 0 to disable.
# DEPRECATED as of 0.8.0, use noise_reduction instead
; integral = 77

# Disables or enables the so-called "Monstercat smoothing" with or without "waves". Set to 0 to disable.
; monstercat = 0
; waves = 0

# Set gravity percentage for "drop off". Higher values means bars will drop faster.
# Accepts only non-negative values. 50 means half gravity, 200 means double. Set to 0 to disable "drop off".
# DEPRECATED as of 0.8.0, use noise_reduction instead
; gravity = 100


# In bar height, bars that would have been lower that this will not be drawn.
# DEPRECATED as of 0.8.0
; ignore = 0

# Noise reduction, int 0 - 100. default 77
# the raw visualization is very noisy, this factor adjusts the integral and gravity filters to keep the signal smooth
# 100 will be very slow and smooth, 0 will be fast but noisy.
; noise_reduction = 77


[eq]

# This one is tricky. You can have as much keys as you want.
# Remember to uncomment more than one key! More keys = more precision.
# Look at readme.md on github for further explanations and examples.
; 1 = 1 # bass
; 2 = 1
; 3 = 1 # midtone
; 4 = 1
; 5 = 1 # treble
```



```bash
[color]
background = 'default'
foreground = '#feb0d3'

; gradient = 0
gradient = 1
gradient_color_1 = '#6d3351'
gradient_color_2 = '#feb0d3'
gradient_color_3 = '#ffd8e7'

horizontal_gradient = 0
; horizontal_gradient = 1
horizontal_gradient_color_1 = '#6d3351'
horizontal_gradient_color_2 = '#feb0d3'
horizontal_gradient_color_3 = '#ffd8e7'
horizontal_gradient_color_4 = '#feb0d3'
horizontal_gradient_color_5 = '#6d3351'
```





get-clock.sh 就是简单的悬停获取时间的脚本， 时钟模块调用的

```bash
#!/bin/bash

HOUR=$(date "+%H")
TIME=$(date "+%H:%M")
TOOLTIP=$(LC_TIME=zh_CN.UTF-8 date "+%Y年%m月%d日 %A")
ICON=""

printf '{"text": "%s %s", "tooltip": "%s"}\n' "$ICON" "$TIME" "$TOOLTIP"
```



下面两个是截屏调用的脚本，因为脚本在 hyprland 快捷键里早就有使用，所以我就拿来复用了

screenshot_edit.sh 

```bash
#!/usr/bin/env bash
# wrapper for waybar: 调用 hypr 编辑脚本
~/.config/hypr/scripts/screenshot_edit.sh
```



screenshot_quick.sh 

```bash
#!/usr/bin/env bash
# wrapper for waybar: 调用 hypr 脚本，确保兼容性
~/.config/hypr/scripts/screenshot_quick.sh
```



screenshot_edit.sh

```bash
#!/usr/bin/env bash
# 选区截图到临时文件，打开 swappy 编辑。swappy 退出后，检测并通知保存的文件（优先 ~/Pictures/Screenshots）
DST_DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DST_DIR"

TMP="/tmp/swappy_screenshot_$$.png"
TS="/tmp/swappy_ts_$$"
date +%s > "$TS"

# take region
if ! grim -g "$(slurp)" "$TMP"; then
  notify-send -a "Swappy" "Selection failed" --hint=int:transient:1
  rm -f "$TMP" "$TS"
  exit 1
fi

# run swappy and wait until it exits
swappy -f "$TMP"

# find newest file in DST_DIR modified after TS
NEW=$(find "$DST_DIR" -type f -newer "$TS" -printf '%T@ %p\n' 2>/dev/null | sort -nr | awk 'NR==1{print $2}')

if [ -n "$NEW" ]; then
  notify-send -a "Swappy" "Saved: $(basename "$NEW")" --hint=int:transient:1
else
  # fallback: find any new file in home that looks like screenshot or swappy-saved
  NEW2=$(find "$HOME" -type f -newer "$TS" \( -iname '*swappy*' -o -iname '*screenshot*' -o -iname '*.png' -o -iname '*.jpg' \) 2>/dev/null | head -n1)
  if [ -n "$NEW2" ]; then
    notify-send -a "Swappy" "Saved (other location): $(basename "$NEW2")" --hint=int:transient:1
  else
    notify-send -a "Swappy" "No new file detected (maybe saved to a custom path)" --hint=int:transient:1
  fi
fi

# cleanup
rm -f "$TMP" "$TS"
exit 0
```



screenshot_quick.sh 

```bash
#!/usr/bin/env bash
# Fullscreen quick screenshot -> save to ~/Pictures/Screenshots, COPY TO CLIPBOARD, and notify

DIR="$HOME/Pictures/Screenshots"
mkdir -p "$DIR"
FILE="$DIR/screenshot_$(date '+%Y%m%d_%H%M%S').png"

# Fullscreen using grim (no slurp)
if grim "$FILE"; then
  # 将生成的图片文件输入给 wl-copy
  wl-copy < "$FILE"

  # 通知文案提示已复制
  notify-send -a "Screenshot" "Saved & Copied: $(basename "$FILE")" --hint=int:transient:1
  exit 0
else
  notify-send -a "Screenshot" "Failed to take fullscreen screenshot" --hint=int:transient:1
  [ -f "$FILE" ] && rm -f "$FILE"
  exit 1
fi
```



set_wallpaper.sh 快捷切换壁纸脚本，和下面的脚本结合使用                  

```bash
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
```



wallpaper_scroll.sh   
壁纸目录应当存放在$HOME/Pictures/anime/wallpapers 下

```bash
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
```





wf-recorder.sh 录屏菜单脚本 

```bash
#!/usr/bin/env bash
set -Eeuo pipefail

# ================== Runtime state ==================
APP="wf-recorder"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/run/user/$UID}"
STATE_DIR="$RUNTIME_DIR/wfrec"
PIDFILE="$STATE_DIR/pid"            # 存放 wf-recorder 进程 ID
SAVEPATH_FILE="$STATE_DIR/save_path"  # 存放当前录制的文件路径
LOGFILE="$STATE_DIR/wf-recorder.log"  # 存放 wf-recorder 的日志

# 存放持久化配置
CFG_CODEC="$STATE_DIR/codec"
CFG_FPS="$STATE_DIR/framerate"
CFG_MIC_AUDIO="$STATE_DIR/mic_audio"
CFG_SYS_AUDIO="$STATE_DIR/sys_audio"
CFG_DRM="$STATE_DIR/drm_device"
CFG_EXT="$STATE_DIR/container_ext"

mkdir -p "$STATE_DIR"
MODE_DECIDED="" # 临时存储选择的模式

# ================== Tunables (ENV overridable) ==================
# 默认值
_DEFAULT_CODEC="h264_vaapi"
_DEFAULT_FRAMERATE=""
_DEFAULT_MIC_AUDIO="off"
_DEFAULT_SYS_AUDIO="on"
_DEFAULT_SAVE_EXT="auto"

# 从文件加载持久化设置
codec_from_file=$(cat "$CFG_CODEC" 2>/dev/null || true)
fps_from_file=$(cat "$CFG_FPS" 2>/dev/null || true)
mic_audio_from_file=$(cat "$CFG_MIC_AUDIO" 2>/dev/null || true)
sys_audio_from_file=$(cat "$CFG_SYS_AUDIO" 2>/dev/null || true)
drm_from_file=$(cat "$CFG_DRM" 2>/dev/null || true)
ext_from_file=$(cat "$CFG_EXT" 2>/dev/null || true)

# 优先级: 环境变量 > 持久化文件 > 默认值
CODEC="${CODEC:-${codec_from_file:-$_DEFAULT_CODEC}}"
FRAMERATE="${FRAMERATE:-${fps_from_file:-$_DEFAULT_FRAMERATE}}"
MIC_AUDIO="${MIC_AUDIO:-${mic_audio_from_file:-$_DEFAULT_MIC_AUDIO}}"
SYS_AUDIO="${SYS_AUDIO:-${sys_audio_from_file:-$_DEFAULT_SYS_AUDIO}}"
DRM_DEVICE="${DRM_DEVICE:-${drm_from_file:-}}"
SAVE_EXT="${SAVE_EXT:-${ext_from_file:-$_DEFAULT_SAVE_EXT}}"

# 其他可配置变量
TITLE="${TITLE:-}"
SAVE_DIR_ENV="${SAVE_DIR:-}"
SAVE_SUBDIR_FS="${SAVE_SUBDIR_FS:-fullscreen}"
OUTPUT="${OUTPUT:-}"
OUTPUT_SELECT="${OUTPUT_SELECT:-auto}"
MENU_TITLE_OUTPUT="${MENU_TITLE_OUTPUT:-}"
MENU_BACKEND="${MENU_BACKEND:-auto}"
RECORD_MODE="${RECORD_MODE:-ask}"
MODE_MENU_TITLE="${MODE_MENU_TITLE:-Select recording mode}"
REC_AREA="${REC_AREA:-}"
GEOM_IN_NAME="${GEOM_IN_NAME:-off}"
PKILL_AFTER_STOP="${PKILL_AFTER_STOP:-on}"

# ================== Utils ==================
# 检查命令是否存在
has() { command -v "$1" >/dev/null 2>&1; }

# 语言设置 (只保留中文)
lang_code() { echo zh; }

# 消息字典
msg() {
  local id="$1"; shift
  case "$(lang_code)" in
    zh)
      case "$id" in
        err_wf_not_found) printf "未找到 wf-recorder" ;;
        err_need_slurp)   printf "需要 slurp 以进行区域选择" ;;
        warn_drm_ignored) printf "警告：DRM_DEVICE=%s 不存在或不可读，将忽略。" "$@" ;;
        warn_invalid_fps) printf "警告：FRAMERATE=\"%s\" 非法，已忽略。" "$@" ;;
        warn_render_unreadable) printf "警告：无效的 render 节点：%s" "$@" ;;
        cancel_no_mode)   printf "已取消：未选择录制模式。" ;;
        cancel_no_output) printf "已取消：未选择输出。" ;;
        cancel_no_region) printf "已取消：未选择区域。" ;;
        warn_multi_outputs_cancel) printf "检测到多个输出但未选择，已取消。" ;;
        notif_started_full)   printf "开始录制（全屏：%s）→ %s" "$@" ;;
        notif_started_region) printf "开始录制（区域）→ %s" "$@" ;;
        notif_device_suffix)  printf "（设备 %s）" "$@" ;;
        notif_saved)    printf "录制已保存：%s" "$@" ;;
        notif_stopped)  printf "录制已停止（未保存文件）。" ;;
        notif_failed_start) printf "录制启动失败！" ;;
        already_running) printf "录制已在运行中。" ;;
        not_running)     printf "录制未在运行。" ;;
        title_mode)      printf "选择录制模式" ;;
        title_output)    printf "选择输出" ;;
        menu_fullscreen) printf "全屏" ;;
        menu_region)     printf "选择区域" ;;
        title_settings)  printf "设置" ;;
        menu_settings)   printf "设置..." ;;
        menu_set_codec)  printf "编码格式：%s" "$@" ;;
        menu_set_fps)    printf "帧率：%s" "$@" ;;
        menu_set_filefmt) printf "文件格式：%s" "$@" ;;
        menu_toggle_audio) printf "麦克风：%s" "$@" ;;
        menu_toggle_sysaudio) printf "系统音频：%s" "$@" ;;
        menu_set_render) printf "渲染设备：%s" "$@" ;;
        menu_back)       printf "返回" ;;
        fps_unlimited)   printf "不限制" ;;
        render_auto)     printf "自动" ;;
        ext_auto)        printf "自动" ;;
        title_select_codec) printf "选择编码格式" ;;
        title_select_fps)   printf "选择帧率" ;;
        title_select_filefmt) printf "选择文件格式" ;;
        title_select_render) printf "选择渲染设备（/dev/dri/renderD*）" ;;
        mode_full)       printf "全屏" ;;
        mode_region)     printf "区域" ;;
        prompt_enter_number) printf "输入编号：" ;;
        menu_exit)       printf "退出" ;;
        *) printf "%s" "$id" ;;
      esac
      ;;
  esac
}

# 检查录制进程是否在运行
is_running() {
  [[ -r "$PIDFILE" ]] || return 1
  local pid; read -r pid <"$PIDFILE" 2>/dev/null || return 1
  [[ -n "$pid" ]] && kill -0 "$pid" 2>/dev/null
}

# 封装 notify-send
notify() { 
  local summary="${1:-}"
  local body="${2:-}"
  if has notify-send; then
    if [[ -n "$body" ]]; then
      notify-send "wf-recorder" "$summary" -b "$body"
    else
      notify-send "wf-recorder" "$summary"
    fi
  fi
}

# 获取视频保存目录
get_save_dir() {
  local videos
  if has xdg-user-dir; then videos="$(xdg-user-dir VIDEOS 2>/dev/null || true)"; fi
  videos="${videos:-"$HOME/Videos"}"
  echo "${SAVE_DIR_ENV:-"$videos/wf-recorder"}"
}

# --- render device helpers ---
# 列出可用的DRM渲染节点
list_render_nodes() {
  local d
  for d in /dev/dri/renderD*; do
    [[ -r "$d" ]] && printf '%s\n' "$d"
  done 2>/dev/null || true
}
# 显示当前选择的渲染节点
render_display() {
  local cur="${1:-}"
  if [[ -z "$cur" ]]; then
    msg render_auto
  else
    printf "%s" "$cur"
  fi
}
# 检查并返回有效的渲染节点
pick_render_device() {
  local dev="${DRM_DEVICE:-}"
  if [[ -n "$dev" && ! -r "$dev" ]]; then
    printf '%s\n' "$(msg warn_drm_ignored "$dev")" >&2
    dev=""
  fi
  echo -n "$dev"
}

# --- file format helpers ---
# 根据编码器推荐文件扩展名
ext_for_codec(){ case "${1,,}" in
  *h264*|*hevc*) echo mp4 ;;
  *vp9*)         echo webm ;;
  *av1*)         echo mkv ;;
  *)             echo mp4 ;;
esac; }
# 决定最终的文件扩展名
choose_ext(){
  local e="${SAVE_EXT,,}"
  if [[ -z "$e" || "$e" == "auto" ]]; then
    ext_for_codec "$CODEC"
  else
    case "$e" in mp4|mkv|webm) echo "$e" ;; *) echo mp4 ;; esac
  fi
}

# ================== Menus ==================
# 规范化菜单输出
__norm() { printf '%s' "$1" | tr -d '\r' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//'; }

# 自动选择菜单后端
_pick_menu_backend() {
  local pref="${MENU_BACKEND,,}"
  case "$pref" in fuzzel|wofi|rofi|bemenu|fzf|term) : ;; auto|"") pref="auto" ;; *) pref="auto" ;; esac
  if [[ "$pref" != "auto" ]]; then
    if has "$pref"; then echo "$pref"; else [[ -t 0 ]] && echo "term" || echo "none"; fi
    return
  fi
  for b in fuzzel wofi rofi bemenu fzf; do has "$b" && { echo "$b"; return; }; done
  [[ -t 0 ]] && echo "term" || echo "none"
}

# 弹出选择菜单
menu_pick() { # $1:title; items...
  local title="${1:-Select}"; shift
  local items=("$@")
  ((${#items[@]})) || return 130

  local backend; backend="$(_pick_menu_backend)"
  local sel rc=130
  case "$backend" in
    fuzzel) set +e; sel="$(printf '%s\n' "${items[@]}" | fuzzel --dmenu -p "$title")"; rc=$?; set -e ;;
    wofi)   set +e; sel="$(printf '%s\n' "${items[@]}" | wofi --dmenu --prompt "$title")"; rc=$?; set -e ;;
    rofi)   set +e; sel="$(printf '%s\n' "${items[@]}" | rofi -dmenu -p "$title")"; rc=$?; set -e ;;
    bemenu) set +e; sel="$(printf '%s\n' "${items[@]}" | bemenu -p "$title")"; rc=$?; set -e ;;
    fzf)    set +e; sel="$(printf '%s\n' "${items[@]}" | fzf --prompt "$title> ")"; rc=$?; set -e ;;
    term)
      echo "$title"
      local i=1; for it in "${items[@]}"; do printf '  %d) %s\n' "$i" "$it"; ((i++)); done
      printf "%s" "$(msg prompt_enter_number)"
      local idx; set +e; read -r idx; rc=$?; set -e
      if [[ $rc -eq 0 && -n "$idx" && "$idx" =~ ^[0-9]+$ ]]; then
        if (( idx>=1 && idx<=${#items[@]} )); then sel="${items[$((idx-1))]}"; rc=0; fi
      fi
      ;;
    none) return 130 ;;
  esac
  [[ $rc -ne 0 || -z "${sel:-}" ]] && return 130
  printf '%s' "$(__norm "$sel")"
}

# ---------- Outputs ----------
# 列出所有显示器输出
list_outputs() {
  local raw
  if raw="$(wf-recorder -L 2>/dev/null)"; then :; elif has wlr-randr; then raw="$(wlr-randr 2>/dev/null | awk '/^[^ ]/{print $1}')"; else raw=""; fi
  awk 'BEGIN{RS="[ \t\r\n,]+"} /^[A-Za-z0-9_.:-]+$/ { if ($0 ~ /^(e?DP|HDMI|DVI|VGA|LVDS|Virtual|XWAYLAND)/) seen[$0]=1 } END{for(k in seen) print k}' <<<"$raw" | sort -u
}
# 决定录制哪个输出
decide_output() {
  if [[ -n "$OUTPUT" ]]; then printf '%s' "$OUTPUT"; return 0; fi
  local -a outs; mapfile -t outs < <(list_outputs || true)
  local out_title; out_title="${MENU_TITLE_OUTPUT:-$(msg title_output)}"
  if [[ "${OUTPUT_SELECT}" == "menu" ]] || { [[ "${OUTPUT_SELECT}" == "auto" ]] && ((${#outs[@]} > 1)); }; then
    local pick; pick="$(menu_pick "$out_title" "${outs[@]}")" || return 130
    printf '%s' "$pick"; return 0
  fi
  if ((${#outs[@]} == 1)); then printf '%s' "${outs[0]}"; else notify "$(msg warn_multi_outputs_cancel)"; return 130; fi
}

# ---------- Settings ----------
# 渲染设备选择菜单
choose_render_menu() {
  local -a nodes
  mapfile -t nodes < <(list_render_nodes | sort -V || true)
  local auto_item; auto_item="$(msg render_auto)"
  local pick
  if ! pick="$(menu_pick "$(msg title_select_render)" "$auto_item" "${nodes[@]}")"; then
    return 0
  fi
  if [[ "$pick" == "$auto_item" ]]; then
    DRM_DEVICE=""
    rm -f "$CFG_DRM"
    return 0
  fi
  local sel="$pick"
  if [[ -n "$sel" && -r "$sel" ]]; then
    DRM_DEVICE="$sel"
    printf '%s' "$DRM_DEVICE" >"$CFG_DRM"
  else
    notify "$(msg warn_render_unreadable "$sel")"
  fi
}

# 文件格式选择菜单
choose_filefmt_menu() {
  local auto_item; auto_item="$(msg ext_auto)"
  local pick
  if ! pick="$(menu_pick "$(msg title_select_filefmt)" "$auto_item" "mp4" "mkv" "webm")"; then
    return 0
  fi
  if [[ "$pick" == "$auto_item" ]]; then
    SAVE_EXT="auto"
    rm -f "$CFG_EXT"
  else
    case "$pick" in
      mp4|mkv|webm) SAVE_EXT="$pick"; printf '%s' "$SAVE_EXT" >"$CFG_EXT" ;;
      *) : ;;
    esac
  fi
}

# 主设置菜单
show_settings_menu() {
  while :; do
    local fps_display="${FRAMERATE:-$(msg fps_unlimited)}"
    local micaudio_display="${MIC_AUDIO}"
    local sysaudio_display="${SYS_AUDIO}"
    local render_display_now; render_display_now="$(render_display "$DRM_DEVICE")"
    local ff_display; if [[ -z "$SAVE_EXT" || "${SAVE_EXT,,}" == "auto" ]]; then ff_display="$(msg ext_auto)"; else ff_display="$SAVE_EXT"; fi

    local pick; pick="$(menu_pick "$(msg title_settings)" \
                      "$(msg menu_set_fps "$fps_display")" \
                      "$(msg menu_toggle_sysaudio "$sysaudio_display")" \
                      "$(msg menu_toggle_audio "$micaudio_display")" \
                      "$(msg menu_set_codec "$CODEC")" \
                      "$(msg menu_set_filefmt "$ff_display")" \
                      "$(msg menu_set_render "$render_display_now")" \
                      "$(msg menu_back)")" || return 0

    if [[ "$pick" == "$(msg menu_set_fps "$fps_display")" ]]; then
      local newf; newf="$(menu_pick "$(msg title_select_fps)" "60" "30" "120" "144" "165" "240" "$(msg fps_unlimited)")" || continue
      if [[ "$newf" == "$(msg fps_unlimited)" ]]; then
        FRAMERATE=""; rm -f "$CFG_FPS"
      else
        if [[ "$newf" =~ ^[0-9]+$ && "$newf" -gt 0 ]]; then FRAMERATE="$newf"; printf '%s' "$FRAMERATE" >"$CFG_FPS"; fi
      fi
    elif [[ "$pick" == "$(msg menu_toggle_sysaudio "$sysaudio_display")" ]]; then
      if [[ "$SYS_AUDIO" == "on" ]]; then SYS_AUDIO="off"; else SYS_AUDIO="on"; fi
      printf '%s' "$SYS_AUDIO" >"$CFG_SYS_AUDIO"
    elif [[ "$pick" == "$(msg menu_toggle_audio "$micaudio_display")" ]]; then
      if [[ "$MIC_AUDIO" == "on" ]]; then MIC_AUDIO="off"; else MIC_AUDIO="on"; fi
      printf '%s' "$MIC_AUDIO" >"$CFG_MIC_AUDIO"
    elif [[ "$pick" == "$(msg menu_set_codec "$CODEC")" ]]; then
      local newc; newc="$(menu_pick "$(msg title_select_codec)" \
                       "h264_vaapi" "libx264" "hevc_vaapi" \
                       "av1_vaapi"  "libsvtav1" "libaom-av1" "libvpx-vp9")" || continue
      CODEC="$newc"; printf '%s' "$CODEC" >"$CFG_CODEC"
    elif [[ "$pick" == "$(msg menu_set_filefmt "$ff_display")" ]]; then
      choose_filefmt_menu
    elif [[ "$pick" == "$(msg menu_set_render "$render_display_now")" ]]; then
      choose_render_menu
    elif [[ "$pick" == "$(msg menu_back)" ]]; then
      return 0
    fi
  done
}

# ---------- Mode selection ----------
# 录制模式选择菜单
decide_mode() {
  case "${RECORD_MODE,,}" in
    full|fullscreen) MODE_DECIDED="full";   return 0 ;;
    region|area)     MODE_DECIDED="region"; return 0 ;;
    *) ;;
  esac
  local L_FULL L_REGION L_SETTINGS L_EXIT
  L_FULL="$(msg menu_fullscreen)"; L_REGION="$(msg menu_region)"; L_SETTINGS="$(msg menu_settings)"; L_EXIT="$(msg menu_exit)";
  local title; title="$(msg title_mode)"
  while :; do
    local pick; pick="$(menu_pick "$title" "$L_FULL" "$L_REGION" "$L_SETTINGS" "$L_EXIT")" || return 130
    if   [[ "$pick" == "$L_FULL"    ]]; then MODE_DECIDED="full";   return 0
    elif [[ "$pick" == "$L_REGION"  ]]; then MODE_DECIDED="region"; return 0
    elif [[ "$pick" == "$L_SETTINGS" ]]; then show_settings_menu; continue
    elif [[ "$pick" == "$L_EXIT"    ]]; then return 130
    else return 130; fi
  done
}

# ================== Start / Stop ==================
# 开始录制
start_rec() {
  if is_running; then notify "$(msg already_running)"; exit 0; fi
  has wf-recorder || { notify "$(msg err_wf_not_found)"; exit 1; }

  MODE_DECIDED=""
  if ! decide_mode; then
    notify "$(msg cancel_no_mode)"; exit 130
  fi
  local mode="$MODE_DECIDED"

  local marker="" output="" GEOM=""
  local -a args
  
  local ROOT_DIR TARGET_DIR
  ROOT_DIR="$(get_save_dir)"
  if [[ "$mode" == "full" ]]; then TARGET_DIR="$ROOT_DIR/${SAVE_SUBDIR_FS}"; else TARGET_DIR="$ROOT_DIR"; fi
  mkdir -p "$TARGET_DIR"

  # 全屏模式
  if [[ "$mode" == "full" ]]; then
    output="$(decide_output)" || { exit 130; } 
    [[ -n "$output" ]] && args+=( -o "$output" )
    marker="FS${output:+-$output}"
  # 区域模式
  else
    if [[ -n "$REC_AREA" ]]; then
      GEOM="$REC_AREA"
    else
      has slurp || { notify "$(msg err_need_slurp)"; exit 1; }
      set +e; GEOM="$(slurp)"; local rc=$?; set -e
      if [[ $rc -ne 0 || -z "${GEOM// /}" ]]; then notify "$(msg cancel_no_region)"; exit 130; fi
    fi
    GEOM="$(echo -n "$GEOM" | tr -s '[:space:]' ' ')"
    args+=( -g "$GEOM" )
    marker="REGION"
  fi

  # 
  local ts safe_title base SAVE_PATH ext
  ts="$(date +'%Y-%m-%d-%H%M%S')"; safe_title="${TITLE// /_}"
  base="$ts${safe_title:+-$safe_title}-${marker}"
  ext="$(choose_ext)"
  SAVE_PATH="$TARGET_DIR/$base.$ext"

  args=( --file "$SAVE_PATH" "${args[@]}" )
  local dev; dev="$(pick_render_device)"; [[ -n "$dev" ]] && args+=( -d "$dev" )

  # 音频参数
  local -a audio_args=() 
  if [[ "$SYS_AUDIO" == "on" ]]; then
      audio_args+=( --audio="@DEFAULT_AUDIO_SINK@.monitor" )
  fi
  if [[ "$MIC_AUDIO" == "on" ]]; then
      audio_args+=( --audio="@DEFAULT_AUDIO_SOURCE@" )
  fi
  
  # 编码器参数
  args+=( -c "$CODEC" )
  if ((${#audio_args[@]} > 0)); then
      args+=( "${audio_args[@]}" ) 
  fi
  if [[ "$CODEC" == *"_vaapi" ]]; then
      args+=( -F "scale_vaapi=format=nv12:out_range=full:out_color_primaries=bt709" )
  else
      args+=( -F "format=yuv420p" ) 
  fi
  
  # 帧率参数
  if [[ -n "$FRAMERATE" ]]; then
    if [[ "$FRAMERATE" =~ ^[0-9]+$ && "$FRAMERATE" -gt 0 ]]; then args+=( --framerate "$FRAMERATE" )
    else notify "$(msg warn_invalid_fps "$FRAMERATE")"; fi
  fi

  # 启动 wf-recorder 进程
  >"$LOGFILE" 
  setsid nohup wf-recorder "${args[@]}" >>"$LOGFILE" 2>&1 &
  local pid=$!
  
  # 检查是否立即启动失败
  sleep 0.5 
  if ! kill -0 "$pid" 2>/dev/null; then
      rm -f "$PIDFILE"
      local err_msg; err_msg=$(tail -n 5 "$LOGFILE")
      notify "$(msg notif_failed_start)" "$err_msg"
      exit 1
  fi

  # 保存状态
  echo "$pid" >"$PIDFILE"
  echo "$SAVE_PATH" >"$SAVEPATH_FILE"

  # 发送录制开始通知
  local note; if [[ "$mode" == "full" ]]; then note="$(msg notif_started_full "$output" "$SAVE_PATH")"; else note="$(msg notif_started_region "$SAVE_PATH")"; fi
  [[ -n "$dev" ]] && note+="$(msg notif_device_suffix "$dev")"
  notify "$note"
}

# 停止录制
stop_rec() {
  if ! is_running; then notify "$(msg not_running)"; exit 0; fi
  local pid; read -r pid <"$PIDFILE"

  # 
  kill -INT "$pid" 2>/dev/null || true
  for _ in {1..40}; do sleep 0.1; is_running || break; done
  is_running && kill -TERM "$pid" 2>/dev/null || true
  sleep 0.2
  is_running && kill -KILL "$pid" 2>/dev/null || true

  # 
  rm -f "$PIDFILE"

  local save_path=""; [[ -r "$SAVEPATH_FILE" ]] && read -r save_path <"$SAVEPATH_FILE"
  if [[ -n "$save_path" && -f "$save_path" ]]; then
    ln -sf "$(basename "$save_path")" "$(dirname "$save_path")/latest.${save_path##*.}" || true
    # 
    local s; s="$(msg notif_saved "$save_path")"; notify "$s"
  else
    # 
    local s; s="$(msg notif_stopped)"
    local err_log; err_log=$(tail -n 5 "$LOGFILE" 2>/dev/null)
    [[ -n "$err_log" ]] && notify "$s" "错误详情: $err_log" || notify "$s"
  fi

  # 
  if [[ "${PKILL_AFTER_STOP,,}" != "off" ]]; then
    for sig in INT TERM KILL; do
      pgrep -x -u "$UID" "$APP" >/dev/null || break
      pkill --"$sig" -x -u "$UID" "$APP" 2>/dev/null || true
      sleep 0.1
    done
  fi
}

# ================== Main ==================
# 
case "${1:-toggle}" in
  start)        start_rec ;;
  stop)         stop_rec ;;
  is-active)    if is_running; then exit 0; else exit 1; fi ;;
  toggle)       is_running && stop_rec || start_rec ;;
  settings)     show_settings_menu ;;
  *)            echo "Usage: $0 {start|stop|toggle|is-active|settings}"; exit 2 ;;
esac
```



switch-audio-output.sh 快捷选择音频输出设备

```bash
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
```



桌面美化效果预览如下

![[_resources/linux笔记/3714b46c5aee50f0520ab81ef0acdbb1_MD5.png]]

有个小瑕疵，就是那个控制息屏的模块，它的两个状态切换的图标大小是不一样的，当前是启用息屏，中间的图标正好居中，我切换到另一个状态，图标就小了一点，中间的图标就会往左移动一些，但我也懒得改了，不过修改也简单，改成大小一致的图标就行，但我还没找到合适的，另一个方案是用 css 的 padding 字段，严格控制该字符的边距就行了，但我暂时也不改了

过一段时间或许会去试试 niri，感觉挺不错的


好的，已经叛逃到 niri 了，hyprland 真的回不去了，同时 waybar 也做了部分优化和为了适配 niri 的部分微调，因此这段配置，能用吧，至少作为 hyprland 的 bar 是可以的，但还是有待优化，之后单独列出 niri 的相关块，或许会顺便优化一下这里的部分通用代码逻辑吧，比如滚动切换壁纸使用 pkill 是很浪费性能的，明明 mpvpaper 就支持直接覆盖，不过还是等我后续修改吧

好了，waybar也不用了，用的noctalia-shell,似乎dms更加完善，潜力更高，但它的动画效果目前是不如noctalia的，所以还是用着noctalia吧，但我认为它们的可定制性还是不如waybar，但仔细想想，waybar如果功能做得比较多了，内存占用就会更大，这时就更需要系统性的配置调优，那我为啥不直接用人家专门开发的桌面shell，主要还是现在的自己不懂开发，忙着备考专升本也没时间学，但我会去学的。










### 剪切板方案
sudo pacman -S --needed wl-clipboard 
yay -S cliphist
然后在 hyprland 配置文件里写入

```bash
exec-once = wl-paste --type text --watch cliphist store # Stores only text data
exec-once = wl-paste --type image --watch cliphist store # Stores only image data

#绑定调用剪切板的快捷键
bind = $mainMod, x, exec, cliphist list | fuzzel --dmenu --with-nth 2 | cliphist decode | wl-copy
#如果用的文件管理器是 fuzzel 的话
```
如果是其他文件管理器，对应的键位绑定配置就去看 hyprland 的 wiki  [https://wiki.hypr.land/Useful-Utilities/Clipboard-Managers/](https://wiki.hypr.land/Useful-Utilities/Clipboard-Managers/)
  
  






### 截图录屏方案
安装这三个包
sudo pacman -S grim slurp wf-recorder 

然后在 hyprland 配置文件里绑定快捷键

```bash
# 区域截图：同时保存到图片目录和剪贴板
bind = $mainMod SHIFT, S, exec, grim -g "$(slurp)" | tee ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png | wl-copy
# 全屏截图：同时保存到图片目录和剪贴板  
bind = $mainMod,q,exec, grim | tee ~/Pictures/screenshot_$(date +%Y%m%d_%H%M%S).png | wl-copy

# 录屏快捷键  
bind = $mainMod SHIFT, v, exec, wf-recorder -g "$(slurp)" -f "$HOME/Videos/recording_$(date +%Y%m%d_%H%M%S).mp4"
bind = $mainMod CTRL, v, exec, pkill -SIGINT wf-recorder  # 停止录制
```







### 禁用触控板
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
sudo chmod +x ~/.config/hypr/scripts/toggle_touchpad.sh

在 hyprland 配置文件上绑定键位 ctrl+f10

```bash
# 切换触控板 (Ctrl + F10)
bind = CTRL, F10, exec, ~/.config/hypr/scripts/toggle_touchpad.sh
```















### 关于 hyprland 的浮动窗口变量设置
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







### 视频壁纸方案
项目名 mpvpape

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
mpvpaper DP-2 /path/to/video

DP-2 是显示器名字，也就是说可以指定显示器播放，自己的显示器名字用 hyprctl monitors all查看所有 hyprland 检测到的显示器信息，懒得看就直接用 ALL 代替所有显示器

笔记本内置屏幕名字一般是 eDP-1,我的就是
但这个只能播放一次，需要循环播放就需要使用命令
例如这样的
mpvpaper -o "--loop-file" eDP-1 Downloads/【哲风壁纸】剪影-多重影像.mp4
这个命令是前台运行，所以可以在尾巴加上&，但是这样关闭终端就会杀死进程，另一种方法是加上& disown，这样即使关闭终端也不会杀死进程，不过如果要写进 exec-once 里只需要单用一个&就足够了
mpvpaper -o "--loop-file" eDP-1 Downloads/【哲风壁纸】剪影-多重影像.mp4 &
这个命令就可以写进 hyprland 的 exec-once 设置开机自启

  
  




### 玩游戏帧率异常
玩鸣潮的时候发现帧率不对劲，帧率不稳定，一战斗就掉帧

看一下 nvidia-smi 回显

```bash
❯ nvidia-smi           
Sun Nov  9 15:24:01 2025        
+-----------------------------------------------------------------------------------------+
| NVIDIA-SMI 580.95.05              Driver Version: 580.95.05      CUDA Version: 13.0     |
+-----------------------------------------+------------------------+----------------------+
| GPU  Name                 Persistence-M | Bus-Id          Disp.A | Volatile Uncorr. ECC |
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory-Usage | GPU-Util  Compute M. |
|                                         |                        |               MIG M. |
|=========================================+========================+======================|
|   0  NVIDIA GeForce RTX 4060 ...    Off |   00000000:01:00.0 Off |                  N/A |
| N/A   70C    P8              5W /   80W |    3944MiB /   8188MiB |      0%      Default |
|                                         |                        |                  N/A |
+-----------------------------------------+------------------------+----------------------+

+-----------------------------------------------------------------------------------------+
| Processes:                                                                              |
|  GPU   GI   CI              PID   Type   Process name                        GPU Memory |
|        ID   ID                                                               Usage      |
|=========================================================================================|
|    0   N/A  N/A             868      G   /usr/lib/Xorg                             4MiB |
|    0   N/A  N/A            2280      G   Hyprland                                  2MiB |
|    0   N/A  N/A           47172    C+G   ...n64\Client-Win64-Shipping.exe       3848MiB |
+-----------------------------------------------------------------------------------------+


```

第 11 行，可以看到 N 卡处于 P8 状态（低功耗状态）,这时游戏挂在后台，p8 倒也没啥，不过正常玩的时候这玩意好像是一直处于 p8 状态，我也不确定

运行这个命令
sudo nvidia-smi -pm 1 # 启用持久模式

就能解决了，这个我不确定是不是临时命令，但重启后也不用再次执行也能正常帧率玩鸣潮了，所以可能是 nvidia 的一点小 bug，这个命令刷新了 N 卡的状态

这种系统抽风问题最难搞了，感觉我不用这个命令，N 卡都不知道自己还有个持久模式😅







### 截屏翻译方案
主要使用 Crow Translate 这个程序
1.安装主程序
yay -S crow-translate

2.安装 Wayland/OCR 核心依赖
tesseract 是引擎, slurp 是划词工具, portal 是 Wayland 门户
sudo pacman -S tesseract slurp xdg-desktop-portal-hyprland


3.安装 OCR 语言包
我玩未来战用的，就装英韩中三个语言吧
sudo pacman -S tesseract-data-eng tesseract-data-kor tesseract-data-chi_sim


打开软件Crow Translate
点右下角三个横线进入这个界面的这个设置
![[_resources/linux笔记/0a0a553e147730d9c419a9bde4feaf87_MD5.png]]
把安装的 OCR 语言包都勾选上

再到这个选项
![[_resources/linux笔记/4a6cfd13a058ea72523797bb98fca63f_MD5.png]]

点一下最右边的按钮 Detect fastest
URL 里面是翻译引擎，默认的早就失效了，需要按这个按钮刷新出新翻译引擎，不然用旧的会在翻译栏报 418 错误

目前只能在程序主界面点击截图才能截图翻译，关于快捷键截图翻译，关于全局的那一片是灰色的不能用，目前猜测是因为我的 plasma 和 hyprland 的混合桌面环境导致的，也有可能是因为 hyprland 禁止绕过它配置快捷键，反正目前还不知道为啥，有待后续排查（我也懒得排查这玩意，不如多找找别的开源项目，排不排查再说吧）

![[_resources/linux笔记/2f595e1d4a2c51550e22cf213bcb7f00_MD5.png]]

另外在安装过程中，有个注意事项，不能在包管理器 pacman 工作的时候后台跑游戏，尤其是 steam 游戏，不然 hyprland 会卡死，忘记是为啥了，反正最好别这样搞













# 11/10
## 软件包降级
clash-verge-rev 更新后发现 tun 模式打不开了，尝试了降级软件包处理

1.首先 pacman 会在本地留下软件包缓存，首先检查这个目录下有没有需要的版本

```bash
❯ ls /var/cache/pacman/pkg/ | grep clash
clash-geoip-202510300021-1-any.pkg.tar.zst
clash-geoip-202510300021-1-any.pkg.tar.zst.sig
clash-geoip-202511060021-1-any.pkg.tar.zst
clash-geoip-202511060021-1-any.pkg.tar.zst.sig
clash-verge-rev-2.4.3-1-x86_64.pkg.tar.zst
clash-verge-rev-2.4.3-1-x86_64.pkg.tar.zst.sig
#发现只有clash-geoip这个包有旧版本，于是尝试先把这个降级
❯ sudo pacman -U /var/cache/pacman/pkg/clash-geoip-202510300021-1-any.pkg.tar.zst
#发现没啥用，还是打不开tun模式，而本地又没有clash-verge-rev这个包的旧缓存，所以只能去aur仓库找
```

2.克隆 AUR 仓库并检测出旧版本

```bash
git clone https://aur.archlinux.org/clash-verge-rev.git
cd clash-verge-rev
```

```bash
❯ git log --oneline --graph --decorate
● 7f0a825 (HEAD -> master, origin/master, origin/HEAD) [lilac] updated to 2.4.3-1
● 8168c5c [lilac] updated to 2.4.2-2
● 8bd360b Update sha512sums
● 4adeec4 [lilac] updated to 2.4.2-1
● 417ee86 [lilac] updated to 2.4.1-1
● 36a1a2e [lilac] updated to 2.4.0-1
● 93bfde8 [lilac] updated to 2.3.2-1
● a0a5484 [lilac] updated to 2.3.1-1
● b6503cb [lilac] updated to 2.3.0-2
● 9c4bd9a [lilac] updated to 2.3.0-1
● 3c510dd [lilac] updated to 2.2.3-3
● 3a2253d [lilac] updated to 2.2.3-2
● 0a10265 [lilac] updated to 2.2.3-1
● 29c9da4 [lilac] updated to 2.2.2-3
● 1fa194f [lilac] updated to 2.2.2-2
● 8f1ee0e [lilac] updated to 2.2.2-1
● fcec89c [lilac] updated to 2.2.1-2
● d01e243 [lilac] updated to 2.2.0-1
● 0b19316 Update from archlinuxcn
● 5719888 Update AUR package
● fb5473c Update AUR package
● 37a5344 Update AUR package
● f74a444 update
● 3443147 Update AUR package
● 11538b8 Update AUR package
● af53270 init
● 2d856f3 init
#开头的字符串是提交哈希
```



3.切换到旧版本提交
git checkout b6503cb  # 切换到 2.3.0-2 版本 指定的是对应版本的提交哈希

4.构建和安装提交的版本
makepkg -si


构建过程中出现了源文件校验和失败的问题，clash-verge-service.tar.gz 的 SHA512 校验和不匹配，这通常是因为源文件在服务器上已被更新，但 PKGBUILD 中的校验和还是旧值
sudo pacman -S pacman-contrib

在项目目录中运行
updpkgsums
这个命令会自动计算当前下载的源文件的 SHA512 校验和，并更新 PKGBUILD 中的 sha512sums 数组

然后重新构建并安装
makepkg -si



然而 pacman -Syu 未来还是必要的，所以在这个问题修复前，我就让 clash-verge-rev 不要跟着一起更新吧
sudo pacman -D --asexplicit clash-verge-rev clash-geoip
这个命令的作用是将包标记为显式安装，而不是依赖安装

通过手动构建安装的包，有时会被 pacman 错误标记为依赖包，如果卸载某些软件，该软件包被视为依赖，就会被 pacman 自动清理，标记为显示安装后，pacman 不会自动清理它

```plain
❯ sudo echo 'IgnorePkg = clash-verge-rev clash-geoip' | sudo tee /etc/pacman.d/ignore.conf

IgnorePkg = clash-verge-rev clash-geoip
```





















# 11/11
## 微信读取系统文件夹异常
这个和 hyprland 无关，我就单独拿出来

具体就是用微信打开本地文件夹发现显示不全

看了一下我的微信是 flatpak 版的，关于 flatpak 沙盒，需要单独安装组件来管理应用权限问题，比如文件读取权限
sudo pacman -S flatseal
安装这个应用。是图形化的，打开后操作比较简单，找到微信，打开对应权限开关就行了














# 11/12
## konsole提示符异常
就是在打开窗口的时候，提示符上面不知道为啥会出现一个%号

原因是我在 zshrc 里面写入的引用 Starship（从社区找来的提示符美化配置文件）和我设置的compinit（ Zsh 的自动补全系统）有冲突

```plain
# 1. 设 置 历 史 记 录e
# -----------------------------------------------------------------
HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000
setoptHIST_IGNORE_DUPS
setoptHIST_IGNORE_SPACE
setoptSHARE_HISTORY
setoptAPPEND_HISTORY
setoptEXTENDED_HISTORY

# 2. 别 名 与 颜 色D
# -----------------------------------------------------------------
alias ls='ls --color=auto'
alias l='ls -CF --color=auto'
alias la='ls -A --color=auto'
alias ll='ls -lA --color=auto'
eval"$(dircolors -b)"

# 3. 补 全 样 式 o
# -----------------------------------------------------------------
zstyle':completion:*' menu select
zstyle':completion:*:default' list-colors $LS_COLORS

# 4. 加 载  Zsh 自 动 建 议 插 件 a
# -----------------------------------------------------------------
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# 5. 激 活  Starship 提 示 符 u
# -----------------------------------------------------------------
eval"$(starship init zsh)"

# 6. 自 动 补 全 s
# -----------------------------------------------------------------
autoload -Uz compinit
compinit

# 7. 加 载 语 法 高 亮 插 件 t
# -----------------------------------------------------------------
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


```


临时方案是rm -f ~/.zcompdump 删除缓存，但需要每次关闭前都删除一次，可以写进 zshrc 里面，但影响性能


我的方案是使用Zsh 插件管理器：Zinit

执行如下命令，脚本会自动处理
bash -c $curl --fail --show-error --silent --location https://raw.githubusercontent.com/zdharma-continuum/zinit/HEAD/scripts/install.sh 


用了几天发现这玩意也没鸟用，正好要移除 plasma，顺手给 konselo 卸载换 kitty 了，不过排查思路是对的，确实是因为这俩玩意冲突，更底层的原因就不懂了  












## sudo 密码输入问题
用 hyprland 发现一个终端即使不关闭，只要一段时间不 sudo，就要我重复输入密码，很烦人，顺便再设置一下首次 sudo 后无论在哪个终端半小时内都不用再次输入密码
sudo EDITOR=vim visudo -f /etc/sudoers.d/99-custom-timeout

在文件中写入如下内容
Defaults timestamp_timeout=30, !tty_tickets



为什么起99-custom-timeout这么奇怪的文件名？

因为 Linux 加载 `/etc/sudoers.d/` 目录下的配置时，是按字母和数字顺序的（从 `00-` 到 `99-`）

系统默认的配置（比如 `10-arch-default`）可能设置了 `timestamp_timeout=0`（0分钟超时）。

我们使用 `99-` 这个最高优先级的文件名，确保我们的配置是最后一个被加载的，因此它会覆盖掉系统所有的默认设置。

timestamp_timeout=30
它把 `sudo` 密码的有效期从默认的（可能是0或5分钟）延长到了 30 分钟。

!tty_tickets
关闭每个 Konsole 窗口都要单独输密码的规则，使得密码有效期可全局共享


















# 11/16
## arch 和 win 双系统配置安全启动
### 理论基础
一、 什么是安全启动？
安全启动 (Secure Boot)是主板 UEFI 固件里的一项安全功能。

它的唯一目的是在操作系统（Arch / Windows）启动之前，阻止任何“不受信任”的代码运行。这主要是为了防御在开机阶段就加载的恶意软件（如 Rootkit）。

理论依据：它的工作原理非常简单：UEFI 固中内置了一个“可信签名数据库”。当你开机时，UEFI 会像个“保安”一样，检查要加载的第一个启动文件（Bootloader）有没有“可信的签名”。
默认情况下，UEFI 只信任一个签名：微软 (Microsoft) 的。

如果启动文件（比如 `grubx664.efi`）没有微软签名，UEFI 会拒绝加载它，启动过程当场中止。



二、 Arch Linux 的解决方案

整套方案，核心理论就是**“信任接力”。我们利用一个微软信任的程序，来“引荐”我们自己的程序

1. 理论依据：`shim` (信任的“中间人”)

+ **它是什么：**`shimx64.efi` 是一个由**微软官方签名**的小型引导程序。
+ **为什么用它：** 因为它有微软签名，所以“保安”(UEFI) 会**允许它启动**。
+ **它的工作：**`shim` 启动后的唯一任务，就是去加载**下一个**程序（也就是我们的 GRUB）。



2. 理论依据：MOK (我们自己的“签名”)

+ **它是什么：** MOK (Machine Owner Key) 是我们**自己创建**的一对“签名密钥”（公钥/私钥）。
+ **为什么用它：**`shim` 也不是什么都加载。它只会加载那些被“它信任的密钥”签过的文件。
+ **它的工作：** 我们把 MOK 的“公钥”注册（Enroll）到主板里，`shim` 就会“认识”它。从此，`shim` 就会信任**任何被我们 MOK“私钥”签过的文件**。
+ **总结：**`UEFI(信任) -> 微软(签名) -> shim(信任) -> MOK(签名) -> 我们的GRUB`。这条信任链就通了。



3. 理论依据：独立的 GRUB 

+ **挑战：** 信任链是通了，但 `shim` 只会验证 `grubx64.efi` 这**一个**文件。但常规的 GRUB 启动时，需要从磁盘上读取**几十个**零散的模块（比如 `fat.mod`, `btrfs.mod`）和配置文件 (`grub.cfg`)。`shim` 无法验证这几十个文件。
+ **解决方案：** 我们不能用常规的 GRUB。我们必须用 `grub-mkimage` 命令，**手动**创建一个“**独立自主**”的 `grubx64.efi`。
+ **理论：**
    1. **打包模块：** 我们把**所有**未来可能用到的驱动模块（`fat`, `part_gpt`, `btrfs` 等）**提前打包并嵌入**到 `grubx64.efi`**文件内部**。
    2. **硬编码配置：** 我们把一个迷你的“启动脚本”（即 `grub-pre.cfg`）也**硬编码**进 `grubx64.efi` 的“大脑”里。
    - 这个“大脑”（`grub-pre.cfg`）的**唯一**任务，就是**加载**它“后备箱”里打包的**正确驱动**（比如 `insmod fat`），然后用**正确的路径**（比如 `set prefix=($root)/grub`），去**找到**那个**真正的菜单** (`grub.cfg`)。



4. 理论依据：`pacman` 钩子 (自动化的“未来”)

+ **挑战：** 这个信任链必须**全程**维护。`grubx64.efi` 需要 MOK 签名，`vmlinuz-linux` (内核) 也**同样**需要 MOK 签名。
+ **问题：**`pacman -Syu` 会用**未签名**的新内核覆盖掉旧的已签名内核。
+ **解决方案：**`pacman` 钩子 (Hook) 是一个自动化脚本。它的理论依据是“**在更新后，立即自动重签**”。
    - **内核钩子：** 监视 `linux-zen` 包。一旦更新，立刻自动运行 `sbsign` 命令，用你的 MOK 私钥给新的 `vmlinuz-linux-zen` 签名。
    - **GRUB 钩子：** 监视 `grub` 包。一旦更新，立刻自动运行 `update-sb-grub-efi.sh`，重新生成那个“独立管家” `grubx64.efi` 并自动签名。

---

**总结成一句话的理论：** 我们利用**微软签名**的 `shim`，来加载一个**我们自己 MOK 签名**的、**内置了驱动和路径（**`**insmod fat**`**）的独立 **`**grubx664.efi**`，这个 `grub` 再去加载**同样被 MOK 签名**的**内核**，最后用 `**pacman**`** 钩子**让这个签名过程自动化。







### 配置过程
#### 1.GRUB 侧的配置
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



#### 2.GRUB MemDisk 和预加载脚本.
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
search.fs_uuid 1B9C-667B root hd0,gpt1

我选择这样填写，uuid 是我的 efi 分区，注意这里的 root 并不是指/分区，而是指 boot 分区，gpt1 则是因为 efi 分区的索引为 1

![[_resources/linux笔记/b3ade282afba90d071c64eae7e0094b2_MD5.png]]



如果之后希望读取更多字体，只需要将相应的 PF2 文件复制到上面创建的 memdisk 中，并在 grub-pre.cfg 中使用 loadfont 命令加载，并重新生成 GRUB EFI 文件，即可正常显示对应字体。

完成上述操作之后，回到 /etc/secureboot 文件夹，执行 update-sb-grub-efi.sh。不出意外的话你会看到下面两行输出，即代表没有问题：

```bash
> sudo ./update-sb-grub-efi.sh
Signing /boot/EFI/ARCH/grubx64.efi...
Signing Unsigned original image
```





#### 3. 内核签名
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







#### 4.准备重启
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

![[_resources/linux笔记/3336fc2cde1b2d0b9e23a4ecf5bb1b30_MD5.png]]







#### 5. 自动更新 GRUB 的 EFI 文件和配置数据
首先，准备一下 update-grub 脚本。可以通过 AUR 包的形式安装（包名为 update-grub），也可以在 /usr/local/bin 下新建一个。文件的内容可以参考[这里](https://aur.archlinux.org/cgit/aur.git/tree/update-grub?h=update-grub)

:::info
yay -S update-grub

:::

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

![[_resources/linux笔记/e958a4e711bd12a528ab5a5ce2093e19_MD5.png]]



至此配置完毕



















# 11/21
## Arch Linux 轻量化音乐播放系统
MPD + ncmpcpp + Cava



1. 安装必要软件

需要安装四个组件：后台服务(MPD)、终端客户端(ncmpcpp)、媒体键支持(mpDris2)、可视化频谱(Cava)。

```bash
# 1. 安装官方仓库软件
sudo pacman -S mpd ncmpcpp cava
# 2. 安装 AUR 插件 (用于支持 playerctl 和 Waybar 控制)
yay -S mpdris2
```



2. 环境初始化

MPD 默认会尝试以系统服务运行，读取 `/etc/mpd.conf`，这会导致权限错误 (`Failed to open /var/lib/...`)。必须手动创建用户目录并禁用系统服务。

```bash
# 1. 停止并禁用系统级服务 (防止冲突)
sudo systemctl stop mpd sudo systemctl disable mpd
 # 2. 创建 MPD 必须的文件夹结构 (不做这一步 MPD 会启动失败)
mkdir -p ~/.config/mpd/playlists 
# 3. 创建空的状态文件 (防止 MPD 报找不到文件的错） 
touch ~/.config/mpd/{database,state,pid,sticker.sql} 
# 4. 创建 mpDris2 和 Cava 的配置目录 
mkdir -p ~/.config/mpdris2 mkdir -p ~/.config/cava
```



3. 配置文件编写

配置 MPD核心 (`~/.config/mpd/mpd.conf`)

```bash
# 音乐目录 (根据实际情况修改)
music_directory    "~/Music"

# 必须的运行文件定义
playlist_directory "~/.config/mpd/playlists"
db_file            "~/.config/mpd/database"
log_file           "syslog"
pid_file           "~/.config/mpd/pid"
state_file         "~/.config/mpd/state"
sticker_file       "~/.config/mpd/sticker.sql"

# 网络设置 (仅限本机访问)
bind_to_address    "127.0.0.1"
port               "6600"

# 自动扫描新歌 & 恢复播放状态
auto_update        "yes"
restore_paused     "yes"

# 音频输出 1: 让你听到声音 (PipeWire/PulseAudio)
audio_output {
        type            "pulse"
        name            "PulseAudio"
}

# 音频输出 2: 可视化数据流 (给 Cava 用)
# 如果不加这个，Cava 只能读取麦克风或系统总声，不灵敏
audio_output {
    type                    "fifo"
    name                    "my_fifo"
    path                    "/tmp/mpd.fifo"
    format                  "44100:16:2"
}
```



配置 mpDris2 (`~/.config/mpdris2/mpdris2.conf`)

让键盘多媒体键和 Waybar 能控制 MPD。

```bash
[Connection]
host = 127.0.0.1
port = 6600
music_dir = ~/Music  # 必须和 MPD 音乐目录一致，用于读取封面

[Bling]
notify = false       # 切歌弹窗 (不喜欢可关)
mmkeys = true        # 启用键盘多媒体键支持
```



还要配置 cava 可视化，但我之前美化 waybar 的时候已经配过了



4. 启动服务

```bash
# 重载配置
systemctl --user daemon-reload

# 启动并开机自启 MPD
systemctl --user enable --now mpd

# 启动并开机自启 mpDris2,不建议设置这个，因为会影响我的waybar的音频可视化
# 模块无法正常隐藏
# systemctl --user enable --now mpDris2
```



5. 客户端 (ncmpcpp) 使用
    

终端输入 ncmpcpp 进入界面。按 F1 可查看帮助。

解决乱序播放/文件夹播放问题：

1. 按 1 进入播放列表。
    
2. 看右上角是否有 [z] 或高亮的 Random。如果有，按 z 键关闭随机模式。
    
3. 按 c 清空当前列表。
    
4. 按 2 进入文件浏览器，选中文件夹，按 空格 即可按顺序添加整张专辑。
    

常用按键功能列表：

1：播放列表（正在播放的歌单） 2：文件浏览（去硬盘找歌） 3：搜索（搜歌名/歌手） 空格：添加歌曲（将选中项加入列表） Enter：播放（立即播放选中项） p：暂停/继续（Pause）

> ：下一首（. 键） <：上一首（, 键） c：清空列表（Clear） u：更新数据库（下载新歌后必按） z：随机模式开关（必须关闭才能顺序播放）




后续优化

为了和我的 waybar 组件配合，让 waybar 的音频可视化能够识别到 MPD 播放的音频，需要打开mpDris2 服务，但如果设置开启自启动的话，waybar 模块就会被一直占用不隐藏了，杀进程又太麻烦，所以写了一个 desktop 文件，用 fuzzel 打开后会在终端运行mpDris2 和 mpd 并打开 ncmpcpp，终端关闭后mpDris2 和 mpd 进程会被杀死，不赖

```bash
❯ cat ~/.local/share/applications/ncmpcpp-temp-mpdris.desktop            
[Desktop Entry]
Type=Application
Name=Ncmpcpp(本地音乐播放器)
GenericName=Music Player
Comment=启动 mpd + mpDris2 + ncmpcpp，窗口关闭时全部销毁
# 核心逻辑解析：
# 1. mpd --no-daemon & -> 启动 MPD 但不让它后台化，这样我们才能获取它的 PID
# 2. mpDris2 &         -> 启动翻译器
# 3. trap "kill..."    -> 退出时同时杀掉 MPD 和 mpDris2 的 PID
# 4. ncmpcpp           -> 启动界面
Exec=kitty --class music_player --title "Music Player" -e bash -c 'mpd --no-daemon >/dev/null 2>&1 & MPD_PID=$!; sleep 0.5; mpDris2 >/dev/null 2>&1 & DRIS_PID=$!; trap "kill $MPD_PID $DRIS_PID 2>/dev/null" EXIT HUP TERM INT; ncmpcpp'
Icon=utilities-terminal
Terminal=false
Categories=Audio;Player;ConsoleOnly;
```















# 11/26

# 11/27
## arch 打开文件夹却显示终端
就是发现在某些应用，我选择打开文件夹，打开的却是我的 kitty 终端，解决方案参考如下
```
❯ xdg-mime query default inode/directory
kitty-open.desktop
❯ xdg-mime default org.gnome.Nautilus.desktop inode/directory
❯ xdg-mime query default inode/directory                     
org.gnome.Nautilus.desktop
```











# 12/5
## archlinux（niri）配置
我的设备信息
[[_resources/linux笔记/05fb4d754cd84c33fdca4e18c3f79d6d_MD5.jpg|Open: Pasted image 20251205231208.png]]
![[_resources/linux笔记/05fb4d754cd84c33fdca4e18c3f79d6d_MD5.jpg]]

我是用archinstall安装的，并安装了显卡驱动，它支持安装niri的初始环境，不过感觉不如最小化安装，但是装都装好了，在此基础上开始我的配置
在archinstall的过程中，我设置了根分区文件系统类型为btrfs，子卷及其挂载情况如下
@ -> /   
@home -> /home 
@pkg -> /var/cache/pacman/pkg
@log -> /var/log
@swap -> /swap
efi分区挂载在/efi上，引导程序用的grub
esp挂载在/efi上
还要选择Mark/Unmark as ESP和Mark/Unmark as bootable标记一下

驱动安装选择的Nvidia (proprietary)，剩余的驱动可以开机后补充安装
`sudo pacman -S --needed mesa lib32-mesa xf86-video-amdgpu vulkan-radeon lib32-vulkan-radeon`
显示管理器用的sddm

archinstall提供了预装软件的功能，我这里预装了这些软件包
git base-devel vim neovim kitty zsh firefox nautilus sushi file-roller gvfs fastfetch btop openssh pipewire wireplumber pipewire-pulse pavucontrol bluez bluez-utils fcitx5-im fcitx5-rime fcitx5-chinese-addons noto-fonts-cjk noto-fonts-emoji ttf-jetbrains-mono-nerd wl-clipboard xdg-desktop-portal-gnome polkit-gnome niri fuzzel mako grim  slurp  swappy snapper snap-pac btrfs-assistant gnome-software grub-btrfs inotify-tools nvidia-prime gst-plugins-bad gst-plugins-ugly gst-libav mpv

要不是不能用yay，我全给它装上了

### 1.配置基础环境
配置yay
编辑pacman配置文件
sudo vim /etc/pacman.conf
写入如下内容
[archlinuxcn]
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch

保存退出后
更新数据库并安装 keyring (这是为了信任 CN 源的签名)
sudo pacman -Sy archlinuxcn-keyring

直接安装 yay
sudo pacman -S yay


生成中文 Locale
不配置的话，中文内容会乱码
sudo vim /etc/locale.gen
找到 `zh_CN.UTF-8 UTF-8` ，把前面的 `#` 去掉，(确保 `en_US.UTF-8 UTF-8` 也是开启的)
然后生成Locale
sudo locale-gen
确认 `/etc/locale.conf` 内容是
LANG=en_US.UTF-8


然后传入了我的dotfile，比如niri配置之类的

#### 配置基础软件包
装梯子
yay -S mihomo-party-bin


再装个xwayland-satellite，保守一点就不装git版本的了
yay -S xwayland-satellite

很多应用默认都是用xwayland运行的，因为xwayland-satellite太垃圾了，所以这些应用都很糊，可以直接修改desktop文件，在exec处添加参数
`--enable-features=UseOzonePlatform --ozone-platform=wayland --enable-wayland-ime`
为了防止被更新覆盖，可以把desktop文件复制到.local下面对应的目录下面再修改,但是使用wayland协议可能会有别的问题，慎重使用

#### 配置输入法
我选择雾凇拼音
1.安装 fcitx5 框架和 rime 引擎
`sudo pacman -S --needed fcitx5-im fcitx5-rime`

2.从 AUR 安装雾凇拼音 (自动配置版)
这个包会自动把配置文件放到正确的位置，省去手动下载解压的麻烦
`yay -S rime-ice-git`

3.配置环境变量
在/etc/environment内写入如下内容
```
QT_IM_MODULE=fcitx
XMODIFIERS=@im=fcitx
SDL_IM_MODULE=fcitx
```

4.配置在 Niri 中自启动
在niri配置文件内自动启动区块写入如下内容
`spawn-at-startup "fcitx5" "-d"
`
重启一下
如果输入法没生效，使用fcitx5-configtool检查是否添加了Rime输入法，如果中文输入法不是雾凇，随便敲几个拼音，在备选框出现时按下F4可以选择切换输入法

#### 配置noctalia
这个直接去看官方手册，很详细的配置过程了，安装的时候要从多个依赖中选一个，我选的qt6-multimedia-ffmpeg
在niri的环境变量中，我选择配置了QT6来管理主题，有些主题会体现图标缺失的情况，所以我选择了papirus主题
安装主题
`yay -S papirus-icon-theme`
使用qt6图形化界面配置
`qt6ct`
在界面的图标主题中选中papirus主题并应用就行了

#### 配置noctalia自动锁屏休眠
因为noctalia的锁屏界面就挺不错，所以我选择这个，使用hypridle
1.安装hypridle
`sudo pacman -S hypridle`

2.创建配置
`mkdir -p ~/.config/hypr`
`vim ~/.config/hypr/hypridle.conf`
写入如下内容
```
general {
    # 使用 Noctalia 原生 IPC 锁屏
    lock_cmd = qs -c noctalia-shell ipc call lockScreen lock
    before_sleep_cmd = qs -c noctalia-shell ipc call lockScreen lock

    # 唤醒时告诉 Niri 开屏
    after_sleep_cmd = niri msg action power-on-monitors
}

listener {
    timeout = 300
    on-timeout = qs -c noctalia-shell ipc call lockScreen lock
}

listener {
    timeout = 330
    # Niri 专用关屏指令
    on-timeout = niri msg action power-off-monitors
    # Niri 专用开屏指令
    on-resume = niri msg action power-on-monitors
}

listener {
    timeout = 1200
    # Noctalia 锁屏并休眠
    on-timeout = qs -c noctalia-shell ipc call sessionMenu lockAndSuspend
}
```

3.配置niri自动启动hypridle
在niri配置文件中写入
`spawn-at-startup "hypridle"`




我的efi分区是挂载在/efi上面的，但很多程序还是喜欢在/boot下面读取grub的配置文件，因此需要做个软链接
`sudo ln -sf /efi/grub /boot/grub`

#### 配置snapper快照
很多软件包我都在archinstall里预装了，但我还是提一下吧
`sudo pacman -S  --needed snapper snap-pac btrfs-assistant`

自动生成快照启动项
`sudo pacman -S grub-btrfs inotify-tools`
`sudo systemctl enable --now grub-btrfsd`

设置覆盖文件系统
因为snapper快照是只读的，所以需要设置一个overlayfs在内存中创建一个临时可写的类似live-cd的环境，否则可能无法正常从快照启动项进入系统。
编辑`/etc/mkinitcpio.conf`
`sudo vim /etc/mkinitcpio.conf`

在HOOKS里添加`grub-btrfs-overlayfs`
`HOOKS= ( ...... grub-btrfs-overlayfs )`

重新生成initramfs
`sudo mkinitcpio -P`

重启后重新生成grub配置文件
`sudo grub-mkconfig -o /efi/grub/grub.cfg`





#### 配置swap分区
我是32G内存，需要睡眠功能，因此设置38G
`sudo btrfs filesystem mkswapfile --size 38g --uuid clear /swap/swapfile` 

写进fstab
/swap/swapfile none swap defaults 0 0












#### 配置greetd
也可以用sddm，设置sddm延迟启动
这是针对混合显卡的优化，因为显示管理器会在显卡驱动还没加载好的时候就启动，导致电脑会黑屏卡死
`sudo mkdir -p /etc/systemd/system/sddm.service.d`
添加以下内容
❯ cat /etc/systemd/system/sddm.service.d/delay.conf                                   `[Service]`
`ExecStartPre=/usr/bin/sleep 2`

sddm搞着麻烦，我换greetd再配置自动登录
`sudo pacman -S greetd greetd-tuigreet`
`sudo vim /etc/greetd/config.toml`
文件内容参考如下
```
[terminal]
# 在第1个虚拟终端运行，避免启动时的闪烁
vt = 1

# --- 1. 开机自动登录配置 (Initial Session) ---
[initial_session]
command = "niri-session"
user = "caster"

# --- 2. 注销后的登录界面 (Default Session) ---
[default_session]
# 使用 tuigreet 界面
# --remember: 记住你上次选的桌面
# --time: 右上角显示时间
# --sessions: 告诉它去哪里找桌面列表 (Wayland 和 X11)
# --cmd: 如果你没选桌面直接回车，默认进 Niri
command = "tuigreet --cmd niri-session --remember --time --sessions /usr/share/wayland-sessions:/usr/share/xsessions"

# 运行登录界面的用户 (这是 greetd 的专用用户，不要改)
user = "greeter"
```
然后配置它延迟两秒启动，说到底它也是个显示管理器，也会导致问题，所以需要设置
`sudo systemctl edit greetd`
在里面写入
```
[Service]
ExecStartPre=/usr/bin/sleep 2
```
其实这个和之前sddm的方式是类似的，最终它们都会生成对应的服务.d目录下的配置覆盖文件
然后把之前的sddm的systemd服务禁用，启用greetd
```
sudo systemctl disable sddm
sudo systemctl enable greetd
```






#### 常用配置
sudo pacman -S flatpak steam lutris spotify-launcher lib32-nvidia-utils lib32-vulkan-radeon

spotify-launcher我在用的听歌软件
lib32-nvidia-utils用于给steam调用32位显卡驱动
lib32-vulkan-radeon是给核显的 32 位 Vulkan 支持（备用）

配置 Flatpak 源
`flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`


关于GTK4应用打开慢的问题，是因为N卡渲染兼容性太差了，因此需要设置环境变量让GTK4应用用回旧的渲染器GL
将如下内容写进/etc/environment文件
强制 GTK4 使用旧版 GL 渲染器 (修复 Nvidia 卡顿)
GSK_RENDERER=gl

#### 配置zsh
sudo pacman -S starship zsh-autosuggestions zsh-syntax-highlighting
这些包是我的zsh要用到的美化文件
.config/starship.toml这个文件是调用的提示符美化文件,要去starship官网自己下载
然后设置默认shell为zsh
`chsh -s /usr/bin/zsh`


#### 配置niri的锁屏设置
(可选，我觉得noctalia自带的锁屏就很好看，所以我没弄这个)
sudo pacman -S swaylock-effects
`mkdir -p ~/.config/swaylock`
`vim ~/.config/swaylock/config`
写入如下内容
```
screenshots
clock
indicator
indicator-radius=200
indicator-thickness=15
effect-blur=10x5
```



配置自动熄屏锁屏休眠
mkdir -p ~/.config/niri/scripts
vim ~/.config/niri/scripts/swayidle.sh
写入如下内容
```
#!/usr/bin/env bash

# 定义 PID 变量
PID=0

# 启动函数
start_swayidle() {
    # 只有当 PID 为 0 或进程不存在时才启动
    if [[ $PID -eq 0 ]] || ! kill -0 "$PID" 2>/dev/null; then
        swayidle -w \
            timeout 300  'swaylock -f' \
            timeout 600  'niri msg action power-off-monitors' \
            resume       'niri msg action power-on-monitors' \
            timeout 1200 'systemctl suspend' &
        PID=$! # 记录 swayidle 的进程 ID
    fi
}

# 停止函数 (关机触发)
cleanup() {
    # 如果有 PID，直接杀掉
    if [[ $PID -ne 0 ]]; then
        kill -9 "$PID" 2>/dev/null
    fi
    exit 0
}

# 捕捉信号：一旦收到关机信号，立即跳转到 cleanup
trap cleanup SIGTERM SIGINT

echo "Swayidle Manager Started..."

while true; do
    # 使用 timeout 防止 systemd-inhibit 在关机时卡死
    if timeout 2s systemd-inhibit --list --no-pager | grep -q "Manually activated by user"; then
        # === 发现抑制锁 ===
        if [[ $PID -ne 0 ]] && kill -0 "$PID" 2>/dev/null; then
            kill "$PID" 2>/dev/null
            PID=0
        fi
    else
        # === 正常状态 ===
        start_swayidle
    fi

    #将 sleep 放入后台并 wait，这样信号能瞬间打断等待
    sleep 5 &
    wait $!
done
```






### 系统体验优化配置
#### rm 安全替换与自动清理
一直用rm -rf，虽然从没出过问题，但毕竟是日常使用的系统，还是保险起见设置一下，思路是用alisa别名设置rm为trash这个工具(功能是移动文件到回收站)，因为我用的是合成器而不是完整DE，所以回收站定时清理还是需要自己写一个systemd服务

1.安装工具
`sudo pacman -S trash-cli
`

2.配置别名
在.zshrc中写入
`alias rm='trash-put'`
然后生效
`source .zshrc`
原生rm被替换，如果某些大文件想直接删除，可以用`\rm`命令，利用linux中 \ 的特性忽略别名设置

3.配置 Systemd 定时清理 (每月一次)
创建一个**用户级**服务，不需要 sudo 权限，也不会污染系统目录。
创建服务文件,这个文件定义“**做什么**”（清理超过 30 天的文件）

创建目录
`mkdir -pv ~/.config/systemd/user/`
创建并编辑文件
`vim ~/.config/systemd/user/trash-clean.service`
写入如下内容
```
[Unit]
Description=清理回收站中存放超过30天的文件

[Service]
Type=oneshot
ExecStart=/usr/bin/trash-empty 30
```

创建定时器文件,这个文件定义“**什么时候做**”（每月运行一次）
创建并编辑文件：
`vim ~/.config/systemd/user/trash-clean.timer`
写入如下内容
```
[Unit]
Description=Run trash-clean monthly

[Timer]
# 调度规则：每月运行一次 (通常是每月1号)
OnCalendar=monthly
# 如果那时关机了，下次开机立刻补做
Persistent=true

[Install]
WantedBy=timers.target
```

激活并验证

启动定时器
`systemctl --user enable --now trash-clean.timer`
验证是否成功,检查一下定时器是否在列表里：
`systemctl --user list-timers --all | grep trash`


#### 配置键盘背光
华硕提供了图形化配置工具
`yay -S rog-control-center asusctl`
启动服务
`sudo systemctl start asusd
然后打开rog控制中心配置就行了



#### 音频提取与修改
安装这两个包
`sudo pacman -S yt-dlp ffmpeg`
使用方法
`yt-dlp -x --audio-format mp3 --no-playlist --embed-metadata --embed-thumbnail 视频链接`
**`-x`**: 下载完成后，将视频提取/转换为音频。
**`--audio-format mp3`**: 指定输出格式为 MP3
**`--no-playlist`**: 如果你给的链接是一个播放列表里的某一首歌，只下载这一首，不要把整个列表几百首歌都下下来
**`--embed-metadata`**: 自动抓取 YouTube（或其他平台）的 标题、歌手、专辑信息，写入 MP3 的 ID3 标签中
**`--embed-thumbnail`**: 下载视频封面并将其嵌入为音频文件的封面图

我这里在zshrc里把这条超长命令配置了别名为getaudio
`alias getaudio='yt-dlp -x --audio-format mp3 --no-playlist --embed-metadata --embed-thumbnail'`

下载的歌曲的元数据信息经常不尽人意，所以需要再引入工具eyeD3来修改歌曲元数据
安装工具
`yay -S python-eyed3` 
使用说明
`-a 修改歌手`
`-A 修改专辑名`
`-t 修改歌曲标题`
`--add-image /path/to/picture.jpg:FRONT_COVER music.mp3 修改歌曲图片`
案例
`eyeD3 -a "周杰伦" -t "夜曲" -A "十一月的肖邦" --add-image cover.jpg:FRONT_COVER music.mp3`





`
# 12/7
## git的使用
### obsidian自动化推送笔记到github备份
是想实现我的markdown笔记云端备份，因此选择了github私有仓库
本地仓库目录/home/caster/Documents/Study_Note

进入目录
`cd /home/caster/Documents/Study_Note`
**1.生成该仓库专用的独立密钥**
`ssh-keygen -t ed25519 -f ~/.ssh/id_ed25519_obsidian -C "linux_note_key"`
一路回车即可

在github上创建私有仓库linuxnote
[[_resources/linux笔记/b79450be15fd37f4bd46d8e4e9e00025_MD5.jpg|Open: Pasted image 20260106114924.png]]
![[_resources/linux笔记/b79450be15fd37f4bd46d8e4e9e00025_MD5.jpg]]

**2.将密钥配置到 GitHub 仓库**
查看并复制公钥
`cat ~/.ssh/id_ed25519_obsidian.pub`

去网页端设置
打开GitHub 仓库 `linuxnote` 页面
点击 **Settings**（选项卡） -> 左侧找到 **Deploy keys**
点击 **Add deploy key**
**Title**: 随便填,我写的archlinux
**Key**: 粘贴刚才 `cat` 出来的全部内容
**重要**：勾选 **Allow write access**（允许写入权限）
点击 **Add key** 保存。

**3.配置 SSH Config (让 Git 认识新密钥)**


### Git仓库推送流程
在github上弄了dotfiles仓库用于个人配置文件存储，项目地址[[https://github.com/Caster6443/dotfiles]]，前置认证流程就不记录了，这里记录一下使用方法

我把本地仓库放在/home/caster/Documents/my-dotfiles处
进入本地目录后
`git status`
检查本地与上游git仓库的文件变化，查看本地相较于git仓库多了哪些变化
确定无误后
`git add .` 
暂存所有修改，准备提交

`git commit -m "这里写点描述"`
将暂存区的更改打包成一个历史记录点，并附上一条描述。

`git push origin main`
推送更改

我设置了 SSH 密钥并启动了ssh-agent，Git 会自动使用我的私钥进行身份验证，不需要重复输入用户名或密码。

### git 如何指定添加编译某个 pr
其实是为了解决微信在 niri 环境下无法右键的问题，在 xwayland-satellite 项目下面发现了有人提交的 pr 可以解决该问题，因此需要指定该 pr 提交的代码编译进去

流程如下

1.安装编译依赖
`sudo pacman -S --needed rust cargo git`

2.克隆仓库
`git clone https://github.com/Supreeeme/xwayland-satellite.git`
`cd xwayland-satellite`

fix: popup position #281 这是 pr 的标题，后面是 pr 的编号 281

3.拉取并切换到 PR #281
从 GitHub 拉取 281 号 PR 的代码，并存到一个叫 pr-281 的新分支里 
`git fetch origin pull/281/head:pr-281`

切换到这个分支 
`git checkout pr-281`

4.编译
`cargo build --release`


5.替换并生效
备份旧的
`sudo mv /usr/bin/xwayland-satellite /usr/bin/xwayland-satellite.bak`
替换新的（注意路径是 target/release/）
`sudo cp target/release/xwayland-satellite /usr/bin/`
重启 Niri 生效
`niri msg action quit`
(或者直接重启电脑)












## KVM/QEMU虚拟机
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

### 嵌套虚拟化
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


### KVM显卡直通
前置的win11虚拟机安装，virtio-win驱动安装不再赘述
virtio-win驱动下载链接参考
https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.285-1/virtio-win-0.1.285.iso

1.确认iommu是否开启，有输出说明开启
`sudo dmesg | grep -e DMAR -e IOMMU`
现代设备通常都支持IOMMU且默认开启，BIOS里的选项通常为Intel VT-d、AMD-V或者IOMMU。如果没有的话搜索一下自己的cpu和主板型号看看是否支持。
![[_resources/linux笔记/0213e11d14c3c5017942db2882b877b0_MD5.jpg]]



2.获取显卡的硬件id，显卡所在group的所有设备的id都记下
```
for d in /sys/kernel/iommu_groups/*/devices/*; do 
    n=${d#*/iommu_groups/*}; n=${n%%/*}
    printf 'IOMMU Group %s ' "$n"
    lspci -nns "${d##*/}"
done
```

这里获得了我的显卡所在组和对应id
[[_resources/linux笔记/41c68fa8ab9ceef4adba6aa125d824f5_MD5.jpg|Open: Pasted image 20251213134113.png]]
![[_resources/linux笔记/41c68fa8ab9ceef4adba6aa125d824f5_MD5.jpg]]

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
这里重启后可以看到N卡已经被独立出去了，在win11虚拟机配置中，添加pci硬件设备，选择独立出的我的4060
[[_resources/linux笔记/62676cbb4a42c76b7f395b46c97e51ad_MD5.jpg|Open: Pasted image 20251213135843.png]]
![[_resources/linux笔记/62676cbb4a42c76b7f395b46c97e51ad_MD5.jpg]]

开机后装上n卡驱动，在设备管理器上可以看到n卡成功安装使用了
[[_resources/linux笔记/099e5e3183ec6f56a47ff67d14f8f207_MD5.jpg|Open: Pasted image 20251213143143.png]]
![[_resources/linux笔记/099e5e3183ec6f56a47ff67d14f8f207_MD5.jpg]]


### moonlight远程连接方案(不建议使用)
删除虚拟机的硬件的显示协议和QXL的显卡，然后添加鼠标和键盘，键盘随便拿了个外接键盘，鼠标就用我现在的雷柏，直通开机后，我直通进去的鼠标键盘就会被虚拟机独占了，所以我的笔记本可以使用自带键盘和触摸板
[[_resources/linux笔记/a5b461818005e59b7a9bd18f0bbef7cc_MD5.jpg|Open: Pasted image 20251213144357.png]]
![[_resources/linux笔记/a5b461818005e59b7a9bd18f0bbef7cc_MD5.jpg]]

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
在 Linux 系统中，为了满足不同程序之间**高速交换数据**的需求，同时避免频繁读写硬盘造成瓶颈，Linux 设计了一个特殊的机制—— `/dev/shm` 目录。
- **虚拟挂载，而非物理分割**： `/dev/shm` 挂载的 `tmpfs` 文件系统，并不像硬盘分区那样物理占用了内存的一半。它仅仅是向操作系统申请了一个 **“最高可用 50% 内存的记账额度”**。
    
- **动态分配机制**： 在 Looking Glass 没运行（或没写入文件）时，`/dev/shm` 占用的物理内存实际上是 **0**。这部分内存完全开放给系统其他软件使用。只有当文件真正写入时，内核才会从物理内存池中动态抓取空闲的内存页来存储数据。
    
- **设备本质**： `/dev/shm` 虽位于设备目录 `/dev` 下，但它不是物理设备文件，而是一个**内存对象**的接口。它让用户能像操作普通磁盘文件一样（打开、读写、关闭），直接操作分散在 RAM 中的内存页。

- **本质**：它的挂载点虽然像个磁盘目录，但其文件系统格式为 `tmpfs`，背后的物理存储介质完全是 **内存 (RAM)**。
    
- **约束**：为了防止临时文件无限制地占满物理内存导致死机，Linux 默认将此目录的大小限制为物理总内存的 **50%**。这是一种**安全限额**——用多少占多少，但绝不允许超过这个上限（一旦超过会直接报错，不会溢出到其他区域）。
    
- **特性**：由于内存断电即失的物理特性，这个目录下的文件在重启后会自动消失，非常适合存放无需永久保存的临时数据。

2.Systemd 临时文件管理 (systemd-tmpfiles)
Linux 系统中专门用于在开机时**自动创建、恢复或清理**那些“断电即失”（易失性）文件的标准化管理机制。

通过在/etc/tmpfiles.d/下书写配置文件（`.conf`）声明“我需要什么文件、什么权限”，系统开机时会自动帮你把这些文件“变”出来，无需人工干预或编写复杂脚本。

主要针对内存挂载目录（如 `/dev/shm`、`/run`、`/tmp`）下的文件。这些文件在重启后会消失，但应用程序（如 Looking Glass）启动时又必须依赖它们。




3.Looking Glass 的工作原理
实际上还要更复杂一些，涉及到内存映射等一系列技术，我这里只谈我作为使用者能直接接触到的

Looking Glass 利用了上述机制来实现“零延迟”的画面传输：

- **共享白板**：Looking Glass 在 `/dev/shm` 下创建了一个文件（也就是划定了一块内存区域）。这块区域成为了虚拟机（Host）和宿主机（Client）的**公共白板**。
    
- **流程**：
    
    1. 虚拟机内的显卡渲染好画面后，通过 IVSHMEM 驱动直接把画面数据“写”进这块内存。
        
    2. 宿主机的 Looking Glass 客户端直接从这块内存里“读”取数据并显示。
        
- **为什么用 `/dev/shm`**：
    
    - **极速**：读写内存的速度远超硬盘。
        
    - **共享**：它是极少数能让两个隔离的系统（Linux 和 Windows VM）同时访问的“虫洞”。
        
    - **自动清理**：配合 `systemd-tmpfiles` 和 `tmpfs` 的特性，保证了每次重启后环境的干净，不会留下垃圾文件。



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
- 设置spice协议
    确认有spice显示协议，显卡设置为none
    
- 键鼠传输
    添加virtio键盘和virtio鼠标（要在xml里面更改bus=“ps2”为bus=“virtio”）加上这个，外部鼠标键盘才能映射到虚拟机的串流画面上
    
    
- 剪贴板同步（可选）
    确认有spice信道设备，没有的话添加，设备类型为spice

- 声音传输
    确认有ich9声卡，点击概况，去到xml底部，在里面找到下面这段，确认type为spice，不是的话自己手动改
`<audio id='1' type='spice'/>`
配置结束大概是这样
[[_resources/linux笔记/52a72e57902a24011dcd312b0bdf4e83_MD5.jpg|Open: Pasted image 20251214003246.png]]
![[_resources/linux笔记/52a72e57902a24011dcd312b0bdf4e83_MD5.jpg]]


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

# ================= 配置区域 =================
# 显卡 ID
VFIO_IDS="10de:28e0,10de:22be"
# 文件路径
MKINIT_CONF="/etc/mkinitcpio.conf"
VFIO_CONF="/etc/modprobe.d/vfio.conf"
# ===========================================

# 颜色定义
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

# 1. 权限检查
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}[错误] 请加上 sudo 执行此命令！${NC}"
  exit 1
fi

echo -e "${BLUE}###############################################${NC}"
echo -e "${BLUE}#      华硕天选4 显卡归属权切换工具           #${NC}"
echo -e "${BLUE}###############################################${NC}"

# 2. 检测当前状态
if grep -q "vfio_pci" "$MKINIT_CONF"; then
    CURRENT_STATE="VM"
    TARGET_STATE="HOST"
    CURRENT_DESC="${YELLOW}虚拟机独占 (直通模式)${NC}"
    TARGET_DESC="${GREEN}宿主机本机 (普通模式)${NC}"
    ACTION_MSG="即将执行：释放显卡，归还给 Arch Linux 使用"
else
    CURRENT_STATE="HOST"
    TARGET_STATE="VM"
    CURRENT_DESC="${GREEN}宿主机本机 (普通模式)${NC}"
    TARGET_DESC="${YELLOW}虚拟机独占 (直通模式)${NC}"
    ACTION_MSG="即将执行：隔离显卡，准备给 Windows 虚拟机使用"
fi

# 3. 信息展示与防呆确认
echo -e "当前状态: [ $CURRENT_DESC ]"
echo -e "目标状态: [ $TARGET_DESC ]"
echo "-----------------------------------------------"
echo -e "${BLUE}$ACTION_MSG${NC}"
echo "-----------------------------------------------"

read -p "请确认是否执行上述切换？(输入 y 确认): " CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
    echo -e "${RED}操作已取消。${NC}"
    exit 0
fi

# 4. 执行配置文件修改
echo -e "\n${BLUE}正在修改配置文件...${NC}"

if [ "$TARGET_STATE" == "HOST" ]; then
    # === 切换到 宿主机模式 ===
    truncate -s 0 "$VFIO_CONF"
    echo "  -> [OK] 已清空 VFIO 配置"
    
    # 强制重置为 amdgpu，防止黑屏
    sed -i 's/^MODULES=(.*)/MODULES=(amdgpu)/' "$MKINIT_CONF"
    echo "  -> [OK] 已将 MODULES 重置为 (amdgpu)"

else
    # === 切换到 虚拟机模式 ===
    echo "options vfio-pci ids=$VFIO_IDS" > "$VFIO_CONF"
    echo "softdep nvidia pre: vfio-pci" >> "$VFIO_CONF"
    echo "softdep nouveau pre: vfio-pci" >> "$VFIO_CONF"
    echo "  -> [OK] 已写入 VFIO ID 配置"

    sed -i 's/^MODULES=(.*)/MODULES=(vfio_pci vfio vfio_iommu_type1 amdgpu)/' "$MKINIT_CONF"
    echo "  -> [OK] 已添加 VFIO 相关驱动模块"
fi

# 5. 重新构建镜像 
echo "-----------------------------------------------"
echo -e "${YELLOW}正在调用 mkinitcpio 重新生成引导镜像...${NC}"
echo -e "请耐心等待 build successful"
echo "-----------------------------------------------"

mkinitcpio -P

# 检查上一条命令的退出代码
if [ $? -eq 0 ]; then
    echo "-----------------------------------------------"
    echo -e "${GREEN}✔ 切换成功！构建顺利完成。${NC}"
    echo -e "请执行: ${BLUE}reboot${NC} 重启电脑生效。"
else
    echo "-----------------------------------------------"
    echo -e "${RED}❌ 构建过程中出现错误！${NC}"
    echo "请向上滚动查看 mkinitcpio 的错误日志。"
    exit 1
fi
```


### KVM虚拟机性能优化和伪装
从这里开始的配置就在克隆系统中进行
#### 禁用memballoon
[libvirt/QEMU Installation — Looking Glass B7 documentation](https://looking-glass.io/docs/B7/install_libvirt/#memballoon)

memlbaloon的目的是提高内存的利用率，但是由于它会不停地“取走”和“归还”虚拟机内存，导致显卡 直通时虚拟机内存性能极差。

将虚拟机xml里面的memballoon改为none，这将显著提高low帧。

```
<memballoon model="none"/>
```







### 共享存储
首先确认启用了内存共享(Virtio-FS 强依赖共享内存)
添加文件系统类型的硬件
[[_resources/linux笔记/3c515fd8863a183782d1c8f03217cd43_MD5.jpg|Open: Pasted image 20251217225758.png]]
![[_resources/linux笔记/3c515fd8863a183782d1c8f03217cd43_MD5.jpg]]
就是这样，然后进入虚拟机内部，安装winfsp驱动，在github的项目地址下面找，后缀名msi，安装成功后，打开windows的服务管理，启动Virtio-FS Service服务，默认是手动启动的，但也可以设置自动启动，不过感觉有点小风险？启动成功后可以找到一个独立的盘，盘名就是设置的目标路径












# 12/13
## grub设置链式引导
有些系统并不希望使用grub引导，比如pop!os有自己的system76引导，所以这时就需要链式引导来让这些系统使用自己的引导程序
参考如下内容
```
❯ cat /etc/grub.d/40_custom
#!/bin/sh
exec tail -n +3 $0
# This file provides an easy way to add custom menu entries.  Simply type the
# menu entries you want to add after this comment.  Be careful not to change
# the 'exec tail' line above.

menuentry 'Pop!_OS(Chainload)' {
    insmod part_gpt
    insmod fat
    insmod chain
    # 搜索 EFI 分区
    search --no-floppy --fs-uuid --set=root 9D1D-A9D4
    # 移交控制权给另一个系统的Shim 引导程序
    chainloader /EFI/BOOT/BOOTX64.EFI
}
```

释义
声明菜单名 (`menuentry`)，这就是grub菜单里显示的名字
`insmod` = Insert Module (插入模块)。
`part_gpt`: 告诉 GRUB 怎么读 GPT 分区表
`fat`: 告诉 GRUB 怎么读 FAT32 文件系统

定位分区
`search --no-floppy --fs-uuid --set=root 9D1D-A9D4`
这句话像是在对 GRUB 喊话：“**全盘搜索！**”
`--no-floppy`: 别搜软驱（节省时间）
`--fs-uuid`: 我是用 UUID 来找的，不是用分区号（因为分区号 `/dev/sda1` 可能会变，UUID 永远不变）
`--set=root`: 找到后，把这个分区设为当前的根目录 (root)
9D1D-A9D4 EFI分区的UUID

指定引导文件
`chainloader /EFI/BOOT/BOOTX64.EFI`
`chainloader`: 意思是我不直接引导内核了，我把控制权“移交”给另一个 `.efi` 文件。
`/EFI/BOOT/BOOTX64.EFI`
是 UEFI 的“默认回退路径”，如果一块硬盘或者 U 盘插上去，主板不知道该读哪个文件夹，主板就会**默认**去读这个文件。它是所有无主系统的“收容所”，但实在找不到系统对应的引导时，就可以使用这个路径，不过多数系统是有具体路径的，比如fedora的是/EFI/fedora/shimx64.efi

# 12/15
## 蓝牙耳机有电流声
**环境：** Arch Linux + Niri (Wayland) + PipeWire + 蓝牙耳机 (漫步者 W820NB, 编码器:SBC)。
**现象：** 播放音频时，偶尔会出现剧烈的“电击式”爆音或断流。
**根本原因：** 音频缓冲区耗尽

解决方案：
`pw-metadata -n settings 0 clock.force-quantum 2048`
临时扩充缓冲区

为了永久生效，我配置了systemd服务
`systemctl --user edit --force --full force-quantum.service`
写入如下内容
```
[Unit]
Description=Force PipeWire Quantum to 2048 for Bluetooth stability
After=pipewire.service wireplumber.service

[Service]
Type=oneshot
# 等待几秒确保 PipeWire 完全启动后再执行，防止命令跑太快失效
ExecStartPre=/usr/bin/sleep 5
ExecStart=/usr/bin/pw-metadata -n settings 0 clock.force-quantum 2048
RemainAfterExit=yes

[Install]
WantedBy=default.target
```

立刻启用
`systemctl --user enable --now force-quantum.service`

如何验证？
`pw-top`命令查看
[[_resources/linux笔记/fac656bba474cf4bdd53348fe1d1c242_MD5.jpg|Open: Pasted image 20251215220719.png]]
![[_resources/linux笔记/fac656bba474cf4bdd53348fe1d1c242_MD5.jpg]]
bluez_output那一行是我的蓝牙耳机输出，从256变成了2048

这个方案是用声音延迟的代价换取稳定
原理我也不太懂得，不过差不多可以这样理解
`时间窗口=QUANT/48000Hz=xx.ms`
我原本的QUANT是256，带入公式得到时间窗口大概是5.33ms(毫秒)
意思是CPU必须每隔5.33毫秒就处理完一次音频数据，但是如果 Niri 渲染一帧画面抢占了 CPU 6 毫秒，音频线程就会错过截止时间。从而导致电流声等问题
**新的时间窗口：** 2048/48000Hz​≈42.66ms
**容错率提升:** 从 5ms 提升到 42ms（约 8 倍）。即使 Niri 发生丢帧或高负载卡顿，音频缓冲区里仍有足够的数据存货，不会断流。
**代价:** 系统音频延迟增加约 37ms。对于视频（播放器会自动补偿）和非竞技类游戏，此延迟在人类感知阈值（<100ms）内，属于无感牺牲。

不过我觉得最好还是买个有线耳机












# 12/21
## 信创适配及安全管理
### 任务一
主机清单
serverA 192.168.122.10
server1 192.168.122.11
server2 192.168.122.12

#### 1.配置DNS主服务器server1
1)安装软件
`[root@server1 ~]# yum -y install bind bind-utils`

2).配置主配置文件 /etc/named.conf 修改监听地址和允许查询范围
`vim /etc/named.conf`
修改后面有注释的行
```
listen-on port 53 { any; }; //监听所有ip
listen-on-v6 port 53 { ::1; };
directory       "/var/named";
dump-file       "/var/named/data/cache_dump.db";
statistics-file "/var/named/data/named_stats.txt";
memstatistics-file "/var/named/data/named_mem_stats.txt";
secroots-file   "/var/named/data/named.secroots";
recursing-file  "/var/named/data/named.recursing";
allow-query     { any; }; //允许任何人查询
allow-transfer  { 192.168.122.12; }; //仅允许Server2同步区域
```
然后在文件尾部写入如下内容
```
//定义正向区域
zone "system.org.cn" IN {
        type master;
        file "db.system.org.cn";
};

//定义反向区域(172.16.50.x网段反着写)
zone "50.16.172.in-addr.arpa" IN {
        type master;
        file "db.50.16.172";
};
```

(2) 编写正向解析文件
复制模板
`cp -p /var/named/named.localhost /var/named/db.system.org.cn`

`vim /var/named/db.system.org.cn`
修改为如下内容
```
$TTL 1D
@       IN SOA  system.org.cn. root.system.org.cn. (
                                        1       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        NS      ns1.system.org.cn.      ;指定本域名的域名服务器
        NS      ns2.system.org.cn.      
ns1     A       192.168.122.11          ;必须告诉别人ns1在哪
ns2     A       192.168.122.12          ;必须告诉别人ns1在哪
app1    A       172.16.50.101
app2    A       172.16.50.102
sts     A       172.16.50.103
```

(3) 编写反向解析文件
复制模板
`cp -p /var/named/db.system.org.cn /var/named/db.50.16.172`
编辑文件
`vim /var/named/db.50.16.172`
写入如下内容
```
$TTL 1D
@       IN SOA  system.org.cn. root.system.org.cn. (
                                        1       ; serial
                                        1D      ; refresh
                                        1H      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        NS      ns1.system.org.cn.      
        NS      ns2.system.org.cn.
101     PTR     app1.system.org.cn.
102     PTR     app2.system.org.cn.
103     PTR     sts.system.org.cn.
```


4)最后验证
`systemctl start named`启动
`systemctl status named`检查服务状态是否正常运行

检查防火墙，放通DNS
`firewall-cmd --add-service=dns --permanent`
`firewall-cmd --reload`

本地测试解析
`nslookup app1.system.org.cn 192.168.122.11`
预期输出：Address: 172.16.50.101
`nslookup 172.16.50.101 192.168.122.11`
预期输出：name = app1.system.org.cn

参考结果
[[_resources/linux笔记/31a77f7a80364c9a32c63641f05924c1_MD5.jpg|Open: Pasted image 20251221155725.png]]
![[_resources/linux笔记/31a77f7a80364c9a32c63641f05924c1_MD5.jpg]]




#### 2.配置 Server2（从 DNS 服务器）
Server2 不需要自己写正反向解析文件（也就是不用 cp 和 vim `db.xxx` 文件），它的任务是告诉系统“我是秘书，我要找 Server1 (192.168.122.11) 下载数据

1)安装软件
`[root@server2 ~]# yum install -y bind bind-utils`

2)修改主配置文件 /etc/named.conf
vim /etc/named.conf
修改内容如下
```
listen-on port 53 { any; }; //监听所有地址
        listen-on-v6 port 53 { ::1; };
        directory       "/var/named";
        dump-file       "/var/named/data/cache_dump.db";
        statistics-file "/var/named/data/named_stats.txt";
        memstatistics-file "/var/named/data/named_mem_stats.txt";
        secroots-file   "/var/named/data/named.secroots";
        recursing-file  "/var/named/data/named.recursing";
        allow-query     { any; }; //允许任何人查询
```
修改注释的行
然后同样在文件底部写入如下内容
```
//定义正向区域(从)
zone "system.org.cn" IN {
        type slave;
        masters { 192.168.122.11; };
        file "slaves/db.system.org.cn"; //数据下载到slaves/ 目录下
};

//定义反向区域(从)
zone "50.16.172.in-addr.arpa" IN {
        type slave;
        masters { 192.168.122.11; };
        file "slaves/db.50.16.172";
};
```

3)启动服务并验证同步
放通防火墙
`firewall-cmd --add-service=dns --permanent`
`firewall-cmd --reload`
启动服务
`systemctl enable --now named`
查看是否同步成功,如果看到 db.system.org.cn 和 db.50.16.172 出现，说明验证通过
`ls -l /var/named/slaves/`



#### 3.配置ServerA(CA中心与证书颁发)
配置DNS服务器
`[root@serverA ~]# vim /etc/resolv.conf`
写入如下内容
```
nameserver 192.168.122.11
nameserver 192.168.122.12
```
测试DNS解析
`[root@serverA demoCA]# ping app1.system.org.cn`
能解析到**172.16.50.101**的ip就是成功，ping不通是正常的，因为地址不存在

1).搭建 CA 基础环境
建立目录结构（系统 OpenSSL 默认依赖这些目录）
`mkdir -p /etc/pki/tls/demoCA/{private,newcerts,certs,crl}`
`touch /etc/pki/tls/demoCA/index.txt`
`echo 01 > /etc/pki/tls/demoCA/serial`

生成 CA 根私钥（8192位）
`cd /etc/pki/tls/demoCA`
`openssl genrsa -out private/cakey.pem 8192`

生成 CA 根证书（有效期10年，CN=ca-rsa.system.org.cn）
`openssl req -new -x509 -key private/cakey.pem -out cacert.pem -days 3650 -subj "/CN=ca-rsa.system.org.cn"`


2)制作服务器证书申请 (CSR)
现在模拟为所有 Server 主机申请身份证。

生成服务器私钥（4096位）
`openssl genrsa -out server-rsa.key 4096`

生成申请表 (CSR)
题目要求极其详细的信息，这里用 -subj 一次性填好，防止手输错误

3)准备 SAN 扩展文件
因为题目要求证书支持 `*.system.org.cn`，这属于扩展属性，必须通过外部文件加载。
创建一个配置文件 v3.ext
```
cat > v3.ext <<EOF
authorityKeyIdentifier=keyid,issuer 
basicConstraints=CA:FALSE 
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment 
subjectAltName = @alt_names 
[alt_names] 
DNS.1 = *.system.org.cn 
DNS.2 = system.org.cn 
EOF
```

4)签发证书
使用 CA 的权利，批准申请，并加上扩展属性。
首先切换路径到上一级，然后执行签发命令（有效期5年 = 1825天）
`[root@serverA demoCA]# cd ..`
`[root@serverA tls]# openssl ca -policy policy_anything -in demoCA/server-rsa.csr -out demoCA/server-rsa.pem -days 1825 -keyfile demoCA/private/cakey.pem -cert demoCA/cacert.pem -extfile demoCA/v3.ext`
中途会有两个交互过程
Sign the certificate? [y/n]和1 out of 1 certificate requests certified, commit? [y/n]
全部输入y回车即可


#### 4.证书分发
题目要求所有 Server 的 `/etc/ssl` 目录下都要有这张证书。
在ServerA上操作
回到demoCA目录下
`[root@serverA tls]# cd demoCA/`
1)复制给自己
`cp server-rsa.pem server-rsa.key /etc/ssl/`

2)复制给 Server1 (192.168.122.11)
`scp server-rsa.pem server-rsa.key root@192.168.122.11:/etc/ssl/`

3)复制给 Server2 (192.168.122.12)
`scp server-rsa.pem server-rsa.key root@192.168.122.12:/etc/ssl/`


#### 验证全流程
**验证 DNS 同步**：在 Server2 上能看到 `/var/named/slaves` 下有文件。
**验证 DNS 解析**：`nslookup app1.system.org.cn 192.168.122.12` 能解析出 IP。
**验证证书内容**： 在任意一台机器执行：
`openssl x509 -in /etc/ssl/server-rsa.pem -noout -text | grep DNS`
**成功标志**：输出中包含 `DNS:*.system.org.cn, DNS:system.org.cn`




### 任务二
刷新软件源并更新软件
`apt update`
`apt upgrade`

为Python 3 环境安装GUI 开发库和包管理工具
`apt install python3-pyqt5 python3-pip`

书写代码
`vim vim calculator.py`
写入如下内容
```
import sys
# 1. 导入必要的 PyQt5 模块
from PyQt5.QtWidgets import QApplication, QWidget, QGridLayout, QLineEdit, QPushButton, QMessageBox
from PyQt5.QtGui import QFont

class SimpleCalculator(QWidget):
    def __init__(self):
        super().__init__()
        self.current_expr = "" # 存储当前的数学表达式字符串
        self.initUI()

    def initUI(self):
        # 【适配点1】窗口标题修改
        self.setWindowTitle("简易计算器（麒麟版）")
        
        # 【适配点2】调整窗口大小和字体
        # 麒麟系统在高分屏下可能显示过小，适当调大尺寸
        self.setGeometry(300, 300, 400, 500) 
        
        # 创建网格布局
        grid = QGridLayout()
        self.setLayout(grid)

        # 显示框（只读）
        self.display = QLineEdit()
        self.display.setReadOnly(True)
        # 【适配点3】CSS样式调整：加大字号以防麒麟系统下模糊
        self.display.setStyleSheet("font-size: 24px; height: 50px; border: 1px solid gray;")
        # 将显示框放在第0行，横跨4列
        grid.addWidget(self.display, 0, 0, 1, 4)

        # 定义按钮标签列表
        # 注意：这里使用了中文全角的符号，因为题目要求显示 × ÷
        names = ['7', '8', '9', '÷',
                 '4', '5', '6', '×',
                 '1', '2', '3', '－',
                 'C', '0', '=', '+']

        # 位置计数器
        positions = [(i, j) for i in range(1, 5) for j in range(4)]
        
        # 循环创建按钮
        for position, name in zip(positions, names):
            button = QPushButton(name)
            # 【适配点4】调整按钮字体大小
            button.setFont(QFont("SansSerif", 14))
            # 绑定点击事件：把按钮上的字传给 on_click 函数
            button.clicked.connect(lambda ch, text=name: self.on_click(text))
            grid.addWidget(button, *position)

    def on_click(self, text):
        # 逻辑：清空
        if text == 'C':
            self.current_expr = ""
        
        # 逻辑：计算结果
        elif text == '=':
            try:
                # 【适配点5】符号转换（核心考点）
                # Python 不认识 × ÷ －，必须换成 * / -
                # 题目原文是全角 '－'，也要替换成半角 '-'
                temp_expr = self.current_expr.replace('×', '*').replace('÷', '/').replace('－', '-')
                
                # eval() 是 Python 内置的计算函数，把字符串当代码跑
                # str() 把计算结果（数字）转回字符串
                result = str(eval(temp_expr))
                self.current_expr = result
            
            except ZeroDivisionError:
                self.current_expr = "错误" # 题目要求显示“错误”
            except Exception as e:
                self.current_expr = "错误"
        
        # 逻辑：普通输入
        else:
            # 如果当前已经显示“错误”，再按数字时应该重置
            if self.current_expr == "错误":
                self.current_expr = ""
            self.current_expr += text

        # 最后更新界面显示
        self.display.setText(self.current_expr)

if __name__ == '__main__':
    # 【适配点6】高 DPI 适配（可选，加分项）
    # 在 4K 屏的麒麟机器上，不加这行界面会很小
    QApplication.setAttribute(Qt.AA_EnableHighDpiScaling) if 'Qt' in globals() else None
    
    app = QApplication(sys.argv)
    calc = SimpleCalculator()
    calc.show()
    # 【适配点7】确保正常退出
    sys.exit(app.exec_())
```



依赖安装差异说明
1.**包管理工具与安装源不同**：
     **Windows**：通常直接使用 Python 自带的 `pip` 工具在线安装（命令：`pip install PyQt5`），依赖于 PyPI 官方源。
    **银河麒麟 (Linux)**：推荐使用系统级包管理器 `apt` 安装（命令：`sudo apt install python3-pyqt5`）。这是因为麒麟 V10 运行在鲲鹏（ARM64）架构上，`apt` 源提供了经过官方编译和适配的二进制包，能完美解决 PyQt5 底层 C++ 库与系统库的**兼容性冲突**，而使用 `pip` 编译安装极易失败。
2.**软件包名称不同**：
	**Windows (pip)**：包名为 `PyQt5`。
    **银河麒麟 (apt)**：包名为 `python3-pyqt5`（明确指定了 Python 3 版本）。
        
3.**权限要求不同**：
	**Windows**：通常默认用户权限即可安装到用户目录，或使用管理员运行 CMD。
	**银河麒麟**：使用 `apt` 安装属于系统级变更，必须使用 `sudo` 提权并输入 root 密码才能执行。




### 任务三
#### 1.安装JDK
1.在 x86 麒麟上，我们用 OpenJDK 11 代替毕昇 JDK 11。
`sudo apt update` 
`sudo apt install openjdk-11-jdk -y`
验证
`java -version`

#### 2.安装达梦数据库 DM8
1）官网下载达梦开发版x86，系统麒麟10,sp3
下载后解压，传到虚拟机/root下
`scp Downloads/dm8_20251203_x86_kylin10_sp3_64/dm8_20251203_x86_kylin10_sp3_64.iso root@192.168.122.132:/root/`

2）新建 dmdba 用户
安装前必须创建 dmdba 用户，禁止使用 root 用户安装数据库。
创建用户所在的组
`groupadd dinstall -g 2001`
创建用户
`useradd  -G dinstall -m -d /home/dmdba -s /bin/bash -u 2001 dmdba`
修改用户密码
`passwd dmdba`

3）修改文件打开最大数
在 Linux、Solaris、AIX 和 HP-UNIX 等系统中，操作系统默认会对程序使用资源进行限制。如果不取消对应的限制，则数据库的性能将会受到影响。
永久修改和临时修改。
重启服务器后永久生效。
使用 root 用户打开 `/etc/security/limits.conf` 文件进行修改
`vi /etc/security/limits.conf`
在文件末尾写入如下内容
```plaintext
dmdba  soft      nice       0
dmdba  hard      nice       0
dmdba  soft      as         unlimited
dmdba  hard      as         unlimited
dmdba  soft      fsize      unlimited
dmdba  hard      fsize      unlimited
dmdba  soft      nproc      65536
dmdba  hard      nproc      65536
dmdba  soft      nofile     65536
dmdba  hard      nofile     65536
dmdba  soft      core       unlimited
dmdba  hard      core       unlimited
dmdba  soft      data       unlimited
dmdba  hard      data       unlimited
```

重启后生效
切换到 dmdba 用户，查看是否生效
`su - dmdba`
`ulimit -a`
[[_resources/linux笔记/e7ebc0bdc9a2590df34e9813ce92b481_MD5.jpg|Open: Pasted image 20251223114145.png]]
![[_resources/linux笔记/e7ebc0bdc9a2590df34e9813ce92b481_MD5.jpg]]
看到标红的选项可以看到配置已经生效

设置参数临时生效（可选）
可使用 dmdba 用户执行如下命令，使设置临时生效
`ulimit -n 65536`
`ulimit -u 65536`


4）目录规划
可根据实际需求规划安装目录，本示例使用默认配置 DM 数据库安装在 /home/dmdba 文件夹下

规划创建实例保存目录、归档保存目录、备份保存目录
使用 root 用户建立文件夹，待 dmdba 用户建立完成后需将文件所有者更改为 dmdba 用户，否则无法安装到该目录下
```shell
#创建实例保存目录，归档保存目录，备份保存目录
mkdir -p /dmdata/{data,arch,dmbak}
```
修改目录权限
将新建的路径目录权限的用户修改为 dmdba，用户组修改为 dinstall
`chown -R dmdba:dinstall /dmdata/`
`chown -R 755 /dmdata/`


5)数据库安装
挂载镜像
`mount -o loop dm8_20251203_x86_kylin10_sp3_64.iso /mnt/`
命令行安装
`su - dmdba`
`cd /mnt/`
先进麒麟的安全中心，把相关的能关的东西都关了，不然会报各种权限问题的错
然后在/mnt目录下执行安装脚本
`./DMInstall.bin -i`
根据提示安装
是否输入Key文件路径? (Y/y:是 N/n:否) [Y/y]:选择n
安装完成后根据提示切换至root用户执行脚本
`bash /home/dmdba/dmdbms/script/root/root_installer.sh` 
该脚本用于创建 DmAPService，否则会影响数据库备份


图形化安装(可选)
没弄快照，下次再搞



6)配置实例
命令行方式初始化实例
使用 dmdba 用户配置实例，进入到 DM 数据库安装目录下的 bin 目录中
`./dminit path=/dmdata/data PAGE_SIZE=32 EXTENT_SIZE=32 CASE_SENSITIVE=y CHARSET=1 DB_NAME=finance_db INSTANCE_NAME=DBSERVER PORT_NUM=5237 SYSDBA_PWD=Dameng123 SYSAUDITOR_PWD=Dameng123`
释义
```
PAGE_SIZE=32  //设置页大小为32
EXTENT_SIZE=32 //设置簇大小为32kb
CASE_SENSITIVE=y //大小写敏感
CHARSET=1 //设置字符集为 utf_8
DB_NAME=finance_db //数据库名为finance_db
INSTANCE_NAME=DBSERVER //实例名为 DBSERVER
PORT_NUM=5237 //端口为5237
SYSDBA_PWD=Dameng123 
SYSAUDITOR_PWD=Dameng123
SYSDBA_PWD 和 SYSAUDITOR_PWD 为配置数据库 SYSDBA 用户和 SYSAUDITOR 用户的登录密码，需要用户自定义配置，且需保证一定的密码强度。
```


图形化初始化实例(可选)
没设置快照，下次再搞


7）命令行注册服务
是基于systemd做的自动化启动数据库的服务，也可以手动启动测试一下
使用dmdba用户
`su - dmdba`
`cd /home/dmdba/dmdbms/bin`
手动启动数据库
`./dmserver /dmdata/data/finance_db/dm.ini`
这里会出现大量日志信息，可添加-noconsole选项将日志信息重定向到log日志文件中
再开一个终端连接dmdba用户
`cd /home/dmdba/dmdbms/bin`
测试连接数据库
`./disql SYSDBA/Dameng123@localhost:5237`


注册服务自动化
DM 提供了将 DM 服务脚本注册成操作系统服务的脚本，同时也提供了卸载操作系统服务的脚本。注册和卸载脚本文件所在目录为安装目录的“/script/root”子目录下。
注册服务脚本为 dm_service_installer.sh，用户可以使用注册服务脚本将服务脚本注册成为操作系统服务。注册服务需使用 root 用户进行注册，使用 root 用户进入数据库安装目录的 `/script/root` 下，如下所示：
`cd /home/dmdba/dmdbms/script/root/`
注册服务
`./dm_service_installer.sh -t dmserver -dm_ini /dmdata/data/finance_db/dm.ini -p DBSERVER`
启动服务
`systemctl start DmServiceDBSERVER.service`
检查服务运行状态
`systemctl status DmServiceDBSERVER`


8）创建表并插入数据
还是在~/dmdbms/bin目录下使用dmdba用户操作
连接数据库
`./disql SYSDBA/Dameng123@localhost:5237`
```shell
#创建一个独立的表空间
CREATE TABLESPACE finance_tbs DATAFILE 'finance.dbf' SIZE 128;
#创建用户（用户名 finance_user，密码 Finance@123）
CREATE USER finance_user IDENTIFIED BY "Finance@123" DEFAULT TABLESPACE finance_tbs;
#授权
GRANT RESOURCE, PUBLIC TO finance_user;
#切换到新用户（密码中间的@会被当作特殊字符处理，要加双引号）
CONN finance_user/"Finance@123"@localhost:5237;
#建表
CREATE TABLE account ( 
account_id VARCHAR(20) PRIMARY KEY, 
balance DECIMAL(15, 2) 
);
#塞点测试数据
INSERT INTO account VALUES('ACC001', 5000.00); 
INSERT INTO account VALUES('ACC002', 1000.00); 
COMMIT;
#验证
SELECT * FROM account;
```


9)配置达梦 JDBC 驱动
使用dmdba用户操作
`cd ~`
创建工作目录
`mkdir -pv work;cd work/`
复制驱动(这里的11对应java的版本)
`cp ~/dmdbms/drivers/jdbc/DmJdbcDriver11.jar .`

`vim SimpleAccountTool.java`
写入代码内容如下
```java
import java.sql.*;
import java.util.Scanner;

public class SimpleAccountTool {
    
    //修改区域开始
    // 1. 修改 URL: 端口改为 5237，指定 schema 防止找不到表
    private static final String URL = "jdbc:dm://localhost:5237?schema=FINANCE_USER";
    
    // 2. 修改用户名: 我们刚才建的 finance_user
    private static final String USER = "finance_user";
    
    // 3. 修改密码: 我们刚才设的 Finance@123
    private static final String PASSWORD = "Finance@123";
    //修改区域结束

    public static void main(String[] args) {
        Scanner scanner = new Scanner(System.in);
        try {
            // 4. 【关键】加载达梦驱动
            Class.forName("dm.jdbc.driver.DmDriver"); 
            
            while(true) {
                System.out.println("\n1. 查询余额  2. 转账  3. 退出");
                System.out.print("请选择功能：");
                String choice = scanner.next();

                if ("1".equals(choice)) {
                    // 补全：查询逻辑
                    System.out.print("请输入账号ID: ");
                    String acc = scanner.next();
                    queryBalance(acc);
                } else if ("2".equals(choice)) {
                    // 补全：转账逻辑
                    System.out.print("转出账号: ");
                    String from = scanner.next();
                    System.out.print("转入账号: ");
                    String to = scanner.next();
                    System.out.print("金额: ");
                    double amt = scanner.nextDouble();
                    transfer(from, to, amt);
                } else if ("3".equals(choice)) {
                    break;
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
    }

    // 查询余额 (样题逻辑修复)
    private static void queryBalance(String account) throws SQLException {
        try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD)) {
            String sql = "SELECT balance FROM account WHERE account_id = ?";
            PreparedStatement ps = conn.prepareStatement(sql);
            ps.setString(1, account);
            ResultSet rs = ps.executeQuery();
            if (rs.next()) {
                System.out.println("账号 " + account + " 余额：" + rs.getDouble("balance"));
            } else {
                System.out.println("账号不存在");
            }
        }
    }

    // 转账并记录日志 (样题被截断了，这里补全了核心事务逻辑)
    private static void transfer(String from, String to, double amount) {
        Connection conn = null;
        try {
            conn = DriverManager.getConnection(URL, USER, PASSWORD);
            conn.setAutoCommit(false); // 开启事务

            // 1. 检查余额 (调用下方补全的 getBalance)
            double fromBalance = getBalance(conn, from);
            if (fromBalance < amount) {
                System.out.println("余额不足，转账失败！");
                return;
            }

            // 2. 扣钱
            updateBalance(conn, from, -amount);
            
            // 3. 加钱
            updateBalance(conn, to, amount);

            // 4. 提交事务
            conn.commit();
            System.out.println("转账成功！");

	   //5.记录日志
	   log(from, to, amount);
            
        } catch (Exception e) {
            try { if (conn != null) conn.rollback(); } catch (SQLException ex) {}
            e.printStackTrace();
        } finally {
            try { if (conn != null) conn.close(); } catch (SQLException ex) {}
        }
    }

    // 辅助方法：更新余额 (样题里完全没有，必须补上，否则转账没法写)
    private static void updateBalance(Connection conn, String acc, double amt) throws SQLException {
        String sql = "UPDATE account SET balance = balance + ? WHERE account_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setDouble(1, amt);
        ps.setString(2, acc);
        ps.executeUpdate();
    }

    // 辅助方法：获取余额 (样题里只有尾巴，这里补全了头)
    private static double getBalance(Connection conn, String account) throws SQLException {
        String sql = "SELECT balance FROM account WHERE account_id = ?";
        PreparedStatement ps = conn.prepareStatement(sql);
        ps.setString(1, account);
        ResultSet rs = ps.executeQuery();
        return rs.next() ? rs.getDouble("balance") : 0;
    }

    // 记录交易日志 (必须叫 finance_log.txt)
    private static void log(String from, String to, double amount) {
        // 使用 try-with-resources 自动关闭文件流
        // FileWriter 的第二个参数 true 表示“追加模式”，不会覆盖旧日志
        try (java.io.FileWriter fw = new java.io.FileWriter("finance_log.txt", true)) {
            // 获取当前时间
            java.time.LocalDateTime now = java.time.LocalDateTime.now();
            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

            // 拼接日志内容：时间 转账：账号A->账号B，金额：XXX
            String logContent = now.format(formatter) + " 转账：" + from + "→" + to + "，金额：" + String.format("%.2f", amount) + "\n";

            fw.write(logContent);
        } catch (java.io.IOException e) {
            System.err.println("日志写入失败：" + e.getMessage());
        }
    }
}
```

编译代码
`javac -encoding utf-8 -cp .:DmJdbcDriver11.jar SimpleAccountTool.java`
运行代码
`java -cp .:DmJdbcDriver11.jar SimpleAccountTool`
测试代码
[[_resources/linux笔记/417aba15e5e0031072ae311e3e8ea945_MD5.jpg|Open: Pasted image 20251223154228.png]]
![[_resources/linux笔记/417aba15e5e0031072ae311e3e8ea945_MD5.jpg]]
注意修改日志finance_log.txt权限为题目要求的600





### 任务四
#### 第一部分：网络内核参数加固
这是为了防止网络攻击（DoS、ICMP攻击）

编辑文件
`vim /etc/sysctl.conf`
写入如下内容（但实际上除了最后一项配置，其他早就写好了）
```conf
#禁止发送IPV4重定向报文
net.ipv4.conf.all.send_redirects=0
net.ipv4.conf.default.send_redirects=0

#禁止接受ICMP重定向报文
net.ipv4.conf.all.accept_redirects=0
net.ipv4.conf.default.accept_redirects=0

#禁止对ping的广播响应
net.ipv4.icmp_echo_ignore_broadcasts=1

#打开SYN泛滥保护(防DOS)
net.ipv4.tcp_syncookies=1

#启用日志记录异常的IP地址报文
net.ipv4.conf.all.log_martians=1
net.ipv4.conf.default.log_martians=1
```

生效配置
`sysctl -p`

#### 第二部分：系统访问控制
目标：禁重启、设置 umask、单用户保护

**禁止 Ctrl+Alt+Del 重启(Systemd 方式)**:
默认情况下，`/usr/lib/systemd/system/ctrl-alt-del.target` 是一个软链接,它指向reboot.target
因此需要使用systemctl mask让这个文件指向一个空设备文件/dev/null，但systemctl mask并不会轻易覆盖链接文件，那么就需要删除原先的链接文件然后重新创建
`rm -f /etc/systemd/system/ctrl-alt-del.target`
`systemctl mask ctrl-alt-del.target`
测试
进入多用户模式
init 3 
按下ctrl alt del快捷键，默认是在命令行界面会自动重启，在设置后则不会重启



**设置默认 umask 为 0077**
编辑配置文件
`vim /etc/profile`
在文件底部写入如下内容
`umask 0077`
生效配置
`source /etc/profile`


**设置安全单用户模式**
防止有人物理接触服务器后直接进 Root
[[_resources/linux笔记/2682450dd30c44dcac1ed4eb255dcb5c_MD5.jpg|Open: Pasted image 20251223170557.png]]
![[_resources/linux笔记/2682450dd30c44dcac1ed4eb255dcb5c_MD5.jpg]]
貌似麒麟server_v10版默认就是安全单用户模式，用上图命令测试




#### 第三部分：账号与密码策略
**密码有效期策略**:
编辑配置文件
`vim /etc/login.defs`
修改如下字段的参数
```
PASS_MAX_DAYS   90 #最大有效期90天
PASS_MIN_DAYS   0  #设置为0则表示可随时更改
PASS_MIN_LEN    8  #最小长度8位
PASS_WARN_AGE   7  #到期前7天提示
```

**防暴力破解**:
/etc/pam.d/system-auth用于全局的默认配置
/etc/pam.d/password-auth是专门给远程服务(主要是 SSHD)用的。
因此需要修改这两个文件的内容
`vim /etc/pam.d/password-auth`
修改或添加有中文注释的行
```
#%PAM-1.0
# User changes will be destroyed the next time authconfig is run.
auth        required      pam_env.so
#预验证检查:将解锁时间修改为300秒
auth        requisite     pam_faillock.so preauth audit deny=3 even_deny_root unlock_time=300
-auth        sufficient    pam_fprintd.so
auth        sufficient    pam_unix.so nullok try_first_pass
-auth        sufficient    pam_sss.so use_first_pass
#验证失败处理:将解锁时间修改为300秒
auth        [default=die] pam_faillock.so authfail audit deny=3 even_deny_root unlock_time=300
#验证成功处理:清除计数,参数保持一致
auth        sufficient    pam_faillock.so authsucc audit deny=3 even_deny_root unlock_time=300
auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success
auth        required      pam_deny.so

account     required      pam_unix.so
#确保ssh登录也能正确检测锁定状态
account     required      pam_faillock.so
account     sufficient    pam_localuser.so
account     sufficient    pam_succeed_if.so uid < 1000 quiet
-account     [default=bad success=ok user_unknown=ignore] pam_sss.so
account     required      pam_permit.so

password    requisite     pam_pwquality.so try_first_pass local_users_only
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
-password    sufficient    pam_sss.so use_authtok
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
-session     optional      pam_systemd.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.so
-session     optional      pam_sss.so
```

然后修改另一个文件
`vim /etc/pam.d/system-auth`
```
#%PAM-1.0
# User changes will be destroyed the next time authconfig is run.
auth        required      pam_env.so
#预验证检查:将解锁时间修改为300秒
auth        requisite     pam_faillock.so preauth audit deny=3 even_deny_root unlock_time=300
-auth        sufficient    pam_fprintd.so
auth        sufficient    pam_unix.so nullok try_first_pass
-auth        sufficient    pam_sss.so use_first_pass
#验证失败处理:将解锁时间修改为300秒
auth        [default=die] pam_faillock.so authfail audit deny=3 even_deny_root unlock_time=300
#验证成功处理:清除计数,参数保持一致
auth        sufficient    pam_faillock.so authsucc audit deny=3 even_deny_root unlock_time=300
auth        requisite     pam_succeed_if.so uid >= 1000 quiet_success
auth        required      pam_deny.so

account     required      pam_unix.so
account     required      pam_faillock.so
account     sufficient    pam_localuser.so
account     sufficient    pam_succeed_if.so uid < 1000 quiet
-account     [default=bad success=ok user_unknown=ignore] pam_sss.so
account     required      pam_permit.so

password    requisite     pam_pwquality.so try_first_pass local_users_only
password    sufficient    pam_unix.so sha512 shadow nullok try_first_pass use_authtok
-password    sufficient    pam_sss.so use_authtok use_first_pass
password    required      pam_deny.so

session     optional      pam_keyinit.so revoke
session     required      pam_limits.so
-session     optional      pam_systemd.so
session     [success=1 default=ignore] pam_succeed_if.so service in crond quiet use_uid
session     required      pam_unix.so
-session     optional      pam_sss.so
```
和刚才的文件的修改区别就是只需要改三处参数



#### 第四部分：SSH 服务加固
编辑配置文件
`vim /etc/ssh/sshd_config`
查找并修改以下行
```
# 登录失败最大次数 3
MaxAuthTries 3
# 禁止空口令登录
PermitEmptyPasswords no
# 15分钟 (900秒) 无操作断开
ClientAliveInterval 900
ClientAliveCountMax 0
```

重启sshd服务
`systemctl restart sshd`

#### 第五部分：Auditd 审计配置
**在日志中使用主机全名**：
`vim /etc/audit/auditd.conf`
修改或添加
`name_format = HOSTNAME`

**添加审计规则**： 
编辑规则文件
`vim /etc/audit/rules.d/audit.rules`
写入如下内容
```
# 审计关键文件改动 (-w 路径 -p 权限wa(写/属性) -k 关键词)
-w /etc/hosts -p wa -k hosts_change
-w /etc/resolv.conf -p wa -k resolv_change 
-w /etc/passwd -p wa -k user_change 
-w /etc/shadow -p wa -k shadow_change 
-w /etc/sudoers -p wa -k sudoers_change 
-w /etc/sudoers.d/ -p wa -k sudoers_d_change 
# 审计命令执行 (-w 路径 -p x(执行) -k 关键词) 
# 先用 `which rm` 和 `which reboot` 确认路径，通常是 /usr/bin/ 
-w /usr/bin/rm -p x -k rm_command 
-w /usr/sbin/reboot -p x -k reboot_command
```



默认情况下，audit是在内核参数中被禁用的，需要编辑内核参数重新启用
`vim /etc/default/grub`
找到 `GRUB_CMDLINE_LINUX` 那一行，把末尾的 **`audit=0`** 改成 **`audit=1`**
刷新 GRUB 配置
`grub2-mkconfig -o /boot/grub2/grub.cfg`
如果是 UEFI 启动，通常还需要刷这个（以防万一也执行一次，报错也没事） 
`grub2-mkconfig -o /boot/efi/EFI/kylin/grub.cfg`

重启后使用`auditctl -l`命令验证
参考如图
[[_resources/linux笔记/116f35fe7335894b2b5ee3abc79ea714_MD5.jpg|Open: Pasted image 20251223194356.png]]
![[_resources/linux笔记/116f35fe7335894b2b5ee3abc79ea714_MD5.jpg]]






# 12/22
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







