---
title: NetWork Flow Problem - Maximum Flow
date: 2016-02-19 20:00:43
tags:
- Algorithm
- Ruby
description: 这里介绍一种计算流系统中最大流的方法，解法使用Ford-Fulkerson方法的基本思想。
---

> 不只是网络流，很多场景都会涉及到流量问题。这里介绍一种计算流系统中最大流的
> 方法，解法使用Ford-Fulkerson方法的基本思想。

在介绍Ford-Fulkerson方法之前需要先理解几个基本概念：
对于一个流网络，该网络由一个源点s、一个汇点t和源点与汇点间的众节点以及各点间的边组成。
-  网络流
网络流有几个性质：
    +  容量限制
    设C为每条边的容量，F为每条边的流量。
    显然 F<=C，一条边的流不超过它自身的容量。
    +  斜对称
    假设一条边的两个端点a和b，a向b流了f的流，就可以认为b向a流了-f的流。
    +  流量守恒
    ```ruby
    Σ F<v,x> = Σ F<x,u>
    ```
-  残余网络
通俗地讲，残余网络就是对于给定的一个网络和该网络的一个流，除去这个已知流其对应还可以容纳的流所组成的网络就称为残余网络。
-  增广路径
增广路径就是残余网络中从源点到汇点的一条简单路径。形象的理解为从s到t存在一条不违反边容量的路径，向这条路径压入流量，可以增加整个网络的流值。
-  割
这里有一个最大流等于最小割的定理。
先介绍割的一个性质，对于一个流网络中的任意割，穿过该割的最大净流量不超过该割的容量。
由此显然可以想到一个网络的最大流量小于等于该网络的最小割。（割将网络分为两部分，上游部分的流量必然会经过割进入下游部分）

问题的解法思路：

1.  构建有向图
2.  使用BFS算法找到一条增广路径（假设起初为0）
3.  找到这条增广路径中限流最小的边
4.  该增广路径中每条边流量减掉3中最小边流量
5.  maxflow加3中最小边流量（此路径为有效路径）
6.  迭代（重复2，3，4，5）
7.  条件边界：找不到增广路径则退出
    
上代码：

```ruby
class GraphTheoryMaxflow
  # edge: 边数
  # spot: 交点数
  # graph: 有向图（二维数组）
  def initialize(edge, spot, graph)
    @graph = graph
    @edge = edge
    @spot = spot
  end

  def max_flow
    max_num = 0
    rgraph = @graph
    boundary, path = augmentation_path(rgraph, 0, @spot-1)
    while boundary
      min_flow = 65535     # 这里给你个限制的最大值（65535为16位int表示最大值）

      v = @spot - 1
      while !path[v].nil?
        u = path[v]
        min_flow = [min_flow, rgraph[u][v]].min
        v = u
        puts v
      end

      v = @spot - 1
      while !path[v].nil?
        u = path[v]
        rgraph[u][v] -= min_flow
        rgraph[v][u] += min_flow
        v = u
        puts v
      end
      max_num += min_flow
      boundary, path = augmentation_path(rgraph, 0, @spot-1)
    end
    max_num
  end

  # s: 源点
  # t: 终点
  def augmentation_path(rgraph, s, t)
    path = {}           # 路径
    visited = {}        # 标记是否访问过点
    queue = []          # 存续bfs中遍历用节点

    queue << s
    visited[s] = true
    # BFS算法找出增广路径
    while queue.size > 0
      top = queue.shift
      (0..@spot-1).each do |i|
        if visited[i] != true && rgraph[top][i] > 0
          path[i] = top
          visited[i] = true
          queue << i
        end
      end
      puts path
    end
    # 此路径是否是通路
    [visited[t] == true, path]
  end
end

# graph = [
#   [0, 40, 0, 20],
#   [0, 0, 30, 20],
#   [0, 0, 0, 10],
#   [0, 0, 0, 0]
# ]
# gtm = GraphTheoryMaxflow.new(5, 4, graph)
# gtm.max_flow
```