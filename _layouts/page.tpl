<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="utf-8" />
<meta name="author" content="sfoolish" />
<meta name="keywords" content="{{ page.tags | join: ',' }}" />
<title>sfoolish{% if page.title %} / {{ page.title }}{% endif %}</title>
<link href="http://sfoolish.github.com/feed.xml" rel="alternate" title="sfoolish_title" type="application/atom+xml" />
<link rel="stylesheet" type="text/css" href="/assets/css/site.css" />
<link rel="stylesheet" type="text/css" href="/assets/css/code/sunburst.css" />
{% for style in page.styles %}<link rel="stylesheet" type="text/css" href="{{ style }}" />
{% endfor %}
</head>

<body class="{{ page.pageClass }}">

<div class="main">
	{{ content }}

	<footer>
		<p>&copy; Since 2012 <a href="http://github.com/sfoolish" target="_blank">github.com/sfoolish</a></p>
	</footer>
</div>

<side>
	<h2><a href="/">sfoolish</a><a href="/feed.xml" class="feed-link" title="RSS订阅"><img src="http://blog.rexsong.com/wp-content/themes/rexsong/icon_feed.gif" alt="RSS feed" /></a></h2>
	
	<nav class="block">
		<ul>
		{% for category in site.custom.categories %}<li class="{{ category.name }}"><a href="/category/{{ category.name }}/">{{ category.title }}</a></li>
		{% endfor %}
		</ul>
	</nav>
	
	<div class="block block-about">
		<h3>About</h3>
		<figure>
			<figcaption><strong>sfoolish</strong></figcaption>
		</figure>
		<p>又是一码农，单身嘿嘿，爱生活，爱代码，爱折腾。电子信息类专业小本，做过三年多嵌入式开发，准备去做 WEB 后端开发。八月初裸辞，在云南呆了近一个月，目前暂居大理剑川沙溪古镇。<strong>Available for hire</strong>, <a href="/liangqi_resume.html">简历 / RESUME / CV</a> .</p>
	</div>
	
	<a href="http://github.com/sfoolish"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_orange_ff7600.png" alt="Fork me on GitHub"></a>
</side>

<script src="http://elfjs.googlecode.com/files/elf-0.3.3-min.js"></script>
<script src="/assets/js/site.js"></script>
<script src="/assets/js/highlight.pack.js"></script>
<script>hljs.initHighlightingOnLoad();</script>
<!-- <script src="/assets/js/highlight.js"></script>
<script src="/assets/js/hljs/languages/css.js"></script>
<script src="/assets/js/hljs/languages/xml.js"></script>
<script src="/assets/js/hljs/languages/javascript.js"></script> -->
{% for script in page.scripts %}<script src="{{ script }}"></script>
{% endfor %}

</body>
</html>