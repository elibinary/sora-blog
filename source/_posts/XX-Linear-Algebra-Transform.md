---
title: [学习笔记]理解线性代数 - 变换
date: 2017-04-08 12:54:17
tags:
  - Math
description: 线性变换
---

线性变换：
1. 直线在变换后仍然保持为直线
2. 原点必须保持固定
总的来说，应该把线性变换看作是“保持网格线平行且等距分布”的变换（keeping grid lines parallel and evenly spaced）

 如何使用数值描述线性变换？
实际上，你只需要记录两个基向量 i, j 变换后的位置，其他向量都会随之而动

具体来说，举个例子：现在在以 i，j为基的空间中有一个向量 v [-1, 2]，那么实际上向量 v 可以被表示为 

$$ \vec v = -1 \vec i + 2 \vec j $$

现在进行一些变换，根据 ‘保持网格线平行且等距分布’ 可以推论出，变换后的向量 v 的位置，就是

$$ \vec v = -1 * Transformed \vec i + 2 * Transformed \vec j $$

而这就意味着，你可以只根据变换后的基向量 i 和 j 推断出变换后的 v，那么比如变换后的 i 落在 [1, -2]， j 落在 [3, 0] 那么

$$
        Transformed \vec v = -1
        \begin{bmatrix}
        1 \\
        -2 \\
        \end{bmatrix}
        +
        2
        \begin{bmatrix}
        3 \\
        0 \\
        \end{bmatrix}
$$ 

**也就是说，只要记录了变换后的 i 和 j，就可以推断出任意向量在变换后的位置，甚至完全不必清楚变换本身到底做了什么**

由此可以得出一个结论：一个二维线性变换仅有四个数字完全确定，一组基变换后的坐标

通常将这些变换后的坐标表示为一个矩阵，比如
$$
        \begin{bmatrix}
        1\ \ 3\\
        -2\ \ 0\\
        \end{bmatrix}
$$ 
你可以把它的列理解为两个特殊的向量，即变换后的 i 和 j。这个矩阵包含了线性变换的信息。

那么现在有一个描述线性变换的矩阵，以及一个给定向量，你想知道线性变换对这个向量的影响，怎么做？

$$
        \begin{bmatrix}
        1\ \ 3\\
        -2\ \ 0\\
        \end{bmatrix}
        \begin{bmatrix}
        x\\
        y\\
        \end{bmatrix}
        =
        x
        \begin{bmatrix}
        1\\
        -2\\
        \end{bmatrix}
        + y
        \begin{bmatrix}
        3\\
        0\\
        \end{bmatrix}
        =
        \begin{bmatrix}
        1x + (-2)y\\
        3x + 0y\\
        \end{bmatrix}
$$ 

这其实就是矩阵向量乘法，而矩阵向量乘法就是计算线性变换作用于给定向量的一种途径
换一种看法：可以把矩阵的列看作变换后的基向量，把矩阵向量乘法看作它们的线性组合

**去理解矩阵很重要的一点就是，每当你看到一个矩阵，你都可以把它解读为对空间的一种特定变换。**

**两个矩阵相乘就是两个线性变换相继作用。**

> Question1: 矩阵相乘时，其顺序到底影响着什么
> Question2: 矩阵乘法的为什么适用结合律

第一个问题，比如现在有两个矩阵相乘
$$
        M1 * M2 * M3 :
        \begin{bmatrix}
        1\ \ 0\\
        2\ \ 3\\
        \end{bmatrix}
        \begin{bmatrix}
        1\ \ 1\\
        1\ \ 0\\
        \end{bmatrix}
        \begin{bmatrix}
        4\ \ 1\\
        -1\ \ -3\\
        \end{bmatrix}
$$ 

根据上面所说的，多个矩阵相乘就表示着多个线性变换相继作用，其作用顺序是从右至左的： 先进行 M3 变换，然后 M2 变换，最后 M1 变换，注意变换的先后顺序必然是会对最终结果造成影响的。
那么为什么却适用结合律呢，你可以通过严谨的算术公式去推到证明，这里你也可以试着用另一个思路去理解，那么根据上面所说
```
M1 * M2 * M3
# 先进行 M3 变换，然后 M2 变换，最后 M1

M1 * (M2 * M3)
# 这个表示先进行 M3 变换和 M2 变换再进行 M1 变换

(M1 * M2) * M3
# 这个表示先进性 M3 变换，然后在进行 M2 与 M1 复合变换的结果变换
```
可以看出，这三种变换其实并没有本质区别

*三维矩阵相乘在部分领域有着非常重要的应用，比如计算机图形学与机器人学*
