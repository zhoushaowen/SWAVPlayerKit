//
//  SWVideoHelper.m
//  Loko_iOS
//
//  Created by zhoushaowen on 2017/7/21.
//  Copyright © 2017年 loko. All rights reserved.
//

#import "SWVideoHelper.h"
#import <AVFoundation/AVFoundation.h>

@interface SWVideoHelper ()

@property (nonatomic,weak) AVAssetImageGenerator *imageGenerator;

@end

@implementation SWVideoHelper

- (UIImage *)syncGetVideoPreViewImageWithURL:(NSURL *)url maximumSize:(CGSize)maximumSize {
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
    AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    assetGen.appliesPreferredTrackTransform = YES;
    assetGen.maximumSize = maximumSize;
    self.imageGenerator = assetGen;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return videoImage;
}

- (void)asyncGetVideoPreViewImageWithURL:(NSURL *)url maximumSize:(CGSize)maximumSize completed:(void(^)(UIImage *resultImage,NSError *error))completedBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:url options:nil];
        AVAssetImageGenerator *assetGen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
        assetGen.maximumSize = maximumSize;
        assetGen.appliesPreferredTrackTransform = YES;
        self.imageGenerator = assetGen;
        CMTime time = CMTimeMakeWithSeconds(0.0, 600);
        NSError *error = nil;
        CMTime actualTime;
        CGImageRef image = [assetGen copyCGImageAtTime:time actualTime:&actualTime error:&error];
        UIImage *videoImage = [[UIImage alloc] initWithCGImage:image];
        CGImageRelease(image);
        if(!error){
            if(completedBlock){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completedBlock(videoImage,nil);
                });
            }
        }else{
            if(completedBlock){
                dispatch_async(dispatch_get_main_queue(), ^{
                    completedBlock(nil,error);
                });
            }
        }
    });
}

- (void)cancelAllImageGeneration {
    [self.imageGenerator cancelAllCGImageGeneration];
}



@end






