---
title: 关于Rails视图渲染
date: 2017-02-11 14:25:22
tags: 
  - Rails
description: 本文主要说一下 controller 到 view 的操作 
---

controller 创建 HTTP 响应的方法有三种：
1. render 向浏览器发送完整的响应
2. redirect_to 向浏览器发送 HTTP 重定向状态码
3. head 向浏览器发送只有 header 信息的响应

首先，如果你在 action 的最后没有显式的调用响应方法，Rails会根据约定去渲染该 action 对应路由的 view，这个我们在开发中很常见就不多说了。

### render

在日常开发中， render 方法是非常非常常用的渲染手段，它可以达成各种各样的效果，不管是 text、json 还是 xml

* 开发web应用时，可以用它来渲染页面
```
render 'show'
# or
render :show
# or
render action: 'show'
```
注意不管是使用 string 还是 symbol 都是可以的。

* 渲染 json
```
render json: {}
```

* 渲染 xml
```
render xml: <<-XML
              <hash>
                <age type="integer">1</age>
                <height type="integer">2</height>
              </hash>
            XML
```
说到 xml ，Rails 实现了 Hash#from_xml 方法用来非常方便的帮助你解析 xml ，比如这样
```
xml = <<-XML
          <hash>
            <age type="integer">1</age>
            <height type="integer">2</height>
          </hash>
        XML
        
hash = Hash.from_xml(xml)
# => {"hash"=>{"age"=>1, "height"=>2}}
```
超简单方便

* 渲染 js
```
render js: "alert('hi, man');"
```

* 渲染纯文本
有时我们会有需要返回一段纯文本给 client ,这时就可以这样
```
render plain: "lalalalalalala"
```

* 渲染 html 片段
有时候你还可以渲染一段 html 代码片段给 client
```
render html: "<strong>Not Found</strong>".html_safe
```

### head
使用 head 方法只会返回 header 信息给 client，比如这样
```
head :bad_request
```
就将返回一个没有任何 body 的 400 response，效果等同于
```
render nothing: true, status: 400
```

也可以用其附加一些 header 信息，如这样
```
head :created, app-vertion: '1.1.1'
```

至于最后一种方法 redirect_to ，它用来告诉浏览器转向另一个新的地址，这里注意它并不是一种类似于 goto 的指令，他只是发新的地址返回给浏览器，同时返回 302 状态码告诉浏览器向这个新地址发起一个新的请求。因为是常用手段，详细的就不多说了。
