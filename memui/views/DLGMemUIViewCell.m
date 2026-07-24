
#import "DLGMemUIViewCell.h"

@interface DLGMemUIViewCell ()

@property (nonatomic) UILabel *lblAddress;
@property (nonatomic) UILabel *lblValue;
@property (nonatomic) UITextField *tfValue;
@property (nonatomic) UIButton *btnViewMemory;
@property (nonatomic) UIButton *checkbox;

@end

@implementation DLGMemUIViewCell

- (instancetype)init {
    self = [super init];
    if (self) {
        [self initAll];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initAll];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initAll];
    }
    return self;
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self initAll];
    }
    return self;
}

- (void)initAll {
    [self initUI];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    CGFloat horizontalMargin = 12;
    CGFloat verticalMargin = 4;
    self.contentView.frame = CGRectInset(self.bounds, horizontalMargin, verticalMargin);
    self.contentView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.contentView.bounds cornerRadius:12].CGPath;
}

- (void)initUI {
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.5];
    self.contentView.layer.cornerRadius = 12;
    self.contentView.layer.masksToBounds = NO;

    self.contentView.layer.shadowColor = [UIColor blackColor].CGColor;
    self.contentView.layer.shadowOffset = CGSizeMake(0, 4);
    self.contentView.layer.shadowRadius = 12;
    self.contentView.layer.shadowOpacity = 0.4;

    self.layer.masksToBounds = NO;
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    [self initAddressLabel];
    [self initValueLabel];
    [self initViewMemoryButton];
    [self initValueInput];
    [self initCheckbox];

    UIView *hoverView = [[UIView alloc] init];
    hoverView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.15];
    hoverView.layer.cornerRadius = 12;
    self.selectedBackgroundView = hoverView;
}

- (void)initAddressLabel {
    UILabel *lbl = [[UILabel alloc] init];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textAlignment = NSTextAlignmentLeft;
    lbl.textColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        lbl.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightMedium];
    } else {
        lbl.font = [UIFont systemFontOfSize:14];
    }
    [self.contentView addSubview:lbl];

    [NSLayoutConstraint activateConstraints:@[
        [lbl.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:16],
        [lbl.widthAnchor constraintEqualToConstant:128],
        [lbl.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [lbl.heightAnchor constraintEqualToConstant:20]
    ]];

    self.lblAddress = lbl;
}

- (void)initValueLabel {
    UILabel *lbl = [[UILabel alloc] init];
    lbl.translatesAutoresizingMaskIntoConstraints = NO;
    lbl.backgroundColor = [UIColor clearColor];
    lbl.textAlignment = NSTextAlignmentLeft;
    lbl.textColor = [UIColor whiteColor];
    lbl.text = @"Value";
    [self.contentView addSubview:lbl];

    NSDictionary *views = @{@"addr":self.lblAddress, @"lbl":lbl};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[addr]-8-[lbl]" options:0 metrics:nil views:views];
    [self.contentView addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[lbl]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:cv];

    lbl.userInteractionEnabled = YES;
    [lbl addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                                                      action:@selector(onValueTapped:)]];

    self.lblValue = lbl;
}

- (void)initViewMemoryButton {
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeSystem];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    [btn setTitle:@"V" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [btn addTarget:self action:@selector(onViewMemoryButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:btn];

    NSDictionary *views = @{@"btn":btn};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:[btn(32)]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[btn]|" options:0 metrics:nil views:views];
    [self.contentView addConstraints:cv];

    self.btnViewMemory = btn;
}

- (void)initValueInput {
    UITextField *tf = [[UITextField alloc] init];
    tf.translatesAutoresizingMaskIntoConstraints = NO;
    tf.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.2];
    tf.textColor = [UIColor whiteColor];
    if (@available(iOS 13.0, *)) {
        tf.font = [UIFont monospacedSystemFontOfSize:14 weight:UIFontWeightRegular];
    } else {
        tf.font = [UIFont systemFontOfSize:14];
    }
    tf.layer.cornerRadius = 6;
    tf.layer.borderWidth = 1;
    tf.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.1].CGColor;

    UIView *paddingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 8, 20)];
    tf.leftView = paddingView;
    tf.leftViewMode = UITextFieldViewModeAlways;
    tf.returnKeyType = UIReturnKeyDone;

    UIToolbar *toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, 0, 44)];
    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *done = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                             target:self
                             action:@selector(onValueDoneTapped:)];
    toolbar.items = @[flexibleSpace, done];
    tf.inputAccessoryView = toolbar;

    [self.contentView addSubview:tf];

    [NSLayoutConstraint activateConstraints:@[
        [tf.leadingAnchor constraintEqualToAnchor:self.lblAddress.trailingAnchor constant:8],
        [tf.trailingAnchor constraintEqualToAnchor:self.btnViewMemory.leadingAnchor constant:-8],
        [tf.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
        [tf.heightAnchor constraintEqualToConstant:32]
    ]];
    [tf addTarget:self action:@selector(onValueEditingEnded:)
        forControlEvents:UIControlEventEditingDidEnd];

    self.tfValue = tf;
}

