//
//  SWAudioPlayerManager.m
//  SWAVPlayerKitDemo
//
//  Created by zhoushaowen on 2018/3/30.
//  Copyright © 2018年 zhoushaowen. All rights reserved.
//

#import "SWAudioPlayerManager.h"
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import <NSObject+RACKVOWrapper.h>
#import <ReactiveObjC.h>

@implementation SWLockScreenMusicModel

- (instancetype)initWithAlbumName:(NSString *)albumName musicName:(NSString *)musicName artistName:(NSString *)artistName albumImage:(UIImage *)albumImage {
    self = [super init];
    if(self){
        self.albumName = albumName;
        self.musicName = musicName;
        self.artistName = artistName;
        self.albumImage = albumImage;
    }
    return self;
}

@end

static SWAudioPlayerManager *Manager = nil;

NSString *const SWAVPlayerWillPlayAudioNotification = @"SWAVPlayerWillPlayAudioNotification";

@interface SWAudioPlayerManager ()

@property (nonatomic,strong) AVPlayer *avPlayer;
@property (nonatomic,strong) AVPlayerLayer *playerLayer;
@property (nonatomic,weak) id timeObserver,didPlayToEndTimeObserver,failedToPlayToEndTimeObserver,audioSessionInterruptionObserver;
@property (nonatomic,strong) void(^playCompletedBlock)(NSError *error);
@property (nonatomic,strong) void(^readyToPlayBlock)(NSError *error,NSTimeInterval totalDuration);
@property (nonatomic,strong) void(^progressBlock)(NSTimeInterval currentTime,NSTimeInterval totalDuration);
@property (nonatomic) NSTimeInterval totalDuration,currentDuration;
@property (nonatomic,strong) RACDisposable *statusDisposable,*loadedTimeRangesDisposable,*playbackBufferEmptyDisposable,*playbackLikelyToKeepUpDisposable;
@property (nonatomic,strong) SWLockScreenMusicModel *currentLockScreenMusicModel;


@end

@implementation SWAudioPlayerManager

+ (instancetype)sharedInstance {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if(!Manager){
            Manager = [[self alloc] init];
        }
    });
    return Manager;
}

#pragma mark - AVPlayer
- (void)playAudioWithURL:(NSURL *)URL readyToPlay:(void(^)(NSError *error,NSTimeInterval totalDuration))readyToPlayBlock progressBlock:(void(^)(NSTimeInterval currentTime,NSTimeInterval totalDuration))progressBlock playCompleted:(void(^)(NSError *error))playCompletedBlock {
    NSAssert([NSThread currentThread].isMainThread, @"请在主线程中调用playAudioWithURL:readyToPlay:progressBlock:playCompleted");
    [[NSNotificationCenter defaultCenter] postNotificationName:SWAVPlayerWillPlayAudioNotification object:nil userInfo:nil];
    //开启状态栏菊花
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    self.playCompletedBlock = playCompletedBlock;
    self.readyToPlayBlock = readyToPlayBlock;
    self.progressBlock = progressBlock;
    [self configLockScreenMusicWithModel:nil];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self cancelLoad];
        [self removeObserver];
        //1.资源的请求
        AVURLAsset *asset = [AVURLAsset URLAssetWithURL:URL options:nil];
        SWLockScreenMusicModel *model = [self getLockScreenMusicModelWithURLAsset:asset];
        dispatch_async(dispatch_get_main_queue(), ^{
            if(self.currentLockScreenMusicModel) return;
            [self configLockScreenMusicWithModel:model];
        });
        //2.资源的组织
        AVPlayerItem *item = [AVPlayerItem playerItemWithAsset:asset];
        //3.资源的播放
        self.avPlayer = [AVPlayer playerWithPlayerItem:item];
        //资源准备好了再播放
        [self addObserver];
    });
}

- (void)cancelLoad {
    [self.avPlayer cancelPendingPrerolls];
    [self.avPlayer.currentItem cancelPendingSeeks];
    [self.avPlayer.currentItem.asset cancelLoading];
    [self.avPlayer replaceCurrentItemWithPlayerItem:nil];
}

