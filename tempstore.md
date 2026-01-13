
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



















