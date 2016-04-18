//
//  ZQFVLCPlayerViewController.m
//  ZQFVLCMoviePlayer
//
//  Created by zqf on 16/4/11.
//  Copyright © 2016年 zengqingfu. All rights reserved.
//

#import "ZQFVLCPlayerViewController.h"
#import <MobileVLCKit/MobileVLCKit.h>
#import <MediaPlayer/MediaPlayer.h>
@interface ZQFVLCPlayerViewController ()<VLCMediaPlayerDelegate>

@property (nonatomic, strong)VLCMediaPlayer *mediaplayer;

//-------------------top-------------------
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewHeightConstraint;
@property (weak, nonatomic) IBOutlet UILabel *movTitleLabel;
@property (weak, nonatomic) IBOutlet UILabel *batteryLevelLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (assign)BOOL batteryMonitoringEnabled;
//-------------------play-------------------
@property (weak, nonatomic) IBOutlet UIView *playerView;

//-------------------state-------------------
@property (weak, nonatomic) IBOutlet UIButton *playButton;
@property (weak, nonatomic) IBOutlet UIView *fastStateView;
@property (weak, nonatomic) IBOutlet UIImageView *fastImageView;
@property (weak, nonatomic) IBOutlet UILabel *fastProgressLabel;
@property (weak, nonatomic) IBOutlet UILabel *fastTotalLabel;

@property (weak, nonatomic) IBOutlet UILabel *tipsLabel;
@property (weak, nonatomic) IBOutlet UILabel *playerStateLabel;


//-------------------bottom-------------------
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseButton;
@property (weak, nonatomic) IBOutlet UILabel *playerCurrentTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *playerTotalTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *playerSlider;
@property (weak, nonatomic) IBOutlet UIButton *zoomButton;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bottomBottomConstraint;


//------config----------
@property (assign)BOOL isEnteredFlag;
@property (assign)BOOL isToolViewHidden;
@property (assign)BOOL isSliderDragging;
@property (assign)BOOL isTransformed;
@property (nonatomic ,assign)NSInteger totalTime;

@property (nonatomic, assign)CGPoint beginPoint;//开始触摸下去的点
@property (assign)NSInteger positionWhenTouched;
@property (assign)NSInteger positionWhenTouchEnd;
@property (nonatomic, assign)BOOL isQuickPlay;//指示手势是否快进或者快退

@end

@implementation ZQFVLCPlayerViewController
- (void)dealloc {
    NSLog(@"%s", __FUNCTION__);
    if (_mediaplayer) {
        if (_mediaplayer.media)
            [_mediaplayer stop];
        if (_mediaplayer)
            _mediaplayer = nil;
    }
}

