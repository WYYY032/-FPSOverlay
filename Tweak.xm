#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>

@interface FPSOverlayView : UILabel
@property(nonatomic, strong) CADisplayLink *displayLink;
@property(nonatomic, assign) CFTimeInterval lastTimestamp;
@property(nonatomic, assign) NSInteger frameCount;
@end

@implementation FPSOverlayView

- (instancetype)init {
    self = [super initWithFrame:CGRectMake(12, 90, 88, 30)];
    if (self) {
        self.text = @"FPS --";
        self.textColor = UIColor.whiteColor;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.72];
        self.font = [UIFont monospacedDigitSystemFontOfSize:13 weight:UIFontWeightSemibold];
        self.textAlignment = NSTextAlignmentCenter;
        self.layer.cornerRadius = 8;
        self.layer.masksToBounds = YES;
        self.userInteractionEnabled = NO;

        _lastTimestamp = 0;
        _frameCount = 0;
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(tick:)];
        if (@available(iOS 15.0, *)) {
            _displayLink.preferredFrameRateRange = CAFrameRateRangeMake(10, 60, 60);
        } else {
            _displayLink.preferredFramesPerSecond = 60;
        }
        [_displayLink addToRunLoop:NSRunLoop.mainRunLoop forMode:NSRunLoopCommonModes];
    }
    return self;
}

- (void)tick:(CADisplayLink *)link {
    if (self.lastTimestamp == 0) {
        self.lastTimestamp = link.timestamp;
        return;
    }
    self.frameCount++;
    CFTimeInterval elapsed = link.timestamp - self.lastTimestamp;
    if (elapsed >= 1.0) {
        NSInteger fps = (NSInteger)llround((double)self.frameCount / elapsed);
        self.text = [NSString stringWithFormat:@"FPS %ld", (long)fps];
        self.frameCount = 0;
        self.lastTimestamp = link.timestamp;
    }
}

- (void)dealloc {
    [_displayLink invalidate];
}
@end

static FPSOverlayView *gFPSView;

static UIWindow *GetKeyWindow(void) {
    UIWindow *keyWindow = nil;
    if (@available(iOS 13.0, *)) {
        for (UIScene *scene in UIApplication.sharedApplication.connectedScenes) {
            if (scene.activationState != UISceneActivationStateForegroundActive) continue;
            if (![scene isKindOfClass:[UIWindowScene class]]) continue;
            UIWindowScene *windowScene = (UIWindowScene *)scene;
            for (UIWindow *window in windowScene.windows) {
                if (window.isKeyWindow) {
                    keyWindow = window;
                    break;
                }
            }
            if (keyWindow) break;
            if (windowScene.windows.count > 0) {
                keyWindow = windowScene.windows.firstObject;
                break;
            }
        }
    }
    if (!keyWindow) {
        // 兼容旧系统兜底
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        keyWindow = UIApplication.sharedApplication.keyWindow;
#pragma clang diagnostic pop
    }
    return keyWindow;
}

%hook UIApplication
- (void)applicationDidBecomeActive:(UIApplication *)application {
    %orig;
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!gFPSView) {
            gFPSView = [[FPSOverlayView alloc] init];
        }
        UIWindow *window = GetKeyWindow();
        if (window && gFPSView.superview != window) {
            [gFPSView removeFromSuperview];
            [window addSubview:gFPSView];
            [window bringSubviewToFront:gFPSView];
        }
    });
}
%end

%ctor {
    @autoreleasepool {
        // 默认只注入 SpringBoard，如需其他 App 请修改 FPSOverlay.plist
    }
}
