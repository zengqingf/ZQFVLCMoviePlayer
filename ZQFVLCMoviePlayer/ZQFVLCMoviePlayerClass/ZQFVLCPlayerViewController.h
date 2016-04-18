//
//  ZQFVLCPlayerViewController.h
//  ZQFVLCMoviePlayer
//
//  Created by zqf on 16/4/11.
//  Copyright © 2016年 zengqingfu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ZQFVLCPlayerViewController : UIViewController
@property (copy, readonly)NSURL *mediaURL;
@property (copy, readonly)NSString *mediaName;

- (instancetype)initWithMediaURL:( NSURL *)mediaURL mediaName:( NSString *)mediaName;
@end
