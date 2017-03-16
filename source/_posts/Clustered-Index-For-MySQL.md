---
title: Clustered Index
tags:
  - db
  - MySQL
description: 本篇主要关于聚集索引的基础认识及在MySQL中的实现及应用。
date: 2016-05-01 13:13:59
---


#### 索引

索引最大的优点是能够让服务器快速定位到表的指定位置。拿最常见的B-Tree索引为例，因为B-Tree索引会按顺序存放数据，故对排序等操作有良好的效率，而且B-Tree索引会存储实际的列值，当索引包含所有的查询返回值时只使用索引就可以完成全部查询。

> 1. 索引大大减少了服务器扫描表的数据量
> 2. 索引可以帮助服务器避免排序和临时表
> 3. 索引可以将随机I/O变为顺序I/O

前两条都很好理解，那么第三条到底是什么意思呢

我们知道数据是不可能全部存储在内存中的，那么每次查询数据时都需要磁盘I/O操作，磁盘I/O操作是需要消耗寻道时间以及旋转时间的，这些机械运动耗费时间是巨大的。想象一下假设我们的数据随机的分布在磁盘中，那么每次进行查询时磁盘的磁头将会在各个扇区不同磁道间来回切换，这将消耗掉大量的时间。由于顺序读取不需要寻道时间且只需很少的旋转时间所以磁盘顺序读取的效率很高，磁盘为了提高效率往往不是严格按需读取，而是每次都会预读数页数据进入内存等待使用。

> 局部性原理, 当一个数据被用到时，其附近的数据也通常会马上被使用。

#### 聚集索引

聚集索引不是一种单独的索引类型，而是一种存储数据方式，索引的键值逻辑顺序决定了表数据行的物理存储顺序。其主要特点：

1. 一个表只能有一个聚集索引，聚集索引因为与表的元组物理顺序一一对应，所以只有一种排序，即一个数据表只有一个聚集索引。
2. 聚集索引存储记录是物理上连续存在，而非聚集索引是逻辑上的连续，物理存储并不连续。

MySQL的存储引擎到目前为止都不支持用户指定聚簇索引，其聚集索引选择规则：

1. 首先选择显式定义的主键建立聚簇索引
2. 如果没有，则选择第一个具有唯一且非空值的索引
3. 还是没有的话，就会去定义一个隐藏的主键，然后对其建立聚簇索引

下面主要看一下InnoDB的聚集索引实现，InnoDB的聚集索引实际上将数据行的全部内容存放在索引的叶子节点中，同时叶子节点之间顺序的以指针相连（如图）。

<div align=center>
  <img src="http://7xsger.com1.z0.glb.clouddn.com/image/blog/Clustered-1.png" height="200" alt="InnoDB聚集索引"/>
</div>

从表中可以看出索引结构中非叶子结点只保存索引值和一个指向下个节点的指针，而叶子节点将会顺序的保存数据行中的所有数据。

上一篇关于索引的文章提到过InnoDB的B-Tree索引实现结构，InnoDB将只聚集在同一个存储数据页中的记录（插入数据超过页大小是会分裂成两页），包含相邻键值的不同页面可能会相距甚远。

聚集索引的优点

1. 聚集索引把相关数据保存在一起以减少磁盘IO
2. 聚集索引将索引和数据保存在同一个B-Tree结构中，因此从聚集索引中查找数据通常比非聚集索引快

同时聚集索引也有很多缺点

1. 首先其插入速度严重依赖插入顺序，试想如果要对一张按随机主键值聚集的表插入一条数据，由于其主键非自增故又有很大可能需要插入到任意中间位置，如果要插入的页满还会产生分裂操作以及涉及到大量数据的移动。故按照主键顺序插入是加在数据到InnoDB表中速度最快的方式。
2. 更新聚集索引列的代价非常高，因为对聚集列进行更新会促使InnoDB将更新后的值移动到新的位置，这中间可能会触发更多的操作
3. 还有就是页分裂的问题，由于对聚集索引的操作有很大几率会触发页分裂，当行的主键值要求必须将这一行插入到一个已满的页时，存储引擎会将该页分裂成两个页面来容纳该行，页分裂会导致表占用更多的磁盘空间，同时频繁的页分裂操作会导致数据存储的不连续，这会导致全表扫描速度变慢。

在把这些随机值载入到聚集索引后，也会需要做一次optimize table操作来重建表以优化页的填充。

需要注意的是，顺序的主键在高并发工作负载时，主键的顺序插入可能会造成键值的争用，主键的上界会成为争用对象，因为所有的插入操作都发生在这所以并发插入可能会导致间隙锁竞争。

关于非聚集索引（普通索引），其实现结构与聚集索引有一点区别，非聚集索引的叶子节点存储的不是全部的数据，也不是指向行的物理地址的指针，而是行的主键值也就是聚集索引的索引值。这就意味着查找时，存储引擎会先找到叶子节点获取对应的主键值，然后再去聚集索引中查找到对应的行。

> 索引并不一定是最好的选择，对于很小的表，大部分情况下进行全表扫描将会更加高效，对于中大型表，索引就非常有效。当数据量达到某种程度，建立和使用索引的代价将会越来越高，只有当索引帮助存储引擎进行快速查找的好处大于其带来的额外工作时，索引才是最有效的。

- - -

- 哈希索引
- 覆盖索引