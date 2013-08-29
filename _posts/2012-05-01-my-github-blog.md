---
layout: post
title: my github blog
category: tools
tags: github markdown
---

#### jekyll使用
    $ gem install jekyll
    $ git clone https://github.com/mytharcher/mytharcher.github.com.git
    $ cd mytharcher.github.com.git && mkdir _site
    $ jekyll --server 

####blog 分类创建
* _config.yml 添加配置
* category 文件夹创建相应文件夹，及index.html文件
* 删除_site文件夹，否则本地测试时，新创建的分类无法生效

####highlight样式修改
    edit:_layouts/page.tpl
    <link rel="stylesheet" type="text/css" href="/assets/css/code/sunburst.css" />

####code
    int main(void) 
    {
        printf("hello world\n");
        return 0;
    }

####REF
* [闭门造轮子]
* [使用github作为博客引擎]
* [install jekyll]


-EOF-

[闭门造轮子]:http://mytharcher.github.com/
[使用github作为博客引擎]:http://blog.leezhong.com/tech/2010/08/25/make-github-as-blog-engine.html
[install jekyll]:http://ruby-china.org/topics/636