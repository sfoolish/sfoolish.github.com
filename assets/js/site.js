///import js.dom.INodeEvent;
///import elf.~shortcut.~dispatcher.string;
///import elf.~shortcut.~dispatcher.function;
///import elf.~shortcut.loadScript;
///import elf.~shortcut.template;
///import elf.~shortcut.ajax;
///import elf.~namespace.URL;

var site = {
	InitMap: {
		list: function () {
			elf('#List>.article>h2').on('click', site.Handlers.loadArticle);
		},
		
		search: function () {
			elf.dom.Stage.loadScript('http://www.google.com/jsapi', {
				onLoad: function () {
					google.load('search', '1', {
						language: 'zh-CN',
						style: google.loader.themes.V2_DEFAULT,
						callback: function() {
							var customSearchControl = new google.search.CustomSearchControl('000346898720731947188:13h55x32l0y', {});
							customSearchControl.setResultSetSize(google.search.Search.FILTERED_CSE_RESULTSET);
							
							var options = new google.search.DrawOptions();
							options.setAutoComplete(true);
							customSearchControl.draw('cse', options);
							
							var url = new elf.URL(location);
							var query = url.getParameter('q');
							if (query) {
								document.title = elf().template(site.Text.TPL_SEARCH_TITLE, query);
								customSearchControl.execute(query);
							}
						}
					});
				}
			});
		},
	},
	
	Handlers: {
		loadArticle: function (ev) {
			var target = ev.target,
				item = elf(target).parent();
			if (target.nodeName != 'A' && item.attr('data-loaded') != 1) {
				elf().ajax({
					url: target.firstChild.getAttribute('href'),
					onsuccess: site.Handlers.showAjaxContent.bind(item)
				});
			}
			target = null;
		},
		
		showAjaxContent: function (response) {
			var content = response.split('<p class="article-meta">')[1].split('</p>');
			content.shift();
			content = content.join('</p>').split(/<\/div>\s*<div id="disqus_thread" class="doc-comments">/)[0];
			this.query('>div.article').html(content);
			this.attr('data-loaded', 1);
		}
	},
	
	Text: {
		TPL_SEARCH_TITLE: 'sfoolish / search：#{0}'
	}
};


elf(function () {
	elf('pre').forEach(function (item) {
		hljs.highlightBlock(item);
	});
	
	var module = document.body.className.replace(/page-type-/g, '').split(' ');
	module.forEach(function (item) {
		var initer = site.InitMap[item];
		initer && elf(initer);
	});
});
