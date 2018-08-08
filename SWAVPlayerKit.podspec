Pod::Spec.new do |s|

  s.name         = "SWAVPlayerKit"

  s.version      = "0.0.5"

  s.homepage      = 'https://github.com/zhoushaowen/SWAVPlayerKit'

  s.ios.deployment_target = '8.0'

  s.summary      = "基于AVPlayer封装的音视频框架,支持本地和远程的音频和视频播放."

  s.license      = { :type => 'MIT', :file => 'LICENSE' }

  s.author       = { "Zhoushaowen" => "348345883@qq.com" }

  s.source       = { :git => "https://github.com/zhoushaowen/SWAVPlayerKit.git", :tag => s.version }
  
  s.source_files  = "SWAVPlayerKitDemo/SWAVPlayerKit/*.{h,m}"
  
  s.requires_arc = true

  s.dependency 'ReactiveObjC'



end