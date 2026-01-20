# Vmware

## 虚拟机启用虚拟机引擎失败

工具：centos7虚拟机，VMware17pro

报错：模块“VPMC”启动失败，未能启动虚拟机

解决方案：在任务管理器中查看到本机CPU支持并已开启了虚拟化功能，而后在安全中心中关闭了内存完整性，成功解决（在此之前关闭了windows功能服务中的windows虚拟机监控程序平台，但并未排除报错，不知道有没有关联，不过hyprv和这个是必须关闭的）

# NFS/autofs
1.NFS 概述 定义：
NFS 是一种允许通过网络共享文件系统的协议，使得不同机器上的文件系统能够像本地文件系统一样被访问。 工作原理：客户端通过网络请求访问 NFS 服务器上共享的目录，服务器根据权限提供访问。

2.NFS 架构 客户端-服务器模式：
NFS 使用客户端和服务器的模型，客户端通过网络访问服务器提供的共享目录。 协议：NFS 是基于 RPC（远程过程调用）协议的，客户端向服务器发起请求，服务器处理请求并返回响应。

3.NFS 服务器配置 共享目录：
通过 /etc/exports 文件配置，指定哪些目录可以共享、哪些客户端可以访问。 权限设置：通过配置选项控制客户端的读写权限、同步与否等.
示例配置：
`/hello 192.168.120.0/24(rw,sync,no_all_squash)`   
`/hello`：共享的目录路径。
`192.168.120.0/24`：允许访问的客户端网络。
`rw`：读写权限。
`sync`：同步写入操作。
`no_all_squash`：禁用 UID/GID 映射，保持客户端原有权限。

4.NFS 客户端操作 挂载共享目录：
客户端使用 mount 命令挂载服务器共享的目录。
示例：
`mount -t nfs [nfs-server-ip]:/hello /mnt/hello` 
访问共享文件：
挂载后，客户端就可以像访问本地文件一样访问远程共享目录中的文件。

5.NFS 文件操作 请求：
客户端向服务器发起文件操作请求（如读取、写入、删除文件等）。 响应：NFS 服务器处理请求后，返回操作结果或文件数据。 文件描述符：通过文件描述符在客户端和服务器之间传输文件操作的请求和响应。

6.权限管理 UID/GID 映射：
NFS 使用 UID 和 GID 来控制文件权限。默认情况下，客户端请求的 UID 和 GID 可能会映射为 nfsnobody 用户，除非使用 no_all_squash 禁用该映射，允许客户端保持原有的 UID/GID 权限。

7.同步与异步操作 同步 (sync)：
数据写入操作必须完成并确认后，才返回响应，确保数据一致性，但可能降低性能。 异步 (async)：写操作不等待确认立即返回，虽然性能更高，但可能导致数据不一致的风险。



8.NFS 服务的管理 启动和管理服务：
NFS 服务器通过 nfs-server 服务提供支持，可以使用 systemctl 命令来启动、停止和查看服务状态。


9.NFS 常用端口 2049/TCP 和 UDP：
这是 NFS 的固定端口，主要用于文件系统操作（如读写、挂载等）。所有文件共享的操作都通过此端口进行。 111/TCP 和 UDP（portmapper 或 rpcbind）：portmapper 服务（在现代系统中通常是 rpcbind）运行在 111 端口，客户端首先通过此端口查询到 NFS 服务的实际端口号。 20048/TCP 和 UDP（nfsd）：用于 NFS 服务器的守护进程，处理客户端的文件操作请求。 32768-65535/TCP 和 UDP：这些端口用于 NFS 的其他相关服务（如锁管理等），它们是动态分配的。

防火墙配置：确保这些端口在防火墙上是开放的，否则客户端将无法访问 NFS 服务。
`firewall-cmd --permanent --add-port=2049/tcp firewall-cmd --permanent --add-port=2049/udp firewall-cmd --permanent --add-port=111/tcp firewall-cmd --permanent --add-port=111/udp firewall-cmd --reload`




## 关于nfs配置文件/etc/exports的权限no_all_squash选项详解

no_all_squash：这是一个与 NFS 权限映射相关的选项。默认情况下，NFS 在进行客户端访问时，可能会将客户端的用户 ID（UID）和组 ID（GID）映射为 nfsnobody（一个权限非常低的用户）。no_all_squash 选项意味着禁用这种映射，而是使用客户端请求时的原始 UID 和 GID。这允许客户端以原用户的身份访问文件系统，而不是以 nfsnobody 用户的身份。




## autofs配置文件解析
/etc/auto.master（主配置文件）
作用：定义挂载点的根目录和对应的映射文件。
格式： [挂载点根目录] [映射文件路径] [可选参数] 

映射文件（如 /etc/remote.misc）
作用：定义子目录如何挂载到远程共享。 常见格式： [子目录名] [挂载选项] [服务器:共享路径]




## autofs使用nfs远程挂载实践


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




# Nginx

## Nginx 编译安装
想要实现一个功能，但是 Nginx 没有默认没有此模块，需要编译安装的方式将新的模块编译进已安装的 nginx

这里需要安装 nginx_upstream_check  模块

在反向代理服务器上配置
Rockylinux9.6
```
主机名: nginx
ip: 192.168.120.153
```



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

![f6b299e7413c5f1125a76cf5259a0232_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/f6b299e7413c5f1125a76cf5259a0232_MD5.png)



整个--prefix 是从 nginx -V 的回显结果里粘贴的

![d68e85fa487f4dac1ed7501995761af9_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/d68e85fa487f4dac1ed7501995761af9_MD5.png)

把 --add-module 模块所在目录绝对路径添加进里面就好

从这个回显也能看出来，这个--prefix 指定了 nginx 的配置文件 nginx.conf，错误日志的位置等等，添加模块也不过是在里面指定了模块文件路径，有修改某个配置文件安装时指定路径的需求时，比如把 nginx.conf 安装到/opt/下面，也可以通过编译安装的方式修改或添加指定的路径。虽然 包管理器安装后也能修改配置文件路径，但远没有编译安装自由


3.make 编译
`[root@nginx nginx-1.28.0]# make`

4.编译安装 （支持覆盖安装）
`[root@nginx nginx-1.28.0]# make install`



5.查看模块安装情况

![3005ff1d65778aee103839056b1b1171_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/3005ff1d65778aee103839056b1b1171_MD5.png)

可以看到模块成功安装了






## nginx 启动方式
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







## nginx 配置文件详解
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





## nginx 配置多个业务
### 1.使用多 IP 地址的方式
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



### 2.使用多端口的方式
就是 listen 只加端口，省略了

### 3.使用多域名的方式
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





