---
layout: post
title: python decorator part1
category: python
tags: python decorator
---

下文只是对 stackoverflow 上关于 python decorator 的经典问答 [Understanding Python decorators][1] 的简要摘录，用作备忘。

### 问题

How can I make two decorators in Python that would do the following.

	@makebold
	@makeitalic
	def say():
	   return "Hello"

which should return

	<b><i>Hello</i></b>

### 答案

    def makebold(fn):
        def wrapped():
            return "<b>" + fn() + "</b>"
        return wrapped
    
    def makeitalic(fn):
        def wrapped():
            return "<i>" + fn() + "</i>"
        return wrapped
    
    @makebold
    @makeitalic
    def hello():
        return "hello world"
    
    print hello() ## returns <b><i>hello world</i></b>

### 原理解析

To understand decorators, you must first understand that functions are objects in Python. This has important consequences. Functions are objects and therefore: 

* can be assigned to a variable;
* can be defined in another function.

Well, that means that a function can return another function.

*Decorators are wrappers which means that they let you execute code before and after the function they decorate without the need to modify the function itself.*

#### Handcrafted decorators && Decorators demystified

    def my_shiny_new_decorator(a_function_to_decorate):
        def the_wrapper_around_the_original_function():
            print "Before the function runs"
            a_function_to_decorate()
            print "After the function runs"
    
        return the_wrapper_around_the_original_function
    
    def a_stand_alone_function():
        print "I am a stand alone function, don't you dare modify me"
    
    a_stand_alone_function() 
    #outputs: I am a stand alone function, don't you dare modify me
    
    a_stand_alone_function = my_shiny_new_decorator(a_stand_alone_function)
    a_stand_alone_function()
    #outputs:
    #Before the function runs
    #I am a stand alone function, don't you dare modify me
    #After the function runs
    
    @my_shiny_new_decorator
    def another_stand_alone_function():
        print "Leave me alone"
    
    another_stand_alone_function()
    #outputs:  
    #Before the function runs
    #Leave me alone
    #After the function runs

@decorator is just a shortcut to:

	another_stand_alone_function = my_shiny_new_decorator(another_stand_alone_function)