- (void)initCheckbox {
    UIButton *cb = [UIButton buttonWithType:UIButtonTypeCustom];
    cb.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        [cb setImage:[UIImage systemImageNamed:@"circle"] forState:UIControlStateNormal];
        [cb setImage:[UIImage systemImageNamed:@"checkmark.circle.fill"] forState:UIControlStateSelected];
    } else {
        [cb setTitle:@"☐" forState:UIControlStateNormal];
        [cb setTitle:@"☑︎" forState:UIControlStateSelected];
        [cb setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        [cb setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
    }
    [cb addTarget:self action:@selector(onCheckboxTapped:) forControlEvents:UIControlEventTouchUpInside];
    cb.hidden = YES;
    [self.contentView addSubview:cb];
    NSDictionary *views = @{@"cb":cb};
    NSArray *ch = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|-4-[cb(24)]" options:0 metrics:nil views:views];
    [self.contentView addConstraints:ch];
    NSArray *cv = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[cb(24)]" options:0 metrics:nil views:views];
    [self.contentView addConstraints:cv];
    self.checkbox = cb;
}

- (void)setAddress:(NSString *)address {
    _address = address;
    self.lblAddress.text = address;
}

- (void)setValue:(NSString *)value {
    _value = value;
    self.lblValue.text = value;
    self.tfValue.text = value;
}

- (void)setModifying:(BOOL)modifying {
    _modifying = modifying;
    self.tfValue.text = self.value;
    self.lblValue.hidden = modifying;
    self.tfValue.hidden = !modifying;
    if (modifying) {
        [self.tfValue becomeFirstResponder];
        [self.tfValue selectAll:nil];
    }
}

- (void)setTextFieldDelegate:(id<UITextFieldDelegate>)textFieldDelegate {
    _textFieldDelegate = textFieldDelegate;
    self.tfValue.delegate = textFieldDelegate;
}

- (void)setShowsCheckbox:(BOOL)show {
    self.checkbox.hidden = !show;
}

- (void)setCheckboxChecked:(BOOL)checked {
    self.checkbox.selected = checked;
}

- (void)onValueTapped:(id)sender {
    if (!self.modifying) {
        self.modifying = YES;
    }
}

- (void)onValueDoneTapped:(id)sender {
    [self.tfValue resignFirstResponder];
}

- (void)onValueEditingEnded:(UITextField *)textField {
    if (!self.modifying) return;

    NSString *text = textField.text;
    if (text.length > 0 && ![text isEqualToString:self.value]) {
        self.value = text;
        if ([self.delegate respondsToSelector:@selector(DLGMemUIViewCellModify:value:)]) {
            [self.delegate DLGMemUIViewCellModify:self.address value:text];
        }
    }
    self.modifying = NO;
}

- (void)onViewMemoryButtonTapped:(id)sender {
    if ([self.delegate respondsToSelector:@selector(DLGMemUIViewCellViewMemory:)]) {
        [self.delegate DLGMemUIViewCellViewMemory:self.address];
    }
}

- (void)onCheckboxTapped:(id)sender {
    self.checkbox.selected = !self.checkbox.selected;
    if (self.checkboxChanged) {
        self.checkboxChanged(self.checkbox.selected);
    }
}

@end
