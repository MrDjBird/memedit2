#import <UIKit/UIKit.h>

typedef void (^MEAlertHandler)(UIAlertController *alert, NSInteger buttonIndex);

UIAlertController *MECreateAlert(NSString *title,
                                 NSString *message,
                                 NSArray<NSString *> *placeholders,
                                 NSArray<NSNumber *> *keyboardTypes,
                                 NSArray<NSString *> *buttonTitles,
                                 MEAlertHandler handler);
void MEPresentAlert(UIAlertController *alert, UIView *view, BOOL animated);