- (instancetype)initWithMediaURL:( NSURL *)mediaURL mediaName:(NSString *)mediaName {
    self = [super init];
    if (self) {
        _mediaURL = [mediaURL copy];
        _mediaName = [mediaName copy];
        _batteryMonitoringEnabled = [[UIDevice currentDevice] isBatteryMonitoringEnabled];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.movTitleLabel.text = _mediaName;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (!_isEnteredFlag) {
        [self setupMoviePlayer];
        _isEnteredFlag = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIDevice currentDevice] setBatteryMonitoringEnabled:_batteryMonitoringEnabled];
    if (_mediaplayer) {
        if (_mediaplayer.media)
            [_mediaplayer stop];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

//配置播放器
- (void)setupMoviePlayer{
    _mediaplayer = [[VLCMediaPlayer alloc] init];
    _mediaplayer.delegate = self;
    _mediaplayer.drawable = self.playerView;
    
    _mediaplayer.media = [VLCMedia mediaWithURL:_mediaURL];
    [_mediaplayer play];
}

//播放或者暂停
- (IBAction)playOrPauseAction:(id)sender {
    if (_mediaplayer.isPlaying) {
        [_mediaplayer pause];
        _playButton.hidden = NO;
    }
    else {
        [_mediaplayer play];
        _playButton.hidden = YES;
    }
}

//==========================slider==============================
- (IBAction)sliderDragInsideAction:(id)sender {
    CGFloat progressValue = _playerSlider.value;
    NSInteger value = self.totalTime * progressValue;
    VLCTime *vlcTime = [VLCTime timeWithInt:(int)value];
    VLCTime *vlcTotalTime = [VLCTime timeWithInt:(int)self.totalTime];
    _fastProgressLabel.text = vlcTime.stringValue;
    _fastTotalLabel.text = vlcTotalTime.stringValue;
    
    if ([vlcTime compare:_mediaplayer.time] == NSOrderedAscending) {
        _fastImageView.highlighted = YES;
    } else {
        _fastImageView.highlighted = NO;
    }
}

- (IBAction)sliderTouchUpInsideAction:(id)sender {
    _fastStateView.hidden = YES;
    _isSliderDragging = NO;
    _mediaplayer.position = _playerSlider.value;
}

- (IBAction)sliderTouchUpOutsideAction:(id)sender {
    static NSString *tipsString = @"操作无效";
    [self tipsLabelShowString:tipsString];
    _fastStateView.hidden = YES;
    _isSliderDragging = NO;
}

- (IBAction)sliderTouchDownAction:(id)sender {
    static NSString *tipsString = @"请拖动";
    [self tipsLabelShowString:tipsString];
    _fastStateView.hidden = NO;
    _isSliderDragging = YES;
}

- (IBAction)sliderTouchCancelAction:(id)sender {
    _fastStateView.hidden = YES;
    _isSliderDragging = NO;
}

- (void)tipsLabelShowString:(NSString *)str {
    _tipsLabel.text = str;
    _tipsLabel.alpha = 1.0;
    [UIView animateWithDuration:2 animations:^{
        _tipsLabel.alpha = 0;
    }];
}

//关闭播放器
- (IBAction)closePlayerVCAction:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//显示当前的时间
- (void)setupCurrentTime {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HH:mm"];
    NSDate *currentDate = [NSDate date];
    NSString *currentDateTimeString = [formatter stringFromDate:currentDate];
    _currentTimeLabel.text = currentDateTimeString;
    _currentTimeLabel.hidden = NO;
}

//显示当前的电量
- (void)setupBatteryLevel {
    UIDevice *currentDevice = [UIDevice currentDevice];
    [currentDevice setBatteryMonitoringEnabled:YES];
    if (currentDevice.batteryState != UIDeviceBatteryStateUnknown) {
        self.batteryLevelLabel.hidden = NO;
        CGFloat batteryLevel = [currentDevice batteryLevel];
        NSString *levelString = [NSString stringWithFormat:@"%ld%%", (NSInteger)(batteryLevel * 100)];
        _batteryLevelLabel.text = levelString;
    } else {
        self.batteryLevelLabel.hidden = YES;
    }
}

//播放器view点击手势
- (IBAction)tapAction:(id)sender {
    
    CGFloat topConstraint = 0;
    CGFloat bottomConstraint = 0;
    
    if (_isToolViewHidden) {
        if (_isTransformed) {
            topConstraint = -20;
            [self setupBatteryLevel];
            [self setupCurrentTime];
        } else {
            _currentTimeLabel.hidden = YES;
            _batteryLevelLabel.hidden = YES;
        }
        _isToolViewHidden = NO;
    } else {
        topConstraint = -64;
        bottomConstraint = -44;
        _isToolViewHidden = YES;
    }
    
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:0.5 animations:^{
        _topViewTopConstraint.constant = topConstraint;
        _bottomBottomConstraint.constant = bottomConstraint;
        [self.view layoutIfNeeded];
    }];
}


//隐藏状态栏
- (BOOL)prefersStatusBarHidden NS_AVAILABLE_IOS(7_0){
    return _isTransformed;
}
//锁定屏幕
- (UIInterfaceOrientationMask)supportedInterfaceOrientations NS_AVAILABLE_IOS(6_0){
    return UIInterfaceOrientationMaskPortrait;
}

#pragma mark - delegate
//接受状态改变通知
- (void)mediaPlayerStateChanged:(NSNotification *)aNotification{
    VLCMediaPlayerState currentState = _mediaplayer.state;
    NSLog(@"状态：%ld", currentState);
    switch (currentState) {
        case VLCMediaPlayerStateStopped: {//0
            _playOrPauseButton.selected = YES;
            _playerStateLabel.text = @"Stopped";
            _playerStateLabel.hidden = NO;
        }
            break;
        case VLCMediaPlayerStateOpening: {//1
            _playerStateLabel.text = @"Opening";
            _playerStateLabel.hidden = NO;
        }
            break;
        case VLCMediaPlayerStateBuffering: {//2
            _playerStateLabel.text = @"正在缓冲";
            _playerStateLabel.hidden = NO;
        }
            break;
        case VLCMediaPlayerStateEnded: {//3
            _playOrPauseButton.selected = YES;
            _playerStateLabel.text = @"The End";
            _playerStateLabel.hidden = NO;
        }
            break;
        case VLCMediaPlayerStateError: {//4
            _playOrPauseButton.selected = YES;
            _playerStateLabel.text = @"Error";
            _playerStateLabel.hidden = NO;
        }
            break;
        case VLCMediaPlayerStatePlaying: {//5
            _playerStateLabel.hidden = YES;
            _playOrPauseButton.selected = NO;
        }
            break;
        case VLCMediaPlayerStatePaused: {//6
            _playOrPauseButton.selected = YES;
        }
            break;
            
        default:
            break;
    }
}

//接受通知，当时间改变时
- (void)mediaPlayerTimeChanged:(NSNotification *)aNotification {
    _playerStateLabel.hidden = YES;
    if(!_isToolViewHidden){
        _playerCurrentTimeLabel.text = _mediaplayer.time.stringValue;
        _playerTotalTimeLabel.text = _mediaplayer.remainingTime.stringValue;
        if (!_isSliderDragging) {
            [_playerSlider setValue:_mediaplayer.position animated:YES];
        }
    }
}

- (NSInteger)totalTime{
    if (_totalTime <= 0) {
        _totalTime =  _mediaplayer.media.length.numberValue.integerValue;
    }
    return _totalTime;
}


//横竖屏
- (IBAction)zoomAction:(id)sender {
    UIButton *button = sender;
    static CGFloat angle = 0;
    if (button.selected) {
        angle = 0;
        button.selected = NO;
        _isTransformed = NO;
    } else {
        UIDevice *device = [UIDevice currentDevice];
        if (device.orientation != UIDeviceOrientationLandscapeRight) {
            angle = M_PI/2;
        } else {
            angle = -M_PI/2;
        }
        button.selected = YES;
        _isTransformed = YES;
    }
    
    CGFloat screenHeight = self.view.bounds.size.height;
    CGFloat screenWidth = self.view.bounds.size.width;
    CGFloat constant = 0;
    if (_isTransformed) {
        constant = -20;
        
        [self setupBatteryLevel];
        [self setupCurrentTime];
        
    } else {
        constant = 0;
        _currentTimeLabel.hidden = YES;
        _batteryLevelLabel.hidden = YES;
    }
    [self.view layoutIfNeeded];
    [UIView animateWithDuration:0.2 animations:^{
        [self.view setTransform:CGAffineTransformMakeRotation(angle)];//旋转view
        self.view.bounds = CGRectMake(0, 0, screenHeight, screenWidth);//设置bounds
        _topViewTopConstraint.constant = constant;
        [self setNeedsStatusBarAppearanceUpdate];
        [self.view layoutIfNeeded];
    }];
}

//开始自定义手势

//开始touch
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event{
    UITouch *touch = [touches anyObject];
    _beginPoint = [touch  locationInView:self.playerView];
    _positionWhenTouched = _mediaplayer.time.numberValue.integerValue;
    _isQuickPlay = NO;
}

//开始移动手指
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
    UITouch *touch = [touches anyObject];
    CGPoint currPoint = [touch  locationInView:self.playerView];
    
    CGFloat horizontal = currPoint.x - _beginPoint.x;
    CGFloat vertical = currPoint.y - _beginPoint.y;
    
    if(fabs(vertical) < 30 && fabs(horizontal) < 30){
//        static NSString *tipsString = @"请滑动手指";
//        [self tipsLabelShowString:tipsString];
    }else if (fabs(vertical) < 30 && fabs(horizontal) > 30) {
        //水平滑动
        _isQuickPlay = YES;
        _fastStateView.hidden = NO;
        CGFloat subVolumeValue = (currPoint.x - _beginPoint.x) / 10.0;
        _positionWhenTouchEnd = _positionWhenTouched + subVolumeValue * 1000;
        if (_positionWhenTouchEnd < 0) {
            _positionWhenTouchEnd = 0;
        }
        
        if (subVolumeValue < 0) {
            _fastImageView.highlighted = YES;
        } else {
            _fastImageView.highlighted = NO;
        }
        
        VLCTime *vlcTime = [VLCTime timeWithInt:(int)_positionWhenTouchEnd];
        VLCTime *vlcTotalTime = [VLCTime timeWithInt:(int)self.totalTime];
        _fastProgressLabel.text = vlcTime.stringValue;
        _fastTotalLabel.text = vlcTotalTime.stringValue;
        _tipsLabel.hidden = NO;
        return;
    } else if (fabs(horizontal) < 30 && fabs(vertical) > 30){
        //竖直滑动，调节音量
        MPMusicPlayerController *volumeControl = [MPMusicPlayerController applicationMusicPlayer];
        CGPoint previousPoint = [touch previousLocationInView:self.playerView];
        CGFloat subVolumeValue = (previousPoint.y - currPoint.y) / 100.0;
        static CGFloat volumeValue = 0;
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
        //写在这个中间的代码,都不会被编译器提示-Wdeprecated-declarations类型的警告
        volumeValue = volumeControl.volume;
        volumeValue += subVolumeValue;
        if (volumeValue > 1) {
            volumeValue = 1.0;
        }
        
        if (volumeValue < 0) {
            volumeValue = 0.0;
        }
        volumeControl.volume = volumeValue;
#pragma clang diagnostic pop
        
        _isQuickPlay = NO;
        _fastStateView.hidden = YES;
        return;
    }else {
        _isQuickPlay = NO;
        _fastStateView.hidden = YES;
        static NSString *tipsString = @"无效动作";
        [self tipsLabelShowString:tipsString];
    }
}

//touch结束
-(void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if(_isQuickPlay) {
        VLCTime *time = [VLCTime timeWithInt:(int)_positionWhenTouchEnd];
        _mediaplayer.time = time;
    }
    _fastStateView.hidden = YES;
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
    _fastStateView.hidden = YES;
}

@end
