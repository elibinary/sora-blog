---
title: [Mongoid]使用总结之一些查询方法
date: 2016-02-26 09:03:29
tags: MongoDB 
- MongoDB
- db
description: 本篇文章主要介绍Mongoid的一些查询命令。
---
> MongoDB 的数据是用JSON格式存储的

同时MongoDB支持丰富的查询方式，查询指令使用JSON形式的标记，能够对document中的embed对象及array对象进行很方便的检索

> MongoDB 不限制每个key对应的values的个数，MongoDB也不要求同一个集合里的不同的文档有相同的key

比如一张"表"中的一个document有：name，title，record_on，like属性，同"表"中的另一个document可以是这样：name，title，record_on，hate，body。

> MongoDB 可以通过分片来支持数据库集群，以此来增加存储容量和吞吐量

分片是使用多个机器存储数据的方法，MongoDB使用分片以支持巨大的数据存储量与对数据操作。
    
MongoDB中数据的分片是以集合为基本单位的，集合中的数据通过片键被分成多部分。不做展开，详细[sharding-introduction](http://docs.mongoing.com/manual/core/sharding-introduction.html)

> MongoDB 的复制功能和高可用
    
MongoDB可以通过配置主从服务器来实现高可用，使用复制功能来同步主从服务器之间的数据。由于从节点从主节点的复制过程是异步的所以从节点返回给client的数据可能不是最新的。详细[replication-introduction](http://docs.mongoing.com/manual/core/replication-introduction.html)
