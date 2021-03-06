---
layout: post
title: 嵌入式调试过程中交叉编译工具的使用
category: embedded
tags: embedded cross-compile binutils linux
---

本文讲述了嵌入式开发过程中交叉编译工具的使用及实际开发过程中的注意事项，并简单介绍了几个常用二进制工具命令的使用。

## 编译测试程序

一些注意事项：
    
    1. [必须] 不要对执行文件做 strip 符合信息操作，至少做一下备份。 strip 后就找不到函数名了。因为对象文件链接时顺序是不固定的，所以相同源码每次编译出来的结果，一般情况下都是不一样的。
    2. [可选] 去除 -O2 等 gcc 优化选项，
    3. [可选] 编译时添加 -g 选项，-g 选项会在编译程序的时候添加调试信息。
2，3 两个可选项一般情况下，只能在调试定位问题时使用。
上述命令，选项对可执行文件大小产生较大的改变。在嵌入式类，内存敏感的场景调试过程中，还要考虑执行文件大小改变对系统运行的影响。

### 编译选项对执行文件的影响

#### -g 选项

-g 选项会在编译程序的时候添加调试相关的 section 。有了调试 section 对执行文件反汇编后，可以看到 C 代码和汇编代码结合的混合代码。
    
    $ cat gdb_test.c 
    ```
        static void segmentation_fault(void)
        {
            *(int *)0 = 0;
        }
        
        static void func(void)
        {
            segmentation_fault();
        }
        
        int main(int argc, char *argv[])
        {
            func();
        
            return 0;
        }
    ```
    $ arm-linux-uclibcgnueabi-gcc -g -o gdb_test gdb_test.c
    $ arm-linux-uclibcgnueabi-objdump -S gdb_test
    ```
        ... ...
        # 000083c4 是函数起始地址，segmentation_fault 为函数名
        000083c4 <segmentation_fault>:
        static void segmentation_fault(void)
        {
            # 83c4 指令地址， e52db004 为指令码， push {fp} 为 arm 指令， ; (str fp, [sp, #-4]!) 为注释
            83c4:       e52db004        push    {fp}            ; (str fp, [sp, #-4]!)
            83c8:       e28db000        add     fp, sp, #0      ; 0x0
            *(int *)0 = 0;
            83cc:       e3a03000        mov     r3, #0  ; 0x0
            83d0:       e3a02000        mov     r2, #0  ; 0x0
            83d4:       e5832000        str     r2, [r3]
        }
            83d8:       e28bd000        add     sp, fp, #0      ; 0x0
            83dc:       e8bd0800        pop     {fp}
            83e0:       e12fff1e        bx      lr
        
        000083e4 <func>:
        
        static void func(void)
        {
            83e4:       e92d4800        push    {fp, lr}
            83e8:       e28db004        add     fp, sp, #4      ; 0x4
            segmentation_fault();
            83ec:       ebfffff4        bl      83c4 <segmentation_fault>
        }
            83f0:       e8bd8800        pop     {fp, pc}
        
        000083f4 <main>:
        
        int main(int argc, char *argv[])
        {
            83f4:       e92d4800        push    {fp, lr}
            83f8:       e28db004        add     fp, sp, #4      ; 0x4
            83fc:       e24dd008        sub     sp, sp, #8      ; 0x8
            8400:       e50b0008        str     r0, [fp, #-8]
            8404:       e50b100c        str     r1, [fp, #-12]
                func();
            8408:       ebfffff5        bl      83e4 <func>
        
                return 0;
            840c:       e3a03000        mov     r3, #0  ; 0x0
        }
            8410:       e1a00003        mov     r0, r3
            8414:       e24bd004        sub     sp, fp, #4      ; 0x4
            8418:       e8bd8800        pop     {fp, pc}
        ... ...
    ```

