
#import "DLGMemUI.h"
#import "DLGMemUIView.h"
#import "MEShortcutBar.h"

static UIWindow *activeApplicationWindow(void)
{
    UIApplication *application = UIApplication.sharedApplication;
    for (UIScene *scene in application.connectedScenes) {
        if (![scene isKindOfClass:UIWindowScene.class]) {
            continue;
        }

        UIWindowScene *windowScene = (UIWindowScene *)scene;
        for (UIWindow *window in windowScene.windows) {
            if (window.isKeyWindow) {
                return window;
            }
        }
    }
    return nil;
}

@implementation DLGMemUI

+ (void)addDLGMemUIView:(id<DLGMemUIViewDelegate>)delegate {
    UIApplication *application = [UIApplication sharedApplication];
    if (application) {
        UIWindow *window = activeApplicationWindow();
        if (window) {
            [DLGMemUI addDLGMemUIViewToWindow:window withDelegate:delegate];
            return;
        }
    }

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [DLGMemUI addDLGMemUIView:delegate];
    });
}

+ (void)addDLGMemUIViewToWindow:(UIWindow *)window withDelegate:(id<DLGMemUIViewDelegate>)delegate{
    CGRect frame = CGRectMake(0, 100, DLG_DEBUG_CONSOLE_VIEW_SIZE, DLG_DEBUG_CONSOLE_VIEW_SIZE);
    DLGMemUIView *view = [DLGMemUIView instance];
    view.delegate = delegate;
    view.translatesAutoresizingMaskIntoConstraints = YES;
    view.autoresizingMask = UIViewAutoresizingNone;
    view.frame = frame;
    view.alpha = 1.0f;
    [window addSubview:view];
    [window setDLGMemUIView:view];

    NSArray *gestures = view.gestureRecognizers;
    if (gestures == nil || gestures.count == 0) {
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:window action:@selector(handleGesture:)];
        [view addGestureRecognizer:pan];

        UITapGestureRecognizer *tttap = [[UITapGestureRecognizer alloc] initWithTarget:window action:@selector(handleTTTapGesture:)];
        tttap.numberOfTapsRequired = 3;
        tttap.numberOfTouchesRequired = 3;
        [window addGestureRecognizer:tttap];
    }

    if ([delegate respondsToSelector:@selector(DLGMemUILaunched:)]) {
        [delegate DLGMemUILaunched:view];
    }

    [MEShortcutBar installInWindow:window];
}

+ (void)removeDLGMemUIView {
    DLGMemUIView *view = [DLGMemUIView instance];
    if (view.expanded) [view doCollapse];
    NSArray *gestures = view.gestureRecognizers;
    for (UIGestureRecognizer *gesture in gestures) {
        [view removeGestureRecognizer:gesture];
    }
    [view removeFromSuperview];
}

@end
