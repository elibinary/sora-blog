---
title: Rack::Request 获取 params 的问题
date: 2019-05-11 18:15:00
tags:
  - Ruby
description: Rack::Request 获取 params 的问题
---

让我们直接进入正题，先来看下 Rack::Request instance 是怎么获取参数的
`/rack-2.0.5/lib/rack/request.rb:357`
```
# Returns the data received in the query string.
def GET
  ...
end

# Returns the data received in the request body.
#
# This method support both application/x-www-form-urlencoded and
# multipart/form-data.
def POST
  if get_header(RACK_INPUT).nil?
    raise "Missing rack.input"
  elsif get_header(RACK_REQUEST_FORM_INPUT) == get_header(RACK_INPUT)
    get_header(RACK_REQUEST_FORM_HASH)
  elsif form_data? || parseable_data?
    ...
    ...
  else
    {}
  end
end

# The union of GET and POST data.
#
# Note that modifications will not be persisted in the env. Use update_param or delete_param if you want to destructively modify params.
def params
  self.GET.merge(self.POST)
rescue EOFError
  self.GET.dup
end
```

可以看到当是 `POST` 请求时，只支持拿 `application/x-www-form-urlencoded` 和 `multipart/form-data` 的内容。

如果想要在 middleware 中取 body 中的参数的话，可以使用 rails 的 `ActionDispatch::ParamsParser` middleware 中提供的方法来轻松获取

```
def call(env)
  if params = parse_formatted_parameters(env)
    env["action_dispatch.request.request_parameters"] = params
  end

  @app.call(env)
end

private
  def parse_formatted_parameters(env)
    request = Request.new(env)

    return false if request.content_length.zero?

    strategy = @parsers[request.content_mime_type]

    return false unless strategy

    case strategy
    when Proc
      strategy.call(request.raw_post)
    when :json
      data = ActiveSupport::JSON.decode(request.raw_post)
      data = {:_json => data} unless data.is_a?(Hash)
      Request::Utils.deep_munge(data).with_indifferent_access
    else
      false
    end
  rescue => e # JSON or Ruby code block errors
    logger(env).debug "Error occurred while parsing request parameters.\nContents:\n\n#{request.raw_post}"

    raise ParseError.new(e.message, e)
  end
```

获取方式：
`env["action_dispatch.request.request_parameters"]['your_params_name']`

需要注意的是使用的地方要在 `ActionDispatch::ParamsParser` 之后

---

当然，也可以自己读取解析，自己动手丰衣足食
