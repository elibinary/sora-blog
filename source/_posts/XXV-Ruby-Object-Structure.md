---
title: 读书笔记 - Ruby 对象 - 结构 
date: 2017-05-21 11:44:47
tags:
  - Ruby
description: 每个 Ruby 对象都是类指针和实例变量数组的组合
---


> 每个 Ruby 对象都是类指针和实例变量数组的组合

### Object
首先先来深入 Ruby 对象内部，来看看其内部结构到底是怎么构成的。
Ruby 把每个自定义对象都保存在名为 RObject 的由 c 语言实现的结构体中。

说起 c 语言的结构体，首先就令我想起了念书时曾做过的“如何使用 c 去模拟实现面向对象的继承与多态”
一个简单的小例子：
```
struct Base
{
  char *name = "base";
  int age;

  void (*fire)(const void *self); 
};

struct Biont
{
  const struct Base base;
  int bb;
};

struct Human
{
  const struct Base base;
  int race;
};
```

fire 的实现
```
void fire(const void *self)
{
  const struct Base *cp = self;
  (*cp) -> fire(self);
}
```
C语言能够模拟实现面向对象语言具有的特性，包括：多态，继承，封装等，现在很多开源软件都了用C语言实现了这几个特性。

让我们把目光重新转到 Ruby 的 Object 结构上，这个 RObject 的结构体到底长啥样呢

![RObject][1]

我第一眼看到就觉得莫名的熟悉感。
可以看出其实在 RObject 结构中还内嵌了一个 RBasic 结构体，RBasic 结构体中包含了所有值都会用到的信息，一组叫作 flags 的布尔值，用来存储各种内部专用的值，还有一个叫 klass 的类指针，用来指向所属类。

```
class MyClass
    attr_accessor :inc_attr_one
    attr_accessor :inc_attr_two
end

obj_1 = MyClass.new
obj_1.inc_attr_one = 'one'
obj_1.inc_attr_two = 'two'

obj_2 = MyClass.new
obj_2.inc_attr_two = 'touch'
```

![RObjet-2][2]

### 关于基础类型对象
> Ruby 中一切皆对象

Ruby 中基本的数据类型也是对象。在 Ruby 中，并不使用上面所说的 RObject 结构体来存储基础类型对象。它为这些基础类型设计了特有的结构

![base-object][3]

RObject 只用来存储自定义类的实例对象以及一些 Ruby 内部创建的少数自定义类的实例对象。不过你可能一经发现了，这些不同结构的对象存储形式中都包含了 RBasic 结构体。


  [1]: http://7xsger.com1.z0.glb.clouddn.com/robject.png
  [2]: http://7xsger.com1.z0.glb.clouddn.com/robject-2.png
  [3]: http://7xsger.com1.z0.glb.clouddn.com/base-object.png

