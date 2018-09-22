---
title: Rails 5 升级日记
date: 2018-08-02 19:54:39
tags:
  - Ruby
description: Rails 5 升级笔记
---


## Rails 5 deprecates alias_method_chain

> https://github.com/rails/rails/pull/19434

在此之前 `alias_method_chain` 经常被用来给父类的方法定义环绕别名，比如：

```
class A
  def name
    'A...'
  end
  
  def say_name
    puts name
  end
end

class B < A
end
```

如果想要在调用 name 前后做一些自己的小动作就可以

```
class B < A
  
  alias_method_chain :name, :with_b
  # 效果等同于
  # alias_method :name_without_b, :name
  # alias_method :name, :name_with_b
  
  def name_with_b
    puts 'B-1...'
    name_without_b
    puts 'B-2...'
  end
end
```

Rails 5 之后推荐使用 `Module.prepend` 来实现类似的功能


## [Rails 5.2] Remove deprecated support to passing a class to ':class_name' on associations

> It eagerloads more classes than necessary and potentially creates circular dependencies.

## [Rails 5.0] Removed deprecated 'serialized_attributes'

Rails 5 开始如果想要获得
`ActiveRecord::ConnectionAdapters::MySQL::Column` 的 `cast_type`
可以使用
`model.type_for_attribute(column.name)`

```
# columns.select { |t| t.cast_type.is_a?(ActiveRecord::Type::Serialized) }.map { |c| [c.name, c.cast_type.coder] }

columns.select { |t| type_for_attribute(t.name).is_a?(ActiveRecord::Type::Serialized) }.map { |c| [c.name, type_for_attribute(c.name).coder]
```

## [Rails 5.1] 'index_name_exists?' 方法不再接受 default 参数

