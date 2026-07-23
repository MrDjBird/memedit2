#import "MEAlert.h"

static UIViewController *viewControllerForView(UIView *view)
{
    UIResponder *responder = view;
    while (responder) {
        if ([responder isKindOfClass:UIViewController.class]) {
            return (UIViewController *)responder;
        }
        responder = responder.nextResponder;
    }
    return view.window.rootViewController;
}

static UIViewController *topViewController(UIViewController *viewController)
{
    while (viewController.presentedViewController) {
        viewController = viewController.presentedViewController;
    }

    if ([viewController isKindOfClass:UINavigationController.class]) {
        return topViewController(((UINavigationController *)viewController).visibleViewController);
    }
    if ([viewController isKindOfClass:UITabBarController.class]) {
        return topViewController(((UITabBarController *)viewController).selectedViewController);
    }
    return viewController;
}

UIAlertController *MECreateAlert(NSString *title,
                                 NSString *message,
                                 NSArray<NSString *> *placeholders,
                                 NSArray<NSNumber *> *keyboardTypes,
                                 NSArray<NSString *> *buttonTitles,
                                 MEAlertHandler handler)
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];

    for (NSUInteger index = 0; index < placeholders.count; index++) {
        [alert addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = placeholders[index];
            textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
            textField.autocorrectionType = UITextAutocorrectionTypeNo;
            if (index < keyboardTypes.count) {
                textField.keyboardType = keyboardTypes[index].integerValue;
            }
        }];
    }

    NSArray<NSString *> *titles = buttonTitles.count ? buttonTitles : @[@"OK"];
    __weak UIAlertController *weakAlert = alert;
    [titles enumerateObjectsUsingBlock:^(NSString *buttonTitle, NSUInteger index, BOOL *stop) {
        UIAlertActionStyle style = UIAlertActionStyleDefault;
        if ([buttonTitle caseInsensitiveCompare:@"Cancel"] == NSOrderedSame) {
            style = UIAlertActionStyleCancel;
        } else if ([buttonTitle.lowercaseString hasPrefix:@"remove"]) {
            style = UIAlertActionStyleDestructive;
        }

        UIAlertAction *action = [UIAlertAction actionWithTitle:buttonTitle
                                                         style:style
                                                       handler:^(UIAlertAction *selectedAction) {
            if (handler) {
                handler(weakAlert, index);
            }
        }];
        [alert addAction:action];
    }];
    return alert;
}

void MEPresentAlert(UIAlertController *alert, UIView *view, BOOL animated)
{
    UIViewController *presenter = topViewController(viewControllerForView(view));
    if (!presenter || !alert) {
        return;
    }
    [presenter presentViewController:alert animated:animated completion:nil];
}
