---
title: ActiveRecord 的 connection pool 设计
date: 2018-08-26 15:36:35
tags:
  - Ruby
description: 本文基于 ActiveRecord 5.2
---


> 本文基于 ActiveRecord 5.2

本篇主要记录下最近我对 AR 的连接管理的一些理解

对于连接池相信大家都不陌生，它主要解决资源的频繁分配和释放所造成的问题，而且可以通过连接池的管理监控机制实时了解 db 连接数和使用情况。

AR 的代码组织及抽象都相当优雅，为了理解其连接池的实现，可以直接去读 `connection_adaters` 下相关的代码，代码量并不是很大

根据我最近的理解，AR 的整个 connection 管理有以下几部分组成：

![AR's connection manage][1]

### ConnectionPool

其中 `ConnectionPool` 为链接管理的基础核心

`ConnectionSpecification` 则负责管理 db connection 的配置信息，比如在 database.yml 中的
```
adapter
encoding
timeout
host
port
...
```
都由 `ConnectionSpecification` 解析管理，并作为创建 `ConnectionPool` 实例的核心参数

### ConnectionHandler

而往上的 `ConnectionHandler` 则是 `ConnectionPool` 的管理者。

> ConnectionHandler is a collection of ConnectionPool objects. It is used for keeping separate connection pools that connect to different databases.

它为 AR 提供了多 DB 连接操作的支持，常用的 `establish_connection` 方法就是由 `ConnectionHandler` 提供的

它管理者复数个的 `connection_pool`，每个 `connection_pool` 可以维护一个目标 DB 的连接池，从而实现通过切换不同的 `connection_pool` 来连接到不同的 DB 的需求。

图中 `ConnectionHandling` 作为一个 module 其作用是对外（引入方）提供了一些管理 `connection_pool` 的方法，比如

```
establish_connection
connection
connection_specification_name
connection_config
connection_pool
...
```

这些方法本质上还是通过 `ConnectionHandler` 来进行操作，只是宿主提供了定制化以及更加便利的封装

### AbstractAdapter

> An AbstractAdapter represents a connection to a database, and provides an abstract interface for database-specific functionality such as establishing a connection, escaping values, building the right SQL fragments

往下的 `AbstractAdapter` 则是一个 DB connection 的封装，它的一个实例真正代表了一个 `connection`

上面 `connection_pool` 中实际上是管理了一组的 `abstract_adapter`，多种类 db systems 的支持也正是在这一层实现的


  [1]: http://7xsger.com1.z0.glb.clouddn.com/image/blog/AR_Connection_1.png