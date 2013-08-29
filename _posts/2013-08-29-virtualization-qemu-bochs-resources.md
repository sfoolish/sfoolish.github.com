---
layout: post
title: 虚拟化相关文章收藏
category: linux
tags: virtualization kvm qemu bochs linux
---

## qemu mac osx 10.6 下编译

    $ ./configure --disable-aio --disable-kvm  --disable-sdl --target-list=i386-softmmu --disable-sdl --prefix=/Users/apple/APP_PRJ/e_vm/qemu/install
    $ make -j4
    $ make install
    $ wget http://wiki.qemu.org/download/linux-0.2.img.bz2
    $ ./qemu linux-0.2.img

在 qemu 中按 ctrl+alt+2 切换到qemu monitor模式，ctrl-alt 主机/虚拟机鼠标切换。

### REF

* [qemu compilation](http://qemu.weilnetz.de/qemu-doc.html#compilation)
The Mac OS X patches are not fully merged in QEMU, so you should look at the QEMU mailing list archive to have all the necessary information. 
* [How to install Qemu on MAC OSX 10.6 & 10.7](http://forum.gns3.net/topic4600.html)
* [QEMU/Monitor](http://en.wikibooks.org/wiki/QEMU/Monitor)
The monitor is accessed from within QEMU by holding down the Control and Alt keys, and pressing Shift-2. Once in the monitor, Shift-1 switches back to the guest OS.

## 虚拟化相关链接

* [Comparison of platform virtual machines](http://en.wikipedia.org/wiki/Comparison_of_platform_virtual_machines)
* [KVM虚拟化原理与实践（连载）](http://smilejay.com/kvm_theory_practice/)
* [Virtual Development Board](http://www.elinux.org/Virtual_Development_Board)

## qemu 相关链接

* [qemu](http://wiki.qemu.org)
* [qemu-github](https://github.com/qemu/QEMU)
* [qemu-wiki](http://wiki.qemu.org/Links)
* [使用 QEMU 进行系统仿真](http://www.ibm.com/developerworks/cn/linux/l-qemu/)

## bochs 相关链接

* [Bochs 简介及配置](http://www.cppblog.com/coreBugZJ/archive/2011/04/03/143334.aspx)
* [如何在macosx上通过源码安装bochs2.4.6并使用peter-bochs进行调试](http://blog.csdn.net/bigstaff/article/details/6311926)
* [oldlinux bochs](http://oldlinux.org/Linux.old/)
