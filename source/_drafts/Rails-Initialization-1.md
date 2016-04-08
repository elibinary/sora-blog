---
title: Rails Initialization - Briefing
tags:
---
> rails 4-2-stable 源码为例

> rails server 为例

- bin/rails

```ruby
#!/usr/bin/env ruby
APP_PATH = File.expand_path('../../config/application', __FILE__)
require_relative '../config/boot'
require 'rails/commands'
```

- config/boot

```ruby
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
```

config/boot.rb文件来载入Bundler,并初始化Bundler的配置。
在一个标准的Rails应用中的Gemfile文件会配置它的所有依赖项。config/boot.rb文件会根据ENV['BUNDLE_GEMFILE']中的值来查找Gemfile文件的路径。如果Gemfile文件存在，那么bundler/setup操作会被执行，Bundler执行该操作是为了配置Gemfile依赖项的加载路径。

然后回去加载执行 rails 框架里的 rails/commands，之间会 require APP_PATH 根据上面 bin/rails 里的定义我们知道实际加载了 config/application

- config/application

> require 不会重复加载已加载过的文件
你可以根据需求对该文件进行配置

- config/environment.rb

config/application.rb为Rails::Application定义了Rails应用初始化之后所有需要用到的资源。当config/application.rb 加载了Rails和命名空间后，我们回到config/environment.rb，就是初始化完成的地方。

Rails.application.initialize!

执行所有railtie、engine、appilcation的initializers

#### Railtie

我们知道 Application 继承 Engine，Engine 继承 Railtie。
Railtie is the core of the Rails framework and provides several hooks to extend Rails and/or modify the initialization process.

