#import "DLGUnityHooksView.h"
#import "MEAlert.h"
#import "../../il2cpp/DLGUnityHookManager.h"

static NSString *DLGUnityHookTypeLabel(DLGUnityHook *hook) {
    switch (hook.hookType) {
        case DLGUnityHookTypeForceTrue: return @"Return true";
        case DLGUnityHookTypeForceFalse: return @"Return false";
        case DLGUnityHookTypeForceZero: return @"Return 0";
        case DLGUnityHookTypeForce9999: return @"Return 9999";
        case DLGUnityHookTypeCallbackShortCircuit:
            return [NSString stringWithFormat:@"Call callback argument %d", hook.callbackParamIndex];
    }
    return @"Unknown";
}

@interface DLGUnityHooksView () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) UIView *containerView;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UILabel *emptyLabel;
@property (nonatomic) UIButton *removeAllButton;
@property (nonatomic) NSArray<DLGUnityHook *> *hooks;
@end

@implementation DLGUnityHooksView

- (instancetype)init {
    self = [super init];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.backgroundColor = [UIColor clearColor];
        self.hooks = @[];
        [self buildUI];
    }
    return self;
}

- (void)buildUI {
    UIView *background = [[UIView alloc] init];
    background.translatesAutoresizingMaskIntoConstraints = NO;
    background.backgroundColor = [UIColor colorWithWhite:0 alpha:0.8];
    [self addSubview:background];
    [NSLayoutConstraint activateConstraints:@[
        [background.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [background.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [background.topAnchor constraintEqualToAnchor:self.topAnchor],
        [background.bottomAnchor constraintEqualToAnchor:self.bottomAnchor]
    ]];
    [background addGestureRecognizer:[[UITapGestureRecognizer alloc]
        initWithTarget:self action:@selector(closeTapped:)]];

    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.98];
    container.layer.cornerRadius = 16;
    container.layer.shadowColor = UIColor.blackColor.CGColor;
    container.layer.shadowOffset = CGSizeMake(0, 8);
    container.layer.shadowRadius = 24;
    container.layer.shadowOpacity = 0.7;
    [self addSubview:container];
    self.containerView = container;

    [NSLayoutConstraint activateConstraints:@[
        [container.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [container.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [container.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:0.9],
        [container.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:0.82],
        [container.widthAnchor constraintLessThanOrEqualToConstant:600],
        [container.heightAnchor constraintLessThanOrEqualToConstant:700]
    ]];

    UILabel *title = [[UILabel alloc] init];
    title.translatesAutoresizingMaskIntoConstraints = NO;
    title.text = @"Unity Hooks";
    title.textColor = UIColor.whiteColor;
    title.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    title.textAlignment = NSTextAlignmentCenter;
    [container addSubview:title];

    UIButton *close = [UIButton buttonWithType:UIButtonTypeSystem];
    close.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        [close setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    } else {
        [close setTitle:@"✕" forState:UIControlStateNormal];
    }
    close.tintColor = UIColor.whiteColor;
    [close addTarget:self action:@selector(closeTapped:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:close];

    UIButton *removeAll = [UIButton buttonWithType:UIButtonTypeSystem];
    removeAll.translatesAutoresizingMaskIntoConstraints = NO;
    [removeAll setTitle:@"Remove All" forState:UIControlStateNormal];
    [removeAll setTitleColor:[UIColor colorWithRed:1 green:0.3 blue:0.3 alpha:1]
                    forState:UIControlStateNormal];
    removeAll.titleLabel.font = [UIFont systemFontOfSize:13 weight:UIFontWeightMedium];
    [removeAll addTarget:self action:@selector(removeAllTapped:) forControlEvents:UIControlEventTouchUpInside];
    [container addSubview:removeAll];
    self.removeAllButton = removeAll;

    UITableView *table = [[UITableView alloc] init];
    table.translatesAutoresizingMaskIntoConstraints = NO;
    table.delegate = self;
    table.dataSource = self;
    table.backgroundColor = UIColor.clearColor;
    table.separatorColor = [UIColor colorWithWhite:1 alpha:0.1];
    table.rowHeight = 58;
    [container addSubview:table];
    self.tableView = table;

    UILabel *empty = [[UILabel alloc] init];
    empty.translatesAutoresizingMaskIntoConstraints = NO;
    empty.text = @"No hooks installed.\n\nChoose a function in Unity Hax and tap Hook.";
    empty.textColor = [UIColor colorWithWhite:0.55 alpha:1];
    empty.font = [UIFont systemFontOfSize:14];
    empty.numberOfLines = 0;
    empty.textAlignment = NSTextAlignmentCenter;
    [container addSubview:empty];
    self.emptyLabel = empty;

    [NSLayoutConstraint activateConstraints:@[
        [title.topAnchor constraintEqualToAnchor:container.topAnchor constant:20],
        [title.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:80],
        [title.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-60],

        [removeAll.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:16],
        [removeAll.centerYAnchor constraintEqualToAnchor:title.centerYAnchor],

        [close.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-16],
        [close.centerYAnchor constraintEqualToAnchor:title.centerYAnchor],
        [close.widthAnchor constraintEqualToConstant:32],
        [close.heightAnchor constraintEqualToConstant:32],

        [table.topAnchor constraintEqualToAnchor:title.bottomAnchor constant:14],
        [table.leadingAnchor constraintEqualToAnchor:container.leadingAnchor],
        [table.trailingAnchor constraintEqualToAnchor:container.trailingAnchor],
        [table.bottomAnchor constraintEqualToAnchor:container.bottomAnchor],

        [empty.centerXAnchor constraintEqualToAnchor:container.centerXAnchor],
        [empty.centerYAnchor constraintEqualToAnchor:container.centerYAnchor],
        [empty.leadingAnchor constraintEqualToAnchor:container.leadingAnchor constant:32],
        [empty.trailingAnchor constraintEqualToAnchor:container.trailingAnchor constant:-32]
    ]];
}

- (void)reloadHooks {
    self.hooks = [[DLGUnityHookManager sharedManager] allHooks];
    BOOL empty = self.hooks.count == 0;
    self.emptyLabel.hidden = !empty;
    self.tableView.hidden = empty;
    self.removeAllButton.hidden = empty;
    [self.tableView reloadData];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.hooks.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *identifier = @"UnityHook";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:identifier];
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:identifier];
        cell.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.5];
        cell.textLabel.textColor = UIColor.whiteColor;
        cell.detailTextLabel.textColor = [UIColor colorWithRed:0.2 green:0.7 blue:1 alpha:1];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }

    DLGUnityHook *hook = self.hooks[indexPath.row];
    cell.textLabel.text = hook.methodName;
    cell.detailTextLabel.text = DLGUnityHookTypeLabel(hook);
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [self showActionsForHook:self.hooks[indexPath.row]];
}

