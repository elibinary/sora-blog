---
title: ActiveRecord::Relation Methods 总结
date: 2017-04-04 12:19:00
tags:
  - Rails
description: 总结几个功能性很强很好用的方法
---

> 总结几个功能性很强很好用的方法

### find_each
有时会有一些需求去遍历处理大批量的数据，比如要写个脚本去遍历处理一张表的数据，这个时候就可以使用 find_each 方法了。
```
# find_each(start: nil, finish: nil, batch_size: 1000, error_on_ignore: nil)
# The find_each method uses find_in_batches with a batch size of 1000 (or as specified by the :batch_size option).
```
相比于使用 each 的优势就是，each 方法会一次性取出所有数据放到内存里再进行遍历，而 find_each 方法会分批次读取，一次读取默认值为 1000，当待处理的数据量大的时候就会显得非常有用。

Options

 - batch_size:       Specifies the size of the batch. Default to 1000.
 - start:            Specifies the primary key value to start from, inclusive of
   the value.
 - finish:           Specifies the primary key value to end at, inclusive of the
   value.
 - error_on_ignore: Overrides the application config to specify if an
   error should be raised when

### to_sql
```
# /active_record/relation.rb
# to_sql()
# Returns sql statement for the relation.
```
有时你用 ActiveRecord 写了一个稍复杂的数据库操作，不确定它到底会不会按构想中生成 sql ，这时就可以使用 to_sql 方法把生成的 sql 打印出来看一看了。
```
User.joins(:talks).to_sql
#=> "SELECT `users`.* FROM `users` INNER JOIN `user_talks` ON `user_talks`.`user_id` = `users`.`id` INNER JOIN `talks` ON `talks`.`id` = `user_talks`.`talk_id`"
```

### explain
是不是异常熟悉，没错在 ActiveRecord::Relation 中也可以使用 explain 来输出 sql 的分析结果，其用途与数据库中一般无二。
```
User.where(nickname: 'xxx').explain
# => EXPLAIN for: SELECT `users`.* FROM `users` WHERE `users`.`nickname` = 'xxx'
# +----+-------------+-------+------+---------------+------+---------+------+------+-------------+
# | id | select_type | table | type | possible_keys | key  | key_len | ref  | rows | Extra       |
# +----+-------------+-------+------+---------------+------+---------+------+------+-------------+
# |  1 | SIMPLE      | users | ALL  | NULL          | NULL | NULL    | NULL |  121 | Using where |
# +----+-------------+-------+------+---------------+------+---------+------+------+-------------+
# 1 row in set (0.00 sec)
```

其源码也很简单
```
# File activerecord/lib/active_record/relation.rb
def explain
  #TODO: Fix for binds.
  exec_explain(collecting_queries_for_explain { exec_queries })
end
```

```
# File activerecord/lib/active_record/explain.rb

# Executes the block with the collect flag enabled. Queries are collected
# asynchronously by the subscriber and returned.
def collecting_queries_for_explain # :nodoc:
  ExplainRegistry.collect = true
  yield
  ExplainRegistry.queries
ensure
  ExplainRegistry.reset
end

# Makes the adapter execute EXPLAIN for the tuples of queries and bindings.
# Returns a formatted string ready to be logged.
def exec_explain(queries) # :nodoc:
  str = queries.map do |sql, bind|
    [].tap do |msg|
      msg << "EXPLAIN for: #{sql}"
      unless bind.empty?
        bind_msg = bind.map {|col, val| [col.name, val]}.inspect
        msg.last << " #{bind_msg}"
      end
      msg << connection.explain(sql, bind)
    end.join("\n")
  end.join("\n")

  # Overriding inspect to be more human readable, especially in the console.
  def str.inspect
    self
  end

  str
end
```

可以看到，最后是使用 db 对应的 adapter 去执行 explain 命令然后把结果打印

### merge
这个方法真的是黑科技，从发现到现在我已经无法离开这个魔术方法了，先看下它的文档描述

> Merges in the conditions from other, if other is an ActiveRecord::Relation. Returns an array representing the intersection of the resulting records with other, if other is an array.

```
Weixin::User.where(nickname: 'xxx').merge(Weixin::User.joins(:tags).where(weixin_tags: {id: 1})).to_sql

#=> "SELECT `weixin_users`.* FROM `weixin_users` INNER JOIN `weixin_user_tags` ON `weixin_user_tags`.`user_id` = `weixin_users`.`id` INNER JOIN `weixin_tags` ON `weixin_tags`.`id` = `weixin_user_tags`.`tag_id` WHERE `weixin_users`.`nickname` = 'xxx' AND `weixin_tags`.`id` = 1"
```

尤其当你要写 join 语句的时候它将非常好用，像这样
```
Post.where(published: true).joins(:comments).merge( Comment.where(spam: false) )
```
