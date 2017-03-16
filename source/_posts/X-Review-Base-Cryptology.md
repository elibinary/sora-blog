---
title: 久违多年重新看密码学
date: 2016-12-10 13:06:29
tags:
  - Cryptology
description: 为什么会写这篇学习笔记呢，这个就说来话。。其实一点也不长，就是前几天突然被 AES 给绊了一跤，另外也是为了增加下知识面的广度。距离上一次系统的（简单的）学习密码学的知识有几个年头了，上次接触还是在大学的密码学课堂上。我和密码学的渊源就先放下不说，现在开始进入今天的话题。
---

> 为什么会写这篇学习笔记呢，这个就说来话。。其实一点也不长，就是前几天突然被 AES 给绊了一跤，另外也是为了增加下知识面的广度。
距离上一次系统的（简单的）学习密码学的知识有几个年头了，上次接触还是在大学的密码学课堂上。我和密码学的渊源就先放下不说，现在开始进入今天的话题。

### 起
还是先从 AES 说起吧，AES 全称 Advanced Encryprion Standard，也就是高级加密标准，在密码学中又称为 Rijndael加密法。

它是一种区块加密法，什么叫区块加密法呢？
其实就是一种对称密钥算法，它将待加密的明文分成多个等长的模块然后使用确定的算法和对称密钥对每组分别加密解密。现代分组加密建立在迭代的思想上产生密文，迭代产生的密文在每一轮加密中使用不同的子密钥，而子密钥生成自原始密钥。看到这里大致还是可以在脑中有一个清晰的理解的，大致就是通过一些替换和排列的手段来增强保密结果。完整的算法实现描述就不在深入的说了（咳，其实我也没看多明白，耐着心思看了其算法描述，让本还觉得数学学得还算不错的我重新对我的数学水平有了一个新的评估。。。）

来看下影响密码安全的两个重要因素：扩散（diffusion）和扰乱（confusion）
扩散的目的是让明文中的单个数字影响密文中的多个数字，从而使明文的统计特征在密文中消失（真正安全的分组加密算法必须考虑到对差分分析线性分析统计学上的弱点），相当于明文的统计结构被扩散。
扰乱是指让密钥与密文的统计信息之间的关系变得复杂，从而增加通过统计方法进行攻击的难度。扰乱可以通过各种代换算法实现。

### 承
说到这里先插入表述一下密码学的基本概念，密码学分为古典密码学和现代密码学，本篇只看现代密码学，现代密码学不只关注信息保密问题，还同时涉及信息完整性验证（消息验证码）、信息发布的不可抵赖性（数字签名）、以及在分布式计算中产生的来源于内部和外部的攻击的所有信息安全问题。其是有大量相关理论基础的一门学科。

常用的加密方式有：对称密钥加密，公开密钥加密以及数字签名等。
对称密钥加密，正如它字面的意思，它有一个秘密密钥，一段明文经过这个秘密秘钥以特定算法进行变换，其得到的密文可以使用这个秘密秘钥重新解密出明文。

公开密钥加密，也称为非对称加密，其有一对加密密钥与解密密钥，一段明文使用加密秘钥生成的密文必须要有与其对应的解密密钥才能够重新解密出明文。知道了其中一个，并不能计算出另外一个。因此公开的密钥为公钥；不公开的密钥为私钥。

数字签名，又称公钥数字签名，通常使用“数字签名”来进行身份确认，数字签名兼具这两种双重属性："可确认性"及"不可否认性"。

### 转
把话题重新转回 AES ，该标准被美国联邦政府替代原先的 DES ，先来看下 DES ，其全称 Data Encryption Standard ，也就是数据加密标准，它也是一种对称密钥加密块密码算法。其使用56位密钥的对称算法，因为比较短的密钥长度而比较容易被破解。
```
[来自 wiki 的信息]最佳公开破解
由于穷举法对DES的破解已经成为可能（见暴力破解），DES现在被认为是不安全的。2008年，最佳的分析攻击是线性密码分析，要求2^43个已知明文，具有2^39–43的时间复杂性；在选择明文攻击下，数据复杂性可以减少到其1/4。
```

再看回 AES，其实 AES 和 Rijndael 加密法并不完全一样（虽然在实际应用中两者可以互换）， Rijndael加密法可以支持更大范围的区块和密钥长度：
AES
区块长度固定为 128 bit 
密钥长度可以是128，192或256 bit

Rijndael
密钥和区块长度可以是32位的整数倍，以128位为下限，256 bit 为上限。

### 折
好，上面算是对整个体系有了浅浅的了解，下面来说说实际的问题。（把糗事放在最后将会不会比较好呢）

