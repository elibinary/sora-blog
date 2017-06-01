---
title: 关于 carrierwave 的实践报告
date: 2017-01-01 15:08:11
tags:
  - Ruby
description: Classier solution for file uploads for Rails, Sinatra and other Ruby web frameworks. This gem provides a simple and extremely flexible way to upload files from Ruby applications. It works well with Rack based web applications, such as Ruby on Rails.
---

> Classier solution for file uploads for Rails, Sinatra and other Ruby web frameworks. 
> This gem provides a simple and extremely flexible way to upload files from Ruby applications. It works well with Rack based web applications, such as Ruby on Rails.

### What
[Carrierwave - GitHub][1]

正如其 README 中所描述的，这个 gem 提供了一套文件上传的解决方案来提高开发效率。使用起来简单方便，不需要再自己手写 File.open file.write 之类的文件操作，一切交给 Carrierwave 的 upload 去做。具体用法详见[上面链接][1]的README文件。

看完使用手册后，这里多说一句，关于你的 uploader 类：
```
class YourUploader < CarrierWave::Uploader::Base
    # Do something
end
```

如果你只是单纯的想要使用文件上传的功能方法，而并不想要其辅助于你的 model 那么你就直接使用你的 uploader 类就行了。 CarrierWave 的 Uploader 提供了很多方便的方法，比如：
```
uploader = YourUploader.new
# 存储
uploader.store!(file)
# 取出
uploader.retrieve_from_store!(filename)
```

同时如果你想用于辅助你的 ORM ，除了关系数据库外，它对 DataMapper, Mongoid, Sequel 也进行了支持，具体怎么实践也可以在文档中找到，这里就不赘述了。

### How
当你想要为你的 ORM mount 一个 upload 时，do this:
```
class User < ActiveRecord::Base
  mount_uploader :avatar, AvatarUploader
end
```
之后就可以使用 carrierwave 提供的一系列方便的方法了。比如直接使用赋值来 assign 一个 file
```
u = User.new
u.avatar = params[:file]
```

那么 mount_uploader 到底做了什么？让我们来深入看看

先看入口，由于 carrierwave 的代码量还真是挺大，这里就只捡要点看了
```
  module CarrierWave
    class Railtie < Rails::Railtie
      initializer "carrierwave.setup_paths" do |app|
        CarrierWave.root = Rails.root.join(Rails.public_path).to_s
        CarrierWave.base_path = ENV['RAILS_RELATIVE_URL_ROOT']
      end

      initializer "carrierwave.active_record" do
        ActiveSupport.on_load :active_record do
          require 'carrierwave/orm/activerecord'
        end
      end
    end
  end
```

