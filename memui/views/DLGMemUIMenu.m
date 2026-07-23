#import "DLGMemUIMenu.h"

@interface DLGMemUIMenu ()

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UIView *menuContainer;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *btnMemoryEditor;
@property (nonatomic) UIButton *btnUnityHax;
#if !JAILED
@property (nonatomic) UIButton *btnUnityHooks;
#endif
@property (nonatomic) UIButton *btnSpeedHack;
@property (nonatomic) UIButton *btnCancel;

@end

@implementation DLGMemUIMenu

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initViews];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initViews];
    }
    return self;
}

- (void)initViews {
    self.backgroundColor = [UIColor clearColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;

    [self initBackgroundView];
    [self initMenuContainer];
    [self initTitleLabel];
    [self initButtons];
}

- (void)initBackgroundView {
    UIView *bg = [[UIView alloc] init];
    bg.translatesAutoresizingMaskIntoConstraints = NO;
    bg.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.6];
    [self addSubview:bg];

    [NSLayoutConstraint activateConstraints:@[
        [bg.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [bg.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [bg.topAnchor constraintEqualToAnchor:self.topAnchor],
        [bg.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];

    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onBackgroundTapped:)];
    [bg addGestureRecognizer:tap];

    self.backgroundView = bg;
}

- (void)initMenuContainer {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.95];
    container.layer.cornerRadius = 20;
    container.layer.shadowColor = [UIColor blackColor].CGColor;
    container.layer.shadowOffset = CGSizeMake(0, 4);
    container.layer.shadowRadius = 12;
    container.layer.shadowOpacity = 0.5;
    [self addSubview:container];

    [NSLayoutConstraint activateConstraints:@[
        [container.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [container.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [container.widthAnchor constraintEqualToConstant:280],
        [container.heightAnchor constraintEqualToConstant:
#if JAILED
         478
#else
         544
#endif
        ]
    ]];

    self.menuContainer = container;
}

- (void)initTitleLabel {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"memedit";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    label.textAlignment = NSTextAlignmentCenter;
    [self.menuContainer addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:self.menuContainer.topAnchor constant:24],
        [label.leadingAnchor constraintEqualToAnchor:self.menuContainer.leadingAnchor constant:20],
        [label.trailingAnchor constraintEqualToAnchor:self.menuContainer.trailingAnchor constant:-20]
    ]];

    self.titleLabel = label;
}

- (void)initButtons {
    UIButton *memBtn = [self createMenuButton:@"Memory Editor" icon:@"memorychip"];
    [memBtn addTarget:self action:@selector(onMemoryEditorTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.menuContainer addSubview:memBtn];
    self.btnMemoryEditor = memBtn;

    UIButton *unityHaxBtn = [self createMenuButton:@"Unity Hax" icon:@"cube"];
    [unityHaxBtn addTarget:self action:@selector(onUnityHaxTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.menuContainer addSubview:unityHaxBtn];
    self.btnUnityHax = unityHaxBtn;

#if !JAILED
    UIButton *unityHooksBtn = [self createMenuButton:@"Unity Hooks" icon:@"bolt.fill"];
    [unityHooksBtn addTarget:self action:@selector(onUnityHooksTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.menuContainer addSubview:unityHooksBtn];
    self.btnUnityHooks = unityHooksBtn;
#endif

    UIButton *speedHackBtn = [self createMenuButton:@"Speed Hack" icon:@"speedometer"];
    [speedHackBtn addTarget:self action:@selector(onSpeedHackTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.menuContainer addSubview:speedHackBtn];
    self.btnSpeedHack = speedHackBtn;

    UIButton *cancelBtn = [self createMenuButton:@"Cancel" icon:@"xmark"];
    cancelBtn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.8];
    [cancelBtn addTarget:self action:@selector(onCancelTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.menuContainer addSubview:cancelBtn];
    self.btnCancel = cancelBtn;

    [NSLayoutConstraint activateConstraints:@[
        [memBtn.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:20],
        [memBtn.leadingAnchor constraintEqualToAnchor:self.menuContainer.leadingAnchor constant:20],
        [memBtn.trailingAnchor constraintEqualToAnchor:self.menuContainer.trailingAnchor constant:-20],
        [memBtn.heightAnchor constraintEqualToConstant:54],

        [unityHaxBtn.topAnchor constraintEqualToAnchor:memBtn.bottomAnchor constant:12],
        [unityHaxBtn.leadingAnchor constraintEqualToAnchor:self.menuContainer.leadingAnchor constant:20],
        [unityHaxBtn.trailingAnchor constraintEqualToAnchor:self.menuContainer.trailingAnchor constant:-20],
        [unityHaxBtn.heightAnchor constraintEqualToConstant:54],

        [speedHackBtn.topAnchor constraintEqualToAnchor:
#if JAILED
         unityHaxBtn.bottomAnchor
#else
         unityHooksBtn.bottomAnchor
#endif
         constant:12],
        [speedHackBtn.leadingAnchor constraintEqualToAnchor:self.menuContainer.leadingAnchor constant:20],
        [speedHackBtn.trailingAnchor constraintEqualToAnchor:self.menuContainer.trailingAnchor constant:-20],
        [speedHackBtn.heightAnchor constraintEqualToConstant:54],

        [cancelBtn.topAnchor constraintEqualToAnchor:speedHackBtn.bottomAnchor constant:12],
        [cancelBtn.leadingAnchor constraintEqualToAnchor:self.menuContainer.leadingAnchor constant:20],
        [cancelBtn.trailingAnchor constraintEqualToAnchor:self.menuContainer.trailingAnchor constant:-20],
        [cancelBtn.heightAnchor constraintEqualToConstant:54]
    ]];

#if !JAILED
    [NSLayoutConstraint activateConstraints:@[
        [unityHooksBtn.topAnchor constraintEqualToAnchor:unityHaxBtn.bottomAnchor constant:12],
        [unityHooksBtn.leadingAnchor constraintEqualToAnchor:self.menuContainer.leadingAnchor constant:20],
        [unityHooksBtn.trailingAnchor constraintEqualToAnchor:self.menuContainer.trailingAnchor constant:-20],
        [unityHooksBtn.heightAnchor constraintEqualToConstant:54]
    ]];
#endif
}

- (UIButton *)createMenuButton:(NSString *)title icon:(NSString *)iconName {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;

    UIButtonConfiguration *configuration = [UIButtonConfiguration filledButtonConfiguration];
    configuration.title = title;
    configuration.image = [UIImage systemImageNamed:iconName];
    configuration.imagePadding = 8;
    configuration.baseForegroundColor = UIColor.whiteColor;
    configuration.baseBackgroundColor = [UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:0.9];
    configuration.cornerStyle = UIButtonConfigurationCornerStyleMedium;
    configuration.titleTextAttributesTransformer = ^NSDictionary<NSAttributedStringKey, id> *(NSDictionary<NSAttributedStringKey, id> *attributes) {
        NSMutableDictionary *updatedAttributes = [attributes mutableCopy];
        updatedAttributes[NSFontAttributeName] = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
        return updatedAttributes;
    };
    btn.configuration = configuration;

    return btn;
}


- (void)onMemoryEditorTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(DLGMemUIMenuDidSelectMemoryEditor:)]) {
        [self.delegate DLGMemUIMenuDidSelectMemoryEditor:self];
    }
    [self hideAnimated:YES];
}

- (void)onUnityHaxTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(DLGMemUIMenuDidSelectUnityHax:)]) {
        [self.delegate DLGMemUIMenuDidSelectUnityHax:self];
    }
    [self hideAnimated:YES];
}

