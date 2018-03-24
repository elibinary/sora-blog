---
title: 学习总结 深入 Ruby 方法定义
date: 2017-07-08 17:41:47
tags:
  - Ruby
description: 一旦学会了 Ruby 元编程内部的实现原理，理解它就会更加容易
---

> 一旦学会了 Ruby 元编程内部的实现原理，理解它就会更加容易

* 如何改变标准的方法定义过程
* 如何操作词法作用域
* 什么是 metaclass 和 singleton class

## 词法作用域
> 词法作用域是指一段代码内的程序语法结构

其实，每当使用 class、module、def 等关键字创建一段新的代码片段的时候，就会定义开启一块新的作用域。
如果把 ruby 程序看做一系列作用域的组合体，大概就是这样：

![lexical scope][1]

图中最外面层是程序的顶级作用域，里面一块块的就是创建的一个个 class、module 等作用域，可以一直嵌套下去。
ruby 在创建新的作用域时会创建一对指针来记录当前作用域及上下文作用域：

* nd_next 指针：指向父层作用域，或者叫上下文作用域
* nd_clss 指针：指向对应于当前作用域的类或模块

```
module MyModule
  class MyClass
  end
end
```

比如上面的代码其词法作用域大致是这样的

![lexical scope case 1][2]

ruby 会为新模块或类创建 RClass 结构体

## 方法定义
理解了上面 ruby 的词法作用域，再来看 ruby 元编程的一些 magic 就更加容易理解了。

比如先来看最常用的 def 关键字
```
def my_method
end
```

默认情况下，ruby 会使用当前的词法作用域来查找新方法的目标类。也就是说 ruby 会为当前词法作用域所对应的类或模块添加新方法。
上边的例子就是为顶级作用域添加了 #my_method 方法

再比如这个例子
```
class MyClass
    def my_method
    end
end
```
当调用 def 关键字时，当前词法作用域所对应的是 RClass: MyClass，那么调用 def 就会在 RClass: MyClass 的方法表中添加方法 #my_method

### 另类方法定义
我们经常使用 'def self.method_name' 这种形式来定义类方法，那么它是怎么工作的呢？
其实它的处理方式和上面普通定义略有不同，这个 self 前缀的作用是用来告诉 ruby 要把方法定义到哪个对象的类中。
```
class MyClass
    def self.my_method
    end
end
```
比如上述例子中，self 就指向 RClass: MyClass，那么方法定义就会为 MyClass 添加类方法 #my_method。
看到这大家肯定会想，既然此处的 self 前缀是用来表明方法的定义去处的，那么我可不可以任意指定别的什么前缀呢？
答案是肯定的，比如这样
```
class MyClass

end

class OtherClass
  def self.my_method
    puts 'Here is OtherClass'
  end

  def MyClass.my_method
    puts "Here is #{self.name}"
  end
end

MyClass.my_method
# => Here is MyClass
```
实际上前缀可以是任意的 ruby 表达式

整个定义过程在 ruby 内部是这样的：

1. 对前缀表达式求值
2. 找到前缀所指对象的元类
3. 在找到的元类中添加方法

*注意：ruby 是在类的元类中保存类方法的*

这里提到了元类，就下来说下 ruby 中的单类和元类

### metaclass & singleton class
在初接触 ruby 时，这两个概念实在是令人困扰，我经常会搞混这两个概念。

先来说说 metaclass ，首先实例对象的方法是定义在其对应的类中的，那么在 ruby 中一切皆对象的，类也不例外。那么是不是类的方法将被定义在类的类中呢？
我们知道，在 ruby 中默认情况下所有类的类都是 Class，显而易见肯定是不能把类方法定义在其中的。实际上当创建新的类的时候，ruby 会创建两个类，类本身以及 metaclass ，然后 ruby 会把新类的 RClass 结构体中的 klass 指针指向 metaclass。而类方法将会被放在类对应的 metaclass 中。

那么 singleton class 又是什么呢，实际上 singleton class 就是单个对象的 metaclass，它的作用是用来保存特定对象独有的方法的。
```
class MyClass

end

my_obj = MyClass.new
def my_obj.sg_method
  puts "Here is #{self.singleton_class}"
end
my_obj.sg_method
# => Here is #<Class:#<MyClass:0x017faa0885b038>>

MyClass.new.sg_method
# => undefined method `sg_method' for #<MyClass:0x017faa0885ae30> (NoMethodError)
```
你可能在想了。。。??? What The ... 不是说类也是对象么？那 singleton class 和 metaclass 有什么区别？

是的，其实它们俩的区别还真不是特别大。。。
事实上当对象本身就是类的时候，metaclass 就是 singleton class。可以这么说：所有的 metaclass 都是 singleton class，但不是所有的 singleton class 都是 metaclass。
事实上在 ruby 内部表示上 metaclass 与 singleton class 是有微小区别的，但就其作用而言二者并无太大差别。

当在使用 def + 前缀的方式定义方法时，ruby 会根据前缀所指的对象来选择是把方法添加到 metaclass 中还是 singleton class 中。

了解了 metaclass 和 singleton class，下面接着来看方法定义

除了上面那种定义类方法的形式外，其实还有一种很常用的方式，没错就是
↓

### class << self
为什么我要给它单独起一个小标题呢，因为其实这种定义方式代表了一类新的定义方式。
```
class MyClass
  class << self
    def my_method
    end
  end
