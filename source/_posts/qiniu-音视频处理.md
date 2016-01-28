---
title: qiniu 音视频处理
date: 2016-01-28 18:37:17
tags:
- Qiniu
- Ruby
---

> 本篇文章主要介绍基于Qiniu的音视频存储及切片和转换处理的ruby实现。
> Qiniu的SDK源码：[ruby-sdk](https://github.com/qiniu/ruby-sdk)

#### 安装使用
    
安装和配置很简单，[qiniu-doc](http://developer.qiniu.com/docs/v6/sdk/ruby-sdk.html)中介绍的很清楚，这里就不做赘述

#### 音视频的处理
    
音视频的处理过程发生在qiniu服务器端，整个流程是这样的：
首先调用qiniu的上传API，音视频上传完毕后**触发事件**并把音视频的转换/切片等处理任务放入一个**队列**中，
qiniu服务器从队列中取出任务处理，处理完毕后会将处理结果以回调的形式发送到我们自己的服务器。

*   qiniu上传策略

上传策略是资源上传时附带的一组配置设定，这组设定指明上传什么资源，上传到哪个空间，资源成功上传后是否执行持久化，是否需要设置反馈信息的内容，以及授权上传的截止时间等等。

*   persistentOps
    
qiniu的API文档对上传策略中的参数都有解释，这里只对persistentOps展开说明。
    
persistentOps: 资源成功上传后执行的持久化指令列表,每个指令是一个API规格字符串，多个指令用“;”分隔。
    
```ruby
put_policy.persistentOps = "avthumb/mp4|saveas/cWJ1Y2tldDpxa2V5;avthumb/flv|saveas/cWJ1Y2tldDpxa2V5"
put_policy.persistentNotifyUrl = "#{server.host}/#{api_path}"
```

#### TODO