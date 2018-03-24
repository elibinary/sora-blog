---
title: 读书笔记 - Ruby 类 - 结构 
date: 2017-05-30 15:10:06
tags:
  - Ruby
description: 每个 Ruby 对象都是类指针和实例变量数组的组合
---


上一篇主要总结了 Ruby 对象的结构，一句话总结就是：

> 每个 Ruby 对象都是类指针和实例变量数组的组合

不管你在 Ruby 中使用任何值，不管它表达是什么，它都是一个对象，因此它都会有类指针和实例变量。那么 Ruby 中类的结构是什么样子的呢？

## 类结构
上一篇中提到，每个对象的 RBasic 中都保存着一个指向 RClass 结构体的指针用来记忆它的类。那么这个 RClass 结构体长什么样呢。

要搞清楚这个问题，我们需要现在思考一下，类中都保存那些信息。
首先非常容易想到，类中保存有方法定义，实例变量名，常量，还有类指针（因为上面说过，ruby 中一切都是对象）

上篇中说过，RObject 结构体中有存一个 ivptr 的指针指向实例变量值数组，也就是说 RObject 中保存了实例变量的值，但其实并没有保存实例变量的名字，实例变量名实际被保存在对象的类中。
*实际上你去看 RObject 的 C 结构体定义（ruby/ruby.h）就会发现在结构体内有一个 iv_index_tbl 的指针指向一个散列表，该散列表中保存的是实例变量名及其在 ivptr 数组中位置的映射，这些散列值存储在每个对象的类所对应的 RClass 结构体中。*

除此之外还有些什么呢？不要忘了类中是可以定义类级的实例变量以及变量的，那么类实例变量和类变量是怎么保存的。

### 类实例变量和类变量
先来看看类实例变量，所谓类实例变量，如果你还没有转过来这个弯的话不妨再回想一下上面反复说道的一句话：**ruby 中一切皆对象**。这样一来是不是就非常容易理解所谓类实例变量到底是个啥了，类也是对象，是对象就有类指针和实例变量。
```
class Myclass
  @variable_alpha

  def self.variable_alpha=(value)
    @variable_alpha = value
  end

  def self.variable_alpha
    @variable_alpha
  end
end

Myclass.variable_alpha
#=> nil
Myclass.variable_alpha = 'go'
Myclass.variable_alpha
#=> "go"
```

其实类级别的实例变量就是在类的上下文中创建的实例变量，如同对象级别的实例变量就是在对象上下文中创建的实例变量一样。

那么类实例变量在其子类中将会如何
```
class Alpha < Myclass
  @variable_alpha = 'alipha'
end

class Bate < Myclass
  @variable_alpha = 'bate'
end

Alpha.variable_alpha
#=> "alipha"
Bate.variable_alpha
#=> "bate"
Myclass.variable_alpha
#=> "go"
```

其实两个子类中都分别有自己的 @variable_alpha 副本。它的值并不会被共享。

那么类变量呢，说实话类变量起初是给了我很大困扰的，虽然我使用 ruby 这么久了使用也很少会用到类变量。
如果说类实例变量是把类看做一个对象来在其上下文中创建的实例变量的话，类变量就是把类就看做是类来在其上下文中创建的变量。（个人理解）

类变量是会在其子类中被共享的
```
class Myclass
  @@class_alpha = 'go'

  def self.class_alpha
    @@class_alpha
  end
end

Myclass.class_alpha
#=> "go"

class Alpha < Myclass
  @@class_alpha = 'alipha'
end

Alpha.class_alpha
#=> "alipha"
Myclass.class_alpha
#=> "alipha"

class Bate < Myclass
  @@class_alpha = 'bate'
end
Alpha.class_alpha
#=> "bate"
Myclass.class_alpha
#=> "bate"
```

创建类变量时，Ruby 会在该类中创建唯一的值，并在其任意子类中共享该值。
如果是类实例变量，Ruby 会在该类和其子类中创建各自独立使用的值。

那么，现在知道类结构中会保存有类实例变量和类变量，实际上 Ruby 在同一张表里保存类变量和类实例变量。

除此之外，我们上面也提到了继承，在创建类时，Ruby 允许随意指定一个超类来实现单继承。如果没有指定超类，Ruby 会默认指派 Object 类作为超类。
比如上面的：
```
class Alpha < Myclass
end
```
Alpha 的类结构一定包含了 Myclass 类的引用，以便 Ruby 能够找到其超类中的方法和属性。
注意这里的指向超类的指针与之前提到的 klass 指针并不是同一个。klass 指针表示 Ruby 类是哪个类的实例，结果会一直是 Class 类。

那么来看下 RClass 的结构：

![rclass][1]

Ruby 使用两个独立的结构体来表示类，RClass 和 rb_classext_struct，每个 RClass 总是有一个指向对应 rb_classext_struct 的指针。

---
上面提到单继承，从 RClass 的结构就可以看出，ruby 是不支持多继承的，但是你可以使用 mix-in 的方式，也就是 module 的方式来实现多重继承的效果。


  [1]: http://7xsger.com1.z0.glb.clouddn.com/image/jpgrclass.png
