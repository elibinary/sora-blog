---
title: VI-String-Matching-KMP
date: 2016-10-07 00:32:37
tags:
  - Algorithm
description: 最近在复习一些基础算法，正好把字符串匹配的各种知识总结记录一下。
---

最近在复习一些基础算法，正好把字符串匹配的各种知识总结记录一下。关于字符串匹配我们都不陌生，例如 ruby 中 String 的 index 等一系列方法。下面先说一下最简单粗暴的解法。

先分解下问题，现在我们要解决的问题可以简单描述为这样：现有一字符串 S ，现查找目标字符串 P 在 S 中的位置。

### 暴力解法
所谓暴力法就是逐字符便利匹配字符串具体过程是这样的：
1. 从头部开始逐字符匹配 S 与 P，设置指针 i 指向 S 头部
2. 如果遇到字符不匹配，则令指针 i 向后移，并重头开始匹配 P
3. 重复第二步，直至成功匹配或者失配

举个简单的例子：
现有字符串 S ： 'acdfcacdchd' , 现查找目标字符串 P： 'acdc'在 S 中的位置。其匹配过程是这样的：
1. 首先 S[0] 与 P[0] 比较，发现匹配，继续向后匹配 S[1] 和 P[1]
2. 直至匹配到 S[3] 与 P[3] 时，发现不匹配。向后移从 S[1] 开始匹配 P
3. 发现 S[1] 与 P[0] 不匹配，继续后移从 S[2] 开始
4. （重复过程略）
5. 发现 S[5] 与 P[0] 匹配，各自向后移一位，继续向后匹配 S[6] 和 P[1]
6. 最终完成匹配

说起来挺啰嗦，其实就是循环匹配的过程，实现起来很简单：

```ruby
def method_one
  i = j = 0
  while i < @a_length && j < @p_length
    if @string_a[i] == @string_p[j]
      i += 1
      j += 1
    else
      i = i - j + 1
      j = 0
    end
  end

  # matching complete
  if j == @p_length
    i - j
  else
    -1
  end
end
```

或者下面这种写法更容易看明白，还可以通过适当剪枝来减少循环数：

```ruby
def method_two
  res = -1
  (0..(@a_length - @p_length)).each do |i|
    (0..(@p_length-1)).each do |j|
      break if @string_a[i + j] != @string_p[j]
      return i if j == @p_length - 1
    end
  end
  res
end
```

经典的 KMP 算法叙述起来可能会比较繁复

### KMP

Knuth-Morris-Pratt 字符串查找算法，简称为“KMP算法”，此算法可在一个主“文本字符串”S内查找一个“词”W的出现位置。此算法通过运用对这个词在不匹配时本身就包含足够的信息来确定下一个匹配将在哪里开始的发现，从而避免重新检查先前匹配的字符。（来自Wiki的简要解释）

#### “部分匹配”表
从上面解释中最重要的就是如何确定下一个匹配将在哪里开始。这里KMP使用了一个“部分匹配”表，当失配时将通过这个表来确定下一个匹配将在哪里开始，因为可以用数组来表示，我们又称其为 next 数组。那么这个 next 数组到底长什么样子又是怎么算出来的呢。

next 数组的构成是这样的，它的下标对应于目标字符串 P 的每个字符的位置，它的 value 就是当失配时下一个匹配将在何处开始的数值，也就是说当 P 的第 j 的字符匹配失败时，下一次将从字符串 P 的 next[j] 处开始匹配。下面举个例子来说明：

现有目标字符串 P = 'abdabch'，经计算其对应的 next 数组就是 [-1, 0, 0, 0, 1, 2, 0]。（下面会详细介绍 next 数组的计算方式）
现在先来看下 next 数组的使用方式：
假设现有主字符串 S = 'cdabdabpoabvb'
1. 依次匹配，当匹配到第6位时，也就是 S[7] != P[5]
2. 查找 next 数组，next[5] = 2
3. 保持 S 的指针不变，移动 P 的指针到 P[next[5]] 也就是 P[2] 位置继续匹配
4. 重复

下面再来说说 next 数组本身，还是借助上面例子来说明：
1. 假设指向 S, P 的指针分别为 i, j
2. 那么当 j = 5, i = 7 时，S[7] != P[5] ，P[5] 前面的字符 'abdab' 与 S 已完成匹配
3. 那么假如 'abdab' 首部尾部有重复字符串，如现在就有重复前后缀 ab ，那么当匹配失败时，可以知道后缀一定是匹配成功的，那么与后缀匹配的前缀也一定匹配成功，那么下一次的匹配就可以从之后的一位开始（在此处也就是 p[2] 处）。

那么至此问题就转化为了求给定字符串的最长匹配的前缀后缀的问题。

#### 怎么构建
用递推的方式来解释

有 P = 'abdabch'

1. 对于一个常数 k , 有p0 p1, ..., pk-1 = pj-k pj-k+1, ..., pj-1， 那么就得出 next[j] = k
2. 那么对于已经知道 next[j] 的值，如何算出 next[j+1]

那么分解

1. 当 p[k] == p[j] 时，next[j + 1] = next[j] + 1 = k + 1
2. 当 p[k] != p[j] 时，就需要去找更短的匹配前缀，也即比较 p[next[k]] 是否等于 p[j]，如果还是不相等，就继续向前找更短的匹配前缀 P[next[next[k]]]，简单来说就是一个自我匹配的过程

先看构建 next 数组的代码

```ruby
k = -1
j = 0
next_arr = Array.new(p_length, 0)
next_arr[0] = -1

while j < p_length
  # when string_p[k] == string_p[j], then next_arr[j+1] = k + 1
  if k == -1 || string_p[k] == string_p[j]
    k += 1
    j += 1
    next_arr[j] = k
  else
    # 往前查找较短的匹配项
    k = next_arr[k]
  end
end

next_arr
```

利用 next 数组进行位置查找的代码：

```
class StringKmp
  def initialize
    @string_a = 'abcddacbabdkllab'
    @string_p = 'abd'

    @a_length = @string_a.length
    @p_length = @string_p.length
  end

  def main
    next_arr = build_next

    i = 0
    j = 0
    while i < @a_length && j < @p_length
      if j == -1 || @string_a[i] == @string_p[j]
        j += 1
        i += 1
      else
        j = next_arr[j]
      end
    end

    # matching complete
    if j == @p_length
      i - j
    else
      -1
    end
  end

  def build_next
    k = -1
    j = 0
    next_arr = Array.new(@p_length, 0)
    next_arr[0] = -1

    while j < @p_length
      # when string_p[k] == string_p[j], then next_arr[j+1] = k + 1
      if k == -1 || @string_p[k] == @string_p[j]
        k += 1
        j += 1
        next_arr[j] = k
      else
        # 往前查找较短的匹配项
        k = next_arr[k]
      end
    end
    next_arr
  end
end
```


*模式串中**每个字符之前**的前缀和后缀公共部分的最大长度*

