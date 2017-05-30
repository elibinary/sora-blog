---
title: [学习笔记]理解线性代数 - 行列式 
date: 2017-04-22 14:48:49
tags:
  - Math
description: The purpose of computation is insight, not numbers.
---

> The purpose of computation is insight, not numbers.

上一篇介绍了变换的表示，这篇就主要介绍一个重要的概念，当变换发生时，究竟对空间有多少拉伸或压缩，也就是变换对一块给定区域的面积的影响。

举个例子，现在有矩阵（变换）
$$
        \begin{bmatrix}
        3\ \ 0\\
        0\ \ 2\\
        \end{bmatrix}
$$ 
那么我们在变换前的单位面积（假定以i=1,j=1为单位长度），为1
这块区域在经过上述变换后变成一个 2*3 的矩形，其面积为 6，这么就说这个线性变换将它的面积变为6倍。
实际上，只要知道了这个单位正方形面积变化的**比例**，它就能告诉你其他任意区域的面积变化比例，因为一个方格无论如何变化，对其他大小的方格来说，都会有相同的变化。这是由“网格线保持平行且等距分布”这一事实推断的。

并且对于不是方格的形状，也是可以用许多方格良好近似的，只要使用的方格足够小，近似就能足够好。

这个特殊的缩放比例，也就是线性变换改变面积的比例，就被称为这个变换的行列式。比如一个线性变换的行列式是3，那么就是说它将一个区域的面积增加为原来的3倍。

一种特殊的情况，一个二维线性变换的行列式为0，说明它将整个平面压缩到一条线，甚至一个点。理解这个很重要，也就是说根据判断一个矩阵的行列式的值是否为0，就能了解这个矩阵所代表的变换是否将空间压缩到更小的维度上。

关于其计算，我们知道行列式的计算方法如下
$$ det(
        \begin{bmatrix}
        a\ \ b\\
        c\ \ d\\
        \end{bmatrix}
        )= ad-bc
$$ 
其中a告诉你i在x轴方向的伸缩比例，d告诉你j在y轴方向的伸缩比例。bc项表示平行四边形在对角方向上拉伸或压缩了多少
$$ det(
        \begin{bmatrix}
        a\ \ b\\
        c\ \ d\\
        \end{bmatrix}
        )= (a+b)(c+d) - ac -bd -2bc = ad -bc
$$ 

对于三维线性变换

$$ det(
        \begin{bmatrix}
        a\ \ b \ \ c \\
        d\ \ e \ \ f \\
        g\ \ h \ \ i \\
        \end{bmatrix}
        )= 
        a * det(
            \begin{bmatrix}
            e\ \ f\\
            h\ \ i\\
            \end{bmatrix}
        ) -
        b * det(
            \begin{bmatrix}
            d\ \ f\\
            g\ \ i\\
            \end{bmatrix}
        ) +
        c * det(
            \begin{bmatrix}
            d\ \ e\\
            g\ \ h\\
            \end{bmatrix}
        )
$$ 

