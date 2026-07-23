
#import "MESpeedHackPanel.h"
#import "MEStore.h"
#import "MESpeedHack.h"

static const double kMinMultiplier = 0.1;
static const double kMaxMultiplier = 10.0;

@interface MESpeedHackPanel ()

@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UIView *container;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *closeButton;
@property (nonatomic) UILabel *valueLabel;
@property (nonatomic) UISwitch *enableSwitch;
@property (nonatomic) UISlider *slider;
@property (nonatomic) NSArray<NSNumber *> *presets;
@property (nonatomic) NSArray<UIButton *> *presetButtons;

@end

@implementation MESpeedHackPanel

- (instancetype)init {
    self = [super init];
    if (self) {
        _presets = @[@0.25, @0.5, @1.0, @2.0, @3.0, @5.0];
        [self initViews];
        [self syncFromState];
    }
    return self;
}

- (void)initViews {
    self.backgroundColor = [UIColor clearColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;

    [self initBackground];
    [self initContainer];
    [self initTitleBar];
    [self initValueLabel];
    [self initEnableRow];
    [self initPresets];
    [self initSlider];
}

- (void)initBackground {
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

- (void)initContainer {
    UIView *c = [[UIView alloc] init];
    c.translatesAutoresizingMaskIntoConstraints = NO;
    c.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.96];
    c.layer.cornerRadius = 20;
    c.layer.shadowColor = [UIColor blackColor].CGColor;
    c.layer.shadowOffset = CGSizeMake(0, 6);
    c.layer.shadowRadius = 16;
    c.layer.shadowOpacity = 0.5;
    [self addSubview:c];
    [NSLayoutConstraint activateConstraints:@[
        [c.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [c.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [c.widthAnchor constraintEqualToConstant:300]
    ]];
    self.container = c;
}

- (void)initTitleBar {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"Speed Hack";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    label.textAlignment = NSTextAlignmentCenter;
    [self.container addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:self.container.topAnchor constant:20],
        [label.leadingAnchor constraintEqualToAnchor:self.container.leadingAnchor constant:50],
        [label.trailingAnchor constraintEqualToAnchor:self.container.trailingAnchor constant:-50]
    ]];
    self.titleLabel = label;

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        [close setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    } else {
        [close setTitle:@"✕" forState:UIControlStateNormal];
    }
    close.tintColor = [UIColor whiteColor];
    [close addTarget:self action:@selector(onCloseTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.container addSubview:close];
    [NSLayoutConstraint activateConstraints:@[
        [close.trailingAnchor constraintEqualToAnchor:self.container.trailingAnchor constant:-16],
        [close.centerYAnchor constraintEqualToAnchor:label.centerYAnchor],
        [close.widthAnchor constraintEqualToConstant:30],
        [close.heightAnchor constraintEqualToConstant:30]
    ]];
    self.closeButton = close;
}

- (void)initValueLabel {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.textColor = [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1.0];
    label.font = [UIFont monospacedDigitSystemFontOfSize:40 weight:UIFontWeightBold];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"1.00×";
    [self.container addSubview:label];
    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:14],
        [label.leadingAnchor constraintEqualToAnchor:self.container.leadingAnchor constant:20],
        [label.trailingAnchor constraintEqualToAnchor:self.container.trailingAnchor constant:-20]
    ]];
    self.valueLabel = label;
}

- (void)initEnableRow {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"Enabled";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:17 weight:UIFontWeightSemibold];
    [self.container addSubview:label];

    UISwitch *sw = [[UISwitch alloc] init];
    sw.translatesAutoresizingMaskIntoConstraints = NO;
    sw.onTintColor = [UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0];
    [sw addTarget:self action:@selector(onEnableChanged:) forControlEvents:UIControlEventValueChanged];
    [self.container addSubview:sw];

    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:self.valueLabel.bottomAnchor constant:14],
        [label.leadingAnchor constraintEqualToAnchor:self.container.leadingAnchor constant:20],

        [sw.centerYAnchor constraintEqualToAnchor:label.centerYAnchor],
        [sw.trailingAnchor constraintEqualToAnchor:self.container.trailingAnchor constant:-20]
    ]];
    self.enableSwitch = sw;
}