- (SWLockScreenMusicModel *)getLockScreenMusicModelWithURLAsset:(AVURLAsset *)asset {
    SWLockScreenMusicModel *model = [SWLockScreenMusicModel new];
    [asset.availableMetadataFormats enumerateObjectsUsingBlock:^(AVMetadataFormat  _Nonnull format, NSUInteger idx, BOOL * _Nonnull stop) {
        NSArray *metadataItems = [asset metadataForFormat:format];
        [metadataItems enumerateObjectsUsingBlock:^(AVMetadataItem*  _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            NSLog(@"%@",item.value);
            if([item.commonKey isEqualToString:@"title"]){
                NSString *musicName = (NSString *)item.value;
                model.musicName = musicName;
            }else if ([item.commonKey isEqualToString:@"artist"]){
                NSString *artist = (NSString *)item.value;
                model.artistName = artist;
            }else if ([item.commonKey isEqualToString:@"albumName"]){
                NSString *albumName = (NSString *)item.value;
                model.albumName = albumName;
            }else if ([item.commonKey isEqualToString:@"artwork"]){
                NSData *imageData = (NSData *)item.value;
                UIImage *albumImage = [[UIImage alloc] initWithData:imageData];
                model.albumImage = albumImage;
            }
        }];
    }];
    return model;
}

- (void)play {
    if(self.avPlayer == nil) return;
    NSError *error = nil;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:0 error:&error];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    if(error){
        NSLog(@"AVAudioSession设置错误：%@",error);
    }
    [self.avPlayer play];
}

- (void)pause {
    [self.avPlayer pause];
}

- (void)stop {
    if(self.avPlayer == nil) return;
    [self.avPlayer pause];
    [self cancelLoad];
    [self removeObserver];
    self.avPlayer = nil;
    [self configLockScreenMusicWithModel:nil];
}

- (void)seekToTime:(NSTimeInterval)time {
    if(self.avPlayer == nil) return;
    NSLog(@"快进到时间:%f",time);
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    //取消之前的缓存快进
    [self.avPlayer.currentItem cancelPendingSeeks];
    CMTime cmTime = CMTimeMakeWithSeconds(time, 1);
    [self.avPlayer seekToTime:cmTime completionHandler:^(BOOL finished) {
        if(finished){
            NSLog(@"快进/快退完成");
        }else{
            NSLog(@"快进/快退取消");
        }
    }];
}

