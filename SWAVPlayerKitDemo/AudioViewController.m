//
//  ViewController.m
//  SWAVPlayerKitDemo
//
//  Created by zhoushaowen on 2018/3/30.
//  Copyright © 2018年 zhoushaowen. All rights reserved.
//

#import "AudioViewController.h"
#import "SWAVPlayerKit.h"
#import <RACEXTScope.h>
#import "VideoViewController.h"
#import "SWAVPlayerKit.h"

@interface AudioViewController ()
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *stopBtn;
@property (weak, nonatomic) IBOutlet UILabel *currentDurationLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalDurationLabel;
@property (nonatomic) BOOL isPause;
@property (nonatomic) BOOL isPlay;

@end

@implementation AudioViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleWillPlayVideoNotification:) name:SWAVPlayerWillPlayVideoNotification object:nil];
}

- (IBAction)playBtnClick:(UIButton *)sender {
    self.isPlay = YES;
    if([sender.currentTitle isEqualToString:@"play"]){
        if(self.isPause){
            [[SWAudioPlayerManager sharedInstance] play];
        }else{
            @weakify(self)
            NSURL *fileUrl = [[NSBundle mainBundle] URLForResource:@"周笔畅-最美的期待.mp3" withExtension:nil];
//            NSURL *url = [NSURL URLWithString:@"http://mp3.9ku.com/m4a/411603.m4a"];
            [[SWAudioPlayerManager sharedInstance] playAudioWithURL:fileUrl readyToPlay:^(NSError *error, NSTimeInterval totalDuration) {
                @strongify(self)
                if(error){
                    [self reset];
                }else{
                    long long min = (long long )totalDuration/60;
                    long long sec = (long long)totalDuration%60;
                    self.totalDurationLabel.text = [NSString stringWithFormat:@"%.2lld:%.2lld",min,sec];
                    self.slider.maximumValue = totalDuration;
                }
            } progressBlock:^(NSTimeInterval currentTime, NSTimeInterval totalDuration) {
                [self.slider setValue:currentTime animated:YES];
                long long min = (long long )currentTime/60;
                long long sec = (long long)currentTime%60;
                self.currentDurationLabel.text = [NSString stringWithFormat:@"%.2lld:%.2lld",min,sec];
            } playCompleted:^(NSError *error) {
                [self reset];
            }];
//            SWLockScreenMusicModel *model = [[SWLockScreenMusicModel alloc] initWithAlbumName:@"我是专辑名" musicName:@"伤不起" artistName:@"王麟" albumImage:[UIImage imageNamed:@"album"]];
//            [[SWAudioPlayerManager sharedInstance] configLockScreenMusicWithModel:model];
        }
        [sender setTitle:@"pause" forState:UIControlStateNormal];
    }else{
        [self pause];
    }
}

- (void)pause {
    [[SWAudioPlayerManager sharedInstance] pause];
    [self.playBtn setTitle:@"play" forState:UIControlStateNormal];
    self.isPause = YES;
}

- (void)reset {
    [self.playBtn setTitle:@"play" forState:UIControlStateNormal];
    self.isPause = NO;
    self.isPlay = NO;
    self.slider.value = 0;
    self.currentDurationLabel.text = @"00:00";
}

- (IBAction)stopBtnClick:(UIButton *)sender {
    [[SWAudioPlayerManager sharedInstance] stop];
    [self reset];
}

- (IBAction)sliderTouchDown:(UISlider *)sender {
    [[SWAudioPlayerManager sharedInstance] pause];
}

- (IBAction)sliderTouchUpInside:(UISlider *)sender {
    [[SWAudioPlayerManager sharedInstance] play];
}
- (IBAction)sliderTouchUpOutside:(UISlider *)sender {
    [[SWAudioPlayerManager sharedInstance] play];
}
- (IBAction)sliderValueChanged:(UISlider *)sender {
    [[SWAudioPlayerManager sharedInstance] seekToTime:sender.value];
}
- (IBAction)goVideoVC:(UIButton *)sender {
    VideoViewController *vc = [VideoViewController new];
    [self presentViewController:vc animated:YES completion:nil];
}

- (void)handleWillPlayVideoNotification:(NSNotification *)note {
    if(self.isPlay){
        [self pause];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
