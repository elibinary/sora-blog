---
title: 基于 Redis 的 locking 实现
date: 2017-11-12 14:27:17
tags:
  - db
description: 利用 redis 的特性实现 lock
---

基于 Redis 的 lock 正是基于其单进程单线程及其原子操作来实现的。对于 Redis 来说，同一时刻只可能有一个命令正在操作，也就是说在 Redis 的层面上，请求是串行进行的。

### SETNX

SETNX 是 Redis 的一个命令，完整形式是这样的：
```
SETNX key value
```
它是 ‘set if not exists’ 的简写，正如其描述一样 SETNX 的作用是给 key 赋值，并且仅当目标 key 不存在时才能成功并返回 1

locking 实现主要就是基于 Redis 的这个命令

其过程是这样的：

1. 首先 ClientA 需要获取锁，然后 SETNX lock_name time_stamp 返回 1 ，加锁成功
2. 此时 ClientB 想要获取该锁，尝试 SETNX 结果因为 key 已存在 返回 0，知道锁正被占用然后选择等待或返回
3. ClientA 做完要做的事情后，使用 DEL 命令删除 lock_name 来完成释放锁的操作
4. 此时该锁可被其他 Client 抢占

看起来很完美，但其实这中间存在着很多细节上的问题，大致分析一下：

* 因为 ClientA 的 SETNX 和 DEL 是分开的操作，那么其中一个问题就是假如 ClientA 在加锁之后因为某些原因没有释放掉这个锁，就会导致很严重的后果
* 上面的问题其实在设计时已经被想到，解决办法就是给这个锁加上过期时间，锁超过过期时间之后，其他的 Client 就可以释放掉它，然后再通过 SETNX 抢占
* 但是在上面的解决方法中其实有另外一个问题存在，那就是假如存在这样的一种情况：
    - ClientA 在加锁后没有释放锁，此时有 ClientB 和 ClientC 在等待
    - 当锁超时时，B 和 C 同时检测到了超时，然后执行 DEL 操作，再 SETNX 抢锁
    - 其单个操作都是原子性的，那么当 C 先 DEL 后又 SETNX 抢到了锁这时 B 执行了 DEL 又把锁释放了，最后两个都获得了锁
* 还有另一种情况，假如 ClientA 并没有死，而是在执行一个很耗时的操作，锁过期了也没执行完，然后在别人抢占了锁之后，它完成了然后执行了 DEL 释放锁的操作。。。GG

下面来看下 redis-objects 这个 gem 是如何实现这个 locking 的

### Locking

看源码实现很简单，一共也就几十行代码

```
 # Get the lock and execute the code block. Any other code that needs the lock
# (on any server) will spin waiting for the lock up to the :timeout
# that was specified when the lock was defined.
def lock(&block)
  expiration = nil
  try_until_timeout do
    expiration = generate_expiration
    # Use the expiration as the value of the lock.
    break if redis.setnx(key, expiration)

    # Lock is being held.  Now check to see if it's expired (if we're using
    # lock expiration).
    # See "Handling Deadlocks" section on http://redis.io/commands/setnx
    if !@options[:expiration].nil?
      old_expiration = redis.get(key).to_f

      if old_expiration < Time.now.to_f
        # If it's expired, use GETSET to update it.
        expiration = generate_expiration
        old_expiration = redis.getset(key, expiration).to_f

        # Since GETSET returns the old value of the lock, if the old expiration
        # is still in the past, we know no one else has expired the locked
        # and we now have it.
        break if old_expiration < Time.now.to_f
      end
    end
  end
  begin
    yield
  ensure
    # We need to be careful when cleaning up the lock key.  If we took a really long
    # time for some reason, and the lock expired, someone else may have it, and
    # it's not safe for us to remove it.  Check how much time has passed since we
    # wrote the lock key and only delete it if it hasn't expired (or we're not using
    # lock expiration)
    if @options[:expiration].nil? || expiration > Time.now.to_f
      redis.del(key)
    end
  end
end
```

先来看它获取锁的过程，首先会在超时时间内不断地循环尝试获取锁

```
def try_until_timeout
  if @options[:timeout] == 0
    yield
  else
    start = Time.now
    while Time.now - start < @options[:timeout]
      yield
      sleep 0.1
    end
  end
  raise LockTimeout, "Timeout on lock #{key} exceeded #{@options[:timeout]} sec"
end
```

可以看到，在超时时间内每隔 0.1 秒尝试一次

再回到 lock 方法，尝试获取锁的过程如下：

1. 使用 SETNX 命令尝试获取锁，如果成功跳出循环往下执行真正的逻辑
2. 如果失败就去校验锁的过期时间，如果没有过期就等待进入下一轮的尝试
3. 如果检查到锁已过期，就使用 GETSET 命令给 lock_key 赋值并返回原值，看其是否超过期，没有就等待下一轮尝试
4. 如果过期就拿到锁，可以开始干自己的事了
5. 做完了自己的事后，在释放锁的操作前会前检查下是否已经过了自己获取锁时定下的过期时间，如果已经超时就不进行释放锁的操作