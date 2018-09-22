---
title: ActiveRecord In Rails
date: 2018-09-22 15:56:46
tags:
  - Ruby
description: ORM In Rails
---


## What is ORM

ORM 全称 Object Relational Mapping
简单来说就是建立面向对象编程中对象与 db 存储之间的映射及转换，使得可以通过在编程中操作虚拟对象的形式来操作数据库

关于到底要不要用 ORM 的疑问，我觉得这完全是一个取舍的问题。ORM 不是必须的，但它确是一个非常有价值的设计，它将软件开发人员从大量相同的数据持久层相关编程工作中解放出来。另外在贴个链接（[what-are-the-advantages-of-using-an-orm][1]）吧

## Active Record

> AR(Object-relational mapping in Rails) connects classes to relational database tables to establish an almost zero-configuration persistence layer for applications.

AR 在 rails 中不仅仅是其 ORM ，同时也被用来驱动整个 MVC 的 M 层

另外，Active Record 本身是一个领域模型，领域模型记录了一个系统中的关键概念和词汇表，显示出了系统中的主要实体之间的关系，并确定了它们的重要的方法和属性（以可视化的形式描述系统中的各个实体及其之间的关系）

基于 Active Record 领域模型的框架在别的语言中也被广泛使用，如：

- python - SQLObject
- PHP - Yii Framework ActiveRecord

---

*之后文中出现的 AR 默认为 Rails 中的 ActiveRecord*

---


## What's in the AR

先看张图

![AR_Struct][2]

先简单来看，AR 可以简单分为三个部分

- Model: 整个 M 层的驱动者，封装了许多相关的方法（为 model 提供了许多祖先）
- Relation: 抽象语法数的上层应用，提供了惰性查询的支持
- Adapter: 提供了 db connection, db driver 的封装

首先先来看 Model 这一部分：

![What in AR][3]

Rails 的 AR model 继承自 `ActiveRecord::Base` 并从此处获得了一连串的‘祖先’，此处只列取了一少部分。

在当前版本中（Rails 5.2），使用 `#ancestors` 看下大概当一个 model 出生时，它就有了 65 个祖先（从侧面也说明了 AR 确是挺重的 [笑]），当然这些祖先并不完全都是属于 AR 的

下面就简单介绍下每个`祖先`都是干嘛的，它们是如何为这个 AR 丰富的功能添砖加瓦的

### ActiveRecord::Suppressor

> ActiveRecord::Suppressor prevents the receiver from being saved during a given block

简单来讲， Suppressor [səˈpresə(r)]  提供了方法来使得你可以跳过 callback 中的链式创建项，举个例子

```
class A < ApplicationRecord
  after_save do
    B.create
  end
end
```

有时可能你并不想在保存 A 的时候创建 B，那么可以通过

```
B.suppress do
  A.create(something)
end
```

来达到目的

不过多提一句，这个功能使用场景并不多，而且我个人不太建议随便使用，因为这会为个例而改变主流程的行为，降低代码的可读性

### ActiveRecord::Reflection

> An association is a connection between two Active Record models

> Reflection enables the ability to examine the associations of Active Record classes and objects

这里 Reflection 不仅仅支撑了 Association，它也为 Aggregation 提供了基础支持

可以说 Reflection obj 是对 association 和 association 的支持和描述，Rails 通过它们来实现对关系数据库的外键关联关系的映射
（*在 db 模型设计中是建议避免使用 db 的外键来约束关联模型的，取而代之应该在代码层面去维护这层关联关系，而实现这一目标的辅助方法也是在这一层实现提供的（比如关联，比如校验）*）

![此处输入图片的描述][4]

每个 association 关系都会先建立与之对应的 reflection obj

reflection 提供了很多方法支持，如 table_name, join_keys, join_table, counter_cache, foreign_key

### ActiveRecord::Transactions

> Transactions are protective blocks where SQL statements are only permanent if they can all succeed as one atomic action(save and destroy are automatically wrapped in a transaction)

这一层并不是真正的 `DB Transaction` 功能提供者，它的主要功能

- 为 AR Model 提供 commit, rollback 等 callback 钩子
- 为 AR Model 提供封装好的简单易用的 transaction 方法支持（ActiveRecord::Base#transaction）

真正提供 `Transaction` 功能封装的是 `ActiveRecord::ConnectionAdapters Transaction`

### ActiveRecord::NestedAttributes, ActiveRecord::AutosaveAssociation

> NestedAttributes allow you to save attributes on associated records through the parent

> AutosaveAssociation is a module that takes care of automatically saving associated records when their parent is saved

这两层提供的方法和实现都比较简单就不做赘述了，想深入了解的可以直接浏览下源码

### ActiveRecord::Timestamp

> Automatically timestamps create and update operations if the table has fields named

这一层也相当简单，代码量也极少，但同时也是我们最常用的，`created_at` `updated_at` 就来自这一层

同时也封装了其自动填充及 `updated_at` 的触发更新


### ActiveRecord::Callbacks

> Callbacks are hooks into the life cycle of an Active Record object that allow you to trigger logic before or after an alteration of the object state

callback 相信大家都不陌生，其实定义的所有 callbacks 都存储在 queues 中，想要查看可以通过方法拿到整个 callback list

一下复制自 AR 注释

```
 # == Debugging callbacks
  #
  # The callback chain is accessible via the <tt>_*_callbacks</tt> method on an object. Active Model \Callbacks support
  # <tt>:before</tt>, <tt>:after</tt> and <tt>:around</tt> as values for the <tt>kind</tt> property. The <tt>kind</tt> property
  # defines what part of the chain the callback runs in.
  #
  # To find all callbacks in the before_save callback chain:
  #
  #   Topic._save_callbacks.select { |cb| cb.kind.eql?(:before) }
  #
  # Returns an array of callback objects that form the before_save chain.
  #
  # To further check if the before_save chain contains a proc defined as <tt>rest_when_dead</tt> use the <tt>filter</tt> property of the callback object:
  #
  #   Topic._save_callbacks.select { |cb| cb.kind.eql?(:before) }.collect(&:filter).include?(:rest_when_dead)
  #
  # Returns true or false depending on whether the proc is contained in the before_save callback chain on a Topic model.
```

### Dirty

> Dirty provides a way to track changes in your object

### ActiveRecord::AttributeMethods

> AttributeMethods generates attribute related methods for columns in the database accessors, mutators and query methods

### ActiveRecord::Attributes

> Attributes defines an attribute with a type on this model, it will override the type of existing attributes if needed


---


### ActiveRecord::Relation

> Arel provides an SQL abstraction that simplifies out Active Record and provides the underpinnings for the relation functionality in Active Record

Relation 背后就是 arel 抽象语法树

[using-arel-to-compose-sql-queries][5]

Relation 的 value methods 大致分为这三类

![Relation Values][6]

在语法树的存储中也会根据这三个类别进行不同规则的处理

可以通过 relation#values 来返回语法树中存储的所有查询条件



  [1]: https://stackoverflow.com/questions/398134/what-are-the-advantages-of-using-an-orm
  [2]: http://7xsger.com1.z0.glb.clouddn.com/ar_struct.png
  [3]: http://7xsger.com1.z0.glb.clouddn.com/what_in_ar.png
  [4]: http://7xsger.com1.z0.glb.clouddn.com/what_in_at_associa_reflect.png
  [5]: https://robots.thoughtbot.com/using-arel-to-compose-sql-queries
  [6]: http://7xsger.com1.z0.glb.clouddn.com/relation_value_methods.png