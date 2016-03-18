---
title: An Introduction To Oauth2 - P2
date: 2016-03-18 09:10:34
tags:
- Security
description: 本篇文章主要简单介绍OAuth2（开放授权）的四种 grant types 。
---

> OAuth defines four grant types: authorization code, implicit, resource owner password credentials, and client credentials

当然也提供扩展机制，可以自定义 grant types ，不同的流程都有不同的处理细节。
在这些流程中会把 Client 角色细分成两类：confidential clients 和 public clients ，主要是根据有没有保密 Client Credentials 来区分，
像是 Server 上的应用可以保证 Client Credentials 保密就是 confidential，如 Native App、In-Browser App 等无法保证 Client Credentials 保密
的就是 public 。不同角色的 Client 所能使用的 grant type 是不同的，比如 Native App 就不能使用 client credentials grant 。

#### Authorization Code Grant

Authorization Code Grant Type 允许获取 access tokens 和 refresh tokens 。

```
             +----------+
             | Resource |
             |   Owner  |
             |          |
             +----------+
                  ^
                  |
                 (B)
             +----|-----+          Client Identifier      +---------------+
             |         -+----(A)-- & Redirection URI ---->|               |
             |  User-   |                                 | Authorization |
             |  Agent  -+----(B)-- User authenticates --->|     Server    |
             |          |                                 |               |
             |         -+----(C)-- Authorization Code ---<|               |
             +-|----|---+                                 +---------------+
               |    |                                         ^      v
              (A)  (C)                                        |      |
               |    |                                         |      |
               ^    v                                         |      |
             +---------+                                      |      |
             |         |>---(D)-- Authorization Code ---------'      |
             |  Client |          & Redirection URI                  |
             |         |                                             |
             |         |<---(E)----- Access Token -------------------'
             +---------+       (w/ Optional Refresh Token)

Note: The lines illustrating steps (A), (B), and (C) are broken into
      two parts as they pass through the user-agent.
```
*摘自[RFC 6749 Authorization Code Grant Flow](https://tools.ietf.org/html/rfc6749)*

1. 首先 Client 把 Resource Owner 的 User-Agent 转到 authorization endpoint ，然后 Authorization Server 验证 Resource Owner 的授权
此步骤中 Client 会把 client identifier、申请的 scope、local state 和 redirection URI 一并传给 authorization endpoint。

2. 然后 Authorization Server 会把 Resource Owner 的 User-Agent 重定向到 Client 提供的 redirection URI ，同时回传 Authorization Code
、许可的 scope 和 local state

3. Client 就可以使用 Authorization Code 去获取 Access Token

*Note: 上述中的 User-Agent 通常是 web browser*

这个流程非常适合 confidential clients 类型的 Client 使用，并且支持 Refresh Token 。

需要注意的是上边 Authorization Code 的设计：这个 code 应该是有有效期的，并且应该是单次使用有效的，如多次使用 Authorization Server 应可以失效掉
之前发放的 Access Token ，建议绑定 code、Client 和 redirection URI 三者的关系。

另外为了防止恶意篡改 Redirection URI 来欺骗 Authorization Server 错误的发放 Access Token 给未经认证及授权的 Client， Authorization Server 
应该要求 Client 预设 Redirection URIs ，并在之后的请求中验证 Redirection URI 的一致性。


#### Implicit Grant

上面 Authorization Code Grant Type 会先返回一个 Authorization Code 给 Client ，然后 Client 使用这个 code 去获取 Access Token ，而
Implicit Grant Type 会在授权通过后直接把 Access Token 附加在 Redirection URI 中返回给 User-Agent 。而且 Implicit Grant 是不支持发放
Refresh Token 的。

```
             +----------+
             | Resource |
             |  Owner   |
             |          |
             +----------+
                  ^
                  |
                 (B)
             +----|-----+          Client Identifier     +---------------+
             |         -+----(A)-- & Redirection URI --->|               |
             |  User-   |                                | Authorization |
             |  Agent  -|----(B)-- User authenticates -->|     Server    |
             |          |                                |               |
             |          |<---(C)--- Redirection URI ----<|               |
             |          |          with Access Token     +---------------+
             |          |            in Fragment
             |          |                                +---------------+
             |          |----(D)--- Redirection URI ---->|   Web-Hosted  |
             |          |          without Fragment      |     Client    |
             |          |                                |    Resource   |
             |     (F)  |<---(E)------- Script ---------<|               |
             |          |                                +---------------+
             +-|--------+
               |    |
              (A)  (G) Access Token
               |    |
               ^    v
             +---------+
             |         |
             |  Client |
             |         |
             +---------+

```
*摘自[RFC 6749 Implicit Grant Flow](https://tools.ietf.org/html/rfc6749)*

1. 第一步与 Authorization Code Grant 是一样的， Client 把 Resource Owner 的 User-Agent 转到 authorization endpoint ，然后 Authorization Server 验证 Resource Owner 的授权。

2. 然后 Authorization Server 会把 Resource Owner 的 User-Agent 重定向到 Client 提供的 redirection URI ，其中会把 Access Token 放到 Fragment 中一起返回。

3. 在之后 User-Agent 会依照转址指令去请求 web-hosted client resource ，web-hosted client resource 会回传一个网页（通常是一个嵌入了一段 script 的 html 页面），这个页面会拿到完整的包括 Fragment 信息的 redirection URI ，然后解出 Access Token。

4. User-Agent 将解出的 Access Token 返回给 Client。

这个流程适用于 public client ，同时因为 Access Token 是直接包含在 redirection URI 中的，故 Resource Owner 可以看到 Access Token ，并且其他可以存取
User-Agent的应用都可以看到 Access Token 。

关于 Fragment 可以看下这篇文章[6 Things You Should Know About Fragment URLs](https://blog.httpwatch.com/2011/03/01/6-things-you-should-know-about-fragment-urls/)

> 题外话: 关于 HTTP redirect 301 302

> Status 301 means that the resource (page) is moved permanently to a new location. The client/browser should not attempt to request the original location but use the new location from now on.

> Status 302 means that the resource is temporarily located somewhere else, and the client/browser should continue requesting the original url.

> 以上是在 stackoverflow 上看到的一个解释，说的清晰明了简单粗暴

#### Resource Owner Password Credentials Grant

在 Resource Owner Password Credentials Grant 流程中， Client 会直接去向 Resource Owner 索取账户密码，然后在凭借得到的账户密码去获取 Access Token。

```
              +----------+
              | Resource |
              |  Owner   |
              |          |
              +----------+
                   v
                   |    Resource Owner
                  (A) Password Credentials
                   |
                   v
              +---------+                                  +---------------+
              |         |>--(B)---- Resource Owner ------->|               |
              |         |         Password Credentials     | Authorization |
              | Client  |                                  |     Server    |
              |         |<--(C)---- Access Token ---------<|               |
              |         |    (w/ Optional Refresh Token)   |               |
              +---------+                                  +---------------+

```
*摘自[RFC 6749 Resource Owner Password Credentials Grant](https://tools.ietf.org/html/rfc6749)*

1. 首先 Client 会向 Resource Owner 请求账户密码信息。
2. 然后 Client 通过 Resource Owner 的账户密码信息去 Authorization Server 获取 Access Token

Resource Owner Password Credentials Grant 是支持发放 Refresh Token 的。

在此流程中， Client 会去直接获取 Resource Owner 的账户密码信息，Resource Owner 将无法控制授权权限以及范围。
Spec中规定， Client 不能存储 Resource Owner 的账户密码信息，再获取到 Access Token 和 Refresh Token 后
应该用其替换之。

应尽量不使用此流程！

#### Client Credentials Grant

此流程中， Client 仅使用 client credentials 向 Authorization Server 请求 Access Token 。
这其实和之前的文章里提到的 API KEY 形式非常相似。

```
            +---------+                                  +---------------+
            |         |                                  |               |
            |         |>--(A)- Client Authentication --->| Authorization |
            | Client  |                                  |     Server    |
            |         |<--(B)---- Access Token ---------<|               |
            |         |                                  |               |
            +---------+                                  +---------------+

```
*摘自[RFC 6749 Client Credentials Grant](https://tools.ietf.org/html/rfc6749)*

从流程中可以看出， Client自己就相当于 Resource Owner ，它可以通过 Authorization Server 颁发的凭证来获取资源。
 

<br /> 
<br /> 
四种内建流程先介绍到这里，更加详细的资料可以到 RFC 的文档中查看。
同时还有关于实做时关于钓鱼攻击、CSRF 以及 Clickjacking 等恶意攻击的防范。

















