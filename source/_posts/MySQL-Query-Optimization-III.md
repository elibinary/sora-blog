---
title: MySQL笔记之查询优化 - III
date: 2016-07-30 14:05:34
tags:
  - MySQL
description: MySQL笔记之特殊查询优化
---


### count() 优化
今天主要看一下 count()聚合函数，以及如何优化其使用

count() 函数有两个作用：
  
    1. 统计某个列值的数量
    2. 统计行数
    
该函数在统计列值时要求列值非空，也就是说它不会去统计值为NULL的。而当MySQL确认count()的参数不为空时，实际上就是在统计行数。最简单的例子就是当我们使用 count(*) 的时候，这种情况下通配符 * 并不会像我们想的那样扩展成所有的列，它会忽略所有的列而直接统计所有的行数。如果MySQL知道某个列col不可能为NULL值，那么内部就会将 count(col) 表达式优化为 count(*) 。

有些场景我们的需求事实上是不需要完全精确的count()结果的，那么这时使用 explain 出来的优化器估算的行数将会是一个不错的近似值，执行explain并不会真正的去执行查询，所以成本较低。很多时候，计算精确值所需要的成本是很糟糕的，而近似值则非常高效。通常的，count()都需要扫描大量的行才能获得精确的结果。

### 关联查询
进行关联查询时，先保证待连接表的 ENGINE 和DEFAULT CHARSET 保持一致（可有效提速），保证 on 条件列的索引（重要！）。MySQL的关联算法是 Nest Loop Join，通过驱动表的结果集作为循环基础，一条条的通过该结果集中的数据作为过滤条件到下一个表中查询数据，最后合并。（N表关联同理）（因此要对关联查询做优化就是尽量减少 nest loop 的循环次数）。

对于一个关联查询，可以先通过 explain 来查看语句的具体情况
```
explain  
select sessions.id from `sessions`   
left join `__temp` on sessions.id = __temp.id;  
```
其结果中第一条出现的表就是驱动表.
故使用小数据量的结果集作为驱动表为最优（尽量缩小驱动表的基础数据量）。
其实优化器在你不指定驱动表的情况下会帮你选择最优的驱动表，所以当你不确定时不要强指定驱动表，交给MySQL优化器将是个不错的选择。

**关联子查询**
对于关联子查询一定要注意，举一个最糟糕的 IN 查询的例子

```
select * from user where user_id in(
    select user_id from user_tag where tag_id = 10
);
```

对于这个查询，一般我们会认为将这样执行：
```
select group_concat(user_id) from user_tag where tag_id = 10;
select * from user where user_id in(...);
```
但事实上，MySQL不会这样执行，它会将相关的外层表压到子查询中，它认为这样可以更高效的执行查询：
```
select * from user where exists(
   select user_id from user_tag where tag_id = 10
   and
   user_tag.user_id = user.user_id
);
```

explain一下我们可以看到，由于子查询需要根据user_id来关联外表user，故MySQL要先对file表进行全表扫描，然后根据返回的user_id来逐个进行子查询。那么这时如果user是一张很大的表，显而易见这简直是一个灾难的查询。

使用关联查询时一定要仔细考虑，最好先进行测试，很多时候，关联子查询也是一种非常合理自然甚至性能更好的写法。