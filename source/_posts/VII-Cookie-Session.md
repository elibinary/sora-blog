---
title: Cookie & Session
date: 2016-10-23 00:44:22
tags: 
description: Cookie & Session
---

## Cookie
cookie 是保存在客户端的的一段数据，常被用于辨别用户身份。现在更是被用于各种各样的用途，由于 HTTP 协议的无状态性，服务器不知道用户的操作上下文，使用 cookie 服务器就可以维护用户跟服务器会话中的状态。

* 临时 cookie
    此类 cookie 由浏览器维护，保存在内存中，浏览器关闭后就消失 
* 持久 cookie
    此类 cookie 保存在硬盘里，除非用户手工清理或到了过期时间，它将一直有效

另外由于 cookie 的大小是限制在 4KB 左右的，所以一般不会用来做复杂的存储。

在 Rails 中， cookie 的实现是在 ActionDispatch::Cookies 这里，在 controller 中读写 cookie 时，主要通过 ActionController#cookies 来实现。cookies 读取从 request 中传递过来的 cookie 信息，而最后也是随着 response 返回。

需要注意的是 cookie 的信息需要是 String 类型的，其它类型信息需要 serialized 后赋值。
rails 中提供了很多针对 cookies 的方法，如
```
cookies.signed[:user_id] = current_user.id

cookies.encrypted[:user_id] = current_user.id

cookies.permanent[:user_id] = current_user.id
```

signed 方法用来 set 一个经过签名的 cookie，用来防止用户篡改其值，其签名算法是通过 app 的 'secrets.secret_key_base' 这个值来签名的。
encrypted 方法用来 set 一个加密的 cookie，用来防止用户读取利用或篡改其值，其同样使用 'secrets.secret_key_base' 的值来计算。
permanent 方法如字面意思就是用来 set 一个永久的 cookie 的。

## Session
Session 是存储在服务器端的，它维护了 client 端与 server 端的一种联系。在浏览器和远程主机之间的HTTP传输中， HTTP cookie 就会被用来包含 session id 等相关信息。

对于 server 来说，session 是非常快速而高效的，但是有注意其在负载均衡的系统中的实现。可以通过共享储存或者设立独立的存储服务器来使各个 server 共享 session 信息。

在 Rails 中， session 只能在 controller 或者 view 中获取使用，其存储形式主要有四种方式：

 - ActionDispatch::Session::CookieStore - Stores everything on the
   client. 
 - ActionDispatch::Session::CacheStore - Stores the data in the
   Rails cache. 
 - ActionDispatch::Session::ActiveRecordStore - Stores the
   data in a database using Active Record. (require
   activerecord-session_store gem).
 - ActionDispatch::Session::MemCacheStore - Stores the data in a
   memcached cluster (this is a legacy implementation; consider using
   CacheStore instead).

与 client 的通信，都是由 cookie 来存储携带一个唯一的 session ID 来建立联系。

---

定义参考 [RFC 2109][1]


  [1]: https://www.ietf.org/rfc/rfc2109.txt
