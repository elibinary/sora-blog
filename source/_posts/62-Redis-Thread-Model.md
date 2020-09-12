---
title: Redis 线程模型
date: 2020-07-08 15:35:09
tags:
  - db
description: redis 所有操作都是在一个线程上执行的吗?
---

在接触到 redis 的时候，看到最多的关于 redis 特性的介绍就是：单线程处理模式，高吞吐，内存 k-v 等等。随着使用和了解的加深，一定会产生很多疑问：

* redis 所有操作都是在一个线程上执行的吗？
* 为啥 redis 单线程也能有这么高吞吐量？
* redis 为啥不用多线程呢？
* redis 的 I/O 多路复用具体体现在哪一块？

## 单线程模型
Redis 最初设计时选择了使用单线程模型，这个选择其实有多方面考量，当然其主要依据点也出发自最关键的：单线程模型到底对运行性能的影响有多大。关于这一点，[Redis FAQ 有一个问答][1]
> **Redis is single threaded. How can I exploit multiple CPU / cores?**
It's not very frequent that CPU becomes your bottleneck with Redis, as usually Redis is either memory or network bound. For instance, using pipelining Redis running on an average Linux system can deliver even 1 million requests per second, so if your application mainly uses O(N) or O(log(N)) commands, it is hardly going to use too much CPU.
...

我们知道，多线程技术能够帮助我们充分利用 CPU 资源来并发的执行任务，减少 CPU 空闲时间。但正如上面回答所说，CPU 并不是 Redis 的性能瓶颈，Redis 并不是一个 [CPU 密集型应用][2]。([What do the terms “CPU bound” and “I/O bound” mean?][3])

所有的 Redis 操作都会在内存中完成，并不会涉及到任何的 I/O 操作（这里是指 c-s 正常读写操作，不包括 AOF 备份，RDB 保存等）。数据的读写只发生在内存中，其处理速度是非常快的（if RAM is rated at 3200 MHz, it performs 3.2 billion cycles per second）。正如上面 FQA 所说，在一个普通的 Linux 服务起上 Redis 也能在 1s 处理 1,000,000 个 requests。

Redis 服务的瓶颈还是在于网络 I/O：等待&读取客户端请求数据，写入&传输结果数据。Redis 使用 I/O 多路复用机制来并发处理来自客户端的多个连接，同时等待多个连接发送的请求。

### 同步非阻塞 I/O
传统的 `阻塞 I/O` 工作方式是：当对一个文件描述符(fd)进行 read/write 操作时，如果当前 fd 不可读或不可写（比如数据未就绪），那么当前执行线程就会阻塞等待，直到 fd 可操作。该方式简单直观，同时也是我们经常用到的方式。

Redis 服务器是一个事件驱动程序，它基于 Reactor 模式实现了自己的网络事件处理器（file event handler）：

* 事件处理器使用 I/O 多路复用程序来同时监听多个 socket
* socket ready 事件有 accept、read、write、close 等
* handler 监听到对应 ready 事件产生后，就会调用 socket 之前关联好的处理函数

虽然`事件处理器`是以单线程方式运行的，但通过 I/O 多路复用技术，这即实现了高性能的网络通信模型，又能很好的与 Redis 服务中的其他同样是单线程方式运行的模块进行对接。

Redis 的 I/O 多路复用程序的所有功能都是通过封装常见 I/O 多路复用函数库(select, epoll, evport, kqueue 等)来实现的。在编译的时候会自动选择系统中支持的性能最高的函数库来使用。

### Redis 是否所有操作都是在一个线程上执行
Redis 使用单线程来处理客户端命令的一系列操作：

* 请求获取(socket 读)
* 数据解析
* 命令执行
* 结果返回(socket 写)

其请求命令的执行是完全串行执行的（在主线程上）
但其实 Redis 也有其他线程在工作，比如 4.x 版本之后引入的异步处理线程，主要用来异步处理一些耗时的删除操作：

* UNLINK
* FLUSHALL ASYNC
* FLUSHDB ASUNC

其主要目的是：避免在删除一些超大键值时，长时间的 block 主线程导致服务吞吐降低。想 UNLINK 命令在主线程中其实只是把 key 从元数据中删除，真正的删除释放操作会在后台异步执行。

### 小结
Redis 使用单线程模型来处理 request 主要是因为 CPU 不是 Redis 的瓶颈，而使用多线程模型在可能获得有限的性能提升的同时也将带来高出很多的开发成本和维护成本。

但从另一方面看，单线程模型也限制了单个 Redis 服务对 CPU 多核的利用，对此官方 FQA 是这么建议的：
> However, to maximize CPU usage you can start multiple instances of Redis in the same box and treat them as different servers. At some point a single box may not be enough anyway, so if you want to use multiple CPUs you can start thinking of some way to shard earlier.

官方建议可以开启多个 Redis 实例，并通过分区来分担压力，关于分区可以参阅：[Partitioning: how to split data among multiple Redis instances.][4]
但同时数据分区也会引入分布式存储常见的问题：

* 热点数据问题
* 数据偏斜
* 扩/缩节点和重新分配问题

上面问题是分布式存储复制&分区所要面对的常见问题，在这里不展开了

## Redis 6.0 引入的多线程模型
在上一章中有提到 Redis 的主要瓶颈在于网络 I/O（request socket 读/写），之前版本使用单线程来处理这些逻辑，6.0 版本引入的多线程模型主要针对此进行改进。

Redis 主线程的时间主要消耗的两方面：

* 逻辑计算
* 同步 I/O 读写，数据拷贝

新的多线程模型，使用一组单独的线程专门处理 socket 读/写调用以及数据解析工作，命令执行依然由主线程来串行执行。




  [1]: https://redis.io/topics/faq#redis-is-single-threaded-how-can-i-exploit-multiple-cpu--cores
  [2]: https://zh.wikipedia.org/wiki/CPU%E5%AF%86%E9%9B%86%E5%9E%8B
  [3]: https://stackoverflow.com/questions/868568/what-do-the-terms-cpu-bound-and-i-o-bound-mean
  [4]: https://redis.io/topics/partitioning