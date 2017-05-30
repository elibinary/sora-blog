---
title: Ruby Base64
date: 2017-04-30 17:32:17
tags:
  - Ruby
description: Base64是一种基于64个可打印字符来表示二进制数据的表示方法。Base64常用于在通常处理文本数据的场合，表示、传输、存储一些二进制数据。包括MIME的email、在XML中存储复杂数据。
---

> Base64是一种基于64个可打印字符来表示二进制数据的表示方法。Base64常用于在通常处理文本数据的场合，表示、传输、存储一些二进制数据。包括MIME的email、在XML中存储复杂数据。

首先先来认识一下 Base64 的模样
1. 首先2的6次方等于64，所以每6个比特为一个单元，对应某个可打印字符。三个字节有24个比特，对应于4个Base64单元，即3个字节可表示4个可打印字符。
2. 在Base64中的可打印字符包括字母A-Z、a-z、数字0-9，这样共有62个字符，此外两个可打印符号在不同的系统中而不同。
3. 通常我们经常见到的使用的字符包括大小写字母各26个，加上10个数字，和加号“+”，斜杠“/”，一共64个字符，等号“=”用来作为后缀用途。
4. 当原数据长度不是3的整数倍时, 如果最后剩下一个输入数据，在编码结果后加2个“=”；如果最后剩下两个输入数据，编码结果后加1个“=”；如果没有剩下任何数据，就什么都不要加。

### ruby 中的 base64
再来看下 ruby 中的 base64
其实现在 Module Base64，目录在 lib/base64.rb
能够看到它有三套编解码方法：

* decode64, encode64
* strict_decode64, strict_encode64
* urlsafe_decode64, urlsafe_encode64

先看第一种方法，这套方法最大的特点就是他会在每 60 位的地方以及末尾增加换行符，文档中也有提到 
"Line feeds are added to every 60 encoded characters."
举个例子：
```ruby
Base64.encode64("Now is the time for all good coders to learn Ruby Now is the time for all good coders to learn Ruby")

 => "Tm93IGlzIHRoZSB0aW1lIGZvciBhbGwgZ29vZCBjb2RlcnMgdG8gbGVhcm4g\nUnVieSBOb3cgaXMgdGhlIHRpbWUgZm9yIGFsbCBnb29kIGNvZGVycyB0byBs\nZWFybiBSdWJ5\n"
 
Base64.encode64("Now is the time for all good coders")

 => "Tm93IGlzIHRoZSB0aW1lIGZvciBhbGwgZ29vZCBjb2RlcnM=\n" 
```

**strict_decode64, strict_encode64**
这一种解编码方法，和上面不同的是它严格执行编码标准，不会在编码结果中增加换行符。

```ruby
Base64.strict_encode64("Now is the time for all good coders to learn Ruby Now is the time for all good coders to learn Ruby")

 => "Tm93IGlzIHRoZSB0aW1lIGZvciBhbGwgZ29vZCBjb2RlcnMgdG8gbGVhcm4gUnVieSBOb3cgaXMgdGhlIHRpbWUgZm9yIGFsbCBnb29kIGNvZGVycyB0byBsZWFybiBSdWJ5"
```

**urlsafe_decode64, urlsafe_encode64**
关于这个 url 安全的编解码方法，先看文档中的说明

*“ This method complies with “Base 64 Encoding with URL and Filename Safe Alphabet'' in RFC 4648. The alphabet uses '-' instead of '+' and '_' instead of '/'. Note that the result can still contain '='. You can remove the padding by setting padding as false.”*

写的很清楚，base64 是经常会应用在在URL中的，Base64编码可用于在HTTP环境下传递较长的标识信息。在其他应用程序中，也常常需要把二进制数据编码为适合放在URL（包括隐藏表单域）中的形式。

然而，标准的Base64并不适合直接放在URL里传输，因为URL编码器会把标准Base64中的“/”和“+”字符变为形如“%XX”的形式。
为解决此问题，可采用一种用于URL的改进Base64编码，它不在末尾填充'='号，并将标准Base64中的“+”和“/”分别改成了“-”和“_”，这样就免去了在URL编解码和数据库存储时所要作的转换，避免了编码信息长度在此过程中的增加，并统一了数据库、表单等处对象标识符的格式。

*另有一种用于正则表达式的改进Base64变种，它将“+”和“/”改成了“!”和“-”，因为“+”，“*”以及前面在IRCu中用到的“[”和“]”在正则表达式中都可能具有特殊含义。*

### 最后的总结
在对接外部系统和第三方服务时，经常会有参数及校验码等等的 base64 编解码的对接，这是由于使用语言不同，虽然大家都遵守着标准的 base64 标准，但在实施上还是会有各种各样的区别，经常会导致编解码结果又细微区别，而且这种细微区别有时候隐藏的很深。
比如在对接测试过程中由于测试数据的单一，极大可能会遇到这种情况，比如你使用的第一种的编解码方式，而外部服务使用的是严格的 base64 ，那么如果你的测试数据从没超过 60 位，你在对接及测试的过程中通常不会发现有什么问题，当真正使用时，一旦遇到各种各样的参数输入输出，bug 就出现了，而且此刻通常都不会想到是 base64 出问题了，因为第一反应就是 ‘诶，握草，奇怪了啊，怎么有的可以有的不可以呢？？？’。

---
来自多次踩坑者的感言。
