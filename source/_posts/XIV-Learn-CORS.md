---
title: 了解 CORS
date: 2017-01-15 14:08:20
tags:
  - Web
description: CORS 全称 Cross-Origin Resource Sharing，也就是跨域资源共享
---

> CORS 全称 Cross-Origin Resource Sharing，也就是跨域资源共享。

### 1
CORS，顾名思义就是指当一个资源请求一个其它域名的资源时，所产生的的跨域请求(cross-origin HTTP request)。而出于安全考虑，浏览器会限制脚本中发起的跨域请求。比如，使用 XMLHttpRequest 对象和Fetch发起 HTTP 请求就必须遵守同源策略。

所谓同源策略就是浏览器会限制从一个源加载的文档或脚本如何与来自另一个源的资源进行交互。那么被认为是一个源的规则就是如果协议，端口（如果指定了一个）和主机对于两个页面是相同的，则两个页面具有相同的源。

同源策略控制了不同源之间的交互，例如在使用XMLHttpRequest 或 'img' 标签时则会受到同源策略的约束。

先说一下 XMLHttpRequest 这个东西，XMLHttpRequest 是一个API, 它为客户端提供了在客户端和服务器之间传输数据的功能。它提供了一个通过 URL 来获取数据的简单方式，并且不会使整个页面刷新。这使得网页只更新一部分页面而不会打扰到用户。XMLHttpRequest 在 AJAX 中被大量使用。比如我们可以在浏览器的 console 环境轻松模拟一个跨域请求：
```
// current source: http://fanyi.baidu.com
var xhr = new XMLHttpRequest();
xhr.open('GET', 'http://www.bilibili.com/html/aboutUs.html',true);
xhr.send()

// XMLHttpRequest cannot load http://www.bilibili.com/html/aboutUs.html. No 'Access-Control-Allow-Origin' header is present on the requested resource. Origin 'http://fanyi.baidu.com' is therefore not allowed access.
```

### 2
简单地说，就是 Web 应用程序通过 XMLHttpRequest 对象或Fetch能且只能向同域名的资源发起 HTTP 请求，而不能向任何其它域名发起请求。浏览器会拦截其返回。

为了能开发出更强大、更丰富、更安全的Web应用程序，开发人员渴望着在不丢失安全的前提下，Web 应用技术能越来越强大、越来越丰富。在当今的 Web 开发中，使用跨域 HTTP 请求加载各类资源（包括CSS、图片、JavaScript 脚本以及其它类资源），已经成为了一种普遍且流行的方式。CORS 是一种新的机制，这种机制让Web应用服务器能支持跨站访问控制，从而使得安全地进行跨站数据传输成为可能。（现在大多数浏览器都已支持 CORS）

跨源资源共享标准通过新增一系列 HTTP 头，让服务器能声明哪些来源可以通过浏览器访问该服务器上的资源

浏览器发送跨域请求的一些 Header 信息：

* Origin
 表明发送请求或者预请求的域，用来告诉服务器端,请求来自哪里.它不包含任何路径信息,只是服务器名。
* Access-Control-Request-Method
 在发出预检请求时带有这个头信息，告诉服务器在实际请求时会使用的请求方式。
* Access-Control-Request-Headers
 在发出预检请求时带有这个头信息，告诉服务器在实际请求时会携带的自定义头信息。如有多个，可以用逗号分开。比如这样

 ```
 Access-Control-Request-Headers: X-PINGOTHER, X-OPTION
 ```

服务器返回的 response header 中的一些信息：

* Access-Control-Allow-Origin
 指定一个允许向该服务器提交请求的URI，指定 '*' 时表示允许来自所有域的请求
* Access-Control-Max-Age
 响应预检请求的时候使用，表示这次预请求的结果的有效期是多久，在有效期内,不用发出另一条预检请求
* Access-Control-Allow-Methods
 响应预检请求的时候使用，指明资源可以被请求的方式有哪些
* Access-Control-Allow-Headers
 响应预检请求的时候使用，用来指明在实际的请求中,可以使用哪些自定义HTTP请求头，用来指明在实际的请求中，可以使用哪些自定义HTTP请求头 

---
QA：

从跨域请求的处理来看，限制跨域访问的应该是浏览器，而不是服务器，服务器是可以正常接收到请求的，只是返回结果被浏览器拦截了。但是这里有个问题，如果这个跨域请求是带有破坏性的请求比如 POST, DELETE ，那么是不是如果服务器端不做特殊处理限制的话，这样的请求实际上已经完成了它想要做的事情，只是由于返回结果被浏览器拦截而无法正常接收返回而已。

还有另一个问题就是，按照跨域的限制来看，返回值被浏览器拦截了，也就是说这是其实浏览器已经正常拿到了完整的返回数据了么？
还是有一些问题现在还不能确定，等我再看些资料亲自试下再来更新文章。