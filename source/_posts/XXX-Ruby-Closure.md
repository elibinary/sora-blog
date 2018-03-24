---
title: Ruby 中的闭包及应用
date: 2017-07-01 13:34:21
tags:
  - Ruby
description: 简单来说，闭包就是引用了自由变量的函数
---

> In languages where functions are first-class citizens, the language supports passing functions as arguments to other functions, returning them as the values from other functions, and assigning them to variables or storing them in data structures. -- from wiki

## 闭包 (Closure)
在计算机科学中，简单来说，闭包就是引用了自由变量的函数。
这里的自由变量其实可以理解为与其相关的引用环境。闭包被用来在一个函数与其相关的引用环境之间创建关联关系，被引用的环境（或者说变量）将和这个函数一同存在，即使已经离开了创造它的环境也不例外。

闭包有几个很重要的特征：
1. 闭包可以被当做参数进行传递，也可以作为函数的返回值
2. 闭包在被创建时，会与当前环境进行关联，换言之它会记住该环境下的变量，并在任何地方执行时都能够访问它引用的变量，哪怕已经不在创建它的环境的范围
3. 惰性求值，闭包只有在被调用时才执行操作

简单来说，在没有闭包存在时，变量的生命周期只限于创建它的环境。但当闭包被创建并引用了这个变量，它就会一直存在。

## Ruby 中的闭包
要理解 ruby 中的闭包，就要先来了解下 block 的慨念

### 块
> block 是 ruby 中最常用且最强大的特性之一

block 不但可以传递代码片段给枚举方法，而且可以利用 yield 关键字定义能调用 block 的函数另作他用。而 block 背后的理论便是闭包，换句话说，block 即是 ruby 的闭包实现。

下面是一段 block 的简单应用
```
str = 'string one'
10.times do
    puts "#{str} in block"
end
```
从这个简单的例子可以看出，block 是可以访问上下文环境或父层作用域中的变量的。

在 ruby 中一方面，block 的行为像是独立的方法，另一方面它是上下文函数或方法的一部分

为了进一步理解 block，来看下 ruby 的 rb_block_t 结构体

![rb_block_t][1]

可以看出，block 就是函数和调用该函数时所用环境的组合

### Lambda 与 Proc
> Ruby 允许把函数作为数据值保存在变量中，以及作为参数进行传递。

lambda 和 proc 把 block 的应用做了进一步的延伸扩展。完美表现 'first-class citizens' 的特性。

在 ruby 中，可以使用 lambda 或者 proc 把块转换为数据值。
```
def show_me
    total_num = 256
    lambda do |params|
        puts "now: #{total_num - params}"
    end
end

block_res = show_me
block_res.call(128)
```

可以看出，在 lambda 被调用时已经不在 show_me 方法的作用域内了，但是它依然可以访问生命周期仅在 show_me 方法作用域内的局部变量 total_num 。

实际上，lambda 和 proc 关键字使用时都会创建 proc 对象

![proc_obj][2]

在内部实现里，ruby 使用 RTypedData 结构体和 rb_proc_t 结构体一起构成 proc 对象的实例。 block 作为闭包在 ruby 的实现，其 rb_block_t 也被包含在 rb_proc_t 中。

这里解释一下 envval 指针，当调用 lambda 时，ruby 会把当前栈帧复制到堆中。其实也就是在堆中保存了一份栈帧的副本。
envval 指针指向了一个内部环境对象，其实就是 rb_env_t 结构，而 rb_env_t 中保存了一个指向那份栈帧副本的指针。实际上 rb_env_t 是对栈帧副本的包装。


此处说到的栈和堆，在这里并不是指数据结构中的栈结构和堆结构（二叉树的一种）。这里指的是栈内存和堆内存，也就是 ruby 保存数据的两个地方。

ruby 在栈中保存每个方法的本地变量、返回值和参数。栈中的值只在方法运行时有效，一旦方法结束，该方法的栈帧及里面的所有值都会被清除。
而堆用来保存需要保留一段时间的信息。在堆中的每个值，只要它被引用，就一直有效。其实这里涉及到了 GC 的概念，GC 会清除堆中不被引用的值以释放内存。

实际上栈中仅保存数据的引用，也就是说栈中仅仅保存了一堆指针，实际的结构体保存在堆中。当然，对于简单的整数值、符号及一些像 nil、true等值来说，引用就是真实的值。

  [1]: http://7xsger.com1.z0.glb.clouddn.com/image/jpg/rb_block_t.png
  [2]: http://7xsger.com1.z0.glb.clouddn.com/image/jpg/proc_obj.png