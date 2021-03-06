---
title: 语法糖与小陷阱
date: 2016-11-19 14:42:50
tags: 
  - Ruby
description: Ruby 的语法糖与小陷阱
---

先说一个与题无关的问题

### 包含性检查

在日常 coding 中，总是会遇到很多需要去检查目标是否在一个集合中存在的场景，通常你会使用什么方式在检查呢？在这种场景下，我通常第一个想到的就是 Array 的 include? 方法。其实这样说并不准确，从 response 方面来说，我只是需要一个能够响应 include? 方法的容器。本题的重点并不在此，让我们接着往下看。

其实能够完成包含性检查的方式有好几种，利用 Hash 也可以很轻易的实现需求。事实上，在所有的集合中， Array#include? 方法的性能是最差的，其时间复杂度是 O(n) ，也就是线性复杂度，当数组元素增加时，所耗费的时间呈线性增长。尤其是当目标不在集合中时，能是会完全遍历整个数组。（当然，在数组中元素很少时，并不需要为这个问题费心）

刚才在上面也提到了 Hash，使用 Hash 的首要好处就是访问集合内元素的时间复杂度可以达到 O(logn)，就效率上而言相比于 Array 要高效非常多，相随而来的一个问题就是为了维护内部数据结构， Hash 需要占用更多的内存。而且很多情境下，最烦人的事就是构建 Hash， Hash的结构是键值对，但是我们没有任何值需要存储。有时为了能够将数组转换成 Hash，需要先将整个数组进行映射，构建一个更大的数组，在转换为 Hash。但是就包含性检查这一需求下，我们并没有去使用 Hash 的大多数特性，我们仅仅是用它来检测是否包含一个元素。

这样，我们就可以考虑到另一个集合 Set ，由于 Set 对象是可以由任何集合对象或 Enumberable 来构建的， Set::new 会替我们完成转换。而且 Set 类的内部是使用 Hash 来存储元素的，这就意味着它享有 Hash 一样的效率和自动去重效果。但是有一点需要注意的是， Array 是一个有序的集合，我们甚至可以通过索引来随机的访问任何一个节点。但是这对于 Set 集合就不适用了， Set 是无需的，虽然其元素的访问顺序应该和插入顺序相同，但其实元素的实际顺序是实现细节决定的，这一点从 Set 的文档描述就能看出来。相对的，如果你不需要元素按照一定顺序排列，没有需要随机访问任一元素，又需要高效的检测元素的包含性，那么就使用 Set 吧。


### 关于默认 Hash 值

相信在不短的编程时光中，你不只一次看到过类似这样的代码：
```
array.each do |item|
    hash[item] ||= 0
    hash[item] += 1
end
```

这时你一定希望当你访问一个 hash 中不存在的键时能够返回你希望得到的结果。看方法定义很容易明白，当你访问一个 hash 中不存在的键时，它实际上只是返回了一个默认值给你，而这个默认值默认为 nil ，你可以随意修改这个默认值。没错，你可以让 Hash 在接收到不存在的键时返回任意你希望的值而不是返回 nil。比如上面代码可以改为这样

```
hash = Hash.new(0)
array.each do |item|
    hash[item] += 1
end
```

一切是那样的美好，再也不用在构建 hash 时为不存在的 key 返回 nil 值感到烦心了。但是，这里有一个问题是需要注意的。在上面例子中，我们在初始化时指定默认值后没有再修改过默认值。当然，上面的代码中的默认值是数值类型，并不能被修改。那么如果我们使用了一种可以修改的值作为默认值会发生什么事情呢？来看下面这个例子：

```
hash = Hash.new([])
hash[:a]
# => []

hash[:a] << 'eli'
# => ['eli']

hash.keys
# => []

hash[:b]
# => ['eli']
```

有没有看出什么问题来。我们很惊讶的发现，当我们无意间的操作改变了默认值时，一切的结果变得那么出人意料。前面的很容易理解，首先我们为生成的 hash 设定了默认值为空数组，到
```
hash[:a] << 'eli'
```
这一步时，一切开始向意料之外的方向发展了。我们原本的目的是向 key 为 :a 的 value 中加入一个新元素，但是这个时候 hash 本身并没有发生改变（没有增加一个名为 :a 的 key） 默认值却发生了改变。再来看下面这种写法：
```
hash = Hash.new([])
hash[:a]
# => []

hash[:a] = hash[:a] << 'eli'
# => ['eli']

hash.keys
# => [:a]

hash[:b] = hash[:b] << 'sora'
# => ['eli', 'sora']

hash.keys
# => [:a, :b]

hash[:a]
# => ['eli', 'sora']

hash[:b]
# => ['eli', 'sora']
```
是否能够更加清晰得明白其中因果了呢，第一种写法中，从头至尾都没有改变 hash 对象本身，只是当请求 hash[:a] 时返回了一个默认的空数组，并在其中插入了元素 'eli' ，这就导致 hash 没有变而默认值改变了。
解决这个问题其实也很简单，只要为其每一个每一次的返回设置一个新的空数组就行了，比如这样
```
hash = Hash.new {[]}
```
它可以接收一个块，实际上这个块可以接收两个参数： hash本身和将要访问的 key，所以我们也可以这样写：
```
hash = Hash.new {|hash, key| hash[key] = []}
```
这样每次访问不存在的 key 时，不然会在 hash 中创建一个新的 key 而且会产生一个新的数组。讲到这里基本就比较清晰了。

接下来还有一个问题，当使用默认值时可能会遇到的一个陷阱，这个陷阱发生在当你判断 hash 中某个 key 的存在与否时。在此之前，我总是习惯于这样写：
```
if hash[key]
...
```
现在，当使用了默认值后，这样的写法将会引入一个风险，当你为 hash 设置的默认值不是 nil 或者 false 时（上一篇提到过，ruby中除 nil 和 false 意外的一切对象都为真），这个条件会一直返回真。从这一点也获得了一个提醒，用获取其值的方式判断键是否存在的方式是不可靠的（其他很多语言中访问不存在的键时通常会抛出异常），建议使用 has_key? 方法来检查 hash 是否包含目标 key。