---
title: HTTP 缓存
date: 2016-05-28 18:52:46
tags:
  - server
description: 本文主要介绍http缓存策略及实践。
---

#### Cache-Control

先来了解一个很重要的概念，HTTP头Cache-Control。每个资源都可以通过 Cache-Control HTTP 头来定义自己的缓存策略，Cache-Control 主要指明谁在什么条件下可以缓存响应以及可以缓存多久。其常见的取值如下：

| value | desc       |
| ------  | ---------  |
| public    | 所有内容都将被缓存  |
| private   | 内容只缓存到私有缓存中，并且不允许任何中继缓存对其进行缓存     |
| no-cache  | 必须先与服务器确认返回的响应是否被更改，然后才能使用该响应来满足后续对同一个网址的请求     |
| no-store  | 禁止浏览器和所有中继缓存存储返回的任何版本的响应 |
| max-age   | 指定从当前请求开始，允许获取的响应被重用的最长时间（单位为秒） |

举个栗子：
现有一个页面index.html，页面中有一个CSS文件style.css。那么我们请求这个页面时，每次都要去服务器请求一次这个css文件，虽然这个css文件可能万年不变。这时就有人想要去干掉这个额外的开销，这里就要提到一个概念304协商缓存。

#### Etag

我们可以利用304，让浏览器使用本地缓存，到这里不得不提到Etag，ETag是HTTP协议提供的一种Web缓存验证机制，并且允许客户端进行缓存协商。这就使得缓存变得更加高效，而且节省带宽。那么ETag是怎么工作的呢

ETag是一个不透明的标识符，由web服务器生成，是一个类似于资源指纹的东西，当资源改变时其指纹也随之发生改变，如此便快速地比较，以确定两个版本的资源是否相同。

    - 首先当一个URL被请求，Web服务器会返回资源和其相应的ETag值，它会被放置在HTTP的“ETag”字段中，同时客户端根据缓存策略来缓存这个资源
    - 然后当客户端在请求相同的URL时，服务器便会去比较客户端的ETag和当前版本资源的ETag。如果ETag值匹配，这就意味着资源没有改变，服务器会返回一个“304未修改”状态的响应。304状态告诉客户端，它的缓存版本是最新的，并应该使用它。

有些要求严苛的人觉得这不是还需要一次服务器请求嘛，为什么我们不能把这个请求也干掉呢，这个请求看着就闹心。对于某些情况下确实可以干掉这个请求以达到最优化。

我们可以不使用ETag，仅依靠Cache-Control的策略并把max-age设的足够大，这样强制浏览器使用本地缓存（cache-control/expires），在资源"过期"之前，将一直不会和服务器通信，大快人心。但是这样就有一个问题，当我们想要更新或废弃已缓存的响应，该怎么办？

相信很多人已经有想法了：我们可以在请求路径中加入版本号嘛，像这样：
```
<link rel="stylesheet" href="style.css?v=1">
```
每当想失效掉浏览器缓存时就更改版本号，但是这样又有一个问题来了，我们不得不每次手动去修改版本号，或者可以写一个统一的处理过程来自动更改版本号，但是如果我们的index.html中有多个css文件而我们只想失效掉其中n个时就一个大写的懵b。

其实解决这个情况很简单，我们上面也提到了ETag的实现，我们可以借用其思想，把文件的指纹加入到请求路径中，像这样：
```
<link rel="stylesheet" href="style.1xa1ssa.css">
```
如此一来，每当文件发生改变时，都会造成其指纹的变化从而改变其请求路径，问题解决。

#### Asset Pipeline

Asset Pipeline 提供了一个框架，用于连接、压缩 JavaScript 和 CSS 文件，以及优化浏览器缓存。

Asset Pipeline 的第一个功能就是连接合并静态资源，用以减少渲染页面时浏览器发起的请求数，同时也可以提升页面加载速度。在把所有 JavaScript 文件合并到一个主 .js 文件，以及把所有 CSS 文件合并到一个主 .css 文件后，它有一个非常重要的动作就是它会在文件名后加上 MD5 指纹，上次分享中提到过这样做的好处，就是我们可以利用Cache-Control的策略并把max-age设的足够大来使浏览器一直能够使用缓存直到资源过期，而当资源发生改变后其MD5指纹将会改变，此时浏览器缓存将自动过期。

上次提到的请求连接后接请求字符串的方式出了上次提到的缺点外还有几处缺陷：首先使用请求字符串时，在集群环境中不同的服务器节点上的文件名可能是不相同的，由于目标字符串多是利用最后修改时间来生成的，那么由于部署新版代码时，所有静态资源文件的最后修改时间都将改变，即便内容没变，客户端也要重新请求这些文件，最后就是有些 CDN 验证缓存时根本无法识别请求字符串。

Asset Pipeline还可以压缩静态资源，删除CSS文件中的空白和注释以及对JavaScript 的定制处理。 Asset Pipeline还允许允许使用高级语言编写静态资源再使用预处理器转换成真正的静态资源。
