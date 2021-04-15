---
title: 关于密码安全
date: 2017-06-17 16:28:05
tags:
  - cryptology
description: 关于散列函数、碰撞和爆破
---

在进入正文之前，先介绍一些基本概念

### Cryptographic Hash Function

先来说下密码散列函数，就如同它的名字一样，它是散列函数的一种。
一个理想的密码散列函数应该有四个主要的特性：

 - 对于任何一个给定的消息，它都很容易就能运算出散列数值
 - 难以由一个已知的散列数值，去推算出原始的消息（不可逆）
 - 修改消息内容必定会导致散列结果改变
 - 不同的消息必定有不同的散列结果

MD5, SHA 等都属此类，区别于 AES 等对称加密算法。严格来说，前者只是一种消息摘要或者说是消息指纹的算法。

### MD5
MD5 被广泛的应用在签名、密码加密、文件完整性校验及数字证书等许多地方

它是一种使用非常广泛的密码散列函数，其编码长度为 128 位，也就是 16 字节。
输入不定长度信息，输出固定长度 128-bits。
 
### SHA
全称 Secure Hash Algorithm，也是一种密码散列函数。它很多个派生：

 - SHA-1
 - SHA-2
 - SHA-3
 
具体各个的区别和特点可以看 wiki 的对比表：
[Wikipedia - Secure Hash Algorithms][1]

### 碰撞
所谓碰撞，就是指两个不同的消息具有相同的哈希值，或者说是摘要值。

虽然最上面有说过，理想的散列函数，不同的消息必定有不同的散列结果。但其实上面说的几种散列函数都是做不到的。当数据量足够多时，碰撞将不可避免。

鸽巢原理：若A是n+1元集，B是n元集，则不存在从A到B的单射。
### 弱密码
弱密码是易于猜测的密码，主要有以下几种：

 - 顺序或重复的字符：“12345678”、“111111”、“abcdefg”、“asdf”、“qwer”键盘上的相邻字母；
 - 使用数字或符号的仅外观类似替换，例如使用数字“1”、“0”替换英文字母“i”、“O”，字符“@”替换字母“a”等；
 - 登录名的一部分：密码为登录名的一部分或完全和登录名相同； 常用的单词：如自己和熟人的名字及其缩写，常用的单词及其缩写，宠物的名字等；
 - 常用数字：比如自己或熟人的生日、证件编号等，以及这些数字与名字、称号等字母的简单组合。

### 密码安全

了解了上面几个基本的概念后，来看下恶意黑客常用的几种破解密码的手段：

**暴力破解**
首先要提到的就是简单暴力的穷举，这种方法是最笨的方法但也是相当有效的方法，尤其是对于一些弱密码的破解。对于四位数字的密码总共也就1万个，穷举所花费的最大次数9999。六位数字的密码100万个..

说它又笨又慢的原因是，理论上穷举法破解所消耗的时间不小于完成破解所需要的多项式时间。但是当有了字典后，破解的时间将会被大大的缩短。所谓字典就是通过预测生成的一大批可能的密码集合。

**算法分析**
研究分析目标所使用的加密算法，比如 MD5，找出其中的弱点，进而缩小备选穷举的范围从而的缩短破解时间。

**生日攻击**
生日攻击的理论源于数学中的生日问题

> 生日问题是指，如果一个房间里有23个或23个以上的人，那么至少有两个人的生日相同的概率要大于50%

生日问题的结果非常的违反直觉，它是这样计算的，假设有n个人在同一房间内，要计算有两个人在同一日出生的概率 $P$，假设房间内任意两人的生日都不相同的概率为 $\check{P}$ , 那么
$$P = 1 - \check{P}$$

任意两人生日都不同的概率计算方式如下：
$$ \check{P} = 1 \left( 1-\frac{1}{365} \right)\left( 1-\frac{2}{365} \right)\left( 1-\frac{n-1}{365} \right) = \frac{365!}{365^n(365-n)!}$$

代入公式就可以算出，当 n = 50 的时候，有两人相同的概率就等于 97% 了，当 n = 100 的时候，其概率为 99.99996%

在回头来说生日攻击，简单的类比就是把输入值的个数看做生日问题中的人数 n，输出值为生日，那么从上面的结论来看只需要比预想中要少的多的输入值，就很大的可能得到至少两个相同的输出值。

为什么可以这样类比呢，就拿上面提到的 MD5 和 SHA 做例，它们将任意长度的输入值通过计算转换为固定长度的输出值，比如 MD5 的输出值固定位 128 位，也就是说它们的值域远小于定义域，这样的情况下碰撞是必然的。

说到这里，就再来深入的说下碰撞，实际上在用户密码安全问题上，显而易见的碰撞并不意味着对于对于一串密文能够得到实际的明文，这是做不到的。它只是找到n串输入经过一样的散列函数散列后得到的输出一样，至于这个输入与你的密码是否一致..╮(╯_╰)╭

实际上碰撞影响最大的是数字签名、文件完整性（指纹）校验这类安全方案。比如文件MD5校验经常被用来验证数据是否被修改，当下载一个文件后比对文件MD5与官网的是否一致就可以校验此文件的完整性。但假如攻击者搞了一个恶意可执行文件的MD5与官网的这个MD5碰撞...

下一个问题，MD5 加盐是解决什么问题的？
MD5 + salt 实际上是在输入值上附加一段信息，然后在进行散列。
这样说可能并不能让你直观的理解其用意，拿上面字典爆破的攻击方式为例，假如我们在存储用户密码的时候进行了加盐操作，那么事实上这个通用字典就失效掉了，当然这并不是说攻击将变得无法进行。
要知道，密码学的应用安全，是建立在破解所要付出的成本远超出能得到的利益上的。这是一个成本的问题，假如攻击者要为每一个用户生成一遍字典，那破解的成本将随着用户量的提高而急剧上升。

既然如此，那么正确的加盐方式也就不言而喻了，应该针对每个输入生成一个随机串，也就是盐值并且这个值在此后都不会在改变，任意两个用户的盐值不能相同（相对意义上）。

加盐也可以有效的防范彩虹表攻击，彩虹表的具体原理实现我自己也没有完全理解透彻，这里就不展开说了免得误导人。

### 反例
在解决密码安全的问题上有许多错误的做法，下面列举几种

 - 使用自己构造的算法
    我认为大多数人都不具备构造完美或逼近完美散列函数的条件，当然，不排除一些天才想法
 - 使用MD5加盐进行多次散列
    这种方式本质上并不会增加安全性，反而会拖慢运算速度。当然如果想要的就是把计算速度拖慢来增加破解的成本的话还不如去用 bcrypt

 - 组合使用各种散列算法
 - 固定盐

  [1]: https://en.wikipedia.org/wiki/Secure_Hash_Algorithms