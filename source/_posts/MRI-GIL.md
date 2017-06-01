---
title: MRI-GIL
date: 2016-05-13 18:07:58
tags:
  - ruby
description: 本篇简单介绍并行并发与ruby的GIL
---

#### Concurrency and Parallelism

> 并发，一个处理器同时处理多个任务，逻辑上的同时发生

> 并行，多个处理器或者是多核的处理器同时处理多个不同的任务，物理上的同时发生

如果你熟悉操作系统的时间片的概念的话，就很容易理解当一台单CPU的机器在处理各个任务时其实就是一个并发环境。各个任务以时间片为时间单位来获取CPU的使用权，给用户以每个线程都在同时运行的错觉。

而在并行环境中，如多个线程是可以利用多CPU的处理能力，在真正意义上实现同一时刻同时执行，以最大限度的利用CPU。

#### GIL

GIL，全称 Global Interpreter Lock，即全局解释器锁。
ruby解释器MRI利用GIL来保护Ruby内核，以免竞争条件造成数据混乱。GIL的存在会使即使是在多核多线程的环境中，同一时刻也只有一个线程和一个核心在工作，也就是说由于GIL的存在，将不能真正的实现并行。

MRI中还有一个计时器线程用来避免一个线程独霸GIL，当MRI启动并只有主线程运行时，计时器线程将会沉睡，当有新的线程在等待GIL,它就会唤醒计时器线程。

一段时间后计时器线程会在当前持有GIL的线程上设置中断标记，并不会立即停止当前线程的执行，而是当线程返回当前方法（ruby方法）的返回值时会去检测中断标记，如果已被设置中断标记则此线程会在返回其值前停止执行并释放锁。

我们来看下下面的代码
```
array = []

5.times.map do
  Thread.new do
    (1..100).each do |i|
      array << i
    end
  end
end.each(&:join)

puts array.to_s
puts array.size
```

在自己的机器上试着执行下，我的执行结果是顺序的5段1到100的数组，就好像这五个线程是顺序的一个执行完毕再执行下一个一样。

再看这段代码
```
array = []

5.times.map do
  Thread.new do
    (1..100).each do |i|
      p i
      # a = a^2+i^2
      array << i
    end
  end
end.each(&:join)

puts array.to_s
puts array.size
```
在循环中加入一个打印语句，此时的执行结果正如理想的并发情景一样是无序的输出。

*由于我对GIL还有很多不理解的地方，下面纯属个人理解，有理解错误的地方请大家指出来。*

由于GIL的存在，同一时间只会有一个线程执行，直到耗尽时间片或被阻塞（IO或者sleep等）就会切换至其他线程。首先第一个例子中其中一个线程获取到了锁，然后在时间片时间内执行完毕然后依次执行其他线程最终就是我们看到的结果，而第二个例子由于打印这个IO操作造成了线程的切换。

---

[Nobody understands the GIL](http://www.jstorimer.com/blogs/workingwithcode/8085491-nobody-understands-the-gil)
