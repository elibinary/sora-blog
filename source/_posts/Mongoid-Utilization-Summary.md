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

上面写了一些MongoDB的特性，下面开始本篇的正题

- ** 关于模糊查询 **

通常的关系数据库SQL写法是这样的

```ruby
User.where("name like ?", '%...%')
```

Mongoid的写法

```ruby
User.where(:name => /abc/)
User.where(:name => /#{str}/)
```

- ** query for array field **

前面提到 mongodb 的存储格式是json文件，其 document 的type可以是array等格式，mongo 对于这种内容也提供了很多方便的检索方法：

```ruby
# 现有一张活动的表，其中 user_ids 是array类型
a1 = create(user_ids: [11, 22, 12])
a2 = create(user_ids: [22, 33, 23])
a3 = create(user_ids: [11, 22, 33])
a4 = create(user_ids: [1])

# 检索出user_ids数组中包含所查数字的记录
Activity.where(user_ids: 11)
# => [a1, a3]
Activity.where(user_ids: 22)
# => [a1, a2, a3]

# 检索出user_ids数组中包含所查数组任意数字的记录
Activity.where(:user_ids.in => [12, 23])
# => [a1, a2]

# 检索出user_ids数组中包含所查数组所有数字的记录（子集）
Activity.all_in(user_ids: [22, 33])
# => [a2, a3]
Activity.all_in(user_ids: [11, 22, 23])
# => []
# 也可以这样写
Activity.where(:user_ids.all => [22, 33])

# 还能这样查
# 检索出user_ids数组中有大于/小于所给数字的记录
# gt: 大于
# lt: 小于
# gte: 大于等于
# lte: 小于等于
Activity.where(:user_ids.gte => 23)
# => [a2, a3]

# 还可以按个数查
# 检索出user_ids数组中包含所给个数个元素的记录
# 检索出user_ids数组只包含一个元素的记录
Activity.where(:user_ids.with_size => 1)
# => [a4]
# 真是mongodb的语句是这样的
# db.model.find({user_ids: {$size: 1}})
# 当然也能检索不等于所给数目的
# db.model.find({user_ids: {$not: {$size: 1}}})
# 转换成mongoid所给方法：
Activity.where(:user_ids.not => {"$size" => 1})
# => [a1, a2, a3]
```

因为mongodb是不要求同一个集合里的不同的文档有相同的key的，所有就有可能 Activity 表中某些 document 没有 user_ids 这个 key，可以用下面方法来检索

```ruby
# 判断哪些 document 中没有 user_ids 这个 key（不是这个字段为空）
Activity.where(:user_ids.exists => true)
```

需要提到一点的是，如果使用 $size 方法 mongodb 将不会使用索引，下面有更好的写法

```ruby
Activity.where(:user_ids.ne => [])
# 等价于
Activity.where(:user_ids.not => {"$size" => 0})

# $ne: not equal
```

- ** about embeds **

有很多 embeds_one 、embeds_many 的用法，也是可以深入检索的

```ruby
embeds_one: attachment

# 对 Activity 表的内嵌对象 attachment 的 key 进行检索
Activity.where(:'attachment.url' => /#{str}/)
```

<br /> 
使用过程中还遇到了 mongoid limit 的一个小问题
```ruby
activity = Activity.limit(3)
# if Activity.count = 1111, then activity.count = 1111
# 这是因为 count ignores 了 limit操作,
# don't mind
# If you want to know how many results are returned
Array(activity).length = 3
```


<br /> 
<br /> 
*  *  *
PS: 后续使用遇到的使用的查询和方法将持续更新进本篇文章 ~_~