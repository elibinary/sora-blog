---
title: Rails Initialization - Briefing
date: 2016-04-14 22:57:03
tags:
- Ruby
- Rails
description: 根据4.2.x源码分析rails启动流程。
---

> rails 4-2-stable 源码为例

> rails server 命令为例

当执行这个命令时，实际上是先加载了 rails 的 railties/bin/rails

- railties/bin/rails

```
git_path = File.expand_path('../../../.git', __FILE__)

if File.exist?(git_path)
  railties_path = File.expand_path('../../lib', __FILE__)
  $:.unshift(railties_path)
end
require "rails/cli"
```

前面先引入 railties/lib 文件夹，就不多说了，我们看最后一句它加载了 railties/lib/rails/cli

- railties/lib/rails/cli
```
require 'rails/app_rails_loader'

# If we are inside a Rails application this method performs an exec and thus
# the rest of this script is not run.
Rails::AppRailsLoader.exec_app_rails

require 'rails/ruby_version_check'
```

如代码所示，它先加载 railties/lib/rails/ruby_version_check，然后执行方法 exec_app_rails

```
EXECUTABLES = ['bin/rails', 'script/rails']
  ...
  exe = find_executable
  exec RUBY, exe, *ARGV

  ...
  # If we exhaust the search there is no executable, this could be a
  # call to generate a new application, so restore the original cwd.
  Dir.chdir(original_cwd) and return if Pathname.new(Dir.pwd).root?

  # Otherwise keep moving upwards in search of an executable.
  Dir.chdir('..')
  ...
def find_executable
  EXECUTABLES.find { |exe| File.file?(exe) }
end
```

可以看出 exec_app_rails 回去执行你项目目录下的 bin/rails 指令，如果当前文件夹下没有bin/rails文件，它会到父级目录去搜索，直到找到为止。所以在Rails应用程序目录下的任意位置，都可以执行rails的命令。

- bin/rails

```ruby
#!/usr/bin/env ruby
APP_PATH = File.expand_path('../../config/application', __FILE__)
require_relative '../config/boot'
require 'rails/commands'
```

它加载了项目目录下的 config/boot 

```
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__)

require 'bundler/setup' # Set up gems listed in the Gemfile.
```

加载执行 bundler/setup 把Gemfile中的相关Gem都加载到load path中。

接下来回到 bin/rails ，继续加载 rails/commands ，这个文件主要用来解析并执行键入的指令

- railties/lib/rails/commands

```
# ...
require 'rails/commands/commands_tasks'

Rails::CommandsTasks.new(ARGV).run_command!(command)
```

解析命令参数的部分很简单，就不贴代码了。我们来看下执行的部分，首先加载了 rails/commands/commands_tasks 并执行 run_command!(command)
方法。

```
# rails/commands/commands_tasks

def server
  set_application_directory!
  require_command!("server")

  Rails::Server.new.tap do |server|
    # We need to require application after the server sets environment,
    # otherwise the --environment option given to the server won't propagate.
    require APP_PATH
    Dir.chdir(Rails.application.root)
    server.start
  end
end

def require_command!(command)
  require "rails/commands/#{command}"
end

# Change to the application's path if there is no config.ru file in current directory.
# This allows us to run `rails server` from other directories, but still get
# the main config.ru and properly set the tmp directory.
def set_application_directory!
  Dir.chdir(File.expand_path('../../', APP_PATH)) unless File.exist?(File.expand_path("config.ru"))
end
```

它会找到项目根目录，然后根据命令去加载 rails/commands/ 目录下的相应文件。
接下来创建了一个 Rails::Server 实例
```
def initialize(*)
  super
  set_environment
end
```
初始化时会去执行父类的初始化方法
```
# rack/lib/rack/server

def initialize(options = nil)
  @ignore_options = []

  if options
    @use_default_options = false
    @options = options
    @app = options[:app] if options[:app]
  else
    argv = defined?(SPEC_ARGV) ? SPEC_ARGV : ARGV
    @use_default_options = true
    @options = parse_options(argv)
  end
end
```
这里看似没有做什么事情，实际上这里的options设置配置了很多配置选项（如environment、Port、Host、config等等），以便给Rails决定如何运行服务提供支持。

当初始化执行完成之后会去加载 APP_PATH ，还记得之前 bin/rails 文件的内容么，在那里面定义了 APP_PATH 指向项目目录下的config/application文件。

- config/application

> require 不会重复加载已加载过的文件
你可以根据需求对该文件进行配置

```
require File.expand_path('../boot', __FILE__)

require 'rails/all'

# ...
```

第一句之前已经加载过了，我们直接来看第二句，它加载了 rails/all