## nginx 常用模块
### 目录索引模块
该模块默认是不开启的,在配置文件中写入指令
`autoindex on;`
来开启目录索引模块
具体表现形式参考各大镜像站的资源列表
根据 nginx 的区块层级，写在不同层级有不同的效果



### 密码登录验证模块
`auth_basic` # 描述信息 
`auth_basic_user_file`  # 指定用户和密码文件所在的路径  
密码文件需要使用htpasswd生成

1.安装httpd-tools 
`[root@rocky ~]# yum -y install httpd-tools`  

2.生成密码文件  
`[root@rocky ~]# htpasswd -b -c /etc/nginx/auth_pass test 000000`

3.在 location 区块中配置
```
auth_basic "abc";
auth_basic_user_file auth_pass;
```




### IP 地址限制模块
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





### 状态模块
stub_status

配置:

```
location /nginx_status {       
stub_status;
}  
```

浏览器访问 www.ck.com/nginx_status

![7f3cf656e7c39d9fa76a6233699144ca_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/7f3cf656e7c39d9fa76a6233699144ca_MD5.png)

```
Active connections # 当前活动的连接数
accepts # 已接收的总 TCP 连接数量
handled # 已处理的 TCP 连接数量
requests # 当前 http 请求数
Reading # 当前读取请求头数量
Writing # 当前响应的请求头数量
Waiting # 等待的请求数（处于 keepalive 的 tcp 连接），开启了 keepalive
```





### 连接限制模块
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
![9f843d783098a79efa5bd6791f926f7a_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/9f843d783098a79efa5bd6791f926f7a_MD5.png)



重定向后

![cd30c2f44fed90ea99bc116c38efa2d4_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/cd30c2f44fed90ea99bc116c38efa2d4_MD5.png)





### 代理缓存区模块
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





### 代理连接超时
proxy_connect_timeout: Nginx 与后端服务器建立连接的超时时间。proxy_read_timeout: Nginx 等待后端服务器响应的超时时间。
proxy_send_timeout: Nginx 向后端服务器发送请求数据的超时时间。

作用区块都是 http，server，location，默认时间都是 60s





## location 和 root 的关系
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







## location 的匹配规则优先级
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




## nginx 与 php 通信


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




## LNMP 架构拆分
### 一、数据库迁移
```
db01(Rocky9.6)    192.168.120.150
web01(Rocky9.6)   192.168.120.129
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

![be97a9f8ca9e0b1767a6726f0e9d1c6c_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/be97a9f8ca9e0b1767a6726f0e9d1c6c_MD5.png)

该图片是 web02 上传的，web01 可正常访问

这样就实现了无论从 web01 还是 02 上传图片，都不影响 网站图片 的整体访问











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

![ad1f3a640f9a46059c6c6e512e5207df_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/ad1f3a640f9a46059c6c6e512e5207df_MD5.png)

返回的却是这个(这个是其他 server 服务)

使用 WireShark 抓包分析得到下面两条

![4a8460ea803585486720dece4c97fee1_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/4a8460ea803585486720dece4c97fee1_MD5.png)

192.168.120.1 访问.153 时，注意蓝色标注条目

Host: www.static.com\r\n

可以看到 host 头部域名正确

![fb68b5c4f4dc1a5d5b04f2bc61ee9c87_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/fb68b5c4f4dc1a5d5b04f2bc61ee9c87_MD5.png)

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

![ebcaf011778388591d7ab089a65df672_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/ebcaf011778388591d7ab089a65df672_MD5.png)



然后就涉及到一个问题，代理服务器访问 web01，web01 的 nginx 的 access 日志  保存的源 ip 是代理服务器的 ip 而不是客户端 ip，这没有意义

![d1782f9d352ebf91850f52160198b97a_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/d1782f9d352ebf91850f52160198b97a_MD5.png)



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

![603a732955a5a5f3b6716d71d4691b7f_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/603a732955a5a5f3b6716d71d4691b7f_MD5.png)

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
Rocky_nginx         192.168.120.153
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
1.rr 轮询
2.加权轮询
3.ip_hash   ip 哈希
4.url_hash  url 哈希
5.最少链接数


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




## 四层负载均衡配置
![bb593528d3e66df5021fad1d3ee4bf78_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/bb593528d3e66df5021fad1d3ee4bf78_MD5.png)

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

![210fac57e84fe4f394f0dde91d337b59_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/210fac57e84fe4f394f0dde91d337b59_MD5.png)

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

![931b1a699d00f1ce51378f6ba7baaca5_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/931b1a699d00f1ce51378f6ba7baaca5_MD5.png)

配置成功




## session 会话保持
以部署 phpmyadmin 业务为例，虚拟机统一使用 rocky9.6

```
nginx   192.168.120.153

web01   192.168.120.129

web02   192.168.120.151
```




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



4.快速部署WEB02 phpmyadmin业务
1. scp配置文件  

```bash
[root@web02 ~]# scp 192.168.120.129:/etc/nginx/conf.d/admin.conf /etc/nginx/conf.d/
root@192.168.120.129's password: 
admin.conf                                                                                                        100%  411   546.8KB/s   00:00    
[root@web02 ~]# nginx -t
nginx: the configuration file /etc/nginx/nginx.conf syntax is ok
nginx: configuration file /etc/nginx/nginx.conf test is successful
[root@web02 ~]# systemctl restart nginx
```



2. 拷贝代码文件

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

![6d036eaa98a62b008ed93df3d0523d52_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/6d036eaa98a62b008ed93df3d0523d52_MD5.png)

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

![33527651eac752f9e3669794a7db38f5_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/33527651eac752f9e3669794a7db38f5_MD5.png)

刷新两次可以看到每次的登录 ip 都不同

![0a7c2ae40046efcd8b5088d8ada62cb4_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/0a7c2ae40046efcd8b5088d8ada62cb4_MD5.png)

![a1fac794434f540b090c08edb9452f4b_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/a1fac794434f540b090c08edb9452f4b_MD5.png)



 查看redis中的session数据  

```bash
[root@db01 ~]# redis-cli
127.0.0.1:6379> keys *
1) "PHPREDIS_SESSION:pp4fc5b21j46269632aqdevvjg"
127.0.0.1:6379> 
```
至此就完成了 session 会话保持，session 存储在了 redis 里




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
`[root@web02 ~]#yum -y install java`

运行java服务
`[root@web02 ~]#/usr/local/tomcat/bin/startup.sh`

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

```bash
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

![2a3896318ad44a046a9bf09e86f79873_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/2a3896318ad44a046a9bf09e86f79873_MD5.png)



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

![d05a8dc4334bac00e8bbc13df88f3b90_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/d05a8dc4334bac00e8bbc13df88f3b90_MD5.png)



模拟静态业务挂了，动态没挂
```bash
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
![ea688788db969be1a905c59530fcb0b9_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/ea688788db969be1a905c59530fcb0b9_MD5.png)







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

