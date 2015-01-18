---
layout: post
title: python decorator part2(应用场景)
category: python
tags: python decorator
---

## 核心原则

装饰器是一种包装，这意味着你不用修改原有函数，就能够在原函数的前后执行自定义的代码。"Decorators are wrappers which means that they let you execute code before and after the function they decorate without the need to modify the function itself."[1][1]

“当我们遇到需要在执行函数前进行的一些检测或预处理（pre），或者后处理（post），同时这部分操作又可以抽象出来的时候，decorator发挥的时候，就到了！”[2][2]

“decorator的魔力就是它可以对所修饰的函数进行加工。那么这种加工是在不改变原来函数代码的情况下进行的。有点象我知道那么一点点的AOP(面向方面编程)的想法。使用 decorator 可以增加程序的灵活性，降低耦合度，使代码变得简单，清晰。
”[3][3]

## 应用场景

针对 [Understanding Python decorators][1] 中提到的几点找几个实例做一下扩展，以加深对 decorator 的认识。

* Classic uses are extending a function behavior from an external lib (you can't modify it)
* You can use them to extends several functions with the same code without rewriting it every time, for DRY's sake.

### python 自带装饰器

**TODO staticmethod, classmethod, property, etc.**

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

#### cache_page 的使用方法

文档中的简单试用实例

    # https://docs.djangoproject.com/en/dev/topics/cache/#django.views.decorators.cache.cache_page
    from django.views.decorators.cache import cache_page

    @cache_page(60 * 15)
    def my_view(request):
        ...

#### cache_page 的代码实现

    # https://github.com/django/django/blob/1.6b1/django/views/decorators/cache.py#L7
    def cache_page(*args, **kwargs):
        """
        Decorator for views that tries getting the page from the cache and
        populates the cache if the page isn't in the cache yet.
    
        The cache is keyed by the URL and some data from the headers.
        Additionally there is the key prefix that is used to distinguish different
        cache areas in a multi-site setup. You could use the
        sites.get_current_site().domain, for example, as that is unique across a Django
        project.
    
        Additionally, all headers from the response's Vary header will be taken
        into account on caching -- just like the middleware does.
        """
        # We also add some asserts to give better error messages in case people are
        # using other ways to call cache_page that no longer work.
        if len(args) != 1 or callable(args[0]):
            raise TypeError("cache_page has a single mandatory positional argument: timeout")
        cache_timeout = args[0]
        cache_alias = kwargs.pop('cache', None)
        key_prefix = kwargs.pop('key_prefix', None)
        if kwargs:
            raise TypeError("cache_page has two optional keyword arguments: cache and key_prefix")
    
        return decorator_from_middleware_with_args(CacheMiddleware)(cache_timeout=cache_timeout, cache_alias=cache_alias, key_prefix=key_prefix)

    # https://github.com/django/django/blob/1.6b1/django/utils/decorators.py#L47
    def decorator_from_middleware_with_args(middleware_class):
        """
        Like decorator_from_middleware, but returns a function
        that accepts the arguments to be passed to the middleware_class.
        Use like::
    
             cache_page = decorator_from_middleware_with_args(CacheMiddleware)
             # ...
    
             @cache_page(3600)
             def my_view(request):
                 # ...
        """
        return make_middleware_decorator(middleware_class)
    
    # https://github.com/django/django/blob/1.6b1/django/utils/decorators.py#L84
    def make_middleware_decorator(middleware_class):
        def _make_decorator(*m_args, **m_kwargs):
            middleware = middleware_class(*m_args, **m_kwargs)
            def _decorator(view_func):
                @wraps(view_func, assigned=available_attrs(view_func))
                def _wrapped_view(request, *args, **kwargs):
                    if hasattr(middleware, 'process_request'):
                        result = middleware.process_request(request)
                        if result is not None:
                            return result
                    if hasattr(middleware, 'process_view'):
                        result = middleware.process_view(request, view_func, args, kwargs)
                        if result is not None:
                            return result
                    try:
                        response = view_func(request, *args, **kwargs)
                    except Exception as e:
                        if hasattr(middleware, 'process_exception'):
                            result = middleware.process_exception(request, e)
                            if result is not None:
                                return result
                        raise
                    if hasattr(response, 'render') and callable(response.render):
                        if hasattr(middleware, 'process_template_response'):
                            response = middleware.process_template_response(request, response)
                        # Defer running of process_response until after the template
                        # has been rendered:
                        if hasattr(middleware, 'process_response'):
                            callback = lambda response: middleware.process_response(request, response)
                            response.add_post_render_callback(callback)
                    else:
                        if hasattr(middleware, 'process_response'):
                            return middleware.process_response(request, response)
                    return response
                return _wrapped_view
            return _decorator
        return _make_decorator

由 middleware_class 来具体实现做哪些装饰。 对与 cache_page 中的 middleware_class 是 CacheMiddleware ，由于本文只关注 decorator ，这里就不贴 CacheMiddleware 的代码。不过，CacheMiddleware 是个多重继承的好例子，这是题外话另文分析，详见： [TODO](http://TO.DO) 。

---

#### permission_required 使用方法

    # https://docs.djangoproject.com/en/dev/topics/auth/default/#the-permission-required-decorator
    from django.contrib.auth.decorators import permission_required
    
    @permission_required('polls.can_vote', login_url='/loginpage/')
    def my_view(request):
        ...

#### permission_required 的代码实现

    # https://github.com/django/django/blob/1.6b1/django/contrib/auth/decorators.py#L59
    def permission_required(perm, login_url=None, raise_exception=False):
        """
        Decorator for views that checks whether a user has a particular permission
        enabled, redirecting to the log-in page if neccesary.
        If the raise_exception parameter is given the PermissionDenied exception
        is raised.
        """
        def check_perms(user):
            # First check if the user has the permission (even anon users)
            if user.has_perm(perm):
                return True
            # In case the 403 handler should be called raise the exception
            if raise_exception:
                raise PermissionDenied
            # As the last resort, show the login form
            return False
        return user_passes_test(check_perms, login_url=login_url)
    
    # https://github.com/django/django/blob/1.6b1/django/contrib/auth/decorators.py#L14
    def user_passes_test(test_func, login_url=None, redirect_field_name=REDIRECT_FIELD_NAME):
        """
        Decorator for views that checks that the user passes the given test,
        redirecting to the log-in page if necessary. The test should be a callable
        that takes the user object and returns True if the user passes.
        """
    
        def decorator(view_func):
            @wraps(view_func, assigned=available_attrs(view_func))
            def _wrapped_view(request, *args, **kwargs):
                if test_func(request.user):
                    return view_func(request, *args, **kwargs)
                path = request.build_absolute_uri()
                # urlparse chokes on lazy objects in Python 3, force to str
                resolved_login_url = force_str(
                    resolve_url(login_url or settings.LOGIN_URL))
                # If the login url is the same scheme and net location then just
                # use the path as the "next" url.
                login_scheme, login_netloc = urlparse(resolved_login_url)[:2]
                current_scheme, current_netloc = urlparse(path)[:2]
                if ((not login_scheme or login_scheme == current_scheme) and
                    (not login_netloc or login_netloc == current_netloc)):
                    path = request.get_full_path()
                from django.contrib.auth.views import redirect_to_login
                return redirect_to_login(
                    path, resolved_login_url, redirect_field_name)
            return _wrapped_view
        return decorator

### Twisted to fake inlining asynchronous functions calls.

**TODO**

### Tornado 中用来处理异步

#### asynchronous && gen 的使用方法

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

#### asynchronous && gen 的代码实现

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

本文只关注实际代码中都是如何使用和实现 decorator ，代码中的一下几行的进一部分分析详见：[TODO](http://TO.DO)

* `foo = yield tornado.gen.Task(c.get, 'foo')`
* `@functools.wraps(func)`
* `with ExceptionStackContext(handle_exception) as deactivate:`

## REF

* [1. Understanding Python decorators][1]
* [2. 关于Python decorator的应用][2]
* [3. [Python学习]decorator的使用][3]
* [4. 依云 winterpy pylib myutils.py](https://github.com/lilydjwg/winterpy/blob/master/pylib/myutils.py)

-- EOF --

[1]: http://stackoverflow.com/questions/739654/understanding-python-decorators
[2]: http://imtx.me/archives/1706.html
[3]: http://blog.donews.com/limodou/archive/2004/12/19/207521.aspx
