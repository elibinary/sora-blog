---
title: 基于 RabbitMQ 的 Ruby 与 Python 服务间通讯
date: 2017-08-27 13:12:18
tags:
  - Python
description: RabbitMQ 是一套开源的消息队列服务软件，是基于高级消息队列协议 AMQP 的开源实现，其基础服务由 Erlang 实现。
---

在微服务化的过程中，每个子服务都是独立自成一体的，这也就意味着再设计子服务时可使其内部细节对外不可见，而以一个黑盒的状态存在。在这样的设计下，外部也可以说是对于整个系统来说其实并不关心其某个子服务的内部实现细节，或实现手段，只要能够对外提供可用的服务。

RabbitMQ 是一套开源的消息队列服务软件，是基于高级消息队列协议 AMQP 的开源实现，其基础服务由 Erlang 实现。

## AMQP
首先介绍一些 AMQP 的基本概念，首先来看它的工作流程：

$Producer$ --pub--> $Exchange$ --routes--> $Queue$ --sub--> $Consumer$

整个过程大致就是这样，消息首先由 Producer 发送给 Exchange，然后 Exchange 将收到的的消息按照某种路由规则发送给绑定的 Queue，最后 AMQP 会把消息投递给订阅了该队列的 Consumer

接下来来看看 AMQP 的 Exchange，AMQP 提供了四种 Exchange

![AMQP Exchange][1]

### Direct exchange
其预声明的默认名称为 (Empty string) 和 amq.direct

Direct Exchange 根据消息携带的 routing key 将消息发送至对应的队列中，一般过程为：

1. 一个绑定着 routing key 的 Queue 绑定到了某 Exchange 上
2. 当一个携带 routing key 的消息被发送给 Exchange 时，Exchange 会把该消息路由给绑定着该 routing key 的 Queue

上图中的 default exchange 实际上就是一个预设的没名字的 direct exchange ，每个新建 Queue 都会自动绑定到默认交换机上，绑定的 routing key 名称与队列名称相同。

### Fanout exchange
其预声明的默认名称为 amq.fanout

Fanout Exchange 会把传来消息路由给所有绑定在此 exchange 的 Queue 而忽略绑定的 routing key

Fanout exchange 一般用来处理 broadcast routing

### Topic exchange
其预声明的默认名称为 amq.topic

Topic exchange 通过匹配消息的 routing key 与 Queue 到 Exchange 之间的绑定模式来把消息路由给复数个 Queue

通常用来处理 multicast routing

### Headers exchange
其预声明的默认名称为 amq.match ，在 rabbitmq 中还有 amq.headers

有时消息的路由操作会涉及到多维属性，这时由于 routing key 必须是一个字符串，使用消息头将更容易且更精确的进行路由表达。

Headers exchange 使用多个消息属性来代替 routing key 建立路由规则。通过判断消息头的值能否与指定的绑定相匹配来确定路由

Headers exchange 可以视为 Direct exchange 的另一种表现形式，不同之处在于路由键必须是一个字符串，而头属性值则没有这个约束，它们甚至可以是整数或者哈希

### Queue
下面来说说 Queue 它们存储着即将被 Consumer 消费掉的消息

如果一个队列尚不存在，声明一个队列会创建它。如果声明的队列已经存在，并且属性完全相同，那么此次声明不会对原有队列产生任何影响

Queue 有两大类

* Durable queues
* Transient queues

正如其名，Durable queues 会被持久化到磁盘上，不会随着 broker 的重启而丢失。

AMQP 大致的几个重要组成先介绍到这
另外 AMQP 是一个使用 TCP 提供可靠投递的应用层协议，可使用认证机制并且提供TLS（SSL）保护

## 通信
作为消息中间件的 rabbitmq ，其核心 AMQP 不在乎通信双方到底是谁

先来看看最基本的通信模式：
$$ Producer_{ruby} --mq--> Consumer_{python} $$

很简单，就不多说了来看代码

首先是 Producer
```
require 'bunny'

conn = Bunny.new
conn.start

channel = conn.create_channel

x = channel.default_exchange
x.publish("This is Eli", routing_key: 'example.hello_eli')

conn.close
```

Consumer
```
#-*- coding：utf-8 -*-
import pika

conn = pika.BlockingConnection()
channel = conn.channel()

channel.queue_declare(queue='example.hello_eli')

def callback(ch, method, properties, body):
  print('输不出中文嘛')
  print(body)

channel.basic_consume(callback, queue='example.hello_eli', no_ack=True)

print('Python: Waiting ...')
channel.start_consuming()
```

启动之后使用 'rabbitmqctl list_queues' 命令就可以看到当前 Queue 中出现了你的队列
```
Listing queues ...
example.hello_eli 0
```

接下来再来看 RPC(Remote procedure call)

RPC 实现也非常简单，它的工作原理直白易懂。这里我们以 $Client$ 和 $Server$ 来表示通信双方
RPC 的工作原理就是 $Client$ 在 publish 出请求前会创建并监听一个匿名私有的 Queue，然后在 publish 请求给 $Server$ 的时候会携带这个匿名 Queue 的信息
而 $Server$ 在收到并处理完请求后会给请求中提到的 Queue 发送 callback 结果

下面来看代码，首先是 $Client_{ruby}$

```
require 'bunny'
require 'thread'
require 'securerandom'

# SecureRandom.uuid

conn = Bunny.new(:automatically_recover => false)
conn.start

ch = conn.create_channel

begin
  reply_queue = ch.queue('', :exclusive => true)

  call_id = SecureRandom.uuid
  lock = Mutex.new
  condition = ConditionVariable.new

  reply_queue.subscribe do |delivery_info, properties, payload|
    if properties[:correlation_id] == call_id
      puts payload
      lock.synchronize { condition.signal }
    end
  end

  x = ch.default_exchange
  x.publish("This is Eli", 
    routing_key: 'example.rpc.hello_eli', 
    correlation_id: call_id,
    reply_to: reply_queue.name)

  lock.synchronize { condition.wait(lock) }
  puts 'over ...'
rescue Interrupt => e
  e
ensure
  ch.close
  conn.close
end
```

下面是 $Server_{python}$
```
#-*- coding：utf-8 -*-
import pika

conn = pika.BlockingConnection()
channel = conn.channel()

channel.queue_declare(queue='example.rpc.hello_eli')

def callback(ch, method, props, body):
  print('输不出中文嘛')
  print(body)

  ch.basic_publish(exchange='',
                   routing_key=props.reply_to,
                   properties=pika.BasicProperties(correlation_id = props.correlation_id),
                   body=str('No, I\'m Python'))
  ch.basic_ack(delivery_tag = method.delivery_tag)

channel.basic_consume(callback, queue='example.rpc.hello_eli')

print('Python: Waiting ...')
channel.start_consuming()
```
---
ps: 最后在吐槽下 python 的编码处理，真是蛋疼死个人

  [1]: http://7xsger.com1.z0.glb.clouddn.com/image/jpg/AMQP-Exchange.png