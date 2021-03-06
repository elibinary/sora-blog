---
title: Greedy-And-Annealing
date: 2016-04-09 13:19:51
tags:
  - Algorithm
description: 本篇简单介绍下贪心算法和模拟退火。
---


#### 贪心

> 所谓贪心算法即是在每次做选择是总是选择当前最优的选择，以期望获得最终的最优解
> 在做出选择的时候不会去考虑整体最优的情况，所以并不能总是得出问题的最优解。

- 最优子结构

先来看几个概念，什么是最优子结构呢，所谓最优子结构即如果问题的最优解所包含的子问题的解也是最优的，我们就称该问题具有最优子结构性质，也称此问题满足最优性原理。而一个问题是否拥有最优子结构是该问题是否能用动态规划和贪心算法的重要指标。

- 贪心选择性质

所谓的贪心选择性质既是指问题的整体最优解可以通过一系列的局部最优解最终推导出来，一个问题必须满足这个性质才可以使用贪心算法来解决。

在动态规划中，每一步的决策是依赖于相关子问题的解的，所以必须先求解相关子问题，然后在作出决策，这是一种自底向上的方法。而贪心算法每次决策都仅仅考虑当前最优，然后再去求解做出这个决策后所产生相关子问题的解，这是一种自顶向下的方法，每
作一次贪心选择就将所求问题简化为规模更小的子问题。

一个问题是否能用贪心算法解决，必须证明其局部最优解能最终导致产生全局最优解。而一旦一个问题被证明可以使用贪心解决，那贪心算法将是一种极为高效的解法。

- 实现细节

这里拿找零钱问题为例，（25美分、10美分、5美分和1美分硬币找n美分零钱的问题，使硬币总数尽可能少。)

1. 首先确定候选集合，这里就是25美分、10美分、5美分和1美分硬币组成的集合
2. 然后是随着贪心策略的不断进行所产生的解集合，这里已找出的零钱组成解集合
3. 再然后是判断解集合是否构成问题最终解的判断函数
4. 贪心策略，贪心策略是贪心算法的关键，贪心策略负责确定候选集合中的哪个对象能够组成解集合，在这里我们的贪心策略就是每次都选择不超过n美分的最大面值的硬币
5. 接下来是可行性判断，每次添加候选对象进入解集合时判断其可行性，在这里就是判断所找零钱不超过应找数。

接下来我们来看下实现的伪码：
```
collection c    # 候选集合
collection s    # 解集合
while(s所构成的解 == 最终解)
{
    n = greedy_strategy(c)          # 贪心策略
    if(feasible(s, n))
    {             # 可行性判断
        s << n
    }
}
return s

```

#### 模拟退火

退火这个名词来自冶金学，它代表了一种物理过程，当固体被加热到一定高温时其原子会离开原来的位置然后再其他位置随机排列，随着温度缓慢降低使原子有较多可能可以找到内能比原先更低的位置。

模拟退火是一种通用概率算法，用来在固定时间内寻找一个大的搜寻空间内找到的最优解。模拟退火算法可以分解为解空间、目标函数和初始解三部分。

基本思路：
    1. 设置初始温度，系统初始应该位于一个高温的状态，故通常选择一个较大的数
    2. 由一个产生函数从当前解产生一个位于解空间的新解
    3. 计算新解和初始解的目标函数差，通常来计算增量Δt′=C(S′)-C(S)，其中C(S)为评价函数
    4. 若Δt′<0则接受S′作为新的当前解，也就是新解更优，否则以概率exp(-Δt′/(KT))接受S′作为新的当前解。（exp表示自然指数，k为常数）。很容易可以看出，温度高的时候会更高概率的接受一个比当前解要差的解，当温度逐渐降低接受一个差解的概率也会随之降低。exp(-Δt′/(KT))的取值范围是(0, 1)
    5. 当新解被接受时，用新解代替当前解进行下一轮迭代
    6. 温度T降至某最低值时，或者完成给定数量迭代中没有可接受新解，停止迭代，接受当前寻找的最优解为最终解。

接下来我们来看下实现的伪码：
```
T = value(t)        # 系统初始温度
k = 0               # 连续未接受新解的次数
s = value(s)        # 初始解

# 假设当温度将为0时或者达到最大连续未接受新解的次数时结束迭代
while(T > 0 && k < max_k)
{
    s_r = selection_function      # 使用选择函数产生一个新解
    t_d = C(s_r) - C(s)
    if(t_d > 0)        # 如果新解是优于当前解就接受新解
    {
        s = s_r
        k = 0          # 重置
    }else if(exp(t_d/(KT)) > random(1)){
        s = s_r        # 概率的接受新解
        k = 0          # 重置
    }else{
        k += 1         # 连续未接受新解的次数加一
    }

    T = r*T            # 0 < r < 1, r用来控制降温速度
}
```

模拟退火算法与初始值无关，算法求得的解与初始解s无关；模拟退火算法具有渐近收敛性，已在理论上被证明是一种以概率1收敛于全局最优解的全局优化算法；同时模拟退火算法具有并行性。

我们可以很容易看出退火解法很想贪心法，但是退火法引入了一个概率接受差解的思想。模拟退火算法以一定的概率来接受一个比当前解要差的解，因此有可能会跳出这个局部的最优解，达到全局的最优解。这个概率随着温度的降低而降低，也就是说随着解集合的成熟而逐渐稳定，逐渐降低接受差解的概率。

模拟退火算法并不总能找到全局的最优解，但是它可以比较快的找到问题的近似最优解。
