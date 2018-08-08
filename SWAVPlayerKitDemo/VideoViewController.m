//
//  VideoViewController.m
//  SWAVPlayerKitDemo
//
//  Created by zhoushaowen on 2018/4/2.
//  Copyright © 2018年 zhoushaowen. All rights reserved.
//

#import "VideoViewController.h"
#import "SWAVPlayerKit.h"
#import <RACEXTScope.h>

@interface VideoViewController ()

@property (weak, nonatomic) IBOutlet UIView *videoView;
@property (weak, nonatomic) IBOutlet UISlider *slider;
@property (weak, nonatomic) IBOutlet UILabel *currentDurationLabel;
@property (weak, nonatomic) IBOutlet UILabel *totalDurationLabel;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (nonatomic) BOOL flag;
@property (nonatomic) BOOL isPause;

@end

@implementation VideoViewController


- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    self.flag = !self.flag;
    [UIView animateWithDuration:0.35f animations:^{
        if(self.flag){
            self.videoView.transform = CGAffineTransformMakeRotation(M_PI_2);
            self.videoView.frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
        }else{
            self.videoView.transform = CGAffineTransformIdentity;
            self.videoView.frame = self.view.bounds;
        }
    } completion:^(BOOL finished) {
        
    }];
}

- (IBAction)playAction:(UIButton *)sender {
    if([sender.currentTitle isEqualToString:@"play"]){
        if(self.isPause){
            [[SWVideoPlayerManager sharedInstance] play];
        }else{
            @weakify(self)
            [[SWVideoPlayerManager sharedInstance] playVideoWithURL:[NSURL URLWithString:@"http://clips.vorwaerts-gmbh.de/big_buck_bunny.mp4"] view:self.videoView readyToPlay:^(NSError *error, NSTimeInterval totalDuration) {
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
        }
        [sender setTitle:@"pause" forState:UIControlStateNormal];
    }else{
        [self pause];
    }

}
    
- (IBAction)stopAction:(UIButton *)sender {
    [[SWVideoPlayerManager sharedInstance] stop];
    [self reset];
}

- (IBAction)dismiss:(UIButton *)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}
- (IBAction)sliderTouchDown:(UISlider *)sender {
    [[SWVideoPlayerManager sharedInstance] pause];
}
- (IBAction)sliderTouchUpInside:(UISlider *)sender {
    [[SWVideoPlayerManager sharedInstance] play];
}
- (IBAction)sliderTouchUpOutside:(UISlider *)sender {
    [[SWVideoPlayerManager sharedInstance] play];
}
- (IBAction)sliderValueChanged:(UISlider *)sender {
    [[SWVideoPlayerManager sharedInstance] seekToTime:sender.value];
}

- (void)pause {
    [[SWVideoPlayerManager sharedInstance] pause];
    [self.playBtn setTitle:@"play" forState:UIControlStateNormal];
    self.isPause = YES;
}

- (void)reset {
    [self.playBtn setTitle:@"play" forState:UIControlStateNormal];
    self.isPause = NO;
    self.slider.value = 0;
    self.currentDurationLabel.text = @"00:00";
}

- (void)viewDidDisappear:(BOOL)animated {
    [[SWVideoPlayerManager sharedInstance] stop];
}
- (IBAction)releaseAction:(id)sender {
    [SWVideoPlayerManager releaseInstance];
}

- (void)dealloc {
    NSLog(@"%s",__func__);
}


@end