> The default arg of index_name_exists? is only used the adapter does not implemented indexes. But currently all adapters implemented indexes (See [#26688][1]). Therefore the default arg is never used.

## [Rails 5.1] Correctly dump native timestamp types for MySQL

https://github.com/rails/rails/pull/23553

before this:
> Rails actually makes some of these decisions for you. Both :timestamp and :datetime will default to DATETIME

一些相关的 Issues: 

- https://github.com/rails/rails/issues/31804
- https://stackoverflow.com/questions/3928275/in-ruby-on-rails-whats-the-difference-between-datetime-timestamp-time-and-da

Mysql:

- https://dev.mysql.com/doc/refman/8.0/en/server-system-variables.html#sysvar_explicit_defaults_for_timestamp


## [Rails 5] Don't default to YAML dumping when quoting values

https://github.com/rails/rails/commit/aa31d21f5f4fc4d679e74a60f9df9706da7de373

> This behavior exists only to support fixtures, so we should handle it there. Leaving it in `#quote` can cause very subtle bugs to slip through, by things appearing to work when they should be blowing up loudly, such as [#18385][2].

Rails 5 之后将不能再使用类似下面的声明形式
```
t.string :arr_ids, array: true, default: []
```
Rails 将不会在对其做 `YAML#dump` 处理，而是直接抛出异常
`can't quote Array`

如果实在需要一个默认值，可将其替换为 dump 后的 string 来解决
```
t.string :arr_ids, array: true, default: "--- []\n"
```

## [Rails 5] Replace deprecated '#load_schema' with '#load_schema_for'

* [5.0] https://github.com/rails/rails/commit/ad783136d747f73329350b9bb5a5e17c8f8800da
* [5.1] https://github.com/rails/rails/commit/419e06b56c3b0229f0c72d3e4cdf59d34d8e5545

## [Rails 5.2] Refactor migration to move migrations paths to connection

> "`ActiveRecord::Migrator.migrations_paths=` is now deprecated and will be removed in Rails 6.0. You can set the `migrations_paths` on the `connection` instead through the `database.yml`."

```
development:
  adapter: mysql2
  username: root
  password:

development_seconddb:
  adapter: mysql2
  username: root
  password:
  migrations_paths: "db/second_db_migrate"
```

https://github.com/rails/rails/commit/a2827ec9811b5012e8e366011fd44c8eb53fc714

这个改动可能会对你的 migrate 脚本造成影响
在 `AR 5.2` 开始如果使用了
`ActiveRecord::Migrator.migrate("db/migrate/")`
需要替换为
`ActiveRecord::MigrationContext.new("db/migrate/").migrate`

`rollback` 同理替换为
`ActiveRecord::MigrationContext.new("db/migrate/").rollback`


## [Rails 5.1] Fixed: Optimistic locking does not work well with null in the database

https://github.com/rails/rails/commit/22a822e5813ef7ea9ab6dbbb670a363899a083af

此问题会导致使用乐观锁的表记录无法更新。

原因：
定义 `locking_column` 的时候没有设置默认值（默认为 NULL）时
老版本代码
```
# activerecord/lib/active_record/locking/optimistic.rb:82
lock_col = self.class.locking_column
previous_lock_value = send(lock_col).to_i
```
尝试去取旧的 `locking_column` 字段的值时，取得 `0` 值
```
# activerecord/lib/active_record/persistence.rb:193
um = arel_table.where(
          constraints.reduce(&:and)
        ).compile_update(_substitute_values(values), primary_key)
```
DB 中真实存储的是 NULL，`update` 操作将永远不被执行


## [Rails 5.1] Underrated and enhanced dirty attributes changes


## [Rails 5] When use FactoryBot#association, ActiveRecord#association will load

**Rails 5.2**
```
class Ax < ApplicationRecord
end

class Bx < ApplicationRecord
  belongs_to :ax
end

FactoryBot.define do
  factory :bx do
    association :ax
  end
end

# when create with 'association'
b = FactoryBot.create(:bx)

# association :ax will be loaded
b.association(:bx).loaded?
=> true

# or

a = FactoryBot.create(:ax)
b = FactoryBot.create(:bx, ax: a)
b.association(:bx).loaded?
=> true
```

## [Rails 5] ActiveRecord#enum will not redefine attribute

**Commit:** [Refactor enum to be defined in terms of the attributes API][3]

> In addition to cleaning up the implementation, this allows type casting behavior to be applied consistently everywhere. (#where for example). A good example of this was the previous need for handling value to key conversion in the setter, because the number had to be passed to `where` directly. This is no longer required, since we can just pass the string along to where. (It's left around for backwards compat)


## [Rails 5.1] Remove deprecated conditions parameter from #destroy_all and #delete_all

https://github.com/rails/rails/pull/27503/commits/e7381d289e4f8751dcec9553dcb4d32153bd922b

> Passing conditions to delete_all is deprecated and will be removed in Rails 5.1. 
To achieve the same use where(conditions).delete_all.

## [Rails 5] Deprecate locking of dirty records

[Deprecate locking of dirty records][4]

> Locking a record with unpersisted changes is deprecated and will raise an exception in Rails 5.2. Use `save` to persist the changes, or `reload` to discard them explicitly.

[Raises when calling `lock!` in a dirty record.][5]

> Locking a record with unpersisted changes is not supported. Use `save` to persist the changes, or `reload` to discard them explicitly.

## [Rails 5] Rename '#type_cast_' methods

- [Type#type_cast_from_database -> Type#deserialize][6]
- [type_cast_for_database -> serialize][7]
- [type_cast_from_user -> cast][8]

- [Remove Type#type_cast][9]
> This helper no longer makes sense as a separate method. Instead I'll just have `deserialize` call `cast` by default. This led to a random infinite loop in the `JSON` pg type, when it called `super` from `deserialize`. Not really a great way to fix that other than not calling super, or continuing to have the separate method, which makes the public API differ from what we say it is.


## [Rails 5] Remove internal 'typecasted_attribute_value' method

https://github.com/rails/rails/commit/057ba1280b1a5a33446387b286adb4a75acdebe4

> [It is useless since 90c8be7][10]

> **Remove most code related to serialized properties**

> Nearly completely implemented in terms of custom properties.
`_before_type_cast` now stores the raw serialized string consistently, which removes the need to keep track of "state". The following is now
consistently true:

> - `model.serialized == model.reload.serialized`
- A model can be dumped and loaded infinitely without changing
- A model can be saved and reloaded infinitely without changing


## [Rails 5] Raise ArgumentError when a instance of ActiveRecord::Base is passed to find and exists? and update


## [Rails 5] TimeHelpers#travel/travel_to travel time helpers, now raise on nested calls, as this can lead to confusing time stubbing

> Calling `travel_to` with a block, when we have previously already made a call to `travel_to`, can lead to confusing time stubbing.

Instead of:
```
travel_to 2.days.from_now do
   # 2 days from today
   travel_to 3.days.from_now do
     # 5 days from today
   end
 end
```

preferred way to achieve above is:    
```
travel 2.days do
   # 2 days from today
 end

 travel 5.days do
   # 5 days from today
 end
```


## [optimistic locking] An explicitly passed nil value is now converted to 0 on LockingType

- https://github.com/rails/rails/commit/210729c4cc05eae875b1e990c5bce39dee23e8f1
- https://github.com/rails/rails/commit/7b37e3edaf25627b6db023be5a1f8bf9733aafdd


> Make sure we handle explicitly passed nil's to lock_version as well. An explicitly passed nil value is now converted to 0 on LockingType, so that we don't end up with ActiveRecord::StaleObjectError in update record


## [Rails 5.1] Remove deprecated support to non-keyword arguments for ADTest#get/process

> Removed support for non-keyword arguments in `#process`, `#get`, `#post`, `#patch`, `#put`, `#delete`, and `#head` for the `ActionDispatch::IntegrationTest` and `ActionController::TestCase` classes.

- https://github.com/rails/rails/commit/98b8309569a326910a723f521911e54994b112fb
- https://github.com/rails/rails/commit/de9542acd56f60d281465a59eac11e15ca8b3323

old:
```
get '/profile', { id: 1 }, { 'HTTP-XX-Header' => '111' }
```

now:
```
get '/profile',
  params: { id: 1 },
  headers: { 'HTTP-XX-Header' => '111' }
```


## [Rails 5] ActionDispatch::ParamsParser is deprecated and was removed from the middleware stack

[Rails 5.2] Remove deprecated `ActionController::ParamsParser::ParseError`.
https://github.com/rails/rails/commit/e16c765ac6dcff068ff2e5554d69ff345c003de1

[Rails 5.0] `ActionDispatch::ParamsParser` is deprecated 
https://github.com/rails/rails/commit/38d2bf5fd1f3e014f2397898d371c339baa627b1
https://github.com/rails/rails/commit/5ed38014811d4ce6d6f957510b9153938370173b

`ActionDispatch::ParamsParser` was removed from the middleware.

Now call `parse_formatted_parameters` and set `env["action_dispatch.request.request_parameters"]` in `ActionDispatch::Request#POST`

```
# Override Rack's POST method to support indifferent access.
def POST
  fetch_header("action_dispatch.request.request_parameters") do
    pr = parse_formatted_parameters(params_parsers) do |params|
      super || {}
    end
    self.request_parameters = Request::Utils.normalize_encode_params(pr)
  end
rescue Http::Parameters::ParseError # one of the parse strategies blew up
  self.request_parameters = Request::Utils.normalize_encode_params(super || {})
  raise
rescue Rack::Utils::ParameterTypeError, Rack::Utils::InvalidParameterError => e
  raise ActionController::BadRequest.new("Invalid request parameters: #{e.message}")
send
```

**Rack#request json parser**
You can override Rack's POST method to support indifferent access.
Or, define middleware like:
https://github.com/rack/rack-contrib/blob/master/lib/rack/contrib/post_body_content_type_parser.rb

## [Rails 5.0] ActionController::Parameters no longer inherits from HashWithIndifferentAccess

Commit: [Make AC::Parameters not inherited from Hash][11]

> Inheriting from `HashWithIndifferentAccess` allowed users to call any enumerable methods on `Parameters` object, resulting in a risk of losing the `permitted?` status or even getting back a pure `Hash` object instead of a `Parameters` object with proper sanitization.
By not inheriting from `HashWithIndifferentAccess`, we are able to make sure that all methods that are defined in `Parameters` object will return a proper `Parameters` object with a correct `permitted?` flag.

When use nested hashe in params, `Parameters#[]` will return a `ActionController::Parameters` object, like:

```
params = ActionController::Parameters.new({a: 1, b: {b1: 'b1', b2: 'b2'}})
#=> <ActionController::Parameters {"a"=>1, "b"=>{"b1"=>"b1", "b2"=>"b2"}} permitted: false>

params[:b]
#=> <ActionController::Parameters {"b1"=>"b1", "b2"=>"b2"} permitted: false>
```

```
# actionpack-5.2.0/lib/action_controller/metal/strong_parameters.rb:813

def convert_parameters_to_hashes(value, using)
  case value
  when Array
    value.map { |v| convert_parameters_to_hashes(v, using) }
  when Hash
    value.transform_values do |v|
      convert_parameters_to_hashes(v, using)
    end.with_indifferent_access
  when Parameters
    value.send(using)
  else
    value
  end
end
```


## [Rails 5.2] Allow attributes with a proc default to be marshalled

[Models using the attributes API with a proc default can now be marshalled.][12]


  [1]: https://github.com/rails/rails/pull/26688
  [2]: https://github.com/rails/rails/issues/18385
  [3]: https://github.com/rails/rails/commit/c51f9b61ce1e167f5f58f07441adcfa117694301
  [4]: https://github.com/rails/rails/commit/578f283012f2f047b9e79ac046a32fd51e274761
  [5]: https://github.com/rails/rails/commit/63cf15877bae859ff7b4ebaf05186f3ca79c1863
  [6]: https://github.com/rails/rails/commit/4a3cb840b0c992b0f15b66274dfa7de71a38fa03
  [7]: https://github.com/rails/rails/commit/1455c4c22feb24b0ff2cbb191afb0bd98ebf7b06
  [8]: https://github.com/rails/rails/commit/9ca6948f72bef56445030a60e346376a821dbc72
  [9]: https://github.com/rails/rails/commit/ad127d8836165bba70290a9429eee5b16033e20c
  [10]: https://github.com/rails/rails/commit/90c8be76a7d00475be5ff4db2eeedde5cc936c2d
  [11]: https://github.com/rails/rails/pull/20868/files
  [12]: https://github.com/rails/rails/commit/0af36c62a5710e023402e37b019ad9982e69de4b
