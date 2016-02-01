---
title: qiniu 音视频处理
date: 2016-01-28 18:37:17
tags:
- Qiniu
- Ruby
description: 本篇文章主要介绍基于Qiniu的音视频存储及切片和转换处理的ruby实现。
---

> 本篇文章主要介绍基于Qiniu的音视频存储及切片和转换处理的ruby实现。
> Qiniu的SDK源码：[ruby-sdk](https://github.com/qiniu/ruby-sdk)

#### 安装使用
    
安装和配置很简单，[qiniu-doc](http://developer.qiniu.com/docs/v6/sdk/ruby-sdk.html)中介绍的很清楚，这里就不做赘述

#### 音视频的处理
    
音视频的处理过程发生在qiniu服务器端，整个流程是这样的：
首先调用qiniu的上传API，音视频上传完毕后**触发事件**并把音视频的转换/切片等处理任务放入一个**队列**中，
qiniu服务器从队列中取出任务处理，处理完毕后会将处理结果以回调的形式发送到我们自己的服务器。

*   qiniu上传策略

上传策略是资源上传时附带的一组配置设定，这组设定指明上传什么资源，上传到哪个空间，资源成功上传后是否执行持久化，是否需要设置反馈信息的内容，以及授权上传的截止时间等等。
    
查看源码：
```ruby
class PutPolicy
...
  PARAMS = {
            # 字符串类型参数
            :scope                  => "scope"               ,
            :save_key               => "saveKey"             ,
            :end_user               => "endUser"             ,
            :return_url             => "returnUrl"           ,
            :return_body            => "returnBody"          ,
            :callback_url           => "callbackUrl"         ,
            :callback_host          => "callbackHost"        ,
            :callback_body          => "callbackBody"        ,
            :callback_body_type     => "callbackBodyType"    ,
            :persistent_ops         => "persistentOps"       ,
            :persistent_notify_url  => "persistentNotifyUrl" ,
            :persistent_pipeline    => "persistentPipeline"  ,

            # 数值类型参数
            :deadline               => "deadline"            ,
            :insert_only            => "insertOnly"          ,
            :fsize_limit            => "fsizeLimit"          ,
            :callback_fetch_key     => "callbackFetchKey"    ,
            :detect_mime            => "detectMime"          ,
            :mime_limit             => "mimeLimit"
          } # PARAMS

  PARAMS.each_pair do |key, fld|
    attr_accessor key
  end
  ...
```
以上就是上传策略中的各个设定

*   persistentOps
    
qiniu的API文档对上传策略中的参数都有解释，这里只对persistentOps展开说明。
    
persistentOps: 资源成功上传后执行的持久化指令列表,每个指令是一个API规格字符串，多个指令用“;”分隔。

persistentNotifyUrl: 接收预转持久化结果通知的URL。(POST)
    
example:
```ruby
put_policy.persistentOps = "avthumb/m3u8/segtime/5/vb/440k"
put_policy.persistentNotifyUrl = "#{server.host}/#{api_path}"
```
可以使用SDK中提供的方法生成 upload token
```ruby
uptoken = Qiniu::Auth.generate_uptoken(put_policy)
```
然后就可以使用客户端直传或服务器上传的形式上传文件，设置 persistentOps 参数后返回值中将会包含 persistentId 字段，
persistentId 字段用来唯一标识预转持久化任务，任务完成后qiniu回调也会包含此字段，也可以拿 persistentId 去查询任务
处理状态。
```ruby
Qiniu::Fop::Persistance.prefop(persistentId)
# 返回结果如下
[
  200, 
  {
    "code"=>0, 
    "desc"=>"The fop was completed successfully", 
    "id"=>"z0.xxxxxxxxxxx", 
    "inputBucket"=>"123", 
    "inputKey"=>"/video/2016/1/29/3629bcdb226c0e65d2eb23c9777b8xxx", 
    "items"=>[
      {
        "cmd"=>"avthumb/m3u8/segtime/5/vb/440k", 
        "code"=>0, 
        "desc"=>"The fop was completed successfully", 
        "hash"=>"Fke2kDZgH1hf9LK8XVywtexxx", 
        "key"=>"r2f70r_DsDkO49jG-Rv9HFBdEww=/xxxxxxxxxxx", 
        "returnOld"=>0
      }
    ], 
    "pipeline"=>"0.default", 
    "reqid"=>"xxxxxxxxxxx"
  }, 
  {
    "server"=>["nginx/1.4.4"], 
    "date"=>["Fri, 29 Jan 2016 07:13:04 GMT"], 
    "content-type"=>["application/json"], 
    "content-length"=>["453"], 
    "connection"=>["close"], 
    "x-log"=>["STATUS;ZONEPROXY:1;APIS:2"], 
    "x-reqid"=>["zEsAACDsvGM21C0U", "zEsAACDsvGM21C0U", "zEsAACDsvGM21C0U"]
  }
]
```
*   音视频切片
音视频切片是七牛云存储提供的云处理功能，用于支持HTTP Live Streaming播放。它将一整个音视频流切割成可由HTTP下载的一个个小的音视频流，并生成一个播放列表（M3U8），客户端只需要获取资源的 M3U8 播放列表即可播放音视频。

```ruby
# qiniu音视频切片接口
"avthumb/m3u8/segtime/<SegSeconds>/vb/<VideoBitRate>/..."

# 例如：要把音视频切片为5秒一片，视频比特率440k
"avthumb/m3u8/segtime/5/vb/440k"
```
qiniu还提供转储的功能，在数据处理命令后用管道符 | 拼接 saveas/<encodedEntryURI> 指令，其中 encodedEntryURI 是 bucket:key 的URL安全的Base64编码结果
可以使用SDK提供的方法生成 encodedEntryURI
```ruby
encodedEntryURI = Qiniu::Storage.encode_entry_uri(bucket, key)

# 指令如下
"avthumb/m3u8/segtime/5/vb/440k|saveas/cWJ1Y2tldDpxa2V5"
```
    
    
然后就是 persistentNotifyUrl 传回的处理结果了
```ruby
# 上面处理的返回数据如下
{
  "id"=>"z0.xxxxxxxxxxx", 
  "pipeline"=>"0.default", 
  "code"=>0, 
  "desc"=>"The fop was completed successfully", 
  "reqid"=>"v0kAACuPf2gXXXX", 
  "inputBucket"=>"123", 
  "inputKey"=>"bingo/video/2016/1/29/3629bcdb226c0e65d2eb23c9777b8xxx", 
  "items"=>[{"cmd"=>"avthumb/m3u8/segtime/5/vb/440k", 
    "code"=>0, 
    "desc"=>"The fop was completed successfully", 
    "hash"=>"Fke2kDZgH1hf9LK8XVywtexxx", 
    "key"=>"r2f70r_DsDkO49jG-Rv9HFBdEww=/xxxxxxxxxxx", 
    "returnOld"=>0}], 
  "format"=>:json, 
  "controller"=>"#{API_PATH}", 
  "action"=>"#{action}", 
  "#{controller_name}"=>{
    "id"=>"z0.xxxxxxxxxxx", 
    "pipeline"=>"0.default", 
    "code"=>0, 
    "desc"=>"The fop was completed successfully", 
    "reqid"=>"v0kAACuPf2gXXXX", 
    "inputBucket"=>"123", 
    "inputKey"=>"bingo/video/2016/1/29/3629bcdb226c0e65d2eb23c9777b8xxx", 
    "items"=>[
      {
        "cmd"=>"avthumb/m3u8/segtime/5/vb/440k", 
        "code"=>0, 
        "desc"=>"The fop was completed successfully", 
        "hash"=>"Fke2kDZgH1hf9LK8XVywtexxx", 
        "key"=>"r2f70r_DsDkO49jG-Rv9HFBdEww=/xxxxxxxxxxx", 
        "returnOld"=>0
      }
    ]
  }
}
```
其中 item 的 key 就是处理指令处理结果的存储的文件key，访问如下链接即可获得 M3U8 播放列表
```ruby
http://{qiniu_server}/{key}
# 列表大致内容如下

#EXTM3U
#EXT-X-VERSION:3
#EXT-X-MEDIA-SEQUENCE:0
#EXT-X-ALLOW-CACHE:YES
#EXT-X-TARGETDURATION:11
#EXT-X-KEY:METHOD=AES-128,URI="http://ztest.qiniudn.com/crypt0.key",IV=0xe532855feb3e18366b8e7ea0c11f3116
#EXTINF:10.066667,
http://ztest.qiniudn.com/Fr88-3sZu8HqPFot_BapyYtuz3k=/FgCBc3IlydY6CFIA8jhe7jIxCt1y/seg0
#EXT-X-KEY:METHOD=AES-128,URI="http://ztest.qiniudn.com/crypt0.key",IV=0x48586a2ac8397fbce9565480259c1b94
#EXTINF:10.000000,
http://ztest.qiniudn.com/Fr88-3sZu8HqPFot_BapyYtuz3k=/FgCBc3IlydY6CFIA8jhe7jIxCt1y/seg1
#EXT-X-KEY:METHOD=AES-128,URI="http://ztest.qiniudn.com/crypt0.key",IV=0x928f18982f6ee1a7e36cfa8f36979c3a
#EXTINF:10.000000,
http://ztest.qiniudn.com/Fr88-3sZu8HqPFot_BapyYtuz3k=/FgCBc3IlydY6CFIA8jhe7jIxCt1y/seg2
#EXT-X-KEY:METHOD=AES-128,URI="http://ztest.qiniudn.com/crypt0.key",IV=0x6651941d56de8af0c7d4bee9ae33a8de
#EXTINF:10.000000,
http://ztest.qiniudn.com/Fr88-3sZu8HqPFot_BapyYtuz3k=/FgCBc3IlydY6CFIA8jhe7jIxCt1y/seg3
#EXT-X-KEY:METHOD=AES-128,URI="http://ztest.qiniudn.com/crypt0.key",IV=0x90df003d61ba2ef9413fdaf521cfce15
#EXTINF:10.000000,
http://ztest.qiniudn.com/Fr88-3sZu8HqPFot_BapyYtuz3k=/FgCBc3IlydY6CFIA8jhe7jIxCt1y/seg4
#EXT-X-KEY:METHOD=AES-128,URI="http://ztest.qiniudn.com/crypt0.key",IV=0xc7773183806b8d3d7e44811076ed5b66
#EXTINF:2.200000,
http://ztest.qiniudn.com/Fr88-3sZu8HqPFot_BapyYtuz3k=/FgCBc3IlydY6CFIA8jhe7jIxCt1y/seg5
#EXT-X-ENDLIST

```
    
    
详细的参数信息等内容请查阅 [qiniu-doc](http://developer.qiniu.com/docs/v6/api/reference/fop/av/segtime.html)







