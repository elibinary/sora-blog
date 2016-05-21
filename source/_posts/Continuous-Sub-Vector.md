---
title: 连续子向量最大和
date: 2016-05-21 10:58:37
tags:
  - Algorithm
description: 计算连续子向量的最大和及其时间度量方法。
---

> 求一串数字的最大连续子向量和，问题是这样的给出一个具有n个整数的向量，求出任何连续子向量中的最大和。

首先想到最暴力的求解方法：穷举。去穷举出所有的子向量然后求和比较即可，思想简单实现简单。可以很容易的给出实现：

```
int max = 0;  
int length = SCALE;  
int i,j,k;  
for (i = 0; i < length; ++i)  
{  
  for (j = i; j < length; ++j)  
  {  
    int sum = 0;  
    for (k = i; k <= j; ++k)  
    {  
      sum += x[k];  
    }  
    max = maxnum(max, sum);  
  }  
}
```

穷举法虽然简单易实现，但是上面的实现我们一眼就可以看出其时间复杂度是立方级的，也就是O(n^3).

看着上面的实现，可以发现其中有着很多的重复计算，那么容易想到可以把中间结果存储起来以备后面再次用到时可以直接取用以此来进行计算优化。

```
max = 0;  

for (i = 0; i < length; ++i)  
{  
  int sum = 0;  
  for (j = i; j < length; ++j)  
  {  
    sum += x[j];  
    max = maxnum(max, sum);  
  }  
}  
```

上述实现只保存了内层计算的中间结果，其时间复杂度O(n^2).
我们可以进一步简化其实现：

```
max = 0;  
int max_end_here = 0;  

for (i = 0; i < length; ++i)  
{  
  max_end_here = maxnum(max_end_here + x[i], 0);  
  max = maxnum(max, max_end_here);  
}
```

上述这种实现的思路就是，如果到当前节点为止结果为正，就继续往后累加（基数为正必然总和会增大），如果为负就舍弃前面的连续，从当前位置开始重新计算连续向量和（如果为负继续累加必然会减小总和）。这样就把时间复杂度控制在了O(n)。

下面给出完整代码以及三种实现的时间度量及比较：

```
#include <stdio.h>  
#include <time.h>  
#include <stdlib.h>  

#define SCALE 3000  

int maxnum(int a, int b);  

int main(int argc, char const *argv[])  
{  
  FILE *fp;  
  fp = fopen("maximum.in", "r");  
  // int x[] = {1,12,-11,10,-65,54,22,-9,21,5,48,5,-8,-2,56,54,-88,-5,2,-8,554,-56,35,-55,555,-65,-545,-23,48,-5,88,-56,16,-8};  
  int *x = (int *)malloc(sizeof(int)*(SCALE+1));  
  int xi = SCALE,a = 0,num_in = 0;  
  while(xi--){  
    fscanf(fp, "%d", &x[a++]);  
  }  


  clock_t start, end;  

  // ***Algorithm-1 cube***  
  start = clock();  

  int max = 0;  
  int length = SCALE;  
  int i,j,k;  
  for (i = 0; i < length; ++i)  
  {  
    for (j = i; j < length; ++j)  
    {  
      int sum = 0;  
      for (k = i; k <= j; ++k)  
      {  
        sum += x[k];  
      }  
      max = maxnum(max, sum);  
    }  
  }  

  // long num = 10000000L;  
  // while(num--);  

  end = clock();  

  double times = (double)(end - start)/CLOCKS_PER_SEC;  
  double dend = (double)end;  

  printf("\n***Algorithm-1 cube***\n");  
  printf("end: %f\n", dend);  
  printf("Time consuming: %f\n", times);  
  printf("%d\n", max);  


  // ***Algorithm-2 square***  
  start = clock();  

  max = 0;  

  for (i = 0; i < length; ++i)  
  {  
    int sum = 0;  
    for (j = i; j < length; ++j)  
    {  
      sum += x[j];  
      max = maxnum(max, sum);  
    }  
  }  

  end = clock();  

  times = (double)(end - start)/CLOCKS_PER_SEC;  
  dend = (double)end;  

  printf("\n***Algorithm-2 square***\n");  
  printf("end: %f\n", dend);  
  printf("Time consuming: %f\n", times);  
  printf("%d\n", max);  


  // ***Algorithm-3 linear***  
  start = clock();  

  max = 0;  
  int max_end_here = 0;  

  for (i = 0; i < length; ++i)  
  {  
    max_end_here = maxnum(max_end_here + x[i], 0);  
    max = maxnum(max, max_end_here);  
  }  

  end = clock();  

  times = (double)(end - start)/CLOCKS_PER_SEC;  
  dend = (double)end;  

  printf("\n***Algorithm-3 linear***\n");  
  printf("end: %f\n", dend);  
  printf("Time consuming: %f\n", times);  
  printf("%d\n", max);  



  free(x);  
  x = NULL;  
  return 0;  
}  

int maxnum(int a, int b)  
{  
  return a > b ? a : b;  
}
```
