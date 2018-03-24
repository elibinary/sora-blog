---
title: 读书笔记 Ruby 的 Module 扩展
date: 2017-06-11 13:15:05
tags:
  - Ruby
description: 上篇中有简单说到 module 的 include，下面来看一些稍复杂的使用情况以及 ruby 是如何处理的
---

上篇中有简单说到 module 的 include，下面来看一些稍复杂的使用情况以及 ruby 是如何处理的

### include

> 那么，首先问题：在 module A 中 include 了 module B，然后 class M 再 include 模块 A，现在 class M 的祖先链是什么样子的？

```
module B
  def say
    puts 'I am B'
  end
end

module A
  include B
  def say
    puts "I'm A"
  end
end

class M
  include A
end

M.new.say
# => I'm A
```

可以看出方法查找先找到的 A 中的 #say 方法，那么 M 的祖先链应该是这样的：
```
M.ancestors
# => [M, A, B, Object, Kernel, BasicObject]
```
事实上，当把 B include 到 A 中时， Ruby 会创建 B 的副本，然后把它设置为 A 的超类，也就是 A 的 super 指针指向 B 的副本。
虽然 module 本身不允许被指派超类，然后在 Ruby 内部可以。
最后把 A include 到 M 中，Ruby 会迭代这两个模块，然后依次作为超类插入。

> 修改已经被 include 的 module 会怎样？

```
module B
  def say
    puts 'I am B'
  end
end

class M
  include B
end

M.new.say
# I am B
M.new.methods
# =>  => [:say, :instance_of?, :public_send ...

module B
  def re_say
    puts 'Double B'
  end
end

M.new.say
# I am B
M.new.re_say
# Double B
M.new.methods
# => [:say, :re_say, :instance_of?, :public_send ...
```

 那么，这是为什么呢，Ruby 做了什么处理
 
 事实上，Ruby 在 include module 时，拷贝副本时拷贝的是 RClass 结构体，但是并不连 m_tbl 指向的方法表一同拷贝，也就是说副本与原 module 是共享同一个方法表的。
 
 ### prepend
 
 有时候我们会有需求期望当前类的方法不会重载掉 module 中的方法，这个时候就会使用 #prepend 方法

```
 module B
  def say
    puts 'I am B'
  end
end

class M
  prepend B

  def say
    puts 'I am M'
  end
end

M.new.say
# I am B
M.ancestors
# => [B, M, Object, Kernel, BasicObject]
```

使用 prepend 时，在超类链中，Ruby 会把 B 放在 M 前面

那么， Ruby 在其中做了什么呢？Ruby 是沿祖先链向后查找方法的，它是如何在 super 指针向下指的情况下做到这样的？

实际上，Ruby 在内部使用了个巧妙的小手段，当使用 prepend 包含一个 module 时，Ruby 会创建 M 的 origin class，并把它设置为前置模块 B 的超类。Ruby 使用 rb_classext_struct 机构体中的 origin 指针指向原 class。 Ruby 还会从 origin class 中把方法全部移动到原 class 中，这意味着这些方法将是可以被前置模块 B 重载的。