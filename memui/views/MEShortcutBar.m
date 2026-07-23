
#import "MEShortcutBar.h"
#import "MEAlert.h"
#import "MEStore.h"
#include "il2cpp_helper.h"

static const CGFloat kBarWidth    = 158.0;
static const CGFloat kPad         = 10.0;
static const CGFloat kHeaderH     = 26.0;
static const CGFloat kHeaderGap   = 8.0;
static const CGFloat kButtonH     = 38.0;
static const CGFloat kButtonGap   = 8.0;

@interface MEShortcutBar ()

@property (nonatomic) UILabel *headerLabel;
@property (nonatomic) UIView *header;
@property (nonatomic) NSMutableArray<UIButton *> *shortcutButtons;
@property (nonatomic) BOOL collapsed;
@property (nonatomic) CGPoint dragStartOrigin;

@end

@implementation MEShortcutBar


+ (void)installInWindow:(UIWindow *)window {
    if (!window) return;

    for (UIView *sub in window.subviews) {
        if ([sub isKindOfClass:[MEShortcutBar class]]) {
            return;
        }
    }

    MEShortcutBar *bar = [[MEShortcutBar alloc] init];
    [window addSubview:bar];

    CGRect screen = [UIScreen mainScreen].bounds;
    bar.frame = CGRectMake(CGRectGetWidth(screen) - kBarWidth - 8, 220, kBarWidth, kHeaderH + kPad * 2);
    [bar rebuild];
}


- (instancetype)init {
    self = [super initWithFrame:CGRectMake(0, 0, kBarWidth, kHeaderH + kPad * 2)];
    if (self) {
        _shortcutButtons = [NSMutableArray array];
        _collapsed = NO;
        self.translatesAutoresizingMaskIntoConstraints = YES;

        self.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.92];
        self.layer.cornerRadius = 14;
        self.layer.shadowColor = [UIColor blackColor].CGColor;
        self.layer.shadowOffset = CGSizeMake(0, 4);
        self.layer.shadowRadius = 12;
        self.layer.shadowOpacity = 0.5;

        [self initHeader];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onShortcutsChanged:)
                                                     name:MEStoreShortcutsChangedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)initHeader {
    UIView *header = [[UIView alloc] init];
    header.backgroundColor = [UIColor clearColor];
    [self addSubview:header];
    self.header = header;

    UILabel *label = [[UILabel alloc] init];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:13 weight:UIFontWeightSemibold];
    label.text = @"⚡ Shortcuts";
    [header addSubview:label];
    self.headerLabel = label;

    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(onHeaderPan:)];
    [header addGestureRecognizer:pan];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onHeaderTap:)];
    [header addGestureRecognizer:tap];
}


- (void)layoutSubviews {
    [super layoutSubviews];

    self.header.frame = CGRectMake(kPad, kPad, kBarWidth - kPad * 2, kHeaderH);
    self.headerLabel.frame = self.header.bounds;

    CGFloat y = kPad + kHeaderH + kHeaderGap;
    for (UIButton *btn in self.shortcutButtons) {
        btn.hidden = self.collapsed;
        if (!self.collapsed) {
            btn.frame = CGRectMake(kPad, y, kBarWidth - kPad * 2, kButtonH);
            y += kButtonH + kButtonGap;
        }
    }
}

- (CGFloat)expandedHeight {
    NSUInteger n = self.shortcutButtons.count;
    if (n == 0) return kHeaderH + kPad * 2;
    return kPad + kHeaderH + kHeaderGap + (n * kButtonH + (n - 1) * kButtonGap) + kPad;
}

- (void)resizeToFit {
    CGFloat h = self.collapsed ? (kHeaderH + kPad * 2) : [self expandedHeight];
    CGRect f = self.frame;

    CGRect screen = [UIScreen mainScreen].bounds;
    if (CGRectGetMaxY(CGRectMake(f.origin.x, f.origin.y, kBarWidth, h)) > CGRectGetHeight(screen)) {
        f.origin.y = MAX(0, CGRectGetHeight(screen) - h - 8);
    }
    f.size.width = kBarWidth;
    f.size.height = h;
    self.frame = f;
    [self setNeedsLayout];
}


