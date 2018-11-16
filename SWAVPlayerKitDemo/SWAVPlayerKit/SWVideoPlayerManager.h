//
//  SWVideoPlayerManager.h
//  SWAVPlayerKitDemo
//
//  Created by zhoushaowen on 2018/4/2.
//  Copyright © 2018年 zhoushaowen. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVAnimation.h>

//将要开始播放视频的通知
extern NSString *const SWAVPlayerWillPlayVideoNotification;

@interface SWVideoPlayerManager : NSObject

+ (instancetype)sharedInstance;

/**
 释放单例对象
 */
+ (void)releaseInstance;

/**
 播放视频,本地的和远程的都可以

 @param URL 视频url地址
 @param view 在哪个视图上显示
 @param videoGravity 视频的显示方式
 @param readyToPlayBlock 准备播放完成的回调,如果准备播放失败了,那么playCompletedBlock就不会调用
 @param progressBlock 播放进度的回调
 @param playCompletedBlock 播放完成的回调
 */
- (void)playVideoWithURL:(NSURL *)URL view:(UIView *)view videoGravity:(AVLayerVideoGravity)videoGravity readyToPlay:(void(^)(NSError *error,NSTimeInterval totalDuration))readyToPlayBlock progressBlock:(void(^)(NSTimeInterval currentTime,NSTimeInterval totalDuration))progressBlock playCompleted:(void(^)(NSError *error))playCompletedBlock;
/**
 默认的videoGravity是AVLayerVideoGravityResize
 */
- (void)playVideoWithURL:(NSURL *)URL view:(UIView *)view readyToPlay:(void(^)(NSError *error,NSTimeInterval totalDuration))readyToPlayBlock progressBlock:(void(^)(NSTimeInterval currentTime,NSTimeInterval totalDuration))progressBlock playCompleted:(void(^)(NSError *error))playCompletedBlock;

/**
 开始AVPlayer播放视频
 */
- (void)play;

/**
 暂停AVPlayer播放视频
 */
- (void)pause;

/**
 停止AVPlayer播放视频
 */
- (void)stop;

/**
 AVPlayer快进
 
 @param time 快进到的时间，单位秒
 */
- (void)seekToTime:(NSTimeInterval)time;



@end
