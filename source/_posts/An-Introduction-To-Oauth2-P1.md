---
title: An Introduction To OAuth2 - P1
date: 2016-03-12 09:17:16
tags:
  - Security
description: 本篇文章主要简单介绍OAuth2（开放授权）。
---

> OAuth是一个开放标准，它提供一种方案使用户可以在不提供账户密码信息的情况下，允许第三方获取用户在某服务器存储的资源。

在传统的client-server模式中，如果用户想要让第三方获取指定受保护服务器上的资源时，需要提供账户密码信息给第三方。
而第三方存储账户密码信息有很多问题，首先这样是不安全的，并且任意第三方程序被破解，都将导致账户密码的泄露；第三方持有
用户账户密码的情况下，将拥有用户在指定服务器上完整的权限；用户撤回授权也将变得麻烦，或许不得不修改密码。

#### OAuth2 的基本工作流程

在介绍 Protocol Flow 之前，先看一下OAuth2的角色分工：

* resource owner: 
  授权别人去指定服务器存取受保护资源的角色，这里就是指用户

* client: 
  被 resource owner 授权去存取指定服务器受保护资源的角色，这里就是指第三方应用程序

* resource server: 
  存放受保护资源的服务器

* authorization server: 
  认证 resource owner 并经 resource owner 授权后核发 access tokens 的服务器


```
             +--------+                               +---------------+
             |        |--(A)- Authorization Request ->|   Resource    |
             |        |                               |     Owner     |
             |        |<-(B)-- Authorization Grant ---|               |
             |        |                               +---------------+
             |        |
             |        |                               +---------------+
             |        |--(C)-- Authorization Grant -->| Authorization |
             | Client |                               |     Server    |
             |        |<-(D)----- Access Token -------|               |
             |        |                               +---------------+
             |        |
             |        |                               +---------------+
             |        |--(E)----- Access Token ------>|    Resource   |
             |        |                               |     Server    |
             |        |<-(F)--- Protected Resource ---|               |
             +--------+                               +---------------+

```
以上是协议流程，摘自[RFC 6749 Abstract Protocol Flow](https://tools.ietf.org/html/rfc6749)

(A). Client 向Resource Owner请求授权

(B). Client 从Resource Owner得到 Authorization Grant ，这个Grant代表Resource Owner的授权许可。规范中定义了四中Grant Types，
     分别是: authorization code, implicit, resource owner password credentials, client credentials. 同时规范中还定义了
     四种内建流程分别与之对应。

(C). Client 使用 Authorization Grant 向 Authorization Server 申请 Access Token 

(D). Authorization Server 认证 Client 及 Authorization Grant ，通过后核发 Access Token 

(E). Client 使用 Authorization Grant 向 Resource Server 申请资源

(F). Resource Server 验证 Access Token ，通过后开放资源给 Client


#### Refresh Token

当 Access Token 过期或失效了， Refresh Token 就被用来向 Authorization Server 重新申请一个 Access Token。
```
            +--------+                                           +---------------+
            |        |--(A)------- Authorization Grant --------->|               |
            |        |                                           |               |
            |        |<-(B)----------- Access Token -------------|               |
            |        |               & Refresh Token             |               |
            |        |                                           |               |
            |        |                            +----------+   |               |
            |        |--(C)---- Access Token ---->|          |   |               |
            |        |                            |          |   |               |
            |        |<-(D)- Protected Resource --| Resource |   | Authorization |
            | Client |                            |  Server  |   |     Server    |
            |        |--(E)---- Access Token ---->|          |   |               |
            |        |                            |          |   |               |
            |        |<-(F)- Invalid Token Error -|          |   |               |
            |        |                            +----------+   |               |
            |        |                                           |               |
            |        |--(G)----------- Refresh Token ----------->|               |
            |        |                                           |               |
            |        |<-(H)----------- Access Token -------------|               |
            +--------+           & Optional Refresh Token        +---------------+
```
以上是协议流程，摘自[RFC 6749 Refreshing an Expired Access Token](https://tools.ietf.org/html/rfc6749)

如允许使用 Refresh Token ，则 Authorization Server 将在核发 Access Token 的同时核发 Refresh Token。当然也可以禁用 Refresh Token，
一些内建流程也会禁用 Refresh Token，如 Implicit Grant。

从图中可以看出当 Access Token 失效后，Client 可以使用 Refresh Token 直接向 Authorization Server 申请新的 Access Token 而无需再一次向
Resource Owner 请求授权。

Refresh Token 一般会在很长一段时间有效，建议将其与被授权的 Client 绑定。申请新的 Access Token 时也可以一并返回新的 Refresh Token 给 Client
，Client 和 Authorization Server 更新新的 Refresh Token 替换旧的。

请注意使用 Refresh Token 获取新的 Access Token 的 scope 应该是 Refresh Token 的子集（也就是被包含的关系），而若返回新的 Refresh Token 其 scope 也应与旧的 Refresh Token 一致或是其子集。

<br /> 
<br /> 
*  *  *
PS: 下篇介绍 OAuth2 的四种 Grant Flows