- (UISwipeActionsConfiguration *)tableView:(UITableView *)tableView
  trailingSwipeActionsConfigurationForRowAtIndexPath:(NSIndexPath *)indexPath
    API_AVAILABLE(ios(11.0)) {
    DLGUnityHook *hook = self.hooks[indexPath.row];
    UIContextualAction *remove = [UIContextualAction
        contextualActionWithStyle:UIContextualActionStyleDestructive
                            title:@"Remove"
                          handler:^(UIContextualAction *action, UIView *view, void (^done)(BOOL)) {
        BOOL removed = [[DLGUnityHookManager sharedManager]
            removeHookForMethodPointer:hook.methodPointer];
        [self reloadHooks];
        done(removed);
    }];
    return [UISwipeActionsConfiguration configurationWithActions:@[remove]];
}

- (void)showActionsForHook:(DLGUnityHook *)hook {
    UIAlertController *alert = MECreateAlert(hook.rawMethodName,
                                             [NSString stringWithFormat:@"Class: %@\nCurrent hook: %@",
                                              hook.className, DLGUnityHookTypeLabel(hook)],
                                             nil,
                                             nil,
                                             @[@"Return True", @"Return False", @"Return 0",
                                               @"Return 9999", @"Remove Hook", @"Cancel"],
                                             ^(UIAlertController *controller, NSInteger index) {
        if (index >= 0 && index <= 3) {
            DLGUnityHookType types[] = {
                DLGUnityHookTypeForceTrue, DLGUnityHookTypeForceFalse,
                DLGUnityHookTypeForceZero, DLGUnityHookTypeForce9999
            };
            [[DLGUnityHookManager sharedManager] changeHookType:types[index]
                                            callbackParamIndex:hook.callbackParamIndex
                                              forMethodPointer:hook.methodPointer];
            [self reloadHooks];
        } else if (index == 4) {
            [[DLGUnityHookManager sharedManager] removeHookForMethodPointer:hook.methodPointer];
            [self reloadHooks];
        }
    });
    MEPresentAlert(alert, self, YES);
}

- (void)removeAllTapped:(id)sender {
    NSArray<DLGUnityHook *> *hooks = self.hooks;
    UIAlertController *alert = MECreateAlert(@"Remove All Hooks",
                                             [NSString stringWithFormat:@"Remove all %lu hooks?",
                                              (unsigned long)hooks.count],
                                             nil,
                                             nil,
                                             @[@"Remove All", @"Cancel"],
                                             ^(UIAlertController *controller, NSInteger index) {
        if (index != 0) return;
        for (DLGUnityHook *hook in hooks) {
            [[DLGUnityHookManager sharedManager] removeHookForMethodPointer:hook.methodPointer];
        }
        [self reloadHooks];
    });
    MEPresentAlert(alert, self, YES);
}

- (void)closeTapped:(id)sender {
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
    [self reloadHooks];

    if (animated) {
        self.alpha = 0;
        self.containerView.transform = CGAffineTransformMakeScale(0.85, 0.85);
        [UIView animateWithDuration:0.3 animations:^{
            self.alpha = 1;
            self.containerView.transform = CGAffineTransformIdentity;
        }];
    }
}

- (void)hideAnimated:(BOOL)animated {
    if (!animated) {
        [self removeFromSuperview];
        return;
    }
    [UIView animateWithDuration:0.2 animations:^{
        self.alpha = 0;
        self.containerView.transform = CGAffineTransformMakeScale(0.9, 0.9);
    } completion:^(BOOL finished) {
        [self removeFromSuperview];
    }];
}

@end
