//
//  SWVideoHelper.h
//  Loko_iOS
//
//  Created by zhoushaowen on 2017/7/21.
//  Copyright © 2017年 loko. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SWVideoHelper : NSObject

/**
 获取视频第一帧图片,同步方法
 */
- (UIImage *)syncGetVideoPreViewImageWithURL:(NSURL *)url maximumSize:(CGSize)maximumSize;

/**
 获取视频第一帧图片,异步方法
 */
- (void)asyncGetVideoPreViewImageWithURL:(NSURL *)url maximumSize:(CGSize)maximumSize completed:(void(^)(UIImage *resultImage,NSError *error))completedBlock;

- (void)cancelAllImageGeneration;

@end