通过 readelf 查看到是否添加 -g 选项，对生成可执行文件内容的影响。

    $ arm-linux-uclibcgnueabi-gcc -o gdb_test gdb_test.c    
    $ arm-linux-uclibcgnueabi-readelf -S gdb_test        
    ```
        There are 23 section headers, starting at offset 0x11bc:
        
        Section Headers:
          [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
          [ 0]                   NULL            00000000 000000 000000 00      0   0  0
          [ 1] .interp           PROGBITS        00008134 000134 000014 00   A  0   0  1
          [ 2] .hash             HASH            00008148 000148 00004c 04   A  3   0  4
          [ 3] .dynsym           DYNSYM          00008194 000194 0000e0 10   A  4   1  4
          [ 4] .dynstr           STRTAB          00008274 000274 00007b 00   A  0   0  1
          [ 5] .rel.plt          REL             000082f0 0002f0 000010 08   A  3   7  4
          [ 6] .init             PROGBITS        00008300 000300 000010 00  AX  0   0  4
          [ 7] .plt              PROGBITS        00008310 000310 00002c 04  AX  0   0  4
          [ 8] .text             PROGBITS        0000833c 00033c 0000e0 00  AX  0   0  4
          [ 9] .fini             PROGBITS        0000841c 00041c 000010 00  AX  0   0  4
          [10] .eh_frame         PROGBITS        0000842c 00042c 000004 00   A  0   0  4
          [11] .init_array       INIT_ARRAY      00010f3c 000f3c 000004 00  WA  0   0  4
          [12] .fini_array       FINI_ARRAY      00010f40 000f40 000004 00  WA  0   0  4
          [13] .jcr              PROGBITS        00010f44 000f44 000004 00  WA  0   0  4
          [14] .dynamic          DYNAMIC         00010f48 000f48 0000b8 08  WA  4   0  4
          [15] .got              PROGBITS        00011000 001000 000014 04  WA  0   0  4
          [16] .data             PROGBITS        00011014 001014 000008 00  WA  0   0  4
          [17] .bss              NOBITS          0001101c 00101c 000004 00  WA  0   0  1
          [18] .comment          PROGBITS        00000000 00101c 0000c4 00      0   0  1
          [19] .ARM.attributes   ARM_ATTRIBUTES  00000000 0010e0 00002d 00      0   0  1
          [20] .shstrtab         STRTAB          00000000 00110d 0000ad 00      0   0  1
          [21] .symtab           SYMTAB          00000000 001554 000490 10     22  54  4
          [22] .strtab           STRTAB          00000000 0019e4 0001bb 00      0   0  1
        Key to Flags:
          W (write), A (alloc), X (execute), M (merge), S (strings)
          I (info), L (link order), G (group), x (unknown)
          O (extra OS processing required) o (OS specific), p (processor specific)
    ```
    $ arm-linux-uclibcgnueabi-gcc -g -o gdb_test gdb_test.c 
    $ arm-linux-uclibcgnueabi-readelf -S gdb_test    
    ```       
        There are 31 section headers, starting at offset 0x14fc:
        
        Section Headers:
          [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
          [ 0]                   NULL            00000000 000000 000000 00      0   0  0
          [ 1] .interp           PROGBITS        00008134 000134 000014 00   A  0   0  1
          [ 2] .hash             HASH            00008148 000148 00004c 04   A  3   0  4
          [ 3] .dynsym           DYNSYM          00008194 000194 0000e0 10   A  4   1  4
          [ 4] .dynstr           STRTAB          00008274 000274 00007b 00   A  0   0  1
          [ 5] .rel.plt          REL             000082f0 0002f0 000010 08   A  3   7  4
          [ 6] .init             PROGBITS        00008300 000300 000010 00  AX  0   0  4
          [ 7] .plt              PROGBITS        00008310 000310 00002c 04  AX  0   0  4
          [ 8] .text             PROGBITS        0000833c 00033c 0000e0 00  AX  0   0  4
          [ 9] .fini             PROGBITS        0000841c 00041c 000010 00  AX  0   0  4
          [10] .eh_frame         PROGBITS        0000842c 00042c 000004 00   A  0   0  4
          [11] .init_array       INIT_ARRAY      00010f3c 000f3c 000004 00  WA  0   0  4
          [12] .fini_array       FINI_ARRAY      00010f40 000f40 000004 00  WA  0   0  4
          [13] .jcr              PROGBITS        00010f44 000f44 000004 00  WA  0   0  4
          [14] .dynamic          DYNAMIC         00010f48 000f48 0000b8 08  WA  4   0  4
          [15] .got              PROGBITS        00011000 001000 000014 04  WA  0   0  4
          [16] .data             PROGBITS        00011014 001014 000008 00  WA  0   0  4
          [17] .bss              NOBITS          0001101c 00101c 000004 00  WA  0   0  1
          [18] .comment          PROGBITS        00000000 00101c 0000c4 00      0   0  1
          [19] .debug_aranges    PROGBITS        00000000 0010e0 000020 00      0   0  1
          [20] .debug_pubnames   PROGBITS        00000000 001100 00001b 00      0   0  1
          [21] .debug_info       PROGBITS        00000000 00111b 0000a2 00      0   0  1
          [22] .debug_abbrev     PROGBITS        00000000 0011bd 00006e 00      0   0  1
          [23] .debug_line       PROGBITS        00000000 00122b 000041 00      0   0  1
          [24] .debug_frame      PROGBITS        00000000 00126c 00006c 00      0   0  4
          [25] .debug_str        PROGBITS        00000000 0012d8 000060 01  MS  0   0  1
          [26] .debug_loc        PROGBITS        00000000 001338 000081 00      0   0  1
          [27] .ARM.attributes   ARM_ATTRIBUTES  00000000 0013b9 00002d 00      0   0  1
          [28] .shstrtab         STRTAB          00000000 0013e6 000115 00      0   0  1
          [29] .symtab           SYMTAB          00000000 0019d4 000530 10     30  64  4
          [30] .strtab           STRTAB          00000000 001f04 0001bb 00      0   0  1
        Key to Flags:
          W (write), A (alloc), X (execute), M (merge), S (strings)
          I (info), L (link order), G (group), x (unknown)
          O (extra OS processing required) o (OS specific), p (processor specific)
    ```

