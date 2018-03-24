---
title: 读书笔记 Ruby 的继承与方法查找
date: 2017-06-03 13:50:57
tags:
  - Ruby
description: 在 ruby 中，在定义一个类时没有指定其超类，那么它的超类默认被指定为 Object
---

在 ruby 中，在定义一个类时没有指定其超类，那么它的超类默认被指定为 Object

```
class MyClass
end

MyClass.superclass
# => Object

class SonClass < MyClass
end
SonClass.superclass
# => MyClass
```

可以看出，当 SonClass 继承 MyClass 时就是把 rb_classext_struct 中的 super 指针指向 MyClass

那么 Ruby 又是如何实现多继承的效果呢，说之前先说下 ruby 中 module 的概念。

### module
在 Ruby 中，模块和类非常的相似，但他们是不同的，不同主要体现在三个方面：
1. 模块不能直接创建对象，也就是说模块没有 new 方法
2. 模块不能指定超类
3. 可以把模块包含进类中

除此之外，模块和类基本类似，其实 Ruby 内部实现模块的方式与实现类的方式相同，也是使用 RClass 和 rb_classext_struct 两个结构体来实现的。结构大致如下：

![此处输入图片的描述][1]

如图所示，在其结构体中还是存在 super 指针的，这是因为 module 在内部是有超类的，只是不允许手动去指定它。

那么在将 module include 进类中的时候发生了什么？
```
module MyModule
end

class MyClass
  include MyModule
end
```
当你 include 的一个 module 的时候，实际上 Ruby 会为该 module 创建一个结构体副本，然后把类的 super 指针指向该 module 副本，再把 module 副本的 super 指针指向该类原本的超类，其整个过程类似于链表结构的插入操作。

![此处输入图片的描述][2]

这样的超类链条就组成了 Ruby 类结构的超类链或者叫祖先链。

```
MyClass.ancestors
# => [MyClass, MyModule, Object, Kernel, BasicObject]
```

### 方法查找
Ruby 中的方法查找正是基于上面的超类链结构来进行的。而且整个算法核心思想比想象中的还要简洁，以上面为例
```
my_obj = MyClass.new
my_obj.one_method
```

![此处输入图片的描述][3]

1. 首先找到当前对象的类（klass 指针指向的类），把该类作为当前类
2. 在当前类的方法表(m_tbl)中查找方法
3. 把当前类的超类(super 指针所指)作为当前类，再次执行2
4. 重复上面 2、3 步直到找到方法

注意方法查找是沿着超类链顺序的向上查找的，一旦找到立刻返回。所以超类在其超类链中的顺序直接影响方法重载。

```
module MyModule
  def say_hello
    puts 'Are you ok?'
  end
end

class MyClass
  def say_hello
    puts 'Hello, MyClass'
  end
end
```
下面
```
class SonClass < MyClass
end

SonClass.new.say_hello
# Hello, MyClass

SonClass
```
如果 include MyModule
```
class SonClass < MyClass
  include MyModule
end

SonClass.new.say_hello
# Are you ok?
SonClass.ancestors
# => [SonClass, MyModule, MyClass, Object, Kernel, BasicObject]
```

Ruby 内部是使用类继承来实现 module 的 include 的。本质上，include module 跟指定超类没有区别，它们都是通过使用类的 super 指针来实现，在类中 include 多个module 等价于指派多个超类。

但是，请注意一点，Ruby 内部依旧强制使用单一的祖先链，虽然你可以 include 多个 module 但是 Ruby 会让它们保持在一个单一的链表中，而这也同样使得方法查找变得简单统一。
```
module MyModule
  def say_hello
    puts 'Are you ok?'
  end
end

module HerModule
  def say_hello
    puts "I'm a little fairy!"
  end
end

class MyClass
  def say_hello
    puts 'Hello, MyClass'
  end
end

class SonClass < MyClass
  include MyModule
  include HerModule
end

SonClass.new.say_hello
# I'm a little fairy!
SonClass.ancestors
# => [SonClass, HerModule, MyModule, MyClass, Object, Kernel, BasicObject]
```

----------

还有一点关于 superclass 方法
我本以为 #superclass 方法是直接返回的 super 指针所指
```
module MyModule
end

class MyClass
end

class SonClass < MyClass
  include MyModule
end
SonClass.superclass
# => MyClass
SonClass.ancestors
# => [SonClass, MyModule, MyClass, Object, Kernel, BasicObject]
```

可以看到，#superclass 跳过了 module，虽然它的 super 指针确实指向 module。
然后我就去找了 #superclass 的实现

```
// ruby/object.c

/*
 *  call-seq:
 *     class.superclass -> a_super_class or nil
 *
 *  Returns the superclass of <i>class</i>, or <code>nil</code>.
 *
 *     File.superclass          #=> IO
 *     IO.superclass            #=> Object
 *     Object.superclass        #=> BasicObject
 *     class Foo; end
 *     class Bar < Foo; end
 *     Bar.superclass           #=> Foo
 *
 *  Returns nil when the given class does not have a parent class:
 *
 *     BasicObject.superclass   #=> nil
 *
 */
 
VALUE
rb_class_superclass(VALUE klass)
{
    VALUE super = RCLASS_SUPER(klass);

    if (!super) {
  if (klass == rb_cBasicObject) return Qnil;
  rb_raise(rb_eTypeError, "uninitialized class");
    }
    while (RB_TYPE_P(super, T_ICLASS)) {
  super = RCLASS_SUPER(super);
    }
    if (!super) {
  return Qnil;
    }
    return super;
}

VALUE
rb_class_get_superclass(VALUE klass)
{
    return RCLASS(klass)->super;
}
```

```
// ruby/include/ruby/ruby.h

#define RCLASS_SUPER(c) rb_class_get_superclass(c)
// ...
#define RMODULE_SUPER(m) RCLASS_SUPER(m)
```

可以看出首先通过 rb_class_get_superclass 找到 super
然后在 while 循环中判断 super 的 type，最后返回 super

```
// ruby/doc/extension.rdoc
T_ICLASS    :: included module
```


  [1]: http://7xsger.com1.z0.glb.clouddn.com/image/jpgRClass-module.png
  [2]: http://7xsger.com1.z0.glb.clouddn.com/image/blog/linked-list-rclass.png
  [3]: http://7xsger.com1.z0.glb.clouddn.com/image/jpg/find-methods.png