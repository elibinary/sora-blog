---
title: 浅谈 redisObject
date: 2016-08-06 10:56:14
tags:
  - DataStructure
description: 简单说下 redis 的核心结构 redisObject
---

redisObject 是 Redis 类型系统的核心结构，Redis 所有的键、值都是由 redisObject 来表示, 大致结构如下：

```
typedef struct redisObject {
    // 类型
    unsigned type:4;

    // 对齐位
    unsigned notused:2;

    // 编码方式
    unsigned encoding:4;

    // LRU 时间（相对于 server.lruclock）
    unsigned lru:22;

    // 引用计数
    int refcount;

    // 指向对象的值
    void *ptr;

} robj;
```

我们主要看其中的 type 和 encoding。

首先我们知道 Redis 的几种常用数据类型分别是：

* String
* Hash
* List
* Set
* Sorted set

type 表示的其实就是value对象具体是其中哪种数据类型，而 encoding 则表示的是其在redis内部的编码方式，redis 的编码有如下这些：

| name        | desc   |
| --------   | -----  |
| raw     | 字符串 |
| int        |   整数   |
| ht        |    哈希表    |
| zipmap        |        |
| linkedlist        |    双向链表    |
| ziplist        |    压缩列表    |
| intset        |    整数集合    |
| skiplist        |    跳跃表    |

可以看出 encoding 类型是比 type 的种类多的，其实它们的关系并不是一对一的，一种 type 在 Redis 内是可以有多种不同的编码方式的，下面列举了其间关系：

![此处输入图片的描述][1]

  [1]: http://7xsger.com1.z0.glb.clouddn.com/image/blog/redisObject01.png
  
>  Redis 2.6 开始， zipmap 不再是任何数据类型的底层结构

- String
String是最常用的一种数据类型，普通的key/value存储都可以归为此类，String在redis内部存储默认就是一个字符串，当遇到incr,decr等操作时会转成数值型进行计算，此时redisObject的encoding字段为int。

- List
创建一个新 List 时默认使用 ziplist 编码，只有当

    1. 试图往列表新添加一个字符串值，且这个字符串的长度超过 server.list_max_ziplist_value （默认值为 64 ）。
    2. ziplist 包含的节点超过 server.list_max_ziplist_entries （默认值为 512 ）。

 时列表会被转换成 linkedlist 编码。
 List 常用操作 lpush,rpush,lpop,rpop ，从这些操作中不难看出底层双向链表的实现，双向链表可以支持反向查找和遍历，更方便操作，不过带来了部分额外的内存开销。
 
- Set
创建Set时所使用的编码取决于第一个添加到 Set 的元素，如果第一个元素是一个整数，那么初始编码就为 
intset ，否则初始编码为 ht。但当 intset 保存的整数值个数超过 server.set_max_intset_entries （默认值为 512 ）或者试图往集合里添加一个非整数元素时就会被转换成 ht 编码。

 Set 的内部实现其实就是一个value永远为null的HashMap，其自动排重的功能也正依赖于此，同时这也是set能提供判断一个成员是否在集合内的原因。

- Hash
创建 Hash 时，程序默认使用 ziplist 编码，而当同 List 一样的原因时，将编码切换为 ht。当使用 ziplist 编码哈希表时，程序通过将键和值一同推入压缩列表，从而形成保存哈希表所需的键-值对结构。当进行查找/删除或更新操作时，程序先定位到键的位置，然后再通过对键的位置来定位值的位置。