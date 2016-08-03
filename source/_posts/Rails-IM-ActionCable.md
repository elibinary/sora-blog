---
title: Rails IM - ActionCable
date: 2016-07-09 12:56:43
tags:
  - Rails
description: rails即时通讯的解决方案 ActionCable
---

上一篇介绍了 MessageBus 的即时通讯的解决方案，主要是利用轮训长轮询等策略。本片就来介绍一下基于 websocket 的实时通信框架 ActionCable 。

ActionCable 适配了Redis的pub/sub机制，还有pgsql的notify机制，你可以通过设置来选择想要使用的适配器。ActionCable 的核心便是 ActionCable::Connection::Base 以及 ActionCable::Channel::Base， client可以通过websocket连接订阅 channel，channel会实时广播消息给订阅者。大致先介绍道这里，下面先看看如何来使用 ActionCable

#### 使用

首先来创建一个 channel ，服务器通过channel发布消息，客户端通过对应的channel订阅消息

```
# app/channels/message_channel.rb
class MessagesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "messages_channel_#{current_user.id}"
  end

  def unsubscribed
  end
end
```

其中 subscribed 方法是当客户端连接上来的时候被调用，unsubscribed 是当客户端与服务器失去连接时被调用。
这样一个简单的 message channel 就可以投入使用了，接下来就是 client 订阅想要的 channel 了
```
App.cable.subscriptions.create "MessagesChannel",
  connected: ->
  
  disconnected: ->
  
  received: (data) ->
     $('#messages').append data["title"], body: data["body"]
```
这样当 client connected 的时候就将成功订阅属于它的频道， 当服务器端广播消息给此 channel 时，client就会通过 received 事件接受并 append 收到的消息。下面还差一步就是服务器如何广播一条消息
```
# Somewhere in your app this is called
ActionCable.server.broadcast "messages_channel_#{current_user.id}", { title: 'test', body: 'test666' }

# The ActionCable.server.broadcast call places a message in the Action Cable pubsub queue under a separate broadcasting name for each user
#  The data is the hash sent as the second parameter to the server-side broadcast call, JSON encoded for the trip across the wire, and unpacked for the data argument arriving to #received.
```

#### 进阶

上面简单介绍了 ActionCable 的其中一种用法，更多的用法可以去看官网的例子以及多多开脑洞。下面来看看使用中的一些要注意的地方和小细节。

- ApplicationCable::Connection

    刚刚上面提到了这个类，那么这个类到底是干什么用的呢，又如何来使用。其实这个类主要是用来 authorize 你的 incoming connection 并且建立这个 connection 的，下面的是官网给出的一个简单例子
    ```
    # app/channels/application_cable/connection.rb
    module ApplicationCable
      class Connection < ActionCable::Connection::Base
        identified_by :current_user
    
        def connect
          self.current_user = find_verified_user
        end
    
        protected
          def find_verified_user
            if current_user = User.find_by(id: cookies.signed[:user_id])
              current_user
            else
              reject_unauthorized_connection
            end
          end
      end
    end
    ```
非常简单易懂就不做过多解释了


- Adapter

    上面说了 ActionCable 适配了多种 Adapter ，我们可以通过配置文件来指定以及个性化定制
    
    ```
    # config/cable.yml
    production: &production
      adapter: redis
      url: redis://localhost:6379/1
    
    development: &development
      adapter: redis
      url: redis://localhost:6379/1
    
    test: *development
    ```
    当然你也可以把配置文件放在别处在，只需要在 Rails.application.paths 里声明一下。
    
- host

    因为actioncable默认只在3000端口上开放websocket服务，如果把它跑在4000端口上，就会报错 'Request origin not allowed' ，当然你可以通过在配置文件中添加配置来解决这个问题
    
    ```
    # passed to the server config as an array
    config.action_cable.allowed_request_origins = ['http://rubyonrails.com', /http:\/\/ruby.*/]
    
    # 或者直接关闭检查
    # Rails.application.config.action_cable.disable_request_forgery_protection = true
    ```
    
    可以看出数组中的配置项可以使用正则来做适配。
    
- server

> Action Cable is powered by a combination of websockets and threads. All of the connection management is handled internally by utilizing Ruby’s native thread support, which means you can use all your regular Rails models with no problems as long as you haven’t committed any thread-safety sins.

> But this also means that Action Cable needs to run in its own server process. So you'll have one set of server processes for your normal web work, and another set of server processes for the Action Cable.

> The Action Cable server does not need to be a multi-threaded application server. This is because Action Cable uses the Rack socket hijacking API to take over control of connections from the application server. Action Cable then manages connections internally, in a multithreaded manner, regardless of whether the application server is multi-threaded or not. So Action Cable works with all the popular application servers -- Unicorn, Puma and Passenger.

> Action Cable does not work with WEBrick, because WEBrick does not support the Rack socket hijacking API.

文档这么说的，其实就是说建议最好把将 ActionCable 独立部署在单独的 server 进程上面以避免阻塞。另外虽然它是依赖于 Ruby’s native thread support 的，但是它将 thread 交给了 rock hijacking 去处理了，所以并不需要一定部署在多线程的 server 中。

ActionCable 的介绍就先到这里，之后在使用中遇到的问题以及细节会在做总结。