---
layout: post
title: python decorator part2(应用场景)
category: python
tags: python decorator
---

## 核心原则

"Decorators are wrappers which means that they let you execute code before and after the function they decorate without the need to modify the function itself." - - - [Understanding Python decorators][1]

“当我们遇到需要在执行函数前进行的一些检测或预处理（pre），或者后处理（post），同时这部分操作又可以抽象出来的时候，decorator发挥的时候，就到了！” - - - [关于Python decorator的应用][2]

“decorator的魔力就是它可以对所修饰的函数进行加工。那么这种加工是在不改变原来函数代码的情况下进行的。有点象我知道那么一点点的AOP(面向方面编程)的想法。使用 decorator 可以增加程序的灵活性，降低耦合度，使代码变得简单，清晰。
” - - - [[Python学习]decorator的使用][3]

## 应用场景

针对 [Understanding Python decorators][1] 中提到的几点找几个实例做一下扩展，以加深对 decorator 的认识。

### Classic uses are extending a function behavior from an external lib (you can't modify it)

### You can use them to extends several functions with the same code without rewriting it every time, for DRY's sake.

### python 本身提供的 staticmethod, classmethod, property, etc.

**TODO**

### For a debug purpose (you don't want to modify it because it's temporary). 

    # https://github.com/lilydjwg/winterpy/blob/master/pylib/myutils.py
    def debugfunc(logger=logging, *, _id=[0]):
        def w(func):
            @wraps(func)
            def wrapper(*args, **kwargs):
                myid = _id[0]
                _id[0] += 1
                logger.debug('[func %d] %s(%r, %r)', myid, func.__name__, args, kwargs)
                ret = func(*args, **kwargs)
                logger.debug('[func %d] return: %r', myid, ret)
                return ret
            return wrapper
        return w

### Django use decorators to manage caching and view permissions. 

**TODO**

### Twisted to fake inlining asynchronous functions calls.

**TODO**

### Tornado 中用来处理异步

    # https://github.com/leporo/tornado-redis/blob/master/demos/simple/app.py#L14
    class MainHandler(tornado.web.RequestHandler):

    @tornado.web.asynchronous
    @tornado.gen.engine
    def get(self):
        c = tornadoredis.Client()
        foo = yield tornado.gen.Task(c.get, 'foo')
        bar = yield tornado.gen.Task(c.get, 'bar')
        zar = yield tornado.gen.Task(c.get, 'zar')
        self.set_header('Content-Type', 'text/html')
        self.render("template.html", title="Simple demo",
                    foo=foo, bar=bar, zar=zar)

    # https://github.com/facebook/tornado/blob/v2.4.1/tornado/web.py#L1113
    def asynchronous(method):
    """Wrap request handler methods with this if they are asynchronous.

    If this decorator is given, the response is not finished when the
    method returns. It is up to the request handler to call self.finish()
    to finish the HTTP request. Without this decorator, the request is
    automatically finished when the get() or post() method returns. ::

       class MyRequestHandler(web.RequestHandler):
           @web.asynchronous
           def get(self):
              http = httpclient.AsyncHTTPClient()
              http.fetch("http://friendfeed.com/", self._on_download)

           def _on_download(self, response):
              self.write("Downloaded!")
              self.finish()

    """
    @functools.wraps(method)
    def wrapper(self, *args, **kwargs):
        if self.application._wsgi:
            raise Exception("@asynchronous is not supported for WSGI apps")
        self._auto_finish = False
        with stack_context.ExceptionStackContext(
            self._stack_context_handle_exception):
            return method(self, *args, **kwargs)
    return wrapper

    # https://github.com/facebook/tornado/blob/v2.4.1/tornado/gen.py#L91
    def engine(func):
    """Decorator for asynchronous generators.

    Any generator that yields objects from this module must be wrapped
    in this decorator.  The decorator only works on functions that are
    already asynchronous.  For `~tornado.web.RequestHandler`
    ``get``/``post``/etc methods, this means that both the
    `tornado.web.asynchronous` and `tornado.gen.engine` decorators
    must be used (for proper exception handling, ``asynchronous``
    should come before ``gen.engine``).  In most other cases, it means
    that it doesn't make sense to use ``gen.engine`` on functions that
    don't already take a callback argument.
    """
    @functools.wraps(func)
    def wrapper(*args, **kwargs):
        runner = None

        def handle_exception(typ, value, tb):
            # if the function throws an exception before its first "yield"
            # (or is not a generator at all), the Runner won't exist yet.
            # However, in that case we haven't reached anything asynchronous
            # yet, so we can just let the exception propagate.
            if runner is not None:
                return runner.handle_exception(typ, value, tb)
            return False
        with ExceptionStackContext(handle_exception) as deactivate:
            gen = func(*args, **kwargs)
            if isinstance(gen, types.GeneratorType):
                runner = Runner(gen, deactivate)
                runner.run()
                return
            assert gen is None, gen
            deactivate()
            # no yield, so we're done
    return wrapper

本文只关注实际代码中都是如何使用 decorator ，代码中的一下几行的进一部分分析详见：[TODO](http://TO.DO)

* `foo = yield tornado.gen.Task(c.get, 'foo')`
* `@functools.wraps(func)`
* `with ExceptionStackContext(handle_exception) as deactivate:`

## REF

* [Understanding Python decorators][1]
* [关于Python decorator的应用][2]
* [[Python学习]decorator的使用][3]
* [依云 winterpy pylib myutils.py](https://github.com/lilydjwg/winterpy/blob/master/pylib/myutils.py)

-- EOF --

[1]: http://stackoverflow.com/questions/739654/understanding-python-decorators
[2]: http://imtx.me/archives/1706.html
[3]: http://blog.donews.com/limodou/archive/2004/12/19/207521.aspx
