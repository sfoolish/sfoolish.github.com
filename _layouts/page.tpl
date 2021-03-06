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
	<h2><a href="/">sfoolish</a></h2>
	
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
		<p>爱生活，爱代码，爱折腾。。。</p>
	</div>
	
	<!--a href="http://github.com/sfoolish"><img style="position: absolute; top: 0; right: 0; border: 0;" src="/assets/css/pic/forkme_right_orange_ff7600.png" alt="Fork me on GitHub"></a-->
</side>

<script src="/assets/js/elf-0.3.3-min.js"></script>
<script src="/assets/js/site.js"></script>
<script src="/assets/js/highlight.pack.js"></script>
<script src="/assets/js/jquery-1.11.2.min.js"></script>
<script>hljs.initHighlightingOnLoad();</script>
<!-- <script src="/assets/js/highlight.js"></script>
<script src="/assets/js/hljs/languages/css.js"></script>
<script src="/assets/js/hljs/languages/xml.js"></script>
<script src="/assets/js/hljs/languages/javascript.js"></script> -->
{% for script in page.scripts %}<script src="{{ script }}"></script>
{% endfor %}

</body>
</html>