- (void)rebuild {
    for (UIButton *btn in self.shortcutButtons) {
        [btn removeFromSuperview];
    }
    [self.shortcutButtons removeAllObjects];

    NSArray<MEShortcut *> *shortcuts = [[MEStore shared] shortcuts];

    if (shortcuts.count == 0) {
        self.hidden = YES;
        return;
    }
    self.hidden = NO;

    self.headerLabel.text = self.collapsed ? @"⚡ Shortcuts ▸" : @"⚡ Shortcuts";

    [shortcuts enumerateObjectsUsingBlock:^(MEShortcut *sc, NSUInteger idx, BOOL *stop) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.tag = idx;
        btn.titleLabel.lineBreakMode = NSLineBreakByTruncatingTail;

        UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
        configuration.title = sc.title.length ? sc.title : sc.methodName;
        configuration.baseForegroundColor = UIColor.whiteColor;
        configuration.baseBackgroundColor = [UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:0.92];
        configuration.contentInsets = NSDirectionalEdgeInsetsMake(0, 8, 0, 8);
        configuration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
        configuration.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *attributes) {
            NSMutableDictionary *updatedAttributes = [attributes mutableCopy];
            updatedAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:14 weight:UIFontWeightSemibold];
            return updatedAttributes;
        };
        btn.configuration = configuration;
        [btn addTarget:self action:@selector(onShortcutTapped:) forControlEvents:UIControlEventTouchUpInside];

        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(onShortcutLongPress:)];
        lp.minimumPressDuration = 0.5;
        [btn addGestureRecognizer:lp];

        [self addSubview:btn];
        [self.shortcutButtons addObject:btn];
    }];

    [self resizeToFit];
}

- (void)onShortcutsChanged:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self rebuild];
    });
}


- (void)onHeaderTap:(UITapGestureRecognizer *)tap {
    self.collapsed = !self.collapsed;
    self.headerLabel.text = self.collapsed ? @"⚡ Shortcuts ▸" : @"⚡ Shortcuts";
    [UIView animateWithDuration:0.2 animations:^{
        [self resizeToFit];
        [self layoutIfNeeded];
    }];
}

- (void)onHeaderPan:(UIPanGestureRecognizer *)pan {
    UIView *parent = self.superview;
    if (!parent) return;

    if (pan.state == UIGestureRecognizerStateBegan) {
        self.dragStartOrigin = self.frame.origin;
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        CGPoint t = [pan translationInView:parent];
        CGRect f = self.frame;
        f.origin.x = self.dragStartOrigin.x + t.x;
        f.origin.y = self.dragStartOrigin.y + t.y;
        self.frame = f;
    } else if (pan.state == UIGestureRecognizerStateEnded ||
               pan.state == UIGestureRecognizerStateCancelled) {
        CGRect screen = [UIScreen mainScreen].bounds;
        CGRect f = self.frame;
        f.origin.x = MAX(0, MIN(f.origin.x, CGRectGetWidth(screen) - CGRectGetWidth(f)));
        f.origin.y = MAX(0, MIN(f.origin.y, CGRectGetHeight(screen) - CGRectGetHeight(f)));
        [UIView animateWithDuration:0.15 animations:^{ self.frame = f; }];
    }
}


- (MEShortcut *)shortcutForButton:(id)sender {
    NSInteger idx = -1;
    if ([sender isKindOfClass:[UIButton class]]) {
        idx = [(UIButton *)sender tag];
    } else if ([sender isKindOfClass:[UIGestureRecognizer class]]) {
        idx = [(UIGestureRecognizer *)sender view].tag;
    }
    NSArray<MEShortcut *> *shortcuts = [[MEStore shared] shortcuts];
    if (idx < 0 || idx >= (NSInteger)shortcuts.count) return nil;
    return shortcuts[idx];
}

