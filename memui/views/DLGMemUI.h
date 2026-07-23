
#import <Foundation/Foundation.h>
#import "UIWindow+DLGMemUI.h"
#import "DLGMemUIViewDelegate.h"

@interface DLGMemUI : NSObject

+ (void)addDLGMemUIView:(id<DLGMemUIViewDelegate>)delegate;
+ (void)addDLGMemUIViewToWindow:(UIWindow *)window withDelegate:(id<DLGMemUIViewDelegate>)delegate;
+ (void)removeDLGMemUIView;

@end
