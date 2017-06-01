---
title: Rails IM - MessageBus
date: 2016-07-02 10:50:31
tags:
  - Rails
description: rails即时通讯的解决方案 MessageBus
---

Rails5 已经release啦，各种新玩意真是令人兴奋。就比如说今天要说的这个即时消息通讯，看到这个就会想到 websocket 。没错，rails5 中也集成了 websocket 的解决方案，就是 ActionCable 这个东西，不过本篇文章暂不介绍 ActionCable 。

本篇来说一下以前的一些解决方案，比如说 MessageBus

#### 使用

MessageBus在后端提供了一种pub/sub的机制，同时在js端也做了封装

首先引入
```ruby
gem 'message_bus'
```

在application.js中
```ruby
//= require message-bus
```

主要的工作方式：
在服务器端可以通过 publish 方法写入信息
```ruby
MessageBus.publish "/channel", data
```
其中 "/channel" 是频道名字，然后client端通过订阅不同频道来获取想要的信息。

```js
MessageBus.start();
MessageBus.callbackInterval = 500;
MessageBus.subscribe("/channel", function(data){
  $('#messages').append("<p>"+ data + "</p>");
  $(document.body).scrollTop(document.body.scrollHeight);
});
```

其中 callbackInterval 用来设置轮询的时间间隔，单位是 ms。

#### 深入源码

先来看一下 MessageBus 到底把信息存储在了什么地方，在 backends 文件夹下我们可以看到 MessageBus 支持三中存储方式分别是：in-memory, PostgreSQL 和 Redis。可以通过以下方式设置：
```
MessageBus.configure(backend: :redis)
```
在没有设置的情况下默认使用 Redis ，这点从源码中可看出：
```
# lib/message_bus.rb
def backend
  @config[:backend] || :redis
end
```

我们来看一下它的工作流程，（以 reids 为例）
当发布一条信息时，调用 lib/message_bus.rb 的 publish 方法
```
def publish(channel, data, opts = nil)
    ......
    ......

    encoded_data = JSON.dump({
      data: data,
      user_ids: user_ids,
      group_ids: group_ids,
      client_ids: client_ids
    })

    reliable_pub_sub.publish(encode_channel_name(channel), encoded_data)
  end
```
这个方法最后会通过 backend 的实例（这里是redis）去执行对应的 publish 方法
```
# lib/message_bus/backends/redis.rb
def publish(channel, data, queue_in_memory=true)
    ......
    ......
    
    redis.multi do |m|

      redis.zadd backlog_key, backlog_id, payload
      redis.expire backlog_key, @max_backlog_age

      redis.zadd global_backlog_key, global_id, backlog_id.to_s << "|" << channel
      redis.expire global_backlog_key, @max_backlog_age

      redis.publish redis_channel_name, payload

      if backlog_id > @max_backlog_size
        redis.zremrangebyscore backlog_key, 1, backlog_id - @max_backlog_size
      end

      if global_id > @max_global_backlog_size
        redis.zremrangebyscore global_backlog_key, 1, global_id - @max_global_backlog_size
      end

    end

    ......
  end
```
可以看到信息在redis中的存储结构是 SortedSet

拉取消息的实现可以看 lib/message_bus/assets/message-bus.js
```
poll = function() {
    var data;
    
    if(stopped) {
      return;
    }
    
    if (callbacks.length === 0) {
      if(!delayPollTimeout) {
        delayPollTimeout = setTimeout(function(){ delayPollTimeout = null; poll();}, 500);
      }
      return;
    }
    
    data = {};
    for (var i=0;i<callbacks.length;i++) {
      data[callbacks[i].channel] = callbacks[i].last_id;
    }
    
    me.longPoll = longPoller(poll,data);
};
```
其中订阅频道获取频道信息的核心就是轮询

本篇文章先介绍到这里，关于 MessageBus 中的很多细节实现可以去研读其源码找到解答