- (void)onSpeedHackTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(DLGMemUIMenuDidSelectSpeedHack:)]) {
        [self.delegate DLGMemUIMenuDidSelectSpeedHack:self];
    }
    [self hideAnimated:YES];
}

#if !JAILED
- (void)onUnityHooksTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(DLGMemUIMenuDidSelectUnityHooks:)]) {
        [self.delegate DLGMemUIMenuDidSelectUnityHooks:self];
    }
    [self hideAnimated:YES];
}
#endif

- (void)onCancelTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(DLGMemUIMenuDidCancel:)]) {
        [self.delegate DLGMemUIMenuDidCancel:self];
    }
    [self hideAnimated:YES];
}

- (void)onBackgroundTapped:(id)sender {
    [self onCancelTapped:sender];
}


- (void)showInView:(UIView *)view animated:(BOOL)animated {
    if (!view) return;

    [view addSubview:self];

    [NSLayoutConstraint activateConstraints:@[
        [self.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [self.topAnchor constraintEqualToAnchor:view.topAnchor],
        [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor]
    ]];

    if (animated) {
        self.alpha = 0;
        self.menuContainer.transform = CGAffineTransformMakeScale(0.8, 0.8);

        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.8
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.alpha = 1;
            self.menuContainer.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)hideAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.2
                              delay:0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:^{
            self.alpha = 0;
            self.menuContainer.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    } else {
        [self removeFromSuperview];
    }
}

@end
