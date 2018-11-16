//
//  SWVideoPlayerManager.m
//  SWAVPlayerKitDemo
//
//  Created by zhoushaowen on 2018/4/2.
//  Copyright © 2018年 zhoushaowen. All rights reserved.
//

#import "SWVideoPlayerManager.h"
#import "SWAVPlayerKit.h"
#import <AVFoundation/AVFoundation.h>
#import <ReactiveObjC.h>

static SWVideoPlayerManager *Manager = nil;

NSString *const SWAVPlayerWillPlayVideoNotification = @"SWAVPlayerWillPlayVideoNotification";

@interface SWVideoPlayerManager ()

@property (nonatomic,strong) SWAudioPlayerManager *playerManager;
@property (nonatomic,strong) RACDisposable *layoutSubviewsDisposable;

@end

@implementation SWVideoPlayerManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(!Manager){
            Manager = [[self alloc] init];
        }
    });
    return Manager;
}

+ (void)releaseInstance {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    [Manager stop];
    Manager = nil;
}

- (instancetype)init {
    self = [super init];
    if(self){
        self.playerManager = [[SWAudioPlayerManager alloc] init];
    }
    return self;
}

- (void)playVideoWithURL:(NSURL *)URL view:(UIView *)view videoGravity:(AVLayerVideoGravity)videoGravity readyToPlay:(void(^)(NSError *error,NSTimeInterval totalDuration))readyToPlayBlock progressBlock:(void(^)(NSTimeInterval currentTime,NSTimeInterval totalDuration))progressBlock playCompleted:(void(^)(NSError *error))playCompletedBlock {
    NSAssert([NSThread currentThread].isMainThread, @"请在主线程中调用playVideoWithURL:view:readyToPlay:progressBlock:playCompleted");
    [[NSNotificationCenter defaultCenter] postNotificationName:SWAVPlayerWillPlayVideoNotification object:nil userInfo:nil];
    //开启状态栏菊花
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.playerManager performSelector:NSSelectorFromString(@"setPlayCompletedBlock:") withObject:playCompletedBlock];
    [self.playerManager performSelector:NSSelectorFromString(@"setReadyToPlayBlock:") withObject:readyToPlayBlock];
    [self.playerManager performSelector:NSSelectorFromString(@"setProgressBlock:") withObject:progressBlock];
    [self.playerManager configLockScreenMusicWithModel:nil];
    [self.playerManager performSelector:NSSelectorFromString(@"cancelLoad") withObject:nil];
    [self.playerManager performSelector:NSSelectorFromString(@"removeObserver") withObject:nil];
    //1.资源的请求
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:URL options:nil];
    //2.资源的组织
    AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
    //3.资源的播放
    [self.playerManager performSelector:NSSelectorFromString(@"setAvPlayer:") withObject:[AVPlayer playerWithPlayerItem:item]];
    AVPlayerLayer *playerLayer = [self.playerManager performSelector:NSSelectorFromString(@"playerLayer") withObject:nil];
    [playerLayer removeFromSuperlayer];
    AVPlayer *avPlayer = [self.playerManager performSelector:NSSelectorFromString(@"avPlayer") withObject:nil];
    [self.playerManager performSelector:NSSelectorFromString(@"setPlayerLayer:") withObject:[AVPlayerLayer playerLayerWithPlayer:avPlayer]];
    playerLayer = [self.playerManager performSelector:NSSelectorFromString(@"playerLayer") withObject:nil];
    playerLayer.videoGravity = videoGravity;
    if(playerLayer.superlayer == nil){
        [view.layer insertSublayer:playerLayer atIndex:0];
        //注意:这里需要用bounds,不能用frame,否则外层view发生旋转的时候playerLayer会错位
        playerLayer.frame = CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height);
    }
    [self removeSubscribe];
    @weakify(playerLayer)
    @weakify(view)
    self.layoutSubviewsDisposable = [[view rac_signalForSelector:@selector(layoutSubviews)] subscribeNext:^(RACTuple * _Nullable x) {
        @strongify(playerLayer)
        @strongify(view)
        //注意:这里需要用bounds,不能用frame,否则外层view发生旋转的时候playerLayer会错位
        playerLayer.frame = CGRectMake(0, 0, view.bounds.size.width, view.bounds.size.height);
    }];
    //资源准备好了再播放
    [self.playerManager performSelector:NSSelectorFromString(@"addObserver") withObject:nil];
#pragma clang diagnostic pop
}

- (void)playVideoWithURL:(NSURL *)URL view:(UIView *)view readyToPlay:(void(^)(NSError *error,NSTimeInterval totalDuration))readyToPlayBlock progressBlock:(void(^)(NSTimeInterval currentTime,NSTimeInterval totalDuration))progressBlock playCompleted:(void(^)(NSError *error))playCompletedBlock {
    [self playVideoWithURL:URL view:view videoGravity:AVLayerVideoGravityResize readyToPlay:readyToPlayBlock progressBlock:progressBlock playCompleted:playCompletedBlock];
}

- (void)play {
    [self.playerManager play];
}

- (void)pause {
    [self.playerManager pause];
}

- (void)stop {
    [self removeSubscribe];
    [self.playerManager stop];
}

- (void)seekToTime:(NSTimeInterval)time {
    [self.playerManager seekToTime:time];
}

- (void)removeSubscribe {
    if(self.layoutSubviewsDisposable){
        [self.layoutSubviewsDisposable dispose];
        self.layoutSubviewsDisposable = nil;
    }
}

- (void)dealloc {
    [self removeSubscribe];
    NSLog(@"%s",__func__);
}



@end
