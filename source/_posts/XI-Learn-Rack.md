---
title: 了解 Rack
date: 2016-12-25 12:58:59
tags:
  - Rails
description: Rack provides a minimal interface between webservers that support Ruby and Ruby frameworks.
---

> Rack provides a minimal interface between webservers that support Ruby and Ruby frameworks.

> To use Rack, provide an "app": an object that responds to the call method, taking the environment hash as a parameter, and returning an Array with three elements:

> * The HTTP response code
> * A Hash of headers
> * The response body, which must respond to each

*以上描述来自 rack doc*
不看不知道，一看吓一跳，rack 的包容之大，应用之广出乎我的想象。
看 [rack doc][1]
对 WEBrick, Mongrel, FCGI, Thin, Puma等等还有很多的 web server 都进行了支持，rack-base 的框架也是多的不行。

```
These frameworks include Rack adapters in their distributions:

Camping
Coset
Espresso
Halcyon
Mack
Maveric
Merb
Racktools::SimpleApplication
Ramaze
Rails
Rum
Sinatra
Sin
Vintage
Waves
Wee
… and many others.
```

'Any valid Rack app will run the same on all these handlers, without changing anything.' -- doc

### Rack 是什么
> Rack provides a minimal, modular and adaptable interface for developing web applications in Ruby.

rack 对 HTTP 请求和响应进行了封装，并对上层提供了一套统一的接口。它需要一个能够响应（response）call 方法的对象，该call方法接收一个 hash 类型的参数 env，并且返回一个三元素的数组
 [code, headers, body]
 
* code: The HTTP response code
* headers: A Hash of headers
* body: The response body, which must respond to each

一个简单的例子：
```
require "rack"
require "awesome_print"

class HelloWorld
  def call(env)
    ap env
    [200, {'tp' => 'tp'}, ['hello world~']]  
  end  
end

Rack::Handler::WEBrick.run HelloWorld.new, Port: 3333
```
很简单吧

根据文档说明 app 只要是一个拥有一个可以接收 env 参数并返回三元素数组的 call 方法的对象就可以，那么就有了更简单的写法。
```
app = Proc.new do |env|
   ['200', {'Content-Type' => 'text/html'}, ['hello world~']]
end

Rack::Handler::WEBrick.run app, Port: 3333
```

它其实就是处于这样一个位置：
![rack-1][2]

### Middleware
> Rack middleware is a way to filter a request and response coming into your application.

废话不多说，先看个例子:
```
require "rack"
require "awesome_print"

class Clock
  def initialize(app)
    @app = app
  end

  def call(env)
    puts "Current Time: #{Time.now}"
    code, headers, body = @app.call(env)
    [code, headers, body << "Current Time: #{Time.now}"]
  end
end

app = Proc.new do |env|
  ['200', {'Content-Type' => 'text/html'}, ['hello world~']]
end

Rack::Handler::WEBrick.run Clock.new(app), Port: 3333
```
从代码可以非常清晰的明白其思路就是对 app 的一层包装，先一步获取请求并对其进行修饰，获取 response 后也可进行修饰后返回。
简单的说，Rack 的 一个 middleware 就是一个类，这个类的实例对象符合 rack 对 'app' 的所有要求。也就是说它的实例本身就可以作为一个 rack app 传递给 Rack::Handler::WEBrick.run，那么 Middleware 也就是可以一层一层的嵌套下去的。
就像这样：
![middleware-1][3]
（看它的结构像什么，我的第一感觉是这玩意就像一个俄罗斯套娃）

再来看一下其工作流：
![rack-2][4]
有没有很熟悉，处理方式有没有很像 pipeline design pattern

### rackup
在接着往下探索之前，先让我们来看一个强大的工具：rackup
> rackup is a useful tool for running Rack applications, which uses the Rack::Builder DSL to configure middleware and build up applications easily. 
-- rack doc

使用 rackup 可以轻松构建并运行一个 rack app
比如这样：
```
# config.ru

class Clock
  def initialize(app)
    @app = app
  end

  def call(env)
    puts "Current Time: #{Time.now}"
    code, headers, body = @app.call(env)
    [code, headers, body << "Current Time: #{Time.now}"]
  end
end

class BodyUpper
  def initialize(app)
    @app = app
  end
  def call(env)
    status, head, body = @app.call(env)
    upcased_body = body.map{|chunk| chunk.upcase }
    [status, head, upcased_body]
  end
end

app = Proc.new do |env|
  ['200', {'Content-Type' => 'text/html'}, ['hello world~']]
end

use Clock
use BodyUpper
run app
```
直接使用rackup命令就可以运行这个样例。
可以看出它使用了一系列方法，约定以及配置帮忙简化了 stack 的生成以及 app 的运行。这些方法来自于 Rack::Builder ，让我们来看一下这个类
> Rack::Builder implements a small DSL to iteratively construct Rack applications.
> -- comments

