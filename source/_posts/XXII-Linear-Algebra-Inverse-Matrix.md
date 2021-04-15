---
title: 学习笔记 - 理解线性代数 - 应用与逆 
date: 2017-04-23 15:00:34
tags:
  - Math
description: To ask the right question is harder than to answer it.
---

> To ask the right question is harder than to answer it.

从前几节的笔记，可以知道线性代数能够用来描述对空间的操纵。这对计算机图形学和机器人学很有用，但是线性代数在几乎所有技术领域中都有所体现并被广泛应用的一个主要原因是，它能够帮助我们求解特定的方程组。

先来看一个特殊的方程组：
$$
\left\{ 
\begin{array}{c}
2x+5y+3z=-3 \\ 
4x+8z=0 \\ 
1x+3y=2
\end{array}
\right. 
$$

可以简单的做下变换让它更好看：
$$
\left\{ 
\begin{array}{c}
2x+5y+3z=-3 \\ 
4x+0y+8z=0 \\ 
1x+3y+0z=2
\end{array}
\right. 
$$

没有幂次，没有奇怪的函数，没有未知数间乘积，未知量之间只有加和
这就是 线性方程组

有没有觉得很眼熟，像不像向量矩阵乘法，实际上可以把这个方程组合并为一个向量方程：
$$
  \begin{bmatrix} 
    2 & 5 & 3 \\ 
    4 & 0 & 8 \\
    1 & 3 & 0 \\
  \end{bmatrix} 
  \begin{bmatrix} 
    x \\ 
    y \\
    z \\
  \end{bmatrix}
  =
  \begin{bmatrix} 
    -3 \\ 
    0 \\
    2 \\
  \end{bmatrix}
$$

可以看出它组成
所有常数系数的矩阵✖一个包含所有未知数的向量＝一个常数向量
用一个简单的方式来表示这个方程：
$$ A\vec{x}=\vec{v} $$

矩阵 A 代表了一种线性变换，那么这个方程其实在几何层面上就表示，寻找一个向量 x，使得其在变换后成为向量 v（与v重合）

### 逆
说到求解方程式，先来说说逆矩阵的概念。
接着拿上面的方程来举例，在上述情况中有且仅有一个向量在经过变换 A 后与 v 重合，并且还可以通过逆向进行变换来找到这个向量，当逆向进行变换的时候，它实际上对应了另一个线性变换，这个线性变换就被称为 A 的逆。

可以看出，A逆具有这样的性质：首先应用 A 变换，在应用 A逆 变换，就会回到原始状态。
前几篇说到，两个变换相继作用在代数上体现为矩阵乘法，所以也可以说 A逆 的核心性质在于：A逆 * A 等于一个什么都不做的矩阵。

只有正方形的矩阵才有，但非必然有逆矩阵，若方阵 A 的逆矩阵存在，则称 A 为非奇异方阵或可逆方阵。与行列式类似，逆矩阵一般常用于求解包含数个变数的数学方程式。


