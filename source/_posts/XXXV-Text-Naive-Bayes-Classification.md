---
title: 基于朴素贝叶斯的广告识别分类尝试
date: 2017-08-12 17:06:58
tags:
  - MachineLearning
description: 因为最近伙伴部分各种广告过于猖獗且很难有效管理，所以打算搞一个广告识别过滤的模块，下面是基于朴素贝叶斯的广告分类模型构建及具体思路的尝试
---

### 贝叶斯定理
贝叶斯定理是关于随机事件 A 和 B 的条件概率的一则定理，用公式来描述就是：
$$ P(A|B) = \frac{P(B|A)P(A)}{P(B)} $$

可以看出，通过贝叶斯公式我们可以在已知三个概率函数时推出第四个。重要应用之一就是根据
$$P(A|B)\quad ->\quad P(B|A)$$

独立变量的联合分布：
$$ P(a_1, a_2, ... , a_n|y_j) = \prod_{i=1}^nP(a_i|y_j)$$

### 应用
假设：
A: features
$$ A = (w_1, w_2, w_3, ... , w_n) $$
B: category

求值：$ P(B|A) $
$$ P(B|A) = P(B|w_1, w_2, ..., w_n) = \frac{P(w_1, w_2, ..., w_n|B)P(B)}{P(w_1, w_2, ... , w_n)} $$

假设各特征之间相互独立，也就是 $w_1, w_2, w_3, ... , w_n$ 之间都相互独立，那么就有
$$ 
P(w_1, w_2, ... , w_n|B) = P(w_1|B)P(w_2|B)...P(w_n|B)
= \prod_{i=1}^nP(w_i|B)
$$

那么最终问题就转化为了对 $P(B)$ 和 $P(w_x|B)$ 求值，或者叫估值
$P(B)$ 就是 B 在训练集中的相对频率
在处理 $P(w_x|B)$ 时，有几种不同的处理方式

**高斯模型**
高斯模型假设特征在各类别下的观测值符合高斯分布
也就是说对于 $w_x$ 有 $w_x$ ~ $N(\mu_b, \sigma_b^2)$

$$ P(w_x|B)
=
\frac{1}{\sigma\sqrt{2\pi}} \, \exp \left( -\frac{(w_x- \mu)^2}{2\sigma^2} \right)$$

其中参数 $\mu, \sigma$ 可通过极大似然法来估计

**多项式模型**
多项式模型假设数据服从多项式分布
$$ P(w_x|B)
=
\frac{N_{bx} + \alpha}{N_b + \alpha n}$$

$P(w_x|B)$ 是对于特征 x 在一个样本中被类 B 拥有的概率
$N_{bi}$ 是在训练集中，特征 x 在属于类 B 的样本中出现的次数
$N_b$ 是类 B 中的所有特征数量和

### 广告分类
朴素贝叶斯尽管看起来其假设非常简单，但是在很多场景下朴素贝叶斯分类器却工作的相当优秀。
而广告识别说白了其实就是一个二分类，给定一个文本，它要么是广告，要么是正常文本，也就是说
$$ B \in (b_{ad}, b_{normal}) $$

下面我尝试使用多项式模型构建模型并估计参数

首先还是使用上一篇中讲的 [文本特征提起][1] 来对训练集进行特征提取，然后就是估计模型以及判别方法
```
import jieba
from sklearn import feature_extraction
from sklearn.feature_extraction.text import TfidfTransformer
from sklearn.feature_extraction.text import CountVectorizer
from collections import defaultdict
import math

# global var for probability
probability_module = {}
# { y_i: len_of_i_docs }
t_n = {}
# { feature_i: {num_of_y_1, num_of_y_2 ... ,num_of_y_n} }
# features_num = defaultdict(dict)
features_num = {}
total_doc_num = 0

samples = []

def tf_idf(file_path):
  file = open(file_path, 'r')
  corpus = []
  temp_str = ''

  temp_samples = []
  for line in file:
    cut_res = jieba.lcut_for_search(line)
    temp_samples.append(cut_res)
    # corpus.append(' '.join(cut_res))
    temp_str += ' '.join(cut_res)
    temp_str += ' '

  file.close
  samples.append(temp_samples)

  corpus.append(temp_str)
  vectorizer = CountVectorizer()
  transformer = TfidfTransformer()
  word_freq = vectorizer.fit_transform(corpus)
  tf_idf = transformer.fit_transform(word_freq)

  words = vectorizer.get_feature_names()
  scores = tf_idf.toarray()[0]
  return zip(words, scores)

# for i in range(len(scores)):
#   print(words[i], scores[i])
# sort_res = sorted(list(arr), key=lambda item: item[1], reverse=True)

def predict_module(samples, y, features):
  global total_doc_num

  for i in range(len(y)):
    if y[i] not in t_n:
      t_n[y[i]] = {}
    t_n[y[i]]['docs'] = len(samples[i])
    t_n[y[i]]['features'] = len(features[i])
    t_n[y[i]]['total'] = 0

  for features_i in features:
    for item in features_i:
      features_num[item] = {}

  for i in range(len(samples)):
    for sample in samples[i]:
      total_doc_num += 1
      for word in sample:
        if word in features_num:
          t_n[y[i]]['total'] += 1
          if y[i] in features_num[word]:
            features_num[word][y[i]] += 1
          else:
            features_num[word][y[i]] = 1

def bayes_multinomial(doc, y):
  v = len(features_num)
  cut_res = jieba.lcut_for_search(doc)
  scores = {}
  for y_i in y:
    p_y = t_n[y_i]['docs'] / total_doc_num
    scores[y_i] = math.log(p_y)
    for word in cut_res:
      if word in features_num:
        if y_i in features_num[word]:
          p_y_w = (features_num[word][y_i] + 1) / (t_n[y_i]['total'] + v)
        else:
          p_y_w = 1 / (t_n[y_i]['total'] + v)
        scores[y_i] += math.log(p_y_w)

  return scores
```

接下来就是测试其分类效果了
本来是要把训练数据分成两份，一份用于参数估计，另一份用于测试模型准确率的。但是因为我本身的训练数据量比较少，一共也就几百条。。。所以只在其中随机挑了几十条作为测试集，准确度在 80% 左右，在输入正常样本是产生误判的几率较大，另外由于训练集和测试集过小，我暂时并不能确定模型完善度。
接下来我打算先使用 NumPy 对实现中参数向量结构部分进行重写，然后去找一个现有的语料库找个大点的数据集跑测一下。顺便有时间再试一下高斯模型以及伯努利模型的效果。

  [1]: https://www.zybuluo.com/elibinary/note/840183