- (void)initPresets {
    UIStackView *vstack = [[UIStackView alloc] init];
    vstack.translatesAutoresizingMaskIntoConstraints = NO;
    vstack.axis = UILayoutConstraintAxisVertical;
    vstack.distribution = UIStackViewDistributionFillEqually;
    vstack.spacing = 10;
    [self.container addSubview:vstack];

    NSMutableArray<UIButton *> *buttons = [NSMutableArray array];
    UIStackView *currentRow = nil;
    for (NSUInteger i = 0; i < self.presets.count; i++) {
        if (i % 3 == 0) {
            currentRow = [[UIStackView alloc] init];
            currentRow.axis = UILayoutConstraintAxisHorizontal;
            currentRow.distribution = UIStackViewDistributionFillEqually;
            currentRow.spacing = 10;
            [vstack addArrangedSubview:currentRow];
        }

        double value = self.presets[i].doubleValue;
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
        btn.tag = i;
        btn.backgroundColor = [UIColor colorWithWhite:0.2 alpha:0.9];
        btn.layer.cornerRadius = 10;
        [btn setTitle:[self labelForMultiplier:value] forState:UIControlStateNormal];
        [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        btn.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
        [btn addTarget:self action:@selector(onPresetTapped:) forControlEvents:UIControlEventTouchUpInside];
        [btn.heightAnchor constraintEqualToConstant:44].active = YES;
        [currentRow addArrangedSubview:btn];
        [buttons addObject:btn];
    }
    self.presetButtons = buttons;

    [NSLayoutConstraint activateConstraints:@[
        [vstack.topAnchor constraintEqualToAnchor:self.enableSwitch.bottomAnchor constant:18],
        [vstack.leadingAnchor constraintEqualToAnchor:self.container.leadingAnchor constant:20],
        [vstack.trailingAnchor constraintEqualToAnchor:self.container.trailingAnchor constant:-20]
    ]];

    vstack.tag = 999;
}

- (void)initSlider {
    UIView *vstack = [self.container viewWithTag:999];

    UISlider *slider = [[UISlider alloc] init];
    slider.translatesAutoresizingMaskIntoConstraints = NO;
    slider.minimumValue = (float)kMinMultiplier;
    slider.maximumValue = (float)kMaxMultiplier;
    slider.value = 1.0f;
    slider.minimumTrackTintColor = [UIColor colorWithRed:0.0 green:0.478 blue:1.0 alpha:1.0];
    [slider addTarget:self action:@selector(onSliderChanged:) forControlEvents:UIControlEventValueChanged];
    [self.container addSubview:slider];

    [NSLayoutConstraint activateConstraints:@[
        [slider.topAnchor constraintEqualToAnchor:vstack.bottomAnchor constant:18],
        [slider.leadingAnchor constraintEqualToAnchor:self.container.leadingAnchor constant:20],
        [slider.trailingAnchor constraintEqualToAnchor:self.container.trailingAnchor constant:-20],
        [slider.bottomAnchor constraintEqualToAnchor:self.container.bottomAnchor constant:-22]
    ]];
    self.slider = slider;
}


- (NSString *)labelForMultiplier:(double)m {
    if (m == (long)m) {
        return [NSString stringWithFormat:@"%ld×", (long)m];
    }
    return [NSString stringWithFormat:@"%g×", m];
}

- (void)syncFromState {
    double m = MESpeedHackGetMultiplier();
    BOOL enabled = MESpeedHackIsEnabled();

    self.enableSwitch.on = enabled;
    self.valueLabel.text = [NSString stringWithFormat:@"%.2f×", m];

    double clamped = MIN(MAX(m, kMinMultiplier), kMaxMultiplier);
    self.slider.value = (float)clamped;

    [self updateValueColorEnabled:enabled];
}

- (void)updateValueColorEnabled:(BOOL)enabled {
    self.valueLabel.textColor = enabled
        ? [UIColor colorWithRed:0.0 green:0.6 blue:1.0 alpha:1.0]
        : [UIColor colorWithWhite:0.5 alpha:1.0];
}

- (void)applyMultiplier:(double)m {
    self.valueLabel.text = [NSString stringWithFormat:@"%.2f×", m];

    double clamped = MIN(MAX(m, kMinMultiplier), kMaxMultiplier);
    if (fabs(self.slider.value - clamped) > 0.0001) {
        self.slider.value = (float)clamped;
    }

    MESpeedHackSetMultiplier(m);
    [MEStore shared].speedMultiplier = m;
}


- (void)onPresetTapped:(UIButton *)sender {
    double value = self.presets[sender.tag].doubleValue;
    [self applyMultiplier:value];
}

- (void)onSliderChanged:(UISlider *)sender {
    double v = round(sender.value / 0.05) * 0.05;
    [self applyMultiplier:v];
}

- (void)onEnableChanged:(UISwitch *)sender {
    MESpeedHackSetEnabled(sender.on);
    [MEStore shared].speedEnabled = sender.on;
    [self updateValueColorEnabled:sender.on];
}

- (void)onCloseTapped:(id)sender {
    [self hideAnimated:YES];
}

- (void)onBackgroundTapped:(id)sender {
    [self hideAnimated:YES];
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

    [self syncFromState];

    if (animated) {
        self.alpha = 0;
        self.container.transform = CGAffineTransformMakeScale(0.85, 0.85);
        [UIView animateWithDuration:0.3 delay:0 usingSpringWithDamping:0.8 initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut animations:^{
            self.alpha = 1;
            self.container.transform = CGAffineTransformIdentity;
        } completion:nil];
    }
}

- (void)hideAnimated:(BOOL)animated {
    if (animated) {
        [UIView animateWithDuration:0.2 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
            self.alpha = 0;
            self.container.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    } else {
        [self removeFromSuperview];
    }
}

@end
