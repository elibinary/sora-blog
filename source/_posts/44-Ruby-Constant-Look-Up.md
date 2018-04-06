---
title: 由 'uninitialized constant' 引发的关于常量查找和词法作用域的思考
date: 2018-04-06 14:40:31
tags:
  - Ruby
description: 由 'uninitialized constant' 引发的关于常量查找和词法作用域的思考
---

事情发生在一个温暖慵懒的午后，当我尝试运行类似下面代码（为方便查看已简化）的时候...

```
class A
  ABC = 'abc'
end

class B < A
  class << self
    def show
      p ABC
    end
  end
end

B.show
```

我得到了 `*** NameError Exception: uninitialized constant`

检查了两遍代码后，发现事情并不简单，于是我换了一种写法：

```
class A
  ABC = 'abc'
end

class B < A
  def self.show
    p ABC
  end
end

B.show
```

测试成功通过...

看来问题是出在了 `class << self` 上，先来看下 ruby 中是如何进行常量查找的（在此之前可以先了解下[词法作用域][1]）

简单来说，其过程相当简洁：

1. 首先会从当前词法作用域开始沿着从内到外一层层查找
2. 如果未找到，就查找其 `ancestors` 沿着祖先链向上挨个把祖先当做当前词法作用域
3. 重复 1 操作

先看下面代码

```
class A
  ABC = 'abc'
end

class B < A
  puts "one: #{self}"

  class << self
    puts "two: #{self}"
    def show
      p ABC
    end
  end
end
```

```
one: B
two: #<Class:B>
```

这个很容易预见，`class << self` 打开了新的作用域([这里][1]做过简单的介绍)，这个新的词法作用域直指 B 的元类（metaclass）

接下来我们来用 `Module#nesting` 看下作用域链，在使用之前还是先看下 `#nesting` 的作用及怎么工作
> Returns the list of Modules nested at the point of call. 
> -- ruby-doc

上面来自文档的方法描述清楚地介绍了其作用，为了加深理解姑且还是来看下 `source code`

```
static VALUE
rb_mod_nesting(void)
{
    VALUE ary = rb_ary_new();
    const NODE *cref = rb_vm_cref();

    while (cref && cref->nd_next) {
        VALUE klass = cref->nd_clss;
        if (!(cref->flags & NODE_FL_CREF_PUSHED_BY_EVAL) &&
            !NIL_P(klass)) {
            rb_ary_push(ary, klass);
        }
        cref = cref->nd_next;
    }
    return ary;
}
```

上面提到过得介绍[词法作用域的文章][1]中也有提到过 ruby 中的作用域的实现主要用到的两个指针分别是

> - nd_next 指针：指向父层作用域，或者叫上下文作用域
> - nd_clss 指针：指向对应于当前作用域的类或模块

上面的源码实现不难理解就不多说了

```
class B < A
  puts "one: #{Module.nesting}"

  class << self
    puts "two: #{Module.nesting}"
    def show
      p ABC
    end
  end
end
```
直接看打印结果
```
one: [B]
two: [#<Class:B>, B]
```

到此结合 ruby 的常量查找算法就很明了了，查找方法简化如下

 1. 检索词法作用域链
 2. 为每个作用域的类检查 autoload
 3. 检索超类链
 4. 为每个超类检查 autoload
 5. 调用 const_missing

再来看下更全的打印信息

```
class A
  ABC = 'abc'
end

class B < A
  puts "[nesting] one: #{Module.nesting}"

  class << self
    puts "[nesting] two: #{Module.nesting}"
    def show
      p ABC
    end
  end
end
```

```
[nesting] one: [B]
[nesting] two: [#<Class:B>, B]
```

```
B.singleton_class
#=> #<Class:B>

B.ancestors
#=> [B, A, Object, Kernel, BasicObject]

B.singleton_class.ancestors
#=> [#<Class:B>, #<Class:A>, #<Class:Object>, #<Class:BasicObject>, Class, Module, Object, Kernel, BasicObject]
```
 
  [1]: http://elibinary.com/2017/07/08/XXXI-Ruby-Method-Definition/