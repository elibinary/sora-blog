---
title: Redis - Sorted Set
date: 2016-08-20 21:00:32
tags:
  - DataStructure
description: 继续上一篇的话题，今天稍微深入的了解下 Redis 中的 Sorted Set 结构
---

上篇曾说过 Sorted Set 有两种编码方式 ziplist， skiplist。那么本篇就来简单说下它是怎么选择底层编码方式的。
其实它和set很相似，也是依靠检查输入的第一个元素，如果第一个元素长度小于服务器属性 server.zset_max_ziplist_value 的值（默认为 64 ）并且服务器属性 server.zset_max_ziplist_entries 的值大于0时，就会默认创建为 ziplist 编码。否则，程序就创建为 skiplist 编码。同理可推得当新元素的长度超过 server.zset_max_ziplist_value 的值就会自动转换为 skiplist 编码。

**ziplist**
其组成方式由一个个的节点相连组成，其中每个元素占两个节点，第一个保存 member，第二个保存 score。各个元素之间按照 score 进行排序。
在效率方面，由于 ziplist 的节点指针只能线性地移动，所以查找的时间复杂度为 O(n)。其依赖查询的操作也都有如此的时耗。

**skiplist**
当使用此种编码时，其底层就会使用字典和跳跃表两个数据结构相结合的方式存储 Sorted Set 。
我们着重来说一下跳跃表，跳跃列表（也称跳表）是一种随机化数据结构，基于并联的链表，其效率可比拟于二叉查找树（对于大多数操作需要O(log n)平均时间，**信息来自 wiki**）。

先来看一个简单的跳跃表：
![简单跳跃表][1]

这就是一个简单的跳跃表，按层构造最底层是一个普通的有序的链表，每个更高层都充当下面列表的“快速跑道”。为什么这么说呢，我们都知道普通的有序链表在查找元素时需要顺序的沿着指针向后查找，故其时间复杂度为O(n)，而如上图的跳跃表，其存储了额外层次的顺序链表，在查找元素时就可以跳过一些元素达到更快的查找速度。

一个跳跃表应该有以下几个性质：

 1. 一个跳表应该有几个层组成；
 2. 跳表的第一层包含所有的元素；
 3. 每一层都是一个有序的链表；
 4. 如果元素x出现在第i层，则所有比i小的层都包含x；
 
下面拿一个典型的跳跃表来说明一下它是如何加快查找速度的
![典型跳跃表][2]

这是一个典型的跳跃表，我们可以看出除了最底层的有序链表，上面一层中分别包含了指向前面第二个元素的指针，那么在查找一个节点时，仅仅需要遍历N/2个节点即可。也就是 O(n/2)。

从上面例子不难看出，跳表的核心思想，其实也是一种通过“空间来换取时间”的算法。通过在每个节点中增加了向前的指针，从而提升查找的效率。

下篇会详细的介绍这一结构。

  [1]: http://7xsger.com1.z0.glb.clouddn.com/image/blog/skiplist-1.png
  [2]: http://7xsger.com1.z0.glb.clouddn.com/image/blog/skiplist-2.png