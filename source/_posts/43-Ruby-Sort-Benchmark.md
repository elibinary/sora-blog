---
title: 对比 Ruby int 和 time 的比较和排序
date: 2018-03-23 18:45:06
tags:
  - Ruby
description: Benchmark for compare and sort
---

```
require 'benchmark'

time_1 = Time.now
time_2 = Time.now + 2592000

time_1_i = time_1.to_i
time_2_i = time_2.to_i

ary = []
1000.times { 
  ary << Time.now + Random.rand(100000)
}

ary_i = ary.map(&:to_i)

n = 50000
m = 1000

Benchmark.bm(20) do |x|
  x.report("compare int")               { n.times { time_1_i > time_2_i } }
  x.report("compare time")              { n.times { time_1 > time_2 } }
  x.report("compare time with to_i")    { n.times { time_1.to_i > time_2.to_i } }
  x.report("sort times")                { m.times { ary.sort_by{ |a| a } } }
  x.report("sort_by times")             { m.times { ary.sort_by{ |a| a } } }
  x.report("sort_by times with to_i")   { m.times { ary.sort_by{ |a| a.to_i } } }
  x.report("sort_by int")               { m.times { ary_i.sort_by{ |a| a } } }
end
```

对比结果

```
                           user     system      total        real
compare int            0.000000   0.000000   0.000000 (  0.002590)
compare time           0.010000   0.000000   0.010000 (  0.007256)
compare time with to_i  0.000000   0.000000   0.000000 (  0.008958)
sort times             0.900000   0.020000   0.920000 (  0.924535)
sort_by times          0.880000   0.010000   0.890000 (  0.909420)
sort_by times with to_i  0.530000   0.010000   0.540000 (  0.542041)
sort_by int            0.460000   0.000000   0.460000 (  0.465086)
```