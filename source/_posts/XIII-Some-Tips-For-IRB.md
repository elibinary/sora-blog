---
title: 一些IRB的小技巧
date: 2017-01-08 18:15:55
tags:
  - Ruby
description: 一些IRB的小技巧
---

### 好用的 '_'
当你在使用irb调试某些语句时有些时候忘记把表达式的结果复制给一个变量时，这时候这个 '_' 就是时候登场了，在执行过输入之后，IRB会将执行过的表达式的结果存入名为 '_' 的变量中，比如：
```
%w(123 153 266 370 456).map do |item|
    res = 0
    (0..(item.length - 1)).each do |i|
        res += (item[i].to_i)**3
    end
    
    if res == item.to_i
        item
    else
        nil
    end
end

_.compact
```
上面的例子是一个简单的挑选水仙花数的小段程序，看这时候 '_' 的方便之处就体现出来了。

### 会话

什么是会话呢，你可以简单的认为会话就是在 IRB 中打开一个新的IRB拷贝的方法。会话有一个非常好用的地方就是你可以进入任何对象，并让这个对象变成当前的执行上下文，并且有效的改变当前对象自身的引用。在 IRB 交互模式中，使用 irb 命令可以创建一个新会话，像这样：
```
2.2.1 :003 > irb
2.2.1 :001 > jobs
 => #0->irb on main (#<Thread:0x0000000087b310>: stop)
 => #1->irb#1 on main (#<Thread:0x0000000086b168>: running)
2.2.1 :002 > irb
2.2.1 :001 > jobs
 => #0->irb on main (#<Thread:0x0000000087b310>: stop)
 => #1->irb#1 on main (#<Thread:0x0000000086b168>: stop)
 => #2->irb#2 on main (#<Thread:0x0000000083aab8>: running)
```
使用jobs可以列出当前所有的会话和它的ID，如上面那样会将会话信息也列出来。知道了会话的ID，可以使用 fg 命令来在会话间切换：
```
2.2.1 :002 > fg 1
    => #<IRB::Irb: @context=#<IRB::Context:0x0000000086acb8>, @signal_status=:IN_EVAL, @scanner=#<RubyLex:0x0000000086a060>>
    
2.2.1 :003 > jobs
 => #0->irb on main (#<Thread:0x0000000087b310>: stop)
 => #1->irb#1 on main (#<Thread:0x0000000086b168>: running)
 => #2->irb#2 on main (#<Thread:0x0000000083aab8>: stop)
```

是不是很方便，除此之外 irb 命令还可以接收参数，如果将一个对象当参数传入，irb命令就会创建一个新会话，并且将该对象变成该会话的上下文，如下：
```
2.2.1 :007 > self.class
 => Object 
2.2.1 :008 > irb [1,2,3]
2.2.1 :001 > self.class
 => Array 
2.2.1 :002 > length
 => 3 
2.2.1 :003 > first
 => 1 
```
可以看到，当前上下文即是 [1,2,3] 本身

当一个会话结束时，使用 exit 命令来终止当前会话，你也可以使用 kill 命令来结束指定ID的会话。