![322a43611a5695b0880c533d4e2b01d1_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/322a43611a5695b0880c533d4e2b01d1_MD5.png)



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









# Ansible
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
`ansible [pattern] -i [inventory] -m [module] -a "[module options]" [--become]`

pattern选项 指定要操作的主机或主机组的模式。

常见的 pattern 语法
`[root@server ansible]# cat node.ini [node] node1 node2`

由于主机密钥检查问题暂时没有好的解决办法，这里的举例使用 在 ansible 的配置文件中禁用 ansible 的密钥检查
`[defaults] host_key_checking = False`

1. 全量匹配 all 或 *：选择所有主机
	`ansible all -m ping`

2. 单主机/主机组
```
-i：指定库存文件的位置。

-m：指定要使用的模块（例如 ping, shell, copy 等）。

-a：指定模块的参数。

--become：使用 sudo 提权执行命令（需要适当的权限配置）。
```

pipx的安装
`python3 -m pip install --user pipx`
`python3 -m pipx ensurepath`



## ansible 模块
`ansible-doc -l`
列出 ansible-core 的模块列表，不加 l 可以查看指定模块

setup 模块 在 剧本执行前,ansible 会自动调用 setup 模块采集目标清单的 fact(事实信息集合)（可禁用自动调用，在剧本的属性中添加gather_facts: no），采集到的 fact 使用该模块的内置变量以键值对的形式存储，格式为 json 格式，剧本调用 setup 模块的内置变量的子属性时，使用' . '来连接父属性和子属性，这个格式使用的是 嵌套字典的形式，例如内置变量 ansible_devices,它的子属性有 vda，vda 的子属性有 size，那么调用 size 变量就需要使用嵌套字典表示 : ansible_devices.vda.size，等价于 python 的嵌套字典语法 ansible_devices['vda']['size'](https://www.google.com/search?q=%E4%B8%8D%E6%98%AF%E5%A4%9A%E7%BB%B4%E6%95%B0%E7%BB%84%EF%BC%8C%E6%98%AF%E5%AD%97%E5%85%B8%E5%B5%8C%E5%A5%97)

- name: get vda_info lineinfile: path: /root/hwreport.txt regexp: "disk_vda_size" line: "{{ ansible_devices.vda.size | default ('none') }}"
    
查看指定模块的使用帮助 ansible-navigator doc 模块名 -m stdout
比 ansible-doc 更完善


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











# Zabbix
## Zabbix 基础架构
![aec1d7088e442a64778f46e3a8b338a2_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/aec1d7088e442a64778f46e3a8b338a2_MD5.png)

代理端是可选项

zabbix-agent 以进程的形式运行在主机的 10050 端口 


基础架构组件介绍

==Zabbix Server==
是 Zabbix 的核心组件，其功能为将 Agent 采集到的数据持久化 存储到数据库里。

==数据库存储==
存储所有由 Agent 采集到的数据，Zabbix 支持多种数据存储，例如: Mysql,Oracle,PostgreSQL,Elasticsearch 等。

==Web 界面==
Zabbix 提供了友好的 Web 界面方便我们操作，Web 界面的运行环境可以是 Nginx+PHP或者Apache+PHP服务组成。Web界面也是ZabbixServer的一部分。

==Proxy 代理端== 
对于分布式环境，Zabbix 也提供了代理的方案，可以代替 Zabbie Server 收集 多个 Agent 的数据，然后在将收集到的数据汇总到 Zabbix Server，Proxy 可以 起到分担 Zabbix Server 负载的作用。

==Agent 客户端==
Zabbix Agent 被部署在需要监控主机上，用于采集监控数据并发送到 Zabbix Server 端。

==Server 服务端==
Zabbix Server 是 C 语言开发的 Zabbix 服务端，有着 强悍的采集和计算性能，而且资源使用率很低。主要的功能如下：

定时读取 Zabbix 数据库，同步 Zabbix UI 配置的信息到缓存，下发到 Zabbix Agent 或者 Zabbix Proxy。

关于这俩不同的采集进程，可以通过(ps -ef|grep zabbix 查看进程列表)

对于被动采集（主动和被动是从设备侧角度来看的）, Zabbix Server 会有专门的 Poller 线程去采集数据，可以定义特定的时间区间或者特定的频率。

对于主动采集，就是Agent或者设备主动上报数据，Zabbix Server 也会有专门的 Trapper 线程来接收数据，时间间隔或者频率取决于设备侧或者Agent上报配置。

接收到的历史数据（来自于 Agent、Proxy、设备侧），Zabbix Server 会缓存下来，进行告警表达式计算，进行动作触发，最终会同步到数据库的历史记录表，history开头的表。




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
`[root@localhost ~]# dnf -y  install zabbix-server-mysql zabbix-web-mysql zabbix-apache-conf zabbix-sql-scripts zabbix-selinux-policy zabbix-agent`


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

![f3ffa6d676413dd0de913d2ba13422fb_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/f3ffa6d676413dd0de913d2ba13422fb_MD5.png)

一直下一步，到连接数据库

![4be80ac82facce3778f555ec69a55e3d_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/4be80ac82facce3778f555ec69a55e3d_MD5.png)

密码是 zabbix 数据库设置的密码 Zabbix@123

但是这里会报错，还是因为使用 的是 MYSQL8.4 的原因

![eec629f74e45d220a94ce4023f43127e_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/eec629f74e45d220a94ce4023f43127e_MD5.png)

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

![b9b344653d1d8d0b7d55b26b4f24ac2c_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/b9b344653d1d8d0b7d55b26b4f24ac2c_MD5.png)

![7dc6c47de5010cfd429d1cc7a538e9ef_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/7dc6c47de5010cfd429d1cc7a538e9ef_MD5.png)

![60e757a51946fb339718e32538efea73_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/60e757a51946fb339718e32538efea73_MD5.png)

用户默认是 Admin  密码是 zabbix

![803dbc0a17b995fcb131fdbd0f9f7e81_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/803dbc0a17b995fcb131fdbd0f9f7e81_MD5.png)

至此配置完成




## 欧拉部署zabbix7.0的版本依赖问题
欧拉的具体版本是 24.03-sp1

zabbix7.0 要求net-snmp-libs 版本要在1:5.9.1-x 以内（大概是这样，我部署的版本是1:5.9.1-17），但是欧拉官方镜像源的net-snmp-libs最旧的版本也是 1:5.9.2-x 的，所以这里我使用了 centos9stream 的 appstream 仓库,由于net-snmp-libs 还有相关依赖所以不能直接降级，卸载后重新安装注意相关依赖项的重新安装

如果版本不对，在启动 zabbix 相关服务时会报错如下图，附上具体的日志信息

![8c5ee793907705df231ecf08121abc97_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/8c5ee793907705df231ecf08121abc97_MD5.png)

![ee86c04f16e7858af1b61e373b6c7c25_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/ee86c04f16e7858af1b61e373b6c7c25_MD5.png)




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

![8770e3d967c92a2a82d906e896a7b746_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/8770e3d967c92a2a82d906e896a7b746_MD5.png)

进入对应 agent 端的监控项并创建监控项

![ea38b37a3a65ccaece89bdaaf62a6c9f_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/ea38b37a3a65ccaece89bdaaf62a6c9f_MD5.png)

键值写刚刚自定义的监控项，信息类型是命令行的结果的数据类型,ip 是对应 agent 客户端的 ip

在添加前可以先测试

![6a201890c13a52ff5bdaaced81cb38b9_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/6a201890c13a52ff5bdaaced81cb38b9_MD5.png)

上面的"获取值"相当于在 zabbix-server 端的命令行中使用 zabbix_get 测试

下面的"获取值并进行测试"是在测试 php（即网页端） 能否调用该键值

测试完成后就可以添加作为自定义监控项在 zabbix-UI 中使用

最后还需要为该监控项配置触发器，路径是：告警-主机-触发器-新建触发器

![8721c9deafcdf3ab14fbdaeaf25d40be_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/8721c9deafcdf3ab14fbdaeaf25d40be_MD5.png)

问题表达式点击"添加"可选择监控项，在"功能"选择需要使用的函数

![b7a5f50ab3acd6f566cc0501aecefbcc_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/b7a5f50ab3acd6f566cc0501aecefbcc_MD5.png)

"结果"是 监控项的数据结果，这里设置检测的结果大于 6 就触发问题表达式

![7cf92c4b4ca70edd6949a47750242af5_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/7cf92c4b4ca70edd6949a47750242af5_MD5.png)

如果需要恢复表达式，也可以添加，和问题表达式一样的操作流程

![058cb0a7f70940f62de2e2fc498e7842_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/058cb0a7f70940f62de2e2fc498e7842_MD5.png)

至此完成配置并添加，完成了一个自定义监控项的简单流程














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

![fe46350bc8ae679e02db5c9b89169724_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/fe46350bc8ae679e02db5c9b89169724_MD5.png)

在实际使用时需要指定参数，这里指定为 root

然后为该监控项配置触发器

![c1cc4bef793487fb821d898843a02cee_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/c1cc4bef793487fb821d898843a02cee_MD5.png)

这里的问题表达式的条件是：最后一条监控项的数据和倒数第二条的数据不等

添加后使用 server 主机 ssh 测试

![6203e5b8bb903e5cb03b093a271bcae9_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/6203e5b8bb903e5cb03b093a271bcae9_MD5.png)

触发了告警,至此完成了一个简单的自定义参数监控项，该监控项逻辑处理有待完善





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

![c7a0dc281e1fafebc84b76cedb096137_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/c7a0dc281e1fafebc84b76cedb096137_MD5.png)

![a3fe1757247f03ca7910595c7a2e8944_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/a3fe1757247f03ca7910595c7a2e8944_MD5.png)



4.修改 zabbix-UI 相关目录及文件的权限

![8caa9f0411a06fc2cf60e32fb429176b_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/8caa9f0411a06fc2cf60e32fb429176b_MD5.png)

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

![97252936acc64441117a4ba067e3c757_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/97252936acc64441117a4ba067e3c757_MD5.png)

nginx 切换 apache 也是一样的逻辑与流程











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












# Openstack

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



## 报错：无效的服务目录，compute

![98bf11f74a0d0f17ba4b93b00a194aee_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/98bf11f74a0d0f17ba4b93b00a194aee_MD5.png)



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



在安装neutron时报错缺少libxslt-1.1.28-5.el7.x86_64，本机版本为libxslt-1.1.28-6.el7.x86_64，若使用yum erase卸载libxslt-1.1.28-6.el7.x86_64重新安装libxslt-1.1.28-5.el7.x86_64后需要重新安装nova服务（iaas-install-nova。。。）。（后续补充：这个报错是因为使用了7.9的镜像，实际上先电2.4应该使用7.5）

因为在卸载libxslt-1.1.28-6.el7.x86_64时也一并卸载了部分nova配置

补充：
在使用glance命令生成镜像时报错，大意是端口号被占用，配置文件错误，重装glance后解决报错，可知这个文件与glance配置也有关系，虽然在一切开始之前我就重新安装了libxslt-1.1.28-5.el7.x86_64版本，但还是报错说我版本没有变化，还是.6版本，不得已在配置过程中卸载重装了这个文件，在dashboard平台的报错弹窗（找不到镜像）也一并解决了





## 报错:无效的服务目录：network
Selinux配置为permis模式
不知道为什么平台又搭建成功了，报错也解决了
与之前操作有所不同的是我把selinux设置为permissive模式，在两个节点执行了systemctl start chronyd和systemctl enable chronyd,搭建过程中电脑全程联外网,
两台主机的时间同步是很重要的，偏差较大会直接影响平台的搭建

修改nova.conf文件的虚拟化类型似乎没必要？因为我上传的镜像的的硬盘格式和容器格式是qcow2和bare，这两者貌似都是被虚拟化类型kvm所支持的，我把搭建好的云主机虚拟化类型改回了kvm，并重启了openstack相关所有服务，结果是并没有影响，不过也有可能是因为这台云主机已经完成了第一次启动？我懒得从头再搭一遍了，以后再说吧(后续补充：确实没有影响，不需要把虚拟化类型修改为qemu)












放弃centos7.9改用7.5

7.5还是在compute安装iaas-pre。。。的时候报错时间服务无法启动

至少因为lib版本原因的报错解决了(经后续排查可知时间服务无法启动的原因是因为重复配置了时间服务配置文件参数，与镜像版本无关，由此可知先电openstack2.4适配的centos版本是7.5版本，2.2好像是7.2版本，但感觉主要还是看内核版本



## 报错：新云主机创建失败：找不到有效主机

懒得截图了
初步排错认为是计算节点资源不足导致，尝试添加一个新计算节点

openstack compute service list --service nova-compute

该命令用于在控制节点获取计算节点的主机名和服务ID

确实是计算资源不够用，添加新计算节点后解决了报错

解决过程：和普通的计算节点一样的配置，把先电的环境配置文件参数修改为对应节点就行，用上面的命令查看计算节点状态，openstack compute service set --enable 计算节点主机名 nova-compute

如果计算节点没有启用的话尝试使用这条命令





## 关于 controller 和 compute 节点在安装完脚本后时间服务器无法启动

报错： Job for chronyd.service failed because the control process exited with error code. See "systemctl status chronyd.service" and "journalctl -xe" for details.

解决方案： 使用系统给出的提示使用 journalctl -xe（这个命令将显示扩展的系统日志，包括最近的错误和警告信息）并使用管道与 grep 结合筛选出与 chronyd 相关的日志信息，结果如图：

![01636d741ab699a12996cde9498ad736_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/01636d741ab699a12996cde9498ad736_MD5.png)

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






由于compute节点也报了lib的版本错误，而此时controller节点的neutron服务已经部署完毕，或许该尝试两个节点同步部署nova服务并更改lib版本，但还是感觉问题出在neutron的几种网络模式的选择上

在使用openstack指令时报错

![c9c64d62cd96874445eea152f3d1ae2f_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/c9c64d62cd96874445eea152f3d1ae2f_MD5.png)

提示需要生效环境变量

即source生效/etc/xiandian/openrc.sh和/etc/keystone/admin-openrc.sh 两个脚本

解决了，原因是服务重复了，删除一个就好，类似的报错都可以从这方面入手

总结一下

云平台报错：错误：Invalid service catalog service: identity

解决方案：openstack service list发现keystone（也就是identity）重复出现，使用openstack service delete 加对应ID删除重复服务并systemctl restart httpd.service memcached.service重启服务

报错原因：重复安装了keystone，由此可知关于lib版本的报错解决并不仅仅是卸载重装这么简单，还需要删除掉对应的多余服务，貌似先电2.2无法识别多余且不可用的服务，2.4没有发现

搭建成功了，关于neutron的网络模式还是需要研究一下












# Ceph
## 10/16
## 搭建ceph

三个节点

Node1，2，3

全部配置免密ssh和主机映射，yum源采用ftp使用controller的本地源

先电2.4没有ceph-deploy，node1新增阿里ceph源

ceph-deploy install --no-adjust-repos ceph-node1 ceph-node2 ceph-node3

在为三个节点安装ceph时，遇到报错无法下载密钥文件，通过添加--no-adjust-repos参数跳过了密钥下载，不知道有没有影响

出现此报错多半是yum源地址有问题

Ceph安装错了位置，全部重置



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

![783df5932e4e96aac58bce37adddb368_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/783df5932e4e96aac58bce37adddb368_MD5.png)

报错原因是阿里云提供的centos源的epel仓库源配置有问题，导致无法启用

解决方案：手动添加一个epel源，这里在阿里云找到了epel源Wget -O /etc/yum.repos.d/epel.repo [https://mirrors.aliyun.com/repo/epel-7.repo](https://mirrors.aliyun.com/repo/epel-7.repo)


## 关于ceph-deploy new报错

![809b3e0389f8e2463704220d5b877df3_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/809b3e0389f8e2463704220d5b877df3_MD5.png)

报错原因：ceph-deploy 工具在尝试启动时遇到了问题。具体来说，是在尝试导入 pkg_resources 模块时出错了。这个模块是 setuptools 包的一部分，在 Python 中用于包管理和资源获取，即没有安装setuptools

解决方案：yum install -y python-setuptools

创建pool命令
ceph osd pool create <pool名> <pg值> <pg备份值>





# Docker
Docker pull的源需要更改，好像要注册一个阿里云镜像站的账号，如果想使用阿里云镜像源的话

关于docker pull的源配置在/etc/docker/daemon.json文件里，配置完成后使用systemctl daemon-reload和systemctl restart docker后使用docker info可以查看源信息



## docker原理
Linux内核支持两个功能，与容器技术的实现有关![3b85d5e8cae5347d129ebc2f31c83d82_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/3b85d5e8cae5347d129ebc2f31c83d82_MD5.png)![da20e5f18dfa2c93587542109c98d9f3_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/da20e5f18dfa2c93587542109c98d9f3_MD5.png)

## docker containerd.io

是Docker容器运行时的核心组件之一，它负责管理和运行容器。它提供了容器的生命周期管理、镜像管理、网络管理等功能





## 国内的docker可用镜像源

"[https://docker.m.daocloud.io](https://docker.m.daocloud.io)",

"[https://noohub.ru](https://noohub.ru)",

"[https://huecker.io](https://huecker.io)",

"[https://dockerhub.timeweb.cloud](https://dockerhub.timeweb.cloud)",

"[https://docker.rainbond.cc](https://docker.rainbond.cc)"


## docker命令补全问题

默认是无法补全的，但可以通过以下命令实现

yum install -y bash-completion

source /usr/share/bash-completion/bash_completion


## docker基础操作
![980d7f13d37fe9f7c8c54cb6f58d42b0_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/980d7f13d37fe9f7c8c54cb6f58d42b0_MD5.png)

![1ef38c4dc170e22e61598a8ebb9ded8c_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/1ef38c4dc170e22e61598a8ebb9ded8c_MD5.png)





## 报错：访问容器tomcat时网页404

报错原因：使用的tomcat镜像默认是最小的镜像，它把所有不必要的都剔除掉了。保证最小可运行的环境。

解决方案：在tomcat目录下有一个webapps.dist目录，这个目录下有所需要的文件，也就是webapps目录所需要的文件，将这个文件中的内容全部拷贝到webapps下。

即执行cp -r webapps.dist/* webapps命令

Docker镜像都是只读的，当容器启动时，一个新的可写层被加载到镜像的顶部，这一次就是我们通常说的容器层，容器之下的都叫镜像层。

（此处知识点涉及到UnionFS（联合文件系统））


## docker重启策略
![748481c4d7486e57390d4e2d6bc72716_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/748481c4d7486e57390d4e2d6bc72716_MD5.png)

注：该图是关于docker container run --restart命令的策略参数

在模拟容器异常退出时可使用pstree -p 查看进程树及对应pid（centos7.5没有安装该命令，执行yum install -y psmisc)以杀死指定容器进程，该命令之所以能够模拟容器异常退出是因为该命令属于宿主机指令干预，而非容器内部指令操作




## docker容器的五种网络模式及其解析

![06fa053890ac3a042bc04e540bf4bba0_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/06fa053890ac3a042bc04e540bf4bba0_MD5.png)

![7aec3570ad6c6c00e111637a90f7b172_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/7aec3570ad6c6c00e111637a90f7b172_MD5.png)

![9509aa2a3a3b7ae049504f49d4a0a50d_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/9509aa2a3a3b7ae049504f49d4a0a50d_MD5.png)

![7f020773142aaa0ac61b9f0796d39729_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/7f020773142aaa0ac61b9f0796d39729_MD5.png)

![f26491c8e5c187be7a4f7af11b8ea515_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/f26491c8e5c187be7a4f7af11b8ea515_MD5.png)

## docker私有仓库在push时报错：需要使用https协议
如下图
在daemon.json配置文件中"insecure-registries":是指采用http协议来进行镜像的上传与下载

![3e9aa21c7c4497c1d9885b76d893a456_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/3e9aa21c7c4497c1d9885b76d893a456_MD5.png)

Registry仓库指定的挂载卷位置与端口：/var/lib/registry 5000


## 容器部署mysql

可参考以下指令格式

docker run -d -p 3310:3306 -v /home/mysql/conf:/etc/mysql/conf.d -v /home/mysql/data:/var/lib/mysql -e MYSQL_ROOT_PASSWORD=123456 --name mysql01 mysql:5.7

////////////////////////////////////////////////////////////////////////////////

目前对构建上下文的理解是对所构建的容器所处的环境的打包

数据卷的挂载默认是以读写的方式

可指定挂载方式，例如在容器被挂载的目录后面加:ro 即只读 :rw 可读写(默认)

若要创建一个容器，指定它的数据卷挂载与另一容器一致（即与另一容器共享数据卷），则需要’ --volumes-from 被共享的容器名 ’ 参数来实现




## dockerfile命令解析

![ac715b24bf24720805fd9d0f147f733a_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/ac715b24bf24720805fd9d0f147f733a_MD5.png)

![8a27da6bfff71225f0dfa133b6b71859_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/8a27da6bfff71225f0dfa133b6b71859_MD5.png)


## docker容器编排工具docker compose

Compose v2

目前 Docker 官方用 GO 语言 重写 了 Docker Compose，并将其作为了 docker cli 的子命令，称为 Compose V2。你可以参照官方文档安装，然后将熟悉的 docker-compose 命令替换为 docker compose，即可使用 Docker Compose。

截止至2024/9/29的centos7,docker-compose指令的使用需要手动安装docker compose

在docker-compose.yml文件的编写中,build参数的使用对象，也就是构建环境中的构建镜像所用文件要严格遵守dockerfile命名规范，即只能将其命名为D(d)ockerfile，否则在构建过程中会因为找不到该文件而报错

另外在docker compose config的使用中，config后面在没有追加选项的情况下，应当填写docker-compose.file文件所处环境（即所处目录），docker-compose的容器编排配置文件也应当固定为dockers-compose.yml

这两点存疑，可能是因为构建上下文或版本的问题，又或者是在没有指定文件名的情况下会遵循这个规则


## dockerfile构建上下文

编写dockerfile时在写宿主机文件路径时需要注意构建上下文问题，例

docker build -t tag:6 -f /path/Dockerfile .

在这里指定了构建上下文为当前目录环境，则在编写dockerfile时书写宿主机文件路径时需要使用相对路径且文件与dockerfile处于同一文件夹（？），例如在COPY的使用上





## 关于docker容器保留前台进程以维持容器运行

由于容器会检测内部pid为1的进程是否存在而判断容器是否在运行，所以为保持容器正常运行，需要指定一个前台进程。

主要是在dockerfile中指定容器运行后执行命令的CMD,一般该参数用于创建一个前台进程，例如在memcached（内存缓存数据库）的dockefile编写中，最后一条CMD是memcached -u root来创建该容器的前台进程(#使用root用户前台启动memcached)



## mariadb的容器化部署

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




## Harbor仓库的私有仓库搭建

可以用注释相关配置实现免证书搭建
如果没有申请证书，需要隐藏https
https:
https port for harbor, default is 443
port: 443

同时可以与daemon.json的参数 "insecure-registries": ["0.0.0.0/0"]配合使用，该配置表示docker使用http协议访问任何镜像仓库位置




## docker compose命令的路径要求

![f1a0a333246e3f12c0ece763cd038c3c_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/f1a0a333246e3f12c0ece763cd038c3c_MD5.png)

在执行docker compose命令时要求当前目录下有docker-compose.yml这个文件，因为Docker Compose 需要一个 YAML 文件来定义服务、网络和卷等配置，这个文件通常以 docker-compose.yml 或 docker-compose.yaml 命名。

## Harbor

Harbor介绍

（一）Harbor镜像仓库简介

Harbor是由VMware公司开源的企业级的Docker Registry管理项目，Harbor主要提供Dcoker Registry管理UI，提供的功能包括：基于角色访问的控制权限管理(RBAC)、AD/LDAP集成、日志审核、管理界面、自我注册、镜像复制和中文支持等。Harbor的目标是帮助用户迅速搭建一个企业级的Docker registry服务。它以Docker公司开源的registry为基础。

Harbor除了提供友好的Web UI界面，角色和用户权限管理，用户操作审计等功能外，它还整合了K8s的插件(Add-ons)仓库，即Helm通过chart方式下载、管理、安装K8S插件，而chartmuseum可以提供存储chart数据的仓库。

注:helm就相当于k8s的yum



在23版本，docker-compose被插件化作为docker的一部分，也就是说在安装23及以后版本的docker时，也一并安装了docker-compose



## docker/podman的挂载卷映射与selinux安全上下文
如果在做挂载卷映射时没有给容器挂载目录打标签，就会被selinux拦截

参考命令如下,要加个z
podman run -d -v /hello:/fine:z centos:latest




## podman 指定镜像仓库位置
在/etc/containers/registries.conf配置文件中书写

```
unqualified-search-registries = ["utility.lab.example.com"]
[registry](registry.md)
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

[registry](registry.md) 作为主仓库标题，[registry.mirror](registry.mirror) 作为备用仓库标题，当主仓库拉取失败时，按顺序向下面的备用仓库拉取镜像


## podman卷映射-v选项的z标签大小写区别

作用都是让selinux放通，但作用不同

小写z标签

表示共享挂载卷，共享宿主机的挂载卷，这样其它容器也能挂载并访问该挂载卷

大写Z标签

表示私有标签，使用该标签后，其它容器就不能通过挂载卷访问该宿主机目录，但这个标签会被覆盖，例如先后有两个容器都对一个宿主机目录做了挂载卷映射，都使用了私有标签Z,生效的是最后打标签的容器，第一个容器失去了通过挂载卷访问该目录的权限

如下

```bash
[root@server ~]# podman run -itd -v /podman-mapper-dir1:/dir1:Z --name first_centos centos:latest e48892657919c025d6004d237bd78ceb14bb0f7b540d1ba8b54ed9aa9cbbaecf [root@server ~]# podman run -itd -v /podman-mapper-dir1:/dir2:Z --name Second_centos centos:latest 03095b52384fc28a0073d9d3028d0378d53c8fb3a2a7f5a42bb8befb68c856da [root@server ~]# podman exec -it first_centos /bin/bash [root@e48892657919 /]# ls
afs bin boot dev dir1 etc home lib lib64 lost+found media mnt opt proc root run sbin srv sys tmp usr var 
[root@e48892657919 /]# cd dir1/ bash: cd: dir1/: Permission denied [root@e48892657919 ~]# exit 
[root@server ~]# podman exec -it Second_centos /bin/bash [root@03095b52384f /]# cd dir2/ 
[root@03095b52384f dir2]#
```














# Redis

## 关于 redis的配置文件部分参数

bind 127.0.0.1

该参数表示只允许本地连接，若要开启远程连接则需要注释该参数或将127.0.0.1修改为0.0.0.0

protected-mode yes

字面意思，开启保护模式，若要关闭保护模式只需将yes修改为no















# MySQL
## mysql8.0 安装后配置

与 8.4 不同，使用 mysql -u root -p 直接进入数据库（注意不是 mysqld），密码输入直接回车，因为默认是空密码,进入数据库，为了安全起见，还是设置一下 root 密码，在数据库中执行以下代码

ALTER USER 'root'@'localhost' IDENTIFIED BY '新密码'; FLUSH PRIVILEGES;





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


## 不进入数据库命令行界面实现交互

可参考该命令mysql -uroot -proot -e " create database djangoblog;"

另外还可以直接进入指定数据库mysql -uroot -proot djangoblog






## 数据库调优-my.cnf配置详解

![7a3e8731c537b0aa65c421cbd92242ef_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/7a3e8731c537b0aa65c421cbd92242ef_MD5.png)

lower_case_table_names =1 //数据库支持大小写
innodb_buffer_pool_size = 4G //设置数据库缓存（缓冲区）大小为4G innodb_log_buffer_size = 64MB //设置数据库的log buffer即redo日志缓冲为64MB 
innodb_log_file_size = 256MB //设置数据库的redo log即redo日志大小为256MB 
innodb_log_files_in_group = 2 //数据库的redo log文件组即redo日志的个数配置为2

systemctl restart mariadb




















# Wordpress

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













# Kubernetes

## K8s基础架构

![602080906e00f1d43df2af815e15f692_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/602080906e00f1d43df2af815e15f692_MD5.png)




## 关于k8s资源清单部分顶级字段

![b1716fecba8988e8d7a93c340ec2d52b_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/b1716fecba8988e8d7a93c340ec2d52b_MD5.png)

![1ba0145f8d5bc1f6702540c0979e5377_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/1ba0145f8d5bc1f6702540c0979e5377_MD5.png)



## K8S的命名空间

命名空间namespace是K8S中“组”的概念，提供同一服务的Pod应该被放置同一命名空间下，而不是混杂在一起。K8S可以用命名空间来做权限控制和资源隔离。如果不指定的话，Pod将被放置在默认的命名空间default下。




## 关于kubectl get

kubectl get可以列出K8S中所有资源，还可以使用别的参数获取其它资源列表信息，如get svc（查看服务）、get rs（查看副本控制器）、get deploy（查看部署）等。

如果想要查看更多信息，指定-o wide参数即可，语法如下：

kubectl get <资源> -n <命名空间> -o wide

加上这个参数之后就可以看到资源的IP和所在节点。


在kubeeasy部署过程中通过查看日志来跟踪k8s安装进度

tail -f /var/log/kubeinstall.log







## kubectl命令行补全

与docker一样，都需要安装bash-completion

source <(kubectl completion bash)

在bash中设置当前shell的自动补全，要先安装bash-completion包。

echo "source <(kubectl completion bash)" >> ~/.bashrc




## kubectl管理pod

注意：如果不指定-n 命名空间，会默认查看default命名空间里的pod，创建pod的时候不指定命名空间，只会将pod创建在default命名空间里

在查看pod时可以使用参数查看kubectl get pod --show-labels=true它的标签，该参数在kubectl get --help能够查到，不过是--show-labels=flase的形式 ，因为它旨在表明kubectl get pod这条命令默认是隐藏标签的，所以当使用该参数时要把flase改成true

该命令可以与kubectl describe po -l 结合使用，因为使用这个命令查看pod具体信息时需要指定它的标签




## namespace自动注入sidecar

Istio 作为重要的 ServiceMesh 框架，已经被越来越多的公司所使用。在 Istio 体系中，应用容器的出入流量都需要经过 Sidecar 的拦截和处理。默认地，Istio sidecar 自动注入是通过给 namespace 打 istio-injection=enabled 或 istio-injection=disabled 标签，来确定是否在该命名空间执行自动注入。

示例：kubectl label ns exam istio-injection=enabled

注：ns是指代命名空间，在kubectl create ns中也是这个作用，该命名空间名字叫exam




## helm

Helm 的 Release 是 Helm 这个 Kubernetes 包管理工具的概念，而不是 Kubernetes 自身的概念。

Helm Release：

在 Helm 中，一个 Release 是指一个包（Chart）的单个部署实例。当你使用 Helm 安装一个 Chart 时，Helm 会创建一个 Release 来跟踪这个部署的状态和历史。

每个 Release 都有一个唯一的标识符，通常是一个名字和一个版本号。

Release 包含了 Chart 的配置信息、部署的 Kubernetes 资源对象以及部署过程中的状态信息。

你可以对同一个 Chart 创建多个 Release，每个 Release 可以有不同的配置和升级历史。


## k8s镜像下载策略有哪些

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






## k8s各组件版本问题 [https://github.com/kubernetes/kubernetes/blob/v1.22.1/build/dependencies.yaml](https://github.com/kubernetes/kubernetes/blob/v1.22.1/build/dependencies.yaml)

将该链接的版本号那一栏改为想要查询的k8s版本从而查看对应的组件版本信息





## k8s提示certificate signed by unknown authority (possibly because of "crypto/rsa: verification error" while trying to verify candidate authority certificate "kubernetes")

原因：这是在重新创建集群之前，原来集群的rm -rf $HOME/.kube文件没有删除，所以导致了认证失去作用。

![71995472fa51dff02d4369e65b179492_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/71995472fa51dff02d4369e65b179492_MD5.png)

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

![b1265d27c6c54feb86ad6fc6dc4d1acc_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/b1265d27c6c54feb86ad6fc6dc4d1acc_MD5.png)

火狐浏览器的K8s网页乱码，用本地服务器的chrome浏览器解决了问题




## kubeadm拉取镜像及初始化报错mageService" , error: exit status 1 To see the stack trace of this error execute with --v=5 or higher

![254071198a2abdf0a9d4a9a1dbedd729_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/254071198a2abdf0a9d4a9a1dbedd729_MD5.png)

原因是containerd的配置文件写错了，在修改cgroup驱动时，将systemd_cgroup = false修改为了true，但实际上应该修改Systemd_cgroup = false为true，两者都存在于配置文件中，只是首字符大小写不一样，集群初始化也没再报错无法通信cri，但我没有执行crictl config runtime-point unix:///var/run/containerd/containerd.sock






## k8s使用国内镜像源

![26a11ad2910c607d57cc46cc4d688773_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/26a11ad2910c607d57cc46cc4d688773_MD5.png)

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



## 使用kubectl命令行创建网络报错8080端口或许被占用

![77c7f534c0997bf20d15cb3d7a24a0bc_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/77c7f534c0997bf20d15cb3d7a24a0bc_MD5.png)

可能的原因是在完成集群初始化后没有将k8s的配置文件admin.conf拷贝到当前用户家目录下并更名为config，因为k8s要读取该配置文件




## k8s的coredns一直处于创建中的状态

![2bc2cf73efbe037270af208e41a03b20_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/2bc2cf73efbe037270af208e41a03b20_MD5.png)

使用kubectl describe pod coredns-c676cc86f-hfp7q -n kube-system查看详细信息发现缺少对应文件/run/flannel/subnet.env文件(该文件一般是自动生成的）

![4af6d086348e0af5fe643310f1844485_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/4af6d086348e0af5fe643310f1844485_MD5.png)

于是手动创建一个，配置如下

![5f193d69cfb466b4150dd3ce2279131c_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/5f193d69cfb466b4150dd3ce2279131c_MD5.png)

对应的集群初始化时指定的参数--pod-network-cidr 192.168.0.0/16

再次查看pod状态

![688a26357a93a290dd6929cce72bfbe0_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/688a26357a93a290dd6929cce72bfbe0_MD5.png)

成功运行




## containerd与docker
containerd 相比于docker , 多了namespace概念, 每个image和container 都会在各自的namespace下可见, 目前k8s会使用k8s.io 作为命名空间,因此在使用ctr命令时一般要使用-n参数指定命名空间

![f2789c5a4edcd83ff6976d3bb2efef22_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/f2789c5a4edcd83ff6976d3bb2efef22_MD5.png)




## 关于flannel的运行状态

日志信息原图找不回了，大概意思是某个ip加端口ping不通，发现是防火墙没关

而后又有新的报错

![9fb0923404b84d4ce394295521861ed6_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/9fb0923404b84d4ce394295521861ed6_MD5.png)

经Al解析得知是因为找不到名为eth0的接口，因为本地的网卡名为ens33，在kube-flannel.yml配置文件中将iface=eth0参数修改为iface=ens33（不修改的话也可以仿openstack搭建前在虚拟机开机时添加参数net.ifnames=0 devbiosname=0,将网卡设置为eth0），且该配置文件中的另一个参数Network要指定为集群初始化时--pod-network-cidr的参数

而后kubeadm reset

再重启配置flannel网络

至此成功搭建了一个完整可用的k8s集群

![11c6ee141827d60d80dcb69fe6d3485c_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/11c6ee141827d60d80dcb69fe6d3485c_MD5.png)

![dce208538ddc7ad50aca9a7b05cd167a_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/dce208538ddc7ad50aca9a7b05cd167a_MD5.png)







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

![5f193d69cfb466b4150dd3ce2279131c_MD5.png](_resources/linux%E7%AC%94%E8%AE%B0/5f193d69cfb466b4150dd3ce2279131c_MD5.png)

该配置也是和--pod-network-cidr所指定的参数相对应的

而后部署flannel并检查pod状态


















# 信创适配及安全管理
## 任务一
主机清单
serverA 192.168.122.10
server1 192.168.122.11
server2 192.168.122.12

### 1.配置DNS主服务器server1
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
[Open: Pasted image 20251221155725.png](_resources/linux%E7%AC%94%E8%AE%B0/31a77f7a80364c9a32c63641f05924c1_MD5.jpg)
![31a77f7a80364c9a32c63641f05924c1_MD5.jpg](_resources/linux%E7%AC%94%E8%AE%B0/31a77f7a80364c9a32c63641f05924c1_MD5.jpg)




### 2.配置 Server2（从 DNS 服务器）
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



### 3.配置ServerA(CA中心与证书颁发)
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


### 4.证书分发
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


### 验证全流程
**验证 DNS 同步**：在 Server2 上能看到 `/var/named/slaves` 下有文件。
**验证 DNS 解析**：`nslookup app1.system.org.cn 192.168.122.12` 能解析出 IP。
**验证证书内容**： 在任意一台机器执行：
`openssl x509 -in /etc/ssl/server-rsa.pem -noout -text | grep DNS`
**成功标志**：输出中包含 `DNS:*.system.org.cn, DNS:system.org.cn`




## 任务二
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




## 任务三
### 1.安装JDK
1.在 x86 麒麟上，我们用 OpenJDK 11 代替毕昇 JDK 11。
`sudo apt update` 
`sudo apt install openjdk-11-jdk -y`
验证
`java -version`

### 2.安装达梦数据库 DM8
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
[Open: Pasted image 20251223114145.png](_resources/linux%E7%AC%94%E8%AE%B0/e7ebc0bdc9a2590df34e9813ce92b481_MD5.jpg)
![e7ebc0bdc9a2590df34e9813ce92b481_MD5.jpg](_resources/linux%E7%AC%94%E8%AE%B0/e7ebc0bdc9a2590df34e9813ce92b481_MD5.jpg)
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
[Open: Pasted image 20251223154228.png](_resources/linux%E7%AC%94%E8%AE%B0/417aba15e5e0031072ae311e3e8ea945_MD5.jpg)
![417aba15e5e0031072ae311e3e8ea945_MD5.jpg](_resources/linux%E7%AC%94%E8%AE%B0/417aba15e5e0031072ae311e3e8ea945_MD5.jpg)
注意修改日志finance_log.txt权限为题目要求的600





## 任务四
### 第一部分：网络内核参数加固
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

### 第二部分：系统访问控制
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
[Open: Pasted image 20251223170557.png](_resources/linux%E7%AC%94%E8%AE%B0/2682450dd30c44dcac1ed4eb255dcb5c_MD5.jpg)
![2682450dd30c44dcac1ed4eb255dcb5c_MD5.jpg](_resources/linux%E7%AC%94%E8%AE%B0/2682450dd30c44dcac1ed4eb255dcb5c_MD5.jpg)
貌似麒麟server_v10版默认就是安全单用户模式，用上图命令测试




### 第三部分：账号与密码策略
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



### 第四部分：SSH 服务加固
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

### 第五部分：Auditd 审计配置
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
[Open: Pasted image 20251223194356.png](_resources/linux%E7%AC%94%E8%AE%B0/116f35fe7335894b2b5ee3abc79ea714_MD5.jpg)
![116f35fe7335894b2b5ee3abc79ea714_MD5.jpg](_resources/linux%E7%AC%94%E8%AE%B0/116f35fe7335894b2b5ee3abc79ea714_MD5.jpg)






