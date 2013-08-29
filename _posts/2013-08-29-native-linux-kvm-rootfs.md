---
layout: post
title: linux rootfs.img 文件的使用
category: linux
tags: rootfs linux kvm
---

文中提到的 rootfs.img 指代 [cloudxy][1] 提供的[domU-x8664-FS.img][2]或[domU-32bit-FS.img][3]。

## rootfs.img 的挂载与卸载

### 方法一

	## 挂载
    $ mkdir rootfs
    $ sudo losetup /dev/loop0 domU-x86_64-FS.img
    $ sudo mount /dev/loop0 rootfs

    ## 卸载
    $ sudo umount rootfs
    $ sudo losetup -d /dev/loop0
    $ rm -rf rootfs

### 方法二

	## 挂载
    $ mkdir rootfs
    $ sudo mount -o loop domU-x86_64-FS.img rootfs/

    ## 卸载
    $ sudo umount rootfs
    $ rm -rf rootfs

## domU-x86_64-FS.img 使用是遇到的问题与处理
下文中需要对文件系统的修改，都需要按照上文提到的方法进行挂载卸载操作，文件系统默认都是挂载到 rootfs 下。

### echo 无法修改 rootfs 中的文件

在使用 domU-x86_64-FS.img 时，遇到 `echo` 无法写文件的问题。网上查了一下，需要通过命令：`set +o noclobber` 进行设置。因为 /etc/profile 中有这么一行： `set -o noclobber` 。 noclobber 这个选项，告诉 bash 在重定向的时候，不要覆盖已有文件。在设定了 noclobber 之后，如何强制覆盖现有文件 `echo hello >| abc`。

### lkvm 运行异常打印处理

使用默认的 domU-x86_64-FS.img ，lkvm 系统启动后，会一直有如下打印：

    ```
        can't open /dev/hvc0: No such file or directory
    ```

将文件系统做如下修改：

    ## 查找配置文件
    $ cd rootfs/etc/
    $ sudo grep -rn hvc ./
    ```
        ./inittab:30:hvc0::respawn:/sbin/getty 38400 hvc0
        ./securetty:20:hvc0
    ```

    ## 修改配置文件
    $ sudo vim inittab +30
    ```
        # hvc0::respawn:/sbin/getty 38400 hvc0    # 直接注释掉
    ```

### 默认挂载 nfs 文件系统

    ## 编辑 domU-x86_64-FS.img 配置脚本
    vim /etc/profile.d/rootfs_config.sh
    ```
        ifconfig eth0 192.168.33.2 netmask 255.255.255.0
        ## 判读 /mnt/tools 是否为空，避免重复挂载
        if [[ "`ls -A /mnt/tools`" = "" ]]; then
            mount -t nfs -o nolock 192.168.33.1:/home/liang/prj/kvm/tools /mnt/tools
        fi
        export PATH=$PATH:/mnt/tools/bin
    ```

用户登入的时候，会执行 `/etc/profile` ， `/etc/profile` 最后有如下语句，因此，上面创建的脚本会被自动执行。

    ```
        for i in /etc/profile.d/*.sh; do
            [[ -f $i ]] && . $i  
    ```

### domU-32bit-FS.img ssh 登陆异常处理

#### 现象描述

    ## 运行 lkvm
    $ sudo ./lkvm  run -d domU-32bit-FS.img --network virtio

    ## 设置虚拟机ip
    # ifconfig eth0 192.168.33.2 netmask 255.255.255.0
    
    ## 主机登陆虚拟机异常
    $ ssh root@192.168.33.2
    ```
        root@192.168.33.2's password: 
        PTY allocation request failed on channel 0
        shell request failed on channel 0
    ```

google 找到答案： [PTY allocation request failed on channel 0 ][4] 。

#### 处理方法一

    ## ssh 登陆后开启交互式 bash
    $ ssh root@192.168.33.2 "/bin/bash -i"
    ```
        root@192.168.33.2's password: 
        bash-3.2# pwd
        /root
        bash-3.2# 
    ```

#### 处理方法二

    ## 虚拟机设置 /dev/pts
    # mkdir /dev/pts 
    # mount -t devpts devpts /dev/pts
    $ ssh root@192.168.33.2
    ```
        root@192.168.33.2's password: 
        % 
    ```

-- EOF --

[1]: https://code.google.com/p/cloudxy/
[2]: https://cloudxy.googlecode.com/files/domU-x86_64-FS.img2.zip
[3]: https://cloudxy.googlecode.com/files/domU-32bit-FS.img.tgz
[4]: http://ejkill.blog.163.com/blog/static/10774945200911135149719/