看这一段，它使用 lazy-load hooks （稍后如果我还记得的话，再来单独写一篇关于 lazy-load hooks 的介绍），这里先往下看它在 load :active_record 的时候 require 了自己的 carrierwave/orm/activerecord ，来把目光转入这里
```
# carrierwave/orm/activerecord.rb

# See +CarrierWave::Mount#mount_uploader+ for documentation
#
def mount_uploader(column, uploader=nil, options={}, &block)
  super

  class_eval <<-RUBY, __FILE__, __LINE__+1
    def remote_#{column}_url=(url)
      column = _mounter(:#{column}).serialization_column
      send(:"\#{column}_will_change!")
      super
    end
  RUBY
end
```
第一眼就看到了我们想要找的方法，看到方法第一行的 super 就知道这个方法来自别处
```
include CarrierWave::Mount
```
看它 include 了 CarrierWave::Mount，进去看看
```
# carrierwave/mount.rb

def mount_uploader(column, uploader=nil, options={}, &block)
  mount_base(column, uploader, options, &block)

  mod = Module.new
  include mod
  mod.class_eval <<-RUBY, __FILE__, __LINE__+1

    def #{column}
      _mounter(:#{column}).uploaders[0] ||= _mounter(:#{column}).blank_uploader
    end

    def #{column}=(new_file)
      _mounter(:#{column}).cache([new_file])
    end

    def #{column}_url(*args)
      #{column}.url(*args)
    end

    def #{column}_cache
      _mounter(:#{column}).cache_names[0]
    end

    def #{column}_cache=(cache_name)
      _mounter(:#{column}).cache_names = [cache_name]
    end

    def remote_#{column}_url
      [_mounter(:#{column}).remote_urls].flatten[0]
    end

    def remote_#{column}_url=(url)
      _mounter(:#{column}).remote_urls = [url]
    end

    def remote_#{column}_request_header=(header)
      _mounter(:#{column}).remote_request_headers = [header]
    end

    def write_#{column}_identifier
      return if frozen?
      mounter = _mounter(:#{column})

      if mounter.remove?
        write_uploader(mounter.serialization_column, nil)
      elsif mounter.identifiers.first
        write_uploader(mounter.serialization_column, mounter.identifiers.first)
      end
    end

    def #{column}_identifier
      _mounter(:#{column}).read_identifiers[0]
    end

    def store_previous_changes_for_#{column}
      @_previous_changes_for_#{column} = changes[_mounter(:#{column}).serialization_column]
    end

    def remove_previously_stored_#{column}
      before, after = @_previous_changes_for_#{column}
      _mounter(:#{column}).remove_previous([before], [after])
    end
  RUBY
end
```
果然，这里定义了一系列的辅助方法，按照惯例从此 module 的注释看起 
```
# If a Class is extended with this module, it gains the mount_uploader
# method, which is used for mapping attributes to uploaders and allowing
# easy assignment.
```
从上面代码可以看出，当你使用 mount_uploader 把一个 attribute mount 到目标 uploader 上时，它首先做的一件事就是复写读取和赋值此 attribute 的方法，来看看 _mounter(:#{column}) 取出的到底是什么东西，首先看到 mount_uploader 方法第一行 
mount_base(column, uploader, options, &block)
我们来看下 mount_base 方法
```
# carrierwave/mount.rb

def mount_base(column, uploader=nil, options={}, &block)
  include CarrierWave::Mount::Extension

  uploader = build_uploader(uploader, &block)
  uploaders[column.to_sym] = uploader
  uploader_options[column.to_sym] = options
  ...
  ...
end

def build_uploader(uploader, &block)
  return uploader if uploader && !block_given?

  uploader = Class.new(uploader || CarrierWave::Uploader::Base)
  const_set("Uploader#{uploader.object_id}".tr('-', '_'), uploader)

  if block_given?
    uploader.class_eval(&block)
    uploader.recursively_apply_block_to_versions(&block)
  end

  uploader
end
```
首先我们传进来的是我们自己的 uploader 类，并且此类继承自 CarrierWave::Uploader::Base
mount_base 方法除了定义一些辅助方法外主要做了一件事，那就是为 @uploaders @uploader_options 这两个变量赋值。看方法 _mounter
```
# carrierwave/mount.rb

def _mounter(column)
    # We cannot memoize in frozen objects :(
    return Mounter.new(self, column) if frozen?
    @_mounters ||= {}
    @_mounters[column] ||= Mounter.new(self, column)
end
```

我们来看 Mounter 类
```
# carrierwave/mounter.rb

def initialize(record, column, options={})
  @record = record
  @column = column
  @options = record.class.uploader_options[column]
end

def uploader_class
  record.class.uploaders[column]
end

def blank_uploader
  uploader_class.new(record, column)
end

def identifiers
  uploaders.map(&:identifier)
end

def read_identifiers
  [record.read_uploader(serialization_column)].flatten.reject(&:blank?)
end

def uploaders
  @uploaders ||= read_identifiers.map do |identifier|
    uploader = blank_uploader
    uploader.retrieve_from_store!(identifier) if identifier.present?
    uploader
  end
end
```
主要看这几个方法，可以看出最终 _mounter(:#{column}).uploaders 返回的是一组 uploader 的实例。
这里再回头看文档中的描述：
> Note: u.avatar will never return nil, even if there is no photo associated to it. To check if a > photo was saved to the model, use u.avatar.file.nil? instead.

直接取 u.avatar 时返回值是绝对不会为空的，因为就算什么也没赋值，它返回的也是一个 uploader 的实例。如果你想要取数据库中真是存储的值时，可以使用 attributes 来取，像这样：
```
u.attributes['avatar']
```

### Trap

在使用的过程中也遇到了不少的问题，大多问题都可以在 wiki 中找到解决方法，下篇我会列几个把我害惨的坑来与大家分享。



  [1]: https://github.com/carrierwaveuploader/carrierwave