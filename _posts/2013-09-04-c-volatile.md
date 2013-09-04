---
layout: post
title: C 语言之 volatile
category: embedded
tags: volatile embedded linux
---

## 原理及使用场景

volatile 字面意思是“易变”，起的作用是避免编译器在编译过程中优化，使每次都能“直接存取原始内存地址”。
使用场景：

    * 并行设备的硬件寄存器；
    * 一个中断服务子程序中会访问到的非自动变量（全局变量）；
    * 多线程应用中被几个任务共享的变量；

## volatile 对编译过程的的影响

### 编译及反汇编命令

    $ arm-linux-uclibcgnueabi-gcc -O2  volatile_test.c -o volatile_test
    $ arm-linux-uclibcgnueabi-objdump -d volatile_test

### 测试程序及反汇编结果

    int main()
    {
        int a;
        *(volatile int *)&a = 0x5a;
        *(volatile int *)&a = 0x5a;
    }
    000083c4 <main>:
        83c4:       e24dd008        sub     sp, sp, #8      ; 0x8
        83c8:       e3a0305a        mov     r3, #90 ; 0x5a
        83cc:       e58d3004        str     r3, [sp, #4]
        83d0:       e58d3004        str     r3, [sp, #4]
        83d4:       e28dd008        add     sp, sp, #8      ; 0x8
        83d8:       e12fff1e        bx      lr
     
    int main()
    {
        int a;
        *(int *)&a = 0x5a;
        *(volatile int *)&a = 0x5a;
    }
    000083c4 <main>:
        83c4:       e24dd008        sub     sp, sp, #8      ; 0x8
        83c8:       e3a0305a        mov     r3, #90 ; 0x5a
        83cc:       e58d3004        str     r3, [sp, #4]
        83d0:       e28dd008        add     sp, sp, #8      ; 0x8
        83d4:       e12fff1e        bx      lr
    
    int main()
    {
        int a;
        *(int *)&a = 0x5a;
        *(int *)&a = 0x5a;
    }
    000083c4 <main>:
        83c4:       e12fff1e        bx      lr

从反汇编结果来看，如果没有使用 volatile 一些逻辑上冗余的代码在编译期间可能被编译器优化掉。在 C 开发过程，一些不能被优化的赋值/取值操作一定要注意 volatile 的使用，否则极有可能留下非常诡异的 bug 。