- (void)addObserver {
    @weakify(self);
    self.statusDisposable = [self.avPlayer.currentItem rac_observeKeyPath:@"status" options:NSKeyValueObservingOptionNew observer:self block:^(id value, NSDictionary *change, BOOL causedByDealloc, BOOL affectedOnlyLastComponent) {
        @strongify(self)
        dispatch_async(dispatch_get_main_queue(), ^{
            [self handleCurrentItemStatusObserver];
        });
    }];
    self.loadedTimeRangesDisposable = [self.avPlayer.currentItem rac_observeKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew observer:self block:^(id value, NSDictionary *change, BOOL causedByDealloc, BOOL affectedOnlyLastComponent) {
        @strongify(self)
        @autoreleasepool {
            CMTimeRange loadedRange = [[[self.avPlayer.currentItem loadedTimeRanges] lastObject] CMTimeRangeValue];
            CMTime loadedTime = CMTimeAdd(loadedRange.start, loadedRange.duration);
            NSTimeInterval loadedTimeSec = CMTimeGetSeconds(loadedTime);
            CGFloat progress = loadedTimeSec/CMTimeGetSeconds(self.avPlayer.currentItem.duration);
            NSLog(@"缓冲的总时长是：%f-------缓冲的总进度是：%f",loadedTimeSec,progress);
            if(progress == 1.0f){
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                });
            }
        }
    }];
    self.playbackBufferEmptyDisposable = [self.avPlayer.currentItem rac_observeKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew observer:self block:^(id value, NSDictionary *change, BOOL causedByDealloc, BOOL affectedOnlyLastComponent) {
        NSLog(@"缓存不足暂停了");
    }];
    self.playbackLikelyToKeepUpDisposable = [self.avPlayer.currentItem rac_observeKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew observer:self block:^(id value, NSDictionary *change, BOOL causedByDealloc, BOOL affectedOnlyLastComponent) {
        @strongify(self)
        @autoreleasepool {
            if(self.avPlayer.currentItem.status == AVPlayerItemStatusReadyToPlay){
                //由于 AVPlayer 缓存不足就会自动暂停，所以缓存充足了需要手动播放，才能继续播放
                NSLog(@"缓存达到可播放程度了，并且此时已经可以准备播放了");
                NSLog(@"%f**************",self.avPlayer.rate);
                //rate ==1.0，表示正在播放；rate == 0.0，暂停；rate == -1.0，播放失败
                if(self.avPlayer.rate == 1.0f){
                    [self.avPlayer play];
                }
                dispatch_async(dispatch_get_main_queue(), ^{
                    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
                });
            }else{
                NSLog(@"缓存达到可播放程度了，但是此时还不可以准备播放");
            }
        }
    }];
    //监听播放进度
    _timeObserver = [self.avPlayer addPeriodicTimeObserverForInterval:CMTimeMake(1, 60) queue:NULL usingBlock:^(CMTime time) {
        @strongify(self);
        @autoreleasepool {
            if(self.avPlayer.currentItem.status != AVPlayerItemStatusReadyToPlay) return;
            NSTimeInterval currentDuration = CMTimeGetSeconds(time);
            self.currentDuration = currentDuration;
            NSTimeInterval totalDuration = CMTimeGetSeconds(self.avPlayer.currentItem.duration);
//            CGFloat progress = currentDuration/totalDuration;
//            NSLog(@"播放进度：%f---总时长：%f",progress,totalDuration);
            if(self.progressBlock){
                self.progressBlock(currentDuration,totalDuration);
            }
            [self configLockScreenMusicWithModel:self.currentLockScreenMusicModel];
        };
    }];
    
    //监听播放完成
    _didPlayToEndTimeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);
        if(self.avPlayer.currentItem != note.object) return;
        NSLog(@"播放完成");
        if(self.playCompletedBlock){
            self.playCompletedBlock(nil);
        }
        [self cancelLoad];
        [self removeObserver];
        self.avPlayer = nil;
    }];
    //播放错误
    _failedToPlayToEndTimeObserver = [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemFailedToPlayToEndTimeNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        @strongify(self);
        if(self.avPlayer.currentItem != note.object) return;
        NSLog(@"播放完成，发生错误%@",note.userInfo);
        if(self.playCompletedBlock){
            NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:@"item has failed to play to its end time"}];
            self.playCompletedBlock(error);
        }
        [self cancelLoad];
        [self removeObserver];
        self.avPlayer = nil;
    }];
}