- railties/lib/rails/all.rb

```
require "rails"

%w(
  active_record
  action_controller
  action_view
  action_mailer
  active_job
  rails/test_unit
  sprockets
).each do |framework|
  begin
    require "#{framework}/railtie"
  rescue LoadError
  end
end
```

从代码中可以看出它一一加载了Rails框架相关的各个内容，每个必要组件都会在这一步被加载

然后我们回到实例化 server 的部分，加载完毕 config/application 之后，将会执行 server.start

```
# server.rb
def start
  print_boot_information
  trap(:INT) { exit }
  create_tmp_directories
  log_to_stdout if options[:log_stdout]

  super
ensure
  # The '-h' option calls exit before @options is set.
  # If we call 'options' with it unset, we get double help banners.
  puts 'Exiting' unless @options && options[:daemonize]
end

private

def print_boot_information
  url = "#{options[:SSLEnable] ? 'https' : 'http'}://#{options[:Host]}:#{options[:Port]}"
  puts "=> Booting #{ActiveSupport::Inflector.demodulize(server)}"
  puts "=> Rails #{Rails.version} application starting in #{Rails.env} on #{url}"
  puts "=> Run `rails server -h` for more startup options"

  puts "=> Ctrl-C to shutdown server" unless options[:daemonize]
end
```

执行到这里，将会进行第一次控制台输出，可以看到这里还创建了一个INT中断，然后再创建tmp/cache,tmp/pids, tmp/sessions和tmp/sockets一系列目录最后去执行父类中的start方法，在start方法中我们主要来看这个方法 wrapped_app 

```
# rack/lib/rack/server

def wrapped_app
  @wrapped_app ||= build_app app
end

def build_app(app)
  middleware[options[:environment]].reverse_each do |middleware|
    middleware = middleware.call(self) if middleware.respond_to?(:call)
    next unless middleware
    klass, *args = middleware
    app = klass.new(app, *args)
  end
  app
end

def app
  @app ||= options[:builder] ? build_app_from_string : build_app_and_options_from_config
end

def build_app_and_options_from_config
  if !::File.exist? options[:config]
    abort "configuration #{options[:config]} not found"
  end

  app, options = Rack::Builder.parse_file(self.options[:config], opt_parser)
  @options.merge!(options) { |key, old, new| old }
  app
end

def build_app_from_string
  Rack::Builder.new_from_string(self.options[:builder])
end
```
可以看到app的创建会先去取options[:config]，options[:config]指向项目下的config.ru文件，我们先来看一下这个文件的样子
```
# config.ru

# This file is used by Rack-based servers to start the application.

require ::File.expand_path('../config/environment', __FILE__)
run Rails.application
```
它加载了项目目录下的 config/environment

- config/environment

```
# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!
```
可以看到这里也会加载项目的 config/application
 
接下来将会执行 Rails.application.initialize! 这个方法会对所有的组件进行初始化
> require 不会重复加载已加载过的文件

- railties/lib/rails/application.rb

```
def initialize!(group=:default) #:nodoc:
  raise "Application has been already initialized." if @initialized
  run_initializers(group, self)
  @initialized = true
  self
end
```
它会调起 railties/lib/rails/initializable.rb 的 run_initializers方法

```
# railties/lib/rails/initializable.rb

def run_initializers(group=:default, *args)
  return if instance_variable_defined?(:@ran)
  initializers.tsort_each do |initializer|
    initializer.run(*args) if initializer.belongs_to?(group)
  end
  @ran = true
end

def initializers
  @initializers ||= self.class.initializers_for(self)
end

module ClassMethods
  def initializers
    @initializers ||= Collection.new
  end

  def initializers_chain
    initializers = Collection.new
    ancestors.reverse_each do |klass|
      next unless klass.respond_to?(:initializers)
      initializers = initializers + klass.initializers
    end
    initializers
  end

  def initializers_for(binding)
    Collection.new(initializers_chain.map { |i| i.bind(binding) })
  end

  def initializer(name, opts = {}, &blk)
    raise ArgumentError, "A block must be passed when defining an initializer" unless blk
    opts[:after] ||= initializers.last.name unless initializers.empty? || initializers.find { |i| i.name == opts[:before] }
    initializers << Initializer.new(name, nil, opts, &blk)
  end
end
```

在方法 initializers_chain 它去遍历所有祖先链并把拿到它们的initializers方法，之后依次执行。这些执行完成后回到 rack/server.rb 的 build_app 方法，这个方法将会依照环境去加载rack所有的middleware,
最后一步 server.run 将会根据你的server类型去启动相应的服务。

到此，整个启动流程就结束了。



