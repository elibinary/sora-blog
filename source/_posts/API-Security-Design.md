---
title: API Security Design
date: 2016-03-04 22:34:00
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

Digest认证方式相比Basic认证，增强了其安全性。它在身份认证信息发出前会对其进行MD5加密，相较于HTTP Basic发送明文而言更加安全。

其加密的大致步骤是这样的：

首先先把身份认证信息排列成下列形式
```ruby
"user:realm:passwd"
```
对其进行MD5加密生成 *HA1* 字符串
然后是接口信息
```ruby
"method:DigestURI"
```
对其进行MD5加密生成 *HA2* 字符串
然后把所有信息排列如下
```ruby
"HA1:nonce:HA2"
```
对其进行MD5加密生成最后的验证信息

> 其中第一步里面的 *realm* 到底是什么呢，[RFC 2617](http://tools.ietf.org/html/rfc2617#page-3)中给出这样的描述：
> 
> The realm directive (case-insensitive) is required for all
   authentication schemes that issue a challenge. The realm value
   (case-sensitive), in combination with the canonical root URL (the
   absoluteURI for the server whose abs_path is empty; see section 5.1.2
   of [2]) of the server being accessed, defines the protection space.
   These realms allow the protected resources on a server to be
   partitioned into a set of protection spaces, each with its own
   authentication scheme and/or authorization database. The realm value
   is a string, generally assigned by the origin server, which may have
   additional semantics specific to the authentication scheme. Note that
   there may be multiple challenges with the same auth-scheme but
   different realms.

> 看起来类似于空间的意思简单地说就是相同的realm是可以共用credentials的。
> 
> 第三步中的 *nonce* 是一个随机数，生成随机数时还可以加入时间戳以防止重放攻击。

由于MD5算法是不可逆的，以此来保障身份信息的安全性。当然，这样并不能保障因密码简单而被暴力破解的方法靠穷举来试出密码，现在有很多现成的字典可以减少穷举次数减小破解难度。

#### About API KEY

API KEY就是服务器端颁发给客户端的key，一般有两个api_key和security_key。客户端使用将使用这两个key对身份验证信息进行签名。

首先Client端会对api_key、时间戳、rest_uri进行组合并编码，然后使用security_key作为密钥使用HMAC对其进行加密生成sign。最后的请求类似如下：
```ruby
"/restapi/interface?api_key=xxx&timestrap=xxx&sign=xxx"
```

服务器端收到请求后，首先验证api_key是否存在，存在则获取其对应的security_key，然后对api_key、时间戳、rest_uri进行组合并编码，然后使用security_key作为密钥使用HMAC对其进行加密生成sign，最后把生成的sign与client端传过来的sign进行比较完成身份认证。其中时间戳可以用来防止重放攻击。

<br /> 
<br /> 
*  *  *
PS: 后续会对 Oauth 协议进行介绍