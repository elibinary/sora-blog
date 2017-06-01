---
title: 关于 Ruby 的类型转换 
date: 2017-05-14 12:06:05
tags:
  - Ruby
description: 在平时写代码的时候少不了要经常进行一些类型转换，经常性的要用到 #to_a, #to_s, #to_i 之类的方法，这些方法就是 ruby 标准类型的显式转换方法。
---


在平时写代码的时候少不了要经常进行一些类型转换，经常性的要用到 #to_a, #to_s, #to_i 之类的方法，这些方法就是 ruby 标准类型的显式转换方法。

有显式转换，那么相对的也有隐式转换。在很多情况下，Ruby会隐式的在参数对象上调用隐式转换方法，以便得到预期的参数类型。举个例子：
```ruby
# String 的 + 运算符能够将多个字符串拼接成一个新字符串
'eli ' + 'zhang'
#=> "eli zhang"

# 那么当我要拼接的对象不是一个字符串对象呢
'eli ' + Time.now
#=> TypeError: no implicit conversion of Time into String
```
当要使用 + 运算符来接受一个 Time 类型的参数时，报了 TypeError 的错。我们知道，ruby是动态类型语言，不会去做类型检查，那么这有是怎么给出的呢。
事实上 String#+ 方法通过隐式的调用 #to_str 方法来检测参数是不是类字符串的（可以看出，ruby 只关心你能不能 response 给定的方法，而不关心你到底是什么，ruby中处处都显露着这种思想），并且使用转换之后的值，如果参数对象不能 response #to_str 方法，变回抛出上面那个 error

事实上， String 是 Ruby 核心类中唯一实现了 #to_str 方法，并且 #to_str 只是简单的返回了字符串本身。 #to_str 方法存在的意义在于，因为许多 Ruby 核心库方法期望得到字符串参数输入，他们就通过在输入对象上隐式的调用 #to_str 方法来实现这种期望。

那么这其实同时也就意味着，我们可以把我们自定义的对象伪装成字符串对象，让 Ruby 核心库方法接受它，并把它转换为真正的字符串对象。
```
class MyString
  def initialize(str)
    @str = str
  end
  
  def to_str
    "is #{@str}"
  end
  
  def to_s
    to_str
  end
end

'eli ' + MyString.new('cool')
#=> "eli is cool"
```
可以看出，这样是能够正常运行的。通过在自定义类中实现 #to_str 方法，来暗示此对象就是一个类字符串对象。

还有一个非常有趣的例子（例子来自[CONFIDENT RUBY]）
```
winners = ['Homestar', 'King of Town', 'Marzipan', 'Strongbad']

Place = Struct.new(:index, :name, :prize)

first = Place.new(0, 'first', 'PQg')
second = Place.new(1, 'second', 'LA')
third = Place.new(2, 'third', 'Bd')

winners[first]
#=> TypeError: no implicit conversion of Place into Integer

class Place
  def to_int
    index
  end
end

winners[first]
#=> "Homestar"
```
之所以可以这样用，是因为 Ruby 会自动在数组下标参数上调用 #to_int 方法，以便将其转换为 integer。