来看下 Ruby 中对于 AES 的用法，Ruby 中对 AES 的实现在 [OpenSSL::Cipher][1] 中
```
# 可以使用 
OpenSSL::Cipher.ciphers 
# 来列出其支持的算法

# => AES-128-CBC  AES-128-CBC-HMAC-SHA1  AES-128-CFB  AES-128-CFB1
# => AES-128-CFB8  AES-128-CTR  AES-128-ECB  AES-128-OFB  AES-128-XTS
# => AES-192-CBC  AES-192-CFB  AES-192-CFB1  AES-192-CFB8  AES-192-CTR
# => AES-192-ECB  AES-192-OFB  AES-256-CBC  AES-256-CBC-HMAC-SHA1  
# => AES-256-CFB AES-256-CFB1  AES-256-CFB8  AES-256-CTR  AES-256-ECB
# => AES-256-OFB  AES-256-XTS  AES128  AES192  AES256
# => bf  bf-cbc  bf-cfb  bf-ecb  bf-ofb
# => blowfish  camellia-128-cbc  camellia-128-cfb
# => ...
```
它实现了上百种加密算法。
我们单看 AES 相关的，可以看出其实现有 128,192和256全三种长度的 key ，同时有 CBC, CFB, CTR, ECB, OFB, XTS等等的模式。

说到这里再插入一点知识，先来看下 AES 的一些需要注意的地方：

* 初始化向量（IV）
  IV，全称 Initialization Vector 是许多工作模式中用于随机化加密的一块数据 。在进行加密的时候，通过设置一个随机初始化值来增加安全性，这样的设计下由相同的明文，相同的密钥也可产生不同的密文。通常情况下 IV 无须保密，因为在大多数情况下不应两次使用相同 IV 。
* 填充
  在区块加密法中块密码只能对确定长度的数据块进行处理，因为消息的长度通常是可变的，这就导致了划分到最后的一块数据可能不够长度，这就需要最后一块在加密前进行填充。CFB，OFB和CTR模式不需要对长度不为密码块大小整数倍的消息进行特别的处理。因为这些模式是通过对块密码的输出与平文进行异或工作的。最后一个平文块（可能是不完整的）与密钥流块的前几个字节异或后，产生了与该平文块大小相同的密文块。
* ECB
  全称 Electronic codebook ，是最简单的加密模式。需要加密的消息按照块密码的块大小被分为数个块，并对每个块进行独立加密。本方法的缺点在于同样的平文块会被加密成相同的密文块；因此，它不能很好的隐藏数据模式。
* CBC
  全称 Cipher-block chaining ，此模式是 IBM 发明的，工作方式是每个平文块先与前一个密文块进行异或后，再进行加密。在这种方法中，每个密文块都依赖于它前面的所有平文块。同时，为了保证每条消息的唯一性，在第一个块中需要使用初始化向量。因此在CBC模式中，IV在加密时必须是无法预测的。
CBC是最为常用的工作模式。它的主要缺点在于加密过程是串行的，无法被并行化，而且消息必须被填充到块大小的整数倍。
* 其他还有几种模式就不一一列出了


要想使用其实现，要先实例化出一个 OpenSSL::Cipher 的实例（又很简单易懂的模式）：
```
# cipher = OpenSSL::Cipher.new('<name>-<key length>-<mode>')
cipher = OpenSSL::Cipher.new('AES-128-CBC')
```

写一个简单的使用样例：
```
require 'openssl'
require 'base64'

def encrypt(key, content)
    aes = OpenSSL::Cipher.new('aes-128-cbc')
    aes.encrypt
 
    aes.key = key
    aes.iv = OpenSSL::Random.random_bytes(16)
    crypted = aes.update(content)
    crypted << aes.final
    [Base64.b64encode(crypted), Base64.b64encode(iv)]
end

def decrypt(key, encrypted, iv=nil)
    dec = OpenSSL::Cipher.new('aes-128-cbc')
    dec.decrypt
    
    dec.key = key
    dec.iv = Base64.decode64(iv) unless iv.nil?
    content = dec.update(Base64.decode64(encrypted))
    content << dec.final
    content
end
```

[参考 - Ruby 2.0.0 - Cipher][2]
[参考 - Ruby 2.3.0 - Cipher][3]
[参考 - Ruby & Java][4]


  [1]: https://github.com/ruby/openssl/blob/master/lib/openssl/cipher.rb
  [2]: https://ruby-doc.org/stdlib-2.0.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html
  [3]: https://docs.ruby-lang.org/ja/latest/class/OpenSSL=3a=3aCipher.html
  [4]: http://techmedia-think.hatenablog.com/entry/20110527/1306499951