带 -g 选项生成的执行文件会变大。

    $ arm-linux-uclibcgnueabi-gcc -o gdb_test gdb_test.c    
    $ ls -lh gdb_test
    ```
        -rwxrwxr-x 1 sfoolish sfoolish 7.0K Apr 19 15:18 gdb_test
    ```
    $ arm-linux-uclibcgnueabi-gcc -g -o gdb_test gdb_test.c 
    $ ls -lh gdb_test
    ```
        -rwxrwxr-x 1 sfoolish sfoolish 8.2K Apr 19 15:18 gdb_test
    ```

#### -O2 选项

gcc -O2 等优化选项可能导致部分函数调用关系被优化，而且优化后的汇编代码更精简也就更难分析(一般情况下也不用看)。
    
    $ arm-linux-uclibcgnueabi-gcc -g -O2 -o gdb_test gdb_test.c 
    $ arm-linux-uclibcgnueabi-objdump -S gdb_test
    ```
        ... ...
        000083c4 <main>:
        static void segmentation_fault(void)
        {
            *(int *)0 = 0;
            83c4:       e3a03000        mov     r3, #0  ; 0x0
        int main(int argc, char *argv[])
        {
                func();
        
                return 0;
        }
            83c8:       e1a00003        mov     r0, r3
        static void segmentation_fault(void)
        {
            *(int *)0 = 0;
            83cc:       e5833000        str     r3, [r3]
        int main(int argc, char *argv[])
        {
                func();
        
                return 0;
        }
            83d0:       e12fff1e        bx      lr
        ... ...
    ```

### strip 对执行文件的影响

