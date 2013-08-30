---
layout: post
title: python closure part1
category: python
tags: python closure
---

## 自己写的第一个 python 闭包

闭包之前在 javascript 中用过，写一个还不简单上代码：

    #!/usr/bin/env python
    def closure_counter():
        count = 0
        def counter():
            count += 1
            print count
    
        return counter
    counter1 = closure_counter()
    counter1()
    counter1()
    counter2 = closure_counter()
    counter2()
    counter2()
    ``` output
    Traceback (most recent call last):
      File "./closure_test.py", line 11, in <module>
        counter1()
      File "./closure_test.py", line 6, in counter
        count += 1
    UnboundLocalError: local variable 'count' referenced before assignment
    ```

我错了，怎么会这样。万能的 google/stackoverflow 救救我吧。 [Can you explain closures (as they relate to Python)?][1] 中的一个示例代码用 `nonlocal` 解决上面的问题，但是 `nonlocal` 是 python 3.0 引入的 python 2.7 不支持。还好 [Python Closures and the Python 2.7 nonlocal Solution][2] 提供了解决方法。
    
    def outer():
        d = {'y' : 0}
        def inner():
            d['y'] += 1
            return d['y']
        return inner

"it’s kinda weird that we can’t access the non local variable but we can access the dictionary." 是啊，太怪了，局部变量不行，字典却可以，具体原因待查待补充。

## python closure counter 最终版本

通过字典这个解决方法看上去还是挺变扭的，想到 [Understanding Python decorators][3] 中有段例代码，一个 counter decorator 用到了闭包。

    #!/usr/bin/env python
    def closure_counter():
        def counter():
            counter.count += 1
            return counter.count
        counter.count = 0
        return counter
    
    c1 = closure_counter()
    c2 = closure_counter()
    print (c1(), c1(), c2(), c2())
    ``` output
    (1, 2, 1, 2)
    ```

## 总结

原始版本跟最终版本相比，不说其中的错误，只说代码本身，测试代码更简洁，原始版本中还把 print 嵌入到功能代码中。代码是码出来的看看是不够的，要多码码，多跑跑，多比比 -:) 。

## REF
* [Can you explain closures (as they relate to Python)?][1]
* [Python Closures and the Python 2.7 nonlocal Solution][2]
* [Understanding Python decorators][3]

--EOF--

[1]: http://stackoverflow.com/questions/13857/can-you-explain-closures-as-they-relate-to-python
[2]: http://technotroph.wordpress.com/2012/10/01/python-closures-and-the-python-2-7-nonlocal-solution/
[3]: http://stackoverflow.com/questions/739654/understanding-python-decorators
