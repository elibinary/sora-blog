---
title: Quick-Sort
tags:
  - Algorithm
description: 本篇简单介绍下快排。
date: 2016-04-23 13:18:42
---


快速排序是一种划分交换排序算法，最早由东尼.霍尔提出，它的中心思想是使用分治法策略把一个待排序序列分为两个子序列，并迭代的进行此过程直至无法在进行分治分割结束。

基本步骤：

1. 从待排序序列中选择一个基准数
2. 把比这个基准数小的放其左边，大的放其右边，相等的放哪边都行
3. 第二步过后会得到左右两个子序列，对这两个子序列迭代的进行第二步操作
4. 当子序列不可在分割时，也就是只有一个元素时，迭代结束

下面是一次排序的过程：

<div align=center>
  <img src="http://7xsger.com1.z0.glb.clouddn.com/image/blog/QuickSort-1.jpg" alt="5-B-Tree-1"/>
</div>

首先我们有如图的一个序列(3,6,4,1,8,7,2,9,5)

1. 选取序列第一个值为基准数，设置边界(l,r)以及循环初始值(i,j)
2. 以j开始从后向前移动，直到找到一个小于（或等于）基准值的元素，或者j<=i
3. 把找到的元素与基准值换位（其实并不是真的交换位置，这个稍后在实现时就可以很容易看出来），并使i++
4. 然后以i开始从前往后移动，直到找到一个大于基准值的元素, 或者i>=j
5. 把找到的元素与基准值换位, 并使j--
6. 循环这个过程，直到i>=j结束循环，这时我们将得到两个以基准值为界左边元素全部小于基准值，右边元素全部大于基准值的子序列
7. 迭代的执行这个过程，最终的到一个有序序列

核心代码：
```
void sort(int left,int right,int b[])
{
  if(left>=right)
    return;
  int low=left,high=right;
  int tmp=b[low];
  while(low!=high)
  {
    while(b[high]>tmp&&high>low)
      high--;
    b[low++]=b[high];
    while(b[low]<tmp&&high>low)
      low++;
    b[high--]=b[low];
  }
  b[low]=tmp;
  sort(left,low-1,b);
  sort(low+1,right,b);  
}
```

来看一下另一种实现思路：

```
void qsort(int left,int right)
{
  int l,h,x,tmp;
  l=left;h=right;
  x=a[(left+right)>>1];
  while(l<=h)
  {
    while(a[l]<x)
      l++;
    while(a[h]>x)
      h--;
    if(l<=h)
    {
      tmp=a[l];
      a[l]=a[h];
      a[h]=tmp;
      l++;  h--;
    }
  }
  if(left<h)
    qsort(left,h);
  if(l<right)
    qsort(l,right);
}
```

#### 分析

不难看出快排每次排序分割操作都会访问所有序列元素，使用O(n)时间。在最好的情况下，假设我们选择的基准值足够好，这样每次分割都能将元序列分成两个相同大小的子序列，这样程序的迭代深度为O(log n)，总得时间复杂度为O(n log n)，更加详细的计算推演可以参考算法导论的主定理（master theorem）部分。

而在最坏的情况下，序列反向有序，可以想象出其递归树的结构将会变成倾斜的一边倒的单边树结构，这种情况下其比较次数将会是
```
(n-1) + (n-2) + (n-3) + ... + 1
```
其时间复杂度为 O(n^2)。

平均情况的计算就略麻烦了，详细的过程还是去看算法导论吧，其结果也是O(n log n)。


#### 关于冒泡排序

其简单流程：

1. 顺序的比较相邻的元素，如果第一个比第二个大，就交换他们两个
2. 对每一对相邻元素都进行操作 1，最大的数将会被排到最后
3. 迭代的进行以上操作，每次迭代都排除最后的有序部分
4. 持续每次对越来越少的元素重复上面的步骤，直到没有任何一对数字需要比较

由上边的流程可以看出，其比较次数为
```
(n-1) + (n-2) + (n-3) + ... + 1
```
其时间复杂度为 O(n^2)。

但是在很多地方都会看到在最优状态时，冒泡排序的最优时间复杂度为 O(n)，这到底是怎么得出的呢。

我们分析其流程可以看出，当某次迭代过程中都未发生交换操作时，我们就可以判定其已经有序可以退出迭代了。这样当目标序列已有序的情况下，其时间复杂度就为 O(n)。

核心代码：
```
for(int i = 0; i < n - 1; i++){
  flag = false;
  for(int j = 0; j < n - 1 - i; j++){
    if(arr[j+1] < arr[j]){
      swap(arr, j, j + 1);
      flag = true;
    }
  }
  if(!flag)
    return;
}
```

- - -

> 分治法
> 辗转相除法
