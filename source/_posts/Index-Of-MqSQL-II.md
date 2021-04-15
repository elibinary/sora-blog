---
title: Index Of MqSQL - II
date: 2016-06-26 11:45:12
tags:
  - MySQL
description: 本篇我们接着来谈索引
---

#### 碎片化
首先B-TREE索引结构可能会出现索引的碎片化，碎片化的索引可能会无序的存储在磁盘上，这样会影响查询效率。
之前介绍过B-TREE索引的结构，我们知道B-TREE索引结构的叶子页并不一定顺序的存储在物理介质上，所以需要随机I/O来定位到叶子页，而随机I/O是非常耗时的操作。对于范围查询或索引覆盖扫描等操作大量的随机I/O会使查询速度受到很大影响。故如果叶子页在物理上是顺序且紧密的那么查询的性能就会比较好。

关于表数据的碎片化，有三种情况：
    
    1. 行碎片 Row Fragmentation
    这种碎片是指数据行被存储为多个地方的多个片段中，即使查询只从索引中访问一行记录，行碎片也会导致性能下降。
    2. 行间碎片 Intra-row Fragmentation
    行间碎片是指逻辑上顺序的页，或者行在磁盘上不是顺序存储的。行间碎片对诸如全表扫描和聚簇索引扫描等操作有很大影响，因为这些操作原本能够从磁盘上顺序存储的数据中获益
    3. 剩余空间碎片 Free Space Fragmentation
    剩余空间碎片是指数据页中有大量的空余空间。之前介绍过服务器每次会读取几块数据页，这会导致服务器读取大量不需要的数据。
    
MySQL 提供了一个清理碎片的命令 'optimize table' ， 该命令会重组表数据以及索引数据的物理存储，以减少存储空间并提高访问时的I/O效率。

When considering whether or not to run optimize, consider the workload of transactions that your server will process。 （对于 InnoDB 引擎来说）

    1. 之前提到过InnoDB的存储方式，它的数据全部存储在叶子页，而且其存储策略不会把一页空间全部占满，用来为更新留下空余空间而不用每次都用进行页分裂。
    2. 删除操作可能会在页空间中留下碎片空间
    3. 在更新行时，通常是在同一页面内重写数据
    4. 其次在高并发工作负载中随着时间推移可能会留下索引碎片
    
在使用这个命令时有一点要注意，'optimize table' 将会锁定目标表。对于小型列表，这一功能的效果很好执行速度也很优秀。但是对于体积很庞大的表来说就不那么乐观了，这个操作将会消耗掉大量的时间，这段时间内目标表将不能正常使用，这种情况下可以考虑使用MySQL的主主复制功能。