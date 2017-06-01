---
title: Rails - Delete the records
date: 2016-09-10 18:23:14
tags:
  - Rails
description: 这两天看了下 ActiveRecord 关于删除记录的部分，故有此记
---

### ActiveRecord::Relation
**delete**
**delete_all**

* delete(id_or_array)
此方法参数为 primary key ，该方法的返回值为删除 rows 的计数，该方法并不会先把 Active Record object 实例化，所以 callbacks 方法并不会被调用。

以下是文档中的例子：
```
# Delete a single row
Todo.delete(1)

# Delete multiple rows
Todo.delete([2,3,4])
```
下面看下其源码实现：
```
# File activerecord/lib/active_record/relation.rb
def delete(id_or_array)
  where(primary_key => id_or_array).delete_all
end
```
源码很简单，这个方法其实就是调用了 delete_all 方法

* delete_all(conditions = nil)
该方法也不会触发 callbacks 方法，起返回值也是受影响的 rows 计数，在效率上文档是这样说的 
"This is a single SQL DELETE statement that goes straight to the database, much more efficient than destroy_all."
之后看了 destroy 和 destroy_all 就会对这句话有更多的理解。

例子：
```
Post.delete_all("person_id = 5 AND (category = 'Something' OR category = 'Else')")
Post.delete_all(["person_id = ? AND (category = ? OR category = ?)", 5, 'Something', 'Else'])
Post.where(person_id: 5).where(category: ['Something', 'Else']).delete_all
```


**destroy**
**destroy_all**

* destroy(id)
这个方法就和上面 delete 系方法不同，首先实例化的对象然后在执行删除操作，所有的 callbacks 和 filters 都将会被执行到

例子：
```
# Destroy a single object
Todo.destroy(1)

# Destroy multiple objects
Todo.destroy([1,2,3])
```

来看下源码实现
```
# File activerecord/lib/active_record/relation.rb
def destroy(id)
  if id.is_a?(Array)
    id.map { |one_id| destroy(one_id) }
  else
    find(id).destroy
  end
end
```

源码中表示该方法会先实例化一个一个的对象再删除。

### ActiveRecord::Associations::CollectionProxy

下面来看下 model 关联时的 :dependent option 
对 has_many 来说
* 如果不设置 :dependent ，那么默认的就是 :nullify ，在这种模式下删除操作只会把 foreign keys 的值设为 NULL 而不会真正删除掉记录

例如：
```
class User < ActiveRecord::Base
  has_many :posts # dependent: :nullify option by default
end

user.posts
# => #<ActiveRecord::Associations::CollectionProxy [#<Post id: 1, body: "aaa", user_id: 1, created_at: "2016-09-09 02:18:47", updated_at: "2016-09-09 02:18:47">, #<Post id: 2, body: "bbb", user_id: 1, created_at: "2016-09-09 02:18:58", updated_at: "2016-09-09 02:18:58">]>

user.posts.delete(Post.find(1))
# or (other way)
user.posts.delete(1)

Post.find(1)
# => #<Post id: 1, body: "aaa", user_id: nil, created_at: "2016-09-09 02:18:47", updated_at: "2016-09-09 02:18:47">

user.posts.delete_all

user.posts.size
# => 0

Post.find(1, 2)
# => [#<Post id: 1, body: "aaa", user_id: nil, created_at: "2016-09-09 02:18:47", updated_at: "2016-09-09 02:18:47">, #<Post id: 2, body: "bbb", user_id: nil, created_at: "2016-09-09 02:18:58", updated_at: "2016-09-09 02:18:58">]
```

* 当设置 dependent: :destroy 时，实际上就会去调用其 destroy 方法，记录将会从数据库中移除。
"all the records are removed by calling their destroy method."

当使用 delete 方法时，被删除记录会被实例化并且删除时 callback 方法会被触发
```
class User < ActiveRecord::Base
  has_many :posts, dependent: :destroy
end

user.posts
# => #<ActiveRecord::Associations::CollectionProxy [#<Post id: 7, body: "1", user_id: 1, created_at: "2016-09-09 06:20:17", updated_at: "2016-09-09 06:20:17">, #<Post id: 8, body: "2", user_id: 1, created_at: "2016-09-09 06:20:20", updated_at: "2016-09-09 06:20:20">, #<Post id: 9, body: "3", user_id: 1, created_at: "2016-09-09 06:20:23", updated_at: "2016-09-09 06:20:23">]>

user.posts.delete(7,8)
# => [#<Post id: 7, body: "1", user_id: 1, created_at: "2016-09-09 06:20:17", updated_at: "2016-09-09 06:20:17">, #<Post id: 8, body: "2", user_id: 1, created_at: "2016-09-09 06:20:20", updated_at: "2016-09-09 06:20:20">]

### DEBUG INFO
# Post Load (0.4ms)  SELECT `posts`.* FROM `posts` WHERE `posts`.`user_id` = 1 AND #`posts`.`id` IN (7, 8)
#   (0.2ms)  BEGIN
#  SQL (0.3ms)  DELETE FROM `posts` WHERE `posts`.`id` = 7
#  SQL (0.2ms)  DELETE FROM `posts` WHERE `posts`.`id` = 8
#   (43.4ms)  COMMIT
```

当使用 delete_all 方法时，虽然设置了 :dependent 为 :destroy ，但实际上其策略却会是 :delete_all ，这时删除操作并不会将记录实例化， callback 方法也不会被触发，实际操作将会是一条 DELETE 语句
```
user.posts.delete_all
### DEBUG INFO
# SQL (0.7ms)  DELETE FROM `posts` WHERE `posts`.`user_id` = 1
```

* 当设置 dependent: :delete_all 时

使用 delete 方法，记录会被真正删除，但是却不会调用其 destroy 方法，也不会触发 callbacks。（注意，如果参数传递的是 id 值，那么当此条目不存在时将会抛出异常 'ActiveRecord::RecordNotFound'）
```
user.posts.delete(12)
### DEBUG INFO
#  Post Load (0.4ms)  SELECT  `posts`.* FROM `posts` WHERE `posts`.`user_id` = 1 AND #`posts`.`id` = 12 LIMIT 1
#   (0.2ms)  BEGIN
#  SQL (0.3ms)  DELETE FROM `posts` WHERE `posts`.`user_id` = 1 AND `posts`.`id` = 12
#   (0.6ms)  COMMIT
```

* 对于 destroy(*records), destroy_all() 方法

这两个方法都会忽视掉 :dependent option
