---
title: 源码阅读-Go Sync
date: 2020-06-16 18:30:58
tags:
  - Golang
description: sync pkg 是我们在并发编程中经常使用到的一个包，它提供了锁，信号同步，单次加载等非常有用的功能
---

> Package sync provides basic synchronization primitives such as mutual exclusion locks. Other than the Once and WaitGroup types, most are intended for use by low-level library routines. Higher-level synchronization is better done via channels and communication.

sync pkg 是我们在并发编程中经常使用到的一个包，它提供了锁，信号同步，单次加载等非常有用的功能

## Once
> Once is an object that will perform exactly one action.

`Once` 经常被用来保证初始化之类的逻辑在并发环境下仅执行一次
它的实现也非常简洁，仅有一个 struct 定义和对外暴露的 `Do` 方法
```
type Once struct {
    done uint32
    m    Mutex
}

func (o *Once) Do(f func()) {
    // [Comment By Eli] 使用原子操作判断状态位
    if atomic.LoadUint32(&o.done) == 0 {
        // Outlined slow-path to allow inlining of the fast-path.
        o.doSlow(f)
    }
}

func (o *Once) doSlow(f func()) {
    o.m.Lock()
    defer o.m.Unlock()
    // [Comment By Eli] 加锁后再一次判断状态位，避免竞争发生
    if o.done == 0 {
        // [Comment By Eli] 在 f() 执行完毕后再进行状态改变
        defer atomic.StoreUint32(&o.done, 1)
        f()
    }
}
```

源码里也给出了一个错误的实现方式
```
// Note: Here is an incorrect implementation of Do:
//
//  if atomic.CompareAndSwapUint32(&o.done, 0, 1) {
//      f()
//  }
```

上面使用 CAS 实现最大的一个问题就是它是先尝试改变状态位，再执行 `f()` 
这样就可能出现 caller 在 f() 方法还未执行完就返回了并开始继续执行下面的逻辑，这可能会导致严重错误发生

## Lock

// TODO

*Package atomic provides low-level atomic memory primitives, useful for implementing synchronization algorithms.*