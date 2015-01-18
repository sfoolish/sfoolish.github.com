---
layout: post
title: python with 及 contextlib 的用法
category: python
tags: python Basic
---

## with 语句

在日常编码过程中，经常用到的 `with` 场景是打开文件进行文件处理，然后隐式地将文件句柄的关闭（同样适合socket操作）。过程类似如下：

    with file('test.py','r') as f :
        print f.readline()

`with` 作用，类似 `try...finally...` ，提供一种上下文机制。要使用 `with` 语句的类，其内部必须提供两个内置函数 `__enter__` 以及 `__exit__` ，前者在主体代码执行前执行，后则在主体代码执行后执行。上面实例代码中， `as` 后面的变量 `f` ，是在 `__enter__` 函数中返回的。通过下面这个代码片段以及注释说明，可以清晰明白 `__enter__` 与 `__exit__` 的用法：

    #!encoding:utf-8
    class echo :
        def output(self) :
            print 'hello world'
        def __enter__(self):
            print 'enter'
            return self #返回自身实例，当然也可以返回任何希望返回的东西
        def __exit__(self, exception_type, exception_value, exception_traceback):
            #若发生异常，会在这里捕捉到，可以进行异常处理
            print 'exit'
            #如果改__exit__可以处理改异常则通过返回True告知该异常不必传播，否则返回False
            if exception_type == ValueError :
                return True
            else:
                return False
      
    with echo() as e:
        e.output()
        print 'do something inside'
    print '-----------'
    with echo() as e:
        raise ValueError('value error')
    print '-----------'
    with echo() as e:
        raise Exception('can not detect')

运行结果：

    enter
    hello world
    do something inside
    exit
    -----------
    enter
    exit
    -----------
    enter
    exit
    Traceback (most recent call last):
      File "tmp.py", line 25, in <module>
        raise Exception('can not detect')
    Exception: can not detect

## contextlib 库

`contextlib` 是为了加强 `with` 语句，提供上下文机制的模块，它是通过 `Generator` 实现的。通过定义类并实现 `__enter__` 和 `__exit__` 来进行上下文管理虽然不难，但是过程很繁琐。`contextlib` 中的 `contextmanager` 作为装饰器来提供一种针对函数级别的上下文管理机制。常用框架如下：
    
    #!encoding:utf-8
    from contextlib import contextmanager
      
    @contextmanager
    def make_context() :
        print 'enter'
        try :
            yield 'hello'
        except RuntimeError, err :
            print 'error' , err
        finally :
            print 'exit'
      
    with make_context() as value :
        print value
    
    @contextmanager
    def make_context(name) :
        print 'enter', name
        yield name
        print 'exit', name
    # 嵌套
    with make_context('A') as a, make_context('B') as b :
        print a
        print b

运行结果：
    
    enter
    hello
    exit
    enter A
    enter B
    A
    B
    exit B
    exit A

## REF

* [python中关于with及contextlib的用法](http://www.cnblogs.com/coser/archive/2013/01/28/2880328.html)
* [contextlib - Utilities for with-statement contexts](https://docs.python.org/2/library/contextlib.html)
* [contextlib 在 Openstack Neutron 代码中的应用](https://github.com/openstack/neutron/commit/323c210d5db60887b37724e03a9a303d9ceb9fe1)