- (void)onShortcutTapped:(UIButton *)sender {
    MEShortcut *sc = [self shortcutForButton:sender];
    if (sc) [self invokeShortcut:sc];
}

- (void)onShortcutLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    NSInteger idx = gesture.view.tag;
    MEShortcut *sc = [self shortcutForButton:gesture];
    if (!sc) return;

    UIAlertController *alert = MECreateAlert(@"Remove Shortcut",
                                             [NSString stringWithFormat:@"Remove \"%@\"?", sc.title],
                                             nil,
                                             nil,
                                             @[@"Remove", @"Cancel"],
                                             ^(UIAlertController *controller, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [[MEStore shared] removeShortcutAtIndex:idx];
        }
    });
    MEPresentAlert(alert, self.window, YES);
}


- (void)invokeShortcut:(MEShortcut *)sc {
    if (!il2cpp_helper_init()) {
        [self toast:@"IL2CPP not ready"];
        return;
    }

    Il2CppClass *klass = il2cpp_find_class_by_full_name([sc.classFullName UTF8String]);
    if (!klass) {
        [self toast:[NSString stringWithFormat:@"Class not found:\n%@", sc.classFullName]];
        return;
    }

    const MethodInfo *method = il2cpp_find_method_by_name(klass, [sc.methodName UTF8String], (int)sc.paramCount);
    if (!method) {
        [self toast:[NSString stringWithFormat:@"Method not found:\n%@", sc.methodName]];
        return;
    }

    void *obj = NULL;
    if (!sc.isStatic) {
        Il2CppInstanceEnumResult *instances = il2cpp_find_instances(klass);
        if (instances && instances->instance_count > 0) {
            obj = instances->instances[0].instance;
        }
        if (instances) il2cpp_free_instance_enum_result(instances);
        if (!obj) {
            [self toast:[NSString stringWithFormat:@"%@: no live instance", sc.title]];
            return;
        }
    }

    NSInteger n = sc.params.count;
    const char **args = NULL;
    if (n > 0) {
        args = (const char **)malloc(sizeof(char *) * n);
        for (NSInteger i = 0; i < n; i++) {
            args[i] = [sc.params[i] UTF8String];
        }
    }

    char *result = il2cpp_invoke_method_with_args(method, obj, args, (int)n);
    if (args) free(args);

    NSString *resultStr = @"done";
    if (result) {
        NSString *s = [NSString stringWithUTF8String:result];
        if (s.length) resultStr = s;
        free(result);
    }

    [self toast:[NSString stringWithFormat:@"%@ → %@", sc.title, resultStr]];
}


- (void)toast:(NSString *)message {
    UIView *host = self.window;
    if (!host) return;

    UILabel *toast = [[UILabel alloc] init];
    toast.text = message;
    toast.numberOfLines = 0;
    toast.textAlignment = NSTextAlignmentCenter;
    toast.textColor = [UIColor whiteColor];
    toast.font = [UIFont systemFontOfSize:14 weight:UIFontWeightMedium];
    toast.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.85];
    toast.layer.cornerRadius = 12;
    toast.clipsToBounds = YES;

    CGFloat maxWidth = MIN(320, CGRectGetWidth(host.bounds) - 40);
    CGSize size = [toast sizeThatFits:CGSizeMake(maxWidth - 24, CGFLOAT_MAX)];
    CGFloat w = MIN(maxWidth, size.width + 24);
    CGFloat h = size.height + 20;
    toast.frame = CGRectMake((CGRectGetWidth(host.bounds) - w) / 2,
                             CGRectGetHeight(host.bounds) - h - 120,
                             w, h);
    toast.alpha = 0;
    [host addSubview:toast];

    [UIView animateWithDuration:0.2 animations:^{
        toast.alpha = 1;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:0.3 delay:1.6 options:0 animations:^{
            toast.alpha = 0;
        } completion:^(BOOL finished2) {
            [toast removeFromSuperview];
        }];
    }];
}

@end
