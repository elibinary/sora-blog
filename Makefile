deploy:
	hexo generate
	hexo generate
	hexo generate
	cp CNAME public
	hexo deploy