end
```
它的原理过程其实很简单，当调用 class << self 时，ruby 会创建新的词法作用域。在这个例子中新创建的词法作用域将指向 self 的元类，也就是 MyClass 的元类。在其作用域中定义的方法将会被添加到 MyClass 的元类成为 MyClass 的类方法。

自然，这里的 self 也可以是 ruby 表达式
```
class MyClass
end

my_obj = MyClass.new
class << my_obj
  def obj_method
    puts 'Here is my_obj'
  end
end
```
这个例子就表示开启一个新的词法作用域指向 my_obj 的 singleton class 并在其中添加方法。

你可以使用 Module#nesting 来查看当前的嵌套作用域
```
class MyClass
  class << self
    Module.nesting
  end
end

# => [#<Class:MyClass>, MyClass]
```

## Magic Essence
理解了上面的概念，接下来再来看 Ruby Metaprogramming 的本质。

先来看 #eval，下面是文档对这个方法的解释：
*'Evaluates the Ruby expression(s) in string. If binding is given, which must be a Binding object, the evaluation is performed in its context. If the optional filename and lineno parameters are present, they will be used when reporting syntax errors.'*

我们知道 #eval 最基本的用途就是可以拿来对一个字符串指令求值，也就是接受一个字符串，然后对其解析、编译并执行。
```
a = 1
b = 2
eval("puts a + b")
```
可以看出，它执行的代码块是可以访问上下文中的变量的。实际上，eval 方法创建了闭包，它包含了函数及该函数被引用位置环境的组合。

为了更加清楚的理解这一点，再来看下 #binding
*'Returns a Binding object, describing the variable and method bindings at the point of call'*

使用它可以得到一个环境引用的对象，而 #eval 刚好可以接受一个环境引用的参数
```
class MyClass
  def initialize
    @a = 1
  end

  def get_binding
    b = 3
    binding
  end
end

eval("puts @a + b", MyClass.new.get_binding)
# => 4
```
方法 #eval 允许你为其指定执行上下文环境，通过 binding 参数。这里的 binding 对象其实就是一个阉割版的闭包，它没有函数，只是一个对当前环境的引用。你可以认为 binding 对象是一种间接访问、保存以及传递 ruby 内部 rb_env_t 结构体的方式。

我们知道还有一个 #eval 的变种方法 #instance_eval，它与 #eval 的不同之处在于它是在接收者，也就是调用对象的上下文环境中对给定字符串进行求值的。
```
class MyClass
  def initialize
    @a = 1
  end

  def get_binding
    c = 3
    binding
  end
end

b = 2
my_obj = MyClass.new
my_obj.instance_eval("puts @a + b")
# => 3

eval("puts @a + b", MyClass.new.get_binding)
# => undefined local variable or method `b' for #<MyClass:0x0   7f625110 @a=1>
```

当 instance_eval 内的代码运行时，其 self 实际上是指向 instance_eval 的接收者，也就是 my_obj 对象的，这也就允许 instance_eval 内的代码可以访问接收者内的值。

除此之外还有一种用来动态定义方法的方式，那就是使用 #define_method
```
class MyClass
  def initialize
    @a = 1
  end

  [:name, :age, :fan].each do |item|
    define_method item do
      puts item.to_s
    end
  end
end
```

define_method 的一个最重要的作用就是可以动态的用一些数据值来构造方法名。
除此之外其实它与 def 还有另外一点非常重要的不同点，因为它是使用块来提供方法体的就像上面那样，你还没有忘记块实质上是什么吧，块就是闭包，这也就意味着定义的方法中的代码（也就是块中的代码）是能够访问外层环境的。举个简单的例子：
```
class MyClass
  def initialize
    @a = 1
  end
end

def a_common_method
  b = 2
  MyClass.send(:define_method, :calc) do
    puts @a + b
  end
end

a_common_method
MyClass.new.calc
# => 3
```

本篇主要对闭包、词法作用域以及方法的定义过程进行了总结，通过了解这些概念可以更加容易理解 ruby 的内部工作原理以及整个 ruby 语言的思想。


  [1]: http://7xsger.com1.z0.glb.clouddn.com/image/jpg/lexical_scope.png
  [2]: http://7xsger.com1.z0.glb.clouddn.com/image/jpg/lexical_scope_case.png