- (void)handleCurrentItemStatusObserver {
    switch (self.avPlayer.currentItem.status) {
        case AVPlayerItemStatusReadyToPlay:
        {
            NSLog(@"准备播放成功");
            self.totalDuration = CMTimeGetSeconds(self.avPlayer.currentItem.duration);
            NSLog(@"总时长：++++++%f",self.totalDuration);
            if(self.readyToPlayBlock){
                self.readyToPlayBlock(nil,self.totalDuration);
            }
            [self play];
        }
            break;
        case AVPlayerItemStatusFailed:
        {
            NSLog(@"准备播放失败:%@",self.avPlayer.currentItem.error.localizedDescription);
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            //在准备播放失败的时候AVPlayerItem会被置为nil,使用ReactiveKVO监听很安全
            if(self.readyToPlayBlock){
                self.readyToPlayBlock(self.avPlayer.currentItem.error,0);
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)removeObserver {
    if(self.avPlayer.currentItem){
        [self.avPlayer replaceCurrentItemWithPlayerItem:nil];
    }
    if(_timeObserver){
        [self.avPlayer removeTimeObserver:_timeObserver];
    }
    if(_didPlayToEndTimeObserver){
        [[NSNotificationCenter defaultCenter] removeObserver:_didPlayToEndTimeObserver];
    }
    if(_failedToPlayToEndTimeObserver){
        [[NSNotificationCenter defaultCenter] removeObserver:_failedToPlayToEndTimeObserver];
    }
    if(self.statusDisposable){
        [self.statusDisposable dispose];
        self.statusDisposable = nil;
    }
    if(self.loadedTimeRangesDisposable){
        [self.loadedTimeRangesDisposable dispose];
        self.loadedTimeRangesDisposable = nil;
    }
    if(self.playbackBufferEmptyDisposable){
        [self.playbackBufferEmptyDisposable dispose];
        self.playbackBufferEmptyDisposable = nil;
    }
    if(self.playbackLikelyToKeepUpDisposable){
        [self.playbackLikelyToKeepUpDisposable dispose];
        self.playbackLikelyToKeepUpDisposable = nil;
    }
    _timeObserver = nil;
    _didPlayToEndTimeObserver = nil;
    _failedToPlayToEndTimeObserver = nil;
}

//设置锁屏音乐信息
- (void)configLockScreenMusicWithModel:(SWLockScreenMusicModel *)model {
    //设置锁屏音乐之前必须要调用beginReceivingRemoteControlEvents,否则设置无效
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    self.currentLockScreenMusicModel = model;
    if(self.currentLockScreenMusicModel == nil){
        [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = nil;
        return;
    }
    NSMutableDictionary *dic = [NSMutableDictionary dictionary];
    //设置专辑名
    dic[MPMediaItemPropertyAlbumTitle] = model.albumName?:@"";
    //设置歌曲名
    dic[MPMediaItemPropertyTitle] = model.musicName?:@"";
    //设置歌手名
    dic[MPMediaItemPropertyArtist] = model.artistName?:@"";
    //设置播放进度
    dic[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(self.currentDuration);

    if(model.albumImage){
        MPMediaItemArtwork *artwork = [[MPMediaItemArtwork alloc] initWithImage:model.albumImage];
        //设置专辑图片
        dic[MPMediaItemPropertyArtwork] = artwork;
    }
    if(self.totalDuration > 0){
        //设置总时长
        dic[MPMediaItemPropertyPlaybackDuration] = @(self.totalDuration);
    }
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = dic;
}

#pragma mark - AVAudioPlayer
- (NSTimeInterval)getLocalAudioDurationWithURL:(NSURL *)URL {
    NSError *error = nil;
    AVAudioPlayer *player = [[AVAudioPlayer alloc] initWithContentsOfURL:URL error:&error];
    if(error){
        NSLog(@"初始化AVAudioPlayer错误：%@",error);
        return 0;
    }
    BOOL isSuccess = [player prepareToPlay];
    if(!isSuccess) {
        NSLog(@"prepareToPlay失败");
        return 0;
    }
    return player.duration;
}

#pragma mark - 短音频
- (void)playShortAudioWithName:(NSString *)name {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSURL *url = [[NSBundle mainBundle] URLForResource:name withExtension:nil];
        SystemSoundID soundID = 0;
        AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(url), &soundID);
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:0 error:nil];
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        AudioServicesPlaySystemSound(soundID);
    });
}

- (void)startVibrate {
    AudioServicesAddSystemSoundCompletion(kSystemSoundID_Vibrate, NULL, NULL, completedCallback, (__bridge void * _Nullable)(self));
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
}

- (void)stopVibrate {
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSObject cancelPreviousPerformRequestsWithTarget:self];
        AudioServicesDisposeSystemSoundID(kSystemSoundID_Vibrate);
        AudioServicesRemoveSystemSoundCompletion(kSystemSoundID_Vibrate);
    });
}

#pragma mark  Private
void completedCallback(SystemSoundID mmSSID,void* clientData) {
    dispatch_async(dispatch_get_main_queue(), ^{
        [Manager performSelector:@selector(triggerVibrate) withObject:nil afterDelay:1];
    });
}

- (void)triggerVibrate {
    AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
}


- (void)dealloc {
    [self removeObserver];
}




@end
