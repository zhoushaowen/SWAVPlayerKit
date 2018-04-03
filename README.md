# SWAVPlayerKit
基于AVPlayer封装的音视频框架,支持本地和远程的音频和视频播放.

#### 导入方式:pod 'SWAVPlayerKit'

截图

![audio](https://raw.githubusercontent.com/zhoushaowen/SWAVPlayerKit/master/screenshot/Simulator%20Screen%20Shot%20-%20iPhone%208%20-%202018-04-03%20at%2016.31.51.png)

![video](https://raw.githubusercontent.com/zhoushaowen/SWAVPlayerKit/master/screenshot/Simulator%20Screen%20Shot%20-%20iPhone%208%20-%202018-04-03%20at%2016.32.00.png)

#####  播放音频请使用:SWAudioPlayerManager

`- (void)playAudioWithURL:(NSURL *)URL readyToPlay:(void(^)(NSError *error,NSTimeInterval totalDuration))readyToPlayBlock progressBlock:(void(^)(NSTimeInterval currentTime,NSTimeInterval totalDuration))progressBlock playCompleted:(void(^)(NSError *error))playCompletedBlock`

##### 播放视频请使用:SWVideoPlayerManager

`- (void)playVideoWithURL:(NSURL *)URL view:(UIView *)view readyToPlay:(void(^)(NSError *error,NSTimeInterval totalDuration))readyToPlayBlock progressBlock:(void(^)(NSTimeInterval currentTime,NSTimeInterval totalDuration))progressBlock playCompleted:(void(^)(NSError *error))playCompletedBlock`