用 readelf 查看 strip 对执行文件的影响。

    $ arm-linux-uclibcgnueabi-strip  -s gdb_test
    $ arm-linux-uclibcgnueabi-readelf -S gdb_test                       
    ```
        There are 21 section headers, starting at offset 0x11ac:
        
        Section Headers:
          [Nr] Name              Type            Addr     Off    Size   ES Flg Lk Inf Al
          [ 0]                   NULL            00000000 000000 000000 00      0   0  0
          [ 1] .interp           PROGBITS        00008134 000134 000014 00   A  0   0  1
          [ 2] .hash             HASH            00008148 000148 00004c 04   A  3   0  4
          [ 3] .dynsym           DYNSYM          00008194 000194 0000e0 10   A  4   1  4
          [ 4] .dynstr           STRTAB          00008274 000274 00007b 00   A  0   0  1
          [ 5] .rel.plt          REL             000082f0 0002f0 000010 08   A  3   7  4
          [ 6] .init             PROGBITS        00008300 000300 000010 00  AX  0   0  4
          [ 7] .plt              PROGBITS        00008310 000310 00002c 04  AX  0   0  4
          [ 8] .text             PROGBITS        0000833c 00033c 0000e0 00  AX  0   0  4
          [ 9] .fini             PROGBITS        0000841c 00041c 000010 00  AX  0   0  4
          [10] .eh_frame         PROGBITS        0000842c 00042c 000004 00   A  0   0  4
          [11] .init_array       INIT_ARRAY      00010f3c 000f3c 000004 00  WA  0   0  4
          [12] .fini_array       FINI_ARRAY      00010f40 000f40 000004 00  WA  0   0  4
          [13] .jcr              PROGBITS        00010f44 000f44 000004 00  WA  0   0  4
          [14] .dynamic          DYNAMIC         00010f48 000f48 0000b8 08  WA  4   0  4
          [15] .got              PROGBITS        00011000 001000 000014 04  WA  0   0  4
          [16] .data             PROGBITS        00011014 001014 000008 00  WA  0   0  4
          [17] .bss              NOBITS          0001101c 00101c 000004 00  WA  0   0  1
          [18] .comment          PROGBITS        00000000 00101c 0000c4 00      0   0  1
          [19] .ARM.attributes   ARM_ATTRIBUTES  00000000 0010e0 00002d 00      0   0  1
          [20] .shstrtab         STRTAB          00000000 00110d 00009d 00      0   0  1
        Key to Flags:
          W (write), A (alloc), X (execute), M (merge), S (strings)
          I (info), L (link order), G (group), x (unknown)
          O (extra OS processing required) o (OS specific), p (processor specific)
    ```
    $ ls -lh gdb_test
    ```
        -rwxrwxr-x 1 sfoolish sfoolish 5.3K Apr 19 15:24 gdb_test
    ```

用 nm 查看 strip 对执行文件的影响

    $ arm-linux-uclibcgnueabi-gcc -g -o gdb_test gdb_test.c 
    $ arm-linux-uclibcgnueabi-nm -n gdb_test
    ```
                 w _Jv_RegisterClasses
                 U __uClibc_main
                 U abort
        00008300 T _init
        0000833c T _start
        00008378 t __do_global_dtors_aux
        00008394 t frame_dummy
        # 000083c4 函数起始地址， t static 函数，segmentation_fault 函数名
        000083c4 t segmentation_fault
        000083e4 t func
        # 000083f4 函数起始地址， T global 函数，main 函数名
        000083f4 T main
        0000841c T _fini
        0000842c r __FRAME_END__
        0000842c A __exidx_end
        0000842c A __exidx_start
        00010f3c t __frame_dummy_init_array_entry
        00010f40 t __do_global_dtors_aux_fini_array_entry
        00010f44 d __JCR_END__
        00010f44 d __JCR_LIST__
        00010f48 d _DYNAMIC
        00011000 d _GLOBAL_OFFSET_TABLE_
        00011014 D __data_start
        00011014 W data_start
        00011018 D __dso_handle
        0001101c A __bss_start
        0001101c A __bss_start__
        0001101c A _edata
        0001101c b completed.5309
        00011020 A __bss_end__
        00011020 A __end__
        00011020 A _bss_end__
        00011020 A _end
    ```
    $ arm-linux-uclibcgnueabi-strip -s gdb_test
    $ arm-linux-uclibcgnueabi-nm -n gdb_test                
    ```
        arm-linux-uclibcgnueabi-nm: gdb_test: no symbols
    ```

## 运行测试程序生成 core 文件

    # ulimit -c unlimited
    # echo /mnt/gdb_test.core > /proc/sys/kernel/core_pattern  ;指定 core 生成路径，这步可选
    # ./gdb_test
    ```
        Segmentation fault (core dumped)
    ```
