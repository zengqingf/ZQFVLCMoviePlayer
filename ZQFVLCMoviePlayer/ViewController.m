//
//  ViewController.m
//  ZQFVLCMoviePlayer
//
//  Created by zqf on 16/4/11.
//  Copyright © 2016年 zengqingfu. All rights reserved.
//

#import "ViewController.h"
#import "ZQFVLCPlayerViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startPlayAction:(id)sender {
    NSString *str = @"http://hc.yinyuetai.com/uploads/videos/common/280B015100F06F42002834D64B33F4D6.flv?sc=20c9f1802269ceda";
    ZQFVLCPlayerViewController *playerVC = [[ZQFVLCPlayerViewController alloc] initWithMediaURL:[NSURL URLWithString:str] mediaName:@"我的电影"];
    [self presentViewController:playerVC animated:YES completion:nil];
}



@end
