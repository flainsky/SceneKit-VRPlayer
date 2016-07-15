//
//  MFBaseMovieViewController.h
//  VRDemo
//
//  Created by flainsky on 16/6/30.
//  Copyright © 2016年 ME Studio. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MFBaseMovieViewController : UIViewController

//ex
//local:    [NSURL fileURLWithPath:path]
//online:   [NSURL URLWithString:@"http://pili-live-hls.ps.qiniucdn.com/NIU7PS/ziwutiandi-test.m3u8"]
- (id)initWithUrl:(NSURL *)playUrl;

@end
