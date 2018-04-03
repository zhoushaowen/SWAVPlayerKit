//
//  SWAudioPlayerManager.h
//  SWAVPlayerKitDemo
//
//  Created by zhoushaowen on 2018/3/30.
//  Copyright © 2018年 zhoushaowen. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SWLockScreenMusicModel : NSObject

/**
 专辑名称
 */
@property (nonatomic,copy) NSString *albumName;
/**
 歌曲名称
 */
@property (nonatomic,copy) NSString *musicName;
/**
 艺术家名称
 */
@property (nonatomic,copy) NSString *artistName;
/**
 专辑图片
 */
@property (nonatomic,strong) UIImage *albumImage;

- (instancetype)initWithAlbumName:(NSString *)albumName musicName:(NSString *)musicName artistName:(NSString *)artistName albumImage:(UIImage *)albumImage;

@end
//将要开始播放音频的通知
extern NSString *const SWAVPlayerWillPlayAudioNotification;

@interface SWAudioPlayerManager : NSObject

/**
 单例

 @return SWAudioPlayerManager
 */
+ (instancetype)sharedInstance;

/**
 播放长音频,本地的和网络的都可以

 @param URL 音频url地址
 @param readyToPlayBlock 准备播放完成的回调,如果准备播放失败了,那么playCompletedBlock就不会调用
 @param progressBlock 播放进度的回调
 @param playCompletedBlock 播放完成的回调
 */
- (void)playAudioWithURL:(NSURL *)URL readyToPlay:(void(^)(NSError *error,NSTimeInterval totalDuration))readyToPlayBlock progressBlock:(void(^)(NSTimeInterval currentTime,NSTimeInterval totalDuration))progressBlock playCompleted:(void(^)(NSError *error))playCompletedBlock;

/**
 开始AVPlayer播放音频
 */
- (void)play;

/**
 暂停AVPlayer播放音频
 */
- (void)pause;

/**
 停止AVPlayer播放音频
 */
- (void)stop;

/**
 配置锁屏音乐信息

 @param model SWLockScreenMusicModel
 */
- (void)configLockScreenMusicWithModel:(SWLockScreenMusicModel *)model;
/**
 获取本地音频时长
 
 @param URL 音频url
 @return 时长
 */
- (NSTimeInterval)getLocalAudioDurationWithURL:(NSURL *)URL;

/**
 AVPlayer快进
 
 @param time 快进到的时间，单位秒
 */
- (void)seekToTime:(NSTimeInterval)time;

/**
 开启震动，会一直持续震动
 */
- (void)startVibrate;

/**
 停止震动
 */
- (void)stopVibrate;

/**
 使用AudioToolbox播放短音频,调用stop是不可以停止播放的
 */
- (void)playShortAudioWithName:(NSString *)name;


@end
