---
title: API Security Design
date: 2016-03-04 17:34:00
tags:
- Security
description: 本篇文章主要简单介绍一些api安全设计的方案。
---

> REST API, REST(Representational State Transfer)是一种设计风格，REST API就在此理解为符合REST设计原则和约束条件的HTTP和HTTPS服务端接口。

在client-server应用系统中，REST重要原则是客户端和服务器之间的交互在请求之间是无状态的，每次请求都得附带身份认证信息。我们需要为它加上各种所需的安全防护。

#### About HTTP Basic

HTTP Basic认证实现起来非常简单，基本形式是客户端在发起请求时提供用户名和口令等身份验证信息。
先把认证信息排列成以下形式：user:pwd，然后再对其进行URL安全的Base64编码。
    
这种方式在客户端要求很低，服务器端实现也很简单，不过相对的安全性也是很低的。Base64编码这一步骤的目的并不是安全与隐私，而是为将用户名和口令中的不兼容的字符转换为均与HTTP协议兼容的字符集。这种认证方式需要保证客户端和服务器主机之间的连接是安全可信的，不然就是裸奔了。

#### About HTTP Digest
