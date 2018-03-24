---
title: 延时任务
date: 2017-09-09 17:45:36
tags:
  - Algorithm
description: 本篇来介绍几种延时任务的解决方案，在平常的开发中，延时任务是一个很常见的需求，诸如用户下单 n 分钟后不付款就取消订单等，当触发一个操作时需要延时一段时间去执行另一个操作的情况。
---

在平常的开发中，延时任务是一个很常见的需求，诸如用户下单 n 分钟后不付款就取消订单等，当触发一个操作时需要延时一段时间去执行另一个操作的情况。

下面来说几种解决方案
## 基于数据库的定时任务
在解决类似需求的时候，很容易想到在触发延时任务时，把执行时间保存起来，然后定时从数据库中查出需要处理任务进行处理就 ok 了。

很容易看出这种方法有很多种缺陷，但是在应付某些特定需求的时候却也是非常简单有效的手段。
比如现在有一个需求，我们要封禁一些不守规矩的用户，并在一定时间后自动解封他们，如果需求是以天为单位，那么只需要设置一个每天凌晨执行的定时任务去数据库中检索出今天待释放的用户处理掉就 ok 了。
再进一步，如果需求有精确地时间要求，也可以在此基础上进行改进，我们可以每天凌晨（根据情况也可以没几个小时，或者多少分钟）检索出今天待处理的任务，然后把它们塞到异步任务队列中，并设定个执行时间就好了。这样还可以解决异步任务堆积及持久化和防丢失等等一系列问题。

## 环形队列
再有就是一种基于环状结构的任务队列，其基本结构张这样
![annular-queue][1]
*ps: 贴一张来自 wiki 的图*

在上面这种结构的每一格中存储延时任务，假定时间精度为 1s ，那么就令指针每一秒前进一格，由于整个结构为环形所以指针将一圈圈走下去。
在处理延时任务时，按当前时间把延时任务插入到这个环中，比如我们设定的环状结构总共 60 格，假设有一个新的延时 10 秒执行的任务进来，就在当前时间往前数 10 格插入任务，当指针走到相应的单元格时，取出该单元格中的任务进行处理。
当延时任务的延时时长超过环形最大值时的解决方法是，为每个任务存一个环次 n ，比如有一个任务延时 123 秒执行，那么 n 就存为 2 
每当指针指向一个单元格时，就取出其中的任务检查如果 n 为 0 就拿出来立刻执行，否则 n 减 1

考虑到一个单元格有多个任务的情况存在，处理方法也有很多种，比如拉链法，单元格存储指针之类

这个结构看上去和 linux 内核的无锁环形队列很相似，有兴趣可以去看下 linux 的内核实现。

## 基于 RabbitMQ 的延时任务
基于 RabbitMQ 的实现思路主要依赖于 MQ 的 Message Time-To-Live 和 Dead Letter Exchange 来实现。

先大致介绍下这两个概念

### Time-to-Live

> Time-to-Live (TTL) is a RabbitMQ extension to AMQP 0.9.1 that allows developers to control how long a message published to a queue can live before it is discarded

对于 TTL 有两种设置对象， queue 和 message
也就是说，你可以在 queue 上设置 TTL 那么进入这个 queue 的 message 就会在设定存活时间过后挂掉
另一种是在 pub message 的时候在 message 上设置 TTL 这样每个 message 都会拥有不一样的存活时间，而与 queue 无关
如果没有特殊设置的话，死掉的 message 将会被丢弃掉

### Dead Letter Exchange (DLE)
之前也介绍过 AMQP 的各种各样的 Exchange，Dead Letter Exchange 可以在任意一种 Exchange 基础上进行声明，'dead-lettered' 的 messages 会被发送至 DLEs 再通过 DLEs 路由给绑定的 queue

以下三种状态的 messages 会被 handle：

* 这个 message 是被 rejected 的或者被 Negative Acknowledgement 并不能被 requeue 的
* 设置了 TTL 并过期的
* 应进 queue 的长度超限而被丢弃的

大致了解了上述两个概念后，来说下延时方案的思路及工作流程

### 延时任务
流程很简单，我们通常这样来使用 MQ

![mq-work-flow][2]

就像这样，生产者 pub 消费者 sub 的形式
延时方案的思路及工作流程是这样的

![mq-work-flow-dle][3]

其中上面那个 queue 中放置着设置了 TTL 的 messages 并且没有设置消费者来处理，这样当 TTL 的时间到了的时候 messages 就会过期被转发给 DLE， 然后 DEL 就会把 'dead-lettered' 路由给绑定的 queue ，然后在这个 queue 上设置消费者来处理其中的 messages

这样整个流程就完成了，当有延时任务进来时，为其设置 TTL 并扔到存活队列中，等他死掉后进入 DLE 被再次路由到对应 queue 中被处理掉。

拿 ruby 来写个小例子
```
require "bunny"

conn = Bunny.new
conn.start

channel = conn.create_channel

exchange = channel.fanout('amq.fanout')

# q = channel.queue('example.delay.await', exclusive: true, arguments: {"x-message-ttl" => 1000}).bind(exchange)

# q = channel.queue('example.delay.await1', exclusive: true).bind(exchange)

# q = channel.queue('example.delay.await2', exclusive: true).bind(exchange)

dlx  = channel.fanout("example.dlx.exchange")
q    = channel.queue('example.delay.life', exclusive: true, arguments: {"x-dead-letter-exchange" => dlx.name}).bind(exchange)

dlq  = channel.queue('example.delay.heaven', exclusive: true).bind(dlx)

10.times do |i|
  exchange.publish("Message #{i}", expiration: 1000 * i)
end

sleep 30
puts "Closing..."
conn.close
```

在上面的例子中，我一共 pub 了 10 个 messages 进入队列 'example.delay.life' 并为每个 message 设置不同的 TTL

10s 内每一秒都会有一个 message 被队列 'example.delay.life' 丢弃并进入到队列 'example.delay.heaven' 中

这里由于我声明的队列都是 exclusive 的，所以 'sleep 30' 来方便查看效果，close 后这两个队列都会被销毁掉

![mq-exchange-dle][4]

![mq-queues-ttl][5]

参考：
[rabbitmq-ttl][6]
[rabbitmq-dlx][7]


  [1]: https://upload.wikimedia.org/wikipedia/commons/thumb/b/b7/Circular_buffer.svg/1024px-Circular_buffer.svg.png
  [2]: http://7xsger.com1.z0.glb.clouddn.com/image/jpg/mq-work-flow.png
  [3]: http://7xsger.com1.z0.glb.clouddn.com/image/jpg/mq-work-flow-dle.png
  [4]: http://7xsger.com1.z0.glb.clouddn.com/image/jpg/mq-exchanges-dle.png
  [5]: http://7xsger.com1.z0.glb.clouddn.com/image/jpg/mq-queues-ttl.png
  [6]: http://www.rabbitmq.com/ttl.html#per-queue-message-ttl
  [7]: http://www.rabbitmq.com/dlx.html