其核心方法如下：
```
# All requests through to this application will first be processed by the middleware class.
# The +call+ method in this example sets an additional environment key which then can be
# referenced in the application if required.
def use(middleware, *args, &block)
  if @map
    mapping, @map = @map, nil
    @use << proc { |app| generate_map app, mapping }
  end
  @use << proc { |app| middleware.new(app, *args, &block) }
end

# Takes an argument that is an object that responds to #call and returns a Rack response.
def run(app)
  @run = app
end
    
# Creates a route within the application.
#
# The +use+ method can also be used here to specify middleware to run under a specific path:
#
#   Rack::Builder.app do
#     map '/' do
#       use Middleware
#       run Heartbeat
#     end
#   end
#
# This example includes a piece of middleware which will run before requests hit +Heartbeat+.
#
def map(path, &block)
  @map ||= {}
  @map[path] = block
end
    
def to_app
  app = @map ? generate_map(@run, @map) : @run
  fail "missing run or map statement" unless app
  app = @use.reverse.inject(app) { |a,e| e[a] }
  @warmup.call(app) if @warmup
  app
end

def call(env)
  to_app.call(env)
end
```
可以看出 to_app 方法最终生成了完整的 app stack ,它已经将 app 以及 middlewares 全部串在了一起, 并且保证一次调用call, 就会按规则经过所有的 middlewares 。

### Rails on Rack
> Rails.application is the primary Rack application object of a Rails application. Any Rack compliant web server should be using Rails.application object to serve a Rails application.
-- rails_on_rack

Rails::Server 加载中间件的方式是这样的：
```
def middleware
  middlewares = []
  middlewares << [Rails::Rack::Debugger] if options[:debugger]
  middlewares << [::Rack::ContentLength]
  Hash.new(middlewares)
end
```
Rails::Application 通过 ActionDispatch::MiddlewareStack 把内部和外部的中间件组合在一起，形成一个完整的 Rails Rack 程序。

同时rails也提供了命令来查看正在使用的中间件链
```
# rake middleware

use Rack::Sendfile
use ActionDispatch::Static
use Rack::Lock
use #<ActiveSupport::Cache::Strategy::LocalCache::Middleware:0x000000029a0838>
use Rack::Runtime
use Rack::MethodOverride
use ActionDispatch::RequestId
use Rails::Rack::Logger
use ActionDispatch::ShowExceptions
use ActionDispatch::DebugExceptions
use ActionDispatch::RemoteIp
use ActionDispatch::Reloader
use ActionDispatch::Callbacks
use ActiveRecord::Migration::CheckPending
use ActiveRecord::ConnectionAdapters::ConnectionManagement
use ActiveRecord::QueryCache
use ActionDispatch::Cookies
use ActionDispatch::Session::CookieStore
use ActionDispatch::Flash
use ActionDispatch::ParamsParser
use Rack::Head
use Rack::ConditionalGet
use Rack::ETag
run MyApp::Application.routes
```

添加一个自己的中间件：
```
# config/application.rb
 
# Push Rack::BounceFavicon at the bottom
config.middleware.use My::SelfMiddle
```

rails 提供了几个方法来更加方便进行这个操作：

* config.middleware.use(new_middleware, args) - Adds the new middleware at the bottom of the middleware stack.

* config.middleware.insert_before(existing_middleware, new_middleware, args) - Adds the new middleware before the specified existing middleware in the middleware stack.

* config.middleware.insert_after(existing_middleware, new_middleware, args) - Adds the new middleware after the specified existing middleware in the middleware stack.

* config.middleware.swap ActionDispatch::ShowExceptions, Lifo::ShowExceptions - Replace ActionDispatch::ShowExceptions with Lifo::ShowExceptions

* config.middleware.delete Rack::Runtime - delete Rack::Runtime

---

[Rails on Rack — Ruby on Rails Guides][5]


  [1]: http://rack.rubyforge.org/doc/
  [2]: http://7xsger.com1.z0.glb.clouddn.com/image/blog/rack-1.png
  [3]: http://7xsger.com1.z0.glb.clouddn.com/image/blog/middleware-1.png
  [4]: http://7xsger.com1.z0.glb.clouddn.com/image/blog/rack-2.png
  [5]: http://guides.rubyonrails.org/rails_on_rack.html