Decorators are just a pythonic variant of the [decorator design pattern](http://en.wikipedia.org/wiki/Decorator_pattern).

You can cumulate decorators. The order you set the decorators MATTERS. 原文例子太长，引用 Python-2.7.3/Doc/whatsnew/2.4.rst 中的一段描述：

More generally, if you have the following::
    
        @A
        @B
        @C
        def f ():
            ...
    
It's equivalent to the following pre-decorator code::
    
        def f(): ...
        f = A(B(C(f)))

#### Passing arguments to the decorated function && Decorating methods

What's great with Python is that methods and functions are really the same, except methods expect their first parameter to be a reference to the current object (self). It means you can build a decorator for methods the same way, just remember to take self in consideration.

    def a_decorator_passing_arbitrary_arguments(function_to_decorate):
        # The wrapper accepts any arguments
        def a_wrapper_accepting_arbitrary_arguments(*args, **kwargs):
            print "Do I have args?:"
            print args
            print kwargs
            function_to_decorate(*args, **kwargs)
        return a_wrapper_accepting_arbitrary_arguments
    
    class Mary(object):
    
        def __init__(self):
            self.age = 31
    
        @a_decorator_passing_arbitrary_arguments
        def sayYourAge(self, lie=-3): # You can now add a default value
            print "I am %s, what did you think ?" % (self.age + lie)
    
    m = Mary()
    m.sayYourAge()
    #outputs
    # Do I have args?:
    #(<__main__.Mary object at 0xb7d303ac>,)
    #{}
    #I am 28, what did you think?

#### Passing arguments to the decorator
    
    def decorator_maker_with_arguments(decorator_arg1, decorator_arg2):
    
        print "I make decorators! And I accept arguments:", decorator_arg1, decorator_arg2
    
        def my_decorator(func):
            # The ability to pass arguments here is a gift from closures.
            # If you are not comfortable with closures, you can assume it's ok,
            # or read: http://stackoverflow.com/questions/13857/can-you-explain-closures-as-they-relate-to-python
            print "I am the decorator. Somehow you passed me arguments:", decorator_arg1, decorator_arg2
    
            # Don't confuse decorator arguments and function arguments!
            def wrapped(function_arg1, function_arg2) :
                print ("I am the wrapper around the decorated function.\n"
                      "I can access all the variables\n"
                      "\t- from the decorator: {0} {1}\n"
                      "\t- from the function call: {2} {3}\n"
                      "Then I can pass them to the decorated function"
                      .format(decorator_arg1, decorator_arg2,
                              function_arg1, function_arg2))
                return func(function_arg1, function_arg2)
    
            return wrapped
    
        return my_decorator
    
    @decorator_maker_with_arguments("Leonard", "Sheldon")
    def decorated_function_with_arguments(function_arg1, function_arg2):
        print ("I am the decorated function and only knows about my arguments: {0}"
               " {1}".format(function_arg1, function_arg2))
    


    c1 = "Penny"
    c2 = "Leslie"
    
    @decorator_maker_with_arguments("Leonard", c1)
    def decorated_function_with_arguments(function_arg1, function_arg2):
        print ("I am the decorated function and only knows about my arguments:"
               " {0} {1}".format(function_arg1, function_arg2))
    
    decorated_function_with_arguments(c2, "Howard")
    #outputs:
    #I make decorators! And I accept arguments: Leonard Penny
    #I am the decorator. Somehow you passed me arguments: Leonard Penny
    #I am the wrapper around the decorated function. 
    #I can access all the variables 
    #   - from the decorator: Leonard Penny 
    #   - from the function call: Leslie Howard 
    #Then I can pass them to the decorated function
    #I am the decorated function and only knows about my arguments: Leslie Howard

As you can see, you can pass arguments to the decorator like any function using this trick. You can even use `*args, **kwargs` if you wish. But remember decorators are called *only once*. Just when Python imports the script. You can't dynamically set the arguments afterwards. When you do "import x", *the function is already decorated*, so you can't change anything.

#### Let's practice: a decorator to decorate a decorator

	def decorator_with_args(decorator_to_enhance):
        def decorator_maker(*args, **kwargs):
            def decorator_wrapper(func):
                return decorator_to_enhance(func, *args, **kwargs)
    
            return decorator_wrapper
    
        return decorator_maker

    @decorator_with_args 
    def decorated_decorator(func, *args, **kwargs): 
        def wrapper(function_arg1, function_arg2):
            print "Decorated with", args, kwargs
            return func(function_arg1, function_arg2)
        return wrapper
    
    # Then you decorate the functions you wish with your brand new decorated decorator.
    
    @decorated_decorator(42, 404, 1024)
    def decorated_function(function_arg1, function_arg2):
        print "Hello", function_arg1, function_arg2
    
    decorated_function("Universe and", "everything")
    #outputs:
    #Decorated with (42, 404, 1024) {}
    #Hello Universe and everything
    
    # Whoooot!

I know, the last time you had this feeling, it was after listening a guy saying: "before understanding recursion, you must first understand recursion". But now, don't you feel good about mastering this?

#### Best practices while using decorators

* They are new as of Python 2.4, so be sure that's what your code is running on.
* Decorators slow down the function call. Keep that in mind.
* You can not un-decorate a function. There are hacks to create decorators that can be removed but nobody uses them. So once a function is decorated, it's done. For all the code.
* Decorators wrap functions, which can make them hard to debug.

Python 2.5 solves this last issue by providing the functools module including functools.wraps that copies the name, module and docstring of any wrapped function to it's wrapper. Fun fact, functools.wraps is a decorator :-)

#### How can the decorators be useful?

Now the big question: what can I use decorators for? Seem cool and powerful, but a practical example would be great. Well, there are 1000 possibilities. Classic uses are extending a function behavior from an external lib (you can't modify it) or for a debug purpose (you don't want to modify it because it's temporary). You can use them to extends several functions with the same code without rewriting it every time, for DRY's sake. E.g.:

    def benchmark(func):
        """
        A decorator that prints the time a function takes
        to execute.
        """
        import time
        def wrapper(*args, **kwargs):
            t = time.clock()
            res = func(*args, **kwargs)
            print func.__name__, time.clock()-t
            return res
        return wrapper
    
    
    def logging(func):
        """
        A decorator that logs the activity of the script.
        (it actually just prints it, but it could be logging!)
        """
        def wrapper(*args, **kwargs):
            res = func(*args, **kwargs)
            print func.__name__, args, kwargs
            return res
        return wrapper
    
    
    def counter(func):
        """
        A decorator that counts and prints the number of times a function has been executed
        """
        def wrapper(*args, **kwargs):
            wrapper.count = wrapper.count + 1
            res = func(*args, **kwargs)
            print "{0} has been used: {1}x".format(func.__name__, wrapper.count)
            return res
        wrapper.count = 0
        return wrapper
    
    @counter
    @benchmark
    @logging
    def reverse_string(string):
        return str(reversed(string))
    
    print reverse_string("Able was I ere I saw Elba")
    print reverse_string("A man, a plan, a canoe, pasta, heros, rajahs, a coloratura, maps, snipe, percale, macaroni, a gag, a banana bag, a tan, a tag, a banana bag again (or a camel), a crepe, pins, Spam, a rut, a Rolo, cash, a jar, sore hats, a peon, a canal: Panama!")
    
    #outputs:
    #reverse_string ('Able was I ere I saw Elba',) {}
    #wrapper 0.0
    #wrapper has been used: 1x 
    #ablE was I ere I saw elbA
    #reverse_string ('A man, a plan, a canoe, pasta, heros, rajahs, a coloratura, maps, snipe, percale, macaroni, a gag, a banana bag, a tan, a tag, a banana bag again (or a camel), a crepe, pins, Spam, a rut, a Rolo, cash, a jar, sore hats, a peon, a canal: Panama!',) {}
    #wrapper 0.0
    #wrapper has been used: 2x
    #!amanaP :lanac a ,noep a ,stah eros ,raj a ,hsac ,oloR a ,tur a ,mapS ,snip ,eperc a ,)lemac a ro( niaga gab ananab a ,gat a ,nat a ,gab ananab a ,gag a ,inoracam ,elacrep ,epins ,spam ,arutaroloc a ,shajar ,soreh ,atsap ,eonac a ,nalp a ,nam A

Python itself provides several decorators: property, staticmethod, etc. Django use decorators to manage caching and view permissions. Twisted to fake inlining asynchronous functions calls. This really is a large playground.

## REF
* [Understanding Python decorators][1]
* [PEP 318 -- Decorators for Functions and Methods](http://www.python.org/dev/peps/pep-0318/)

-- EOF --

[1]: http://stackoverflow.com/questions/739654/understanding-python-decorators
