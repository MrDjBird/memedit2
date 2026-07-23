#import "DLGUnityHaxView.h"
#import "MEAlert.h"
#import "../MEStore.h"
#import "../../RemoteLog.h"
#include "../../il2cpp/il2cpp_helper.h"
#if !JAILED
#import "../../il2cpp/DLGUnityHookManager.h"
#endif

#define UNITY_LOG(fmt, ...) RLog(@"[unity hax] " fmt, ##__VA_ARGS__)

typedef enum {
    UNITY_VIEW_MODE_CLASSES,
    UNITY_VIEW_MODE_GLOBAL_METHODS,
    UNITY_VIEW_MODE_METHODS,
    UNITY_VIEW_MODE_FIELDS,
    UNITY_VIEW_MODE_INSTANCES
} UnityViewMode;

@interface DLGUnityHaxView () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>

@property (nonatomic) UnityViewMode viewMode;
@property (nonatomic) UIView *backgroundView;
@property (nonatomic) UIView *containerView;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *btnClose;
@property (nonatomic) UIButton *btnBack;
@property (nonatomic) UISegmentedControl *viewModeControl;
@property (nonatomic) UISegmentedControl *instanceModeControl;
@property (nonatomic) UISearchBar *searchBar;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIActivityIndicatorView *loadingIndicator;

@property (nonatomic) Il2CppEnumResult *classResults;
@property (nonatomic) Il2CppMethodEnumResult *methodResults;
@property (nonatomic) Il2CppFieldEnumResult *fieldResults;
@property (nonatomic) Il2CppInstanceEnumResult *instanceResults;
@property (nonatomic) Il2CppClass *selectedClass;
@property (nonatomic) void *selectedInstance;
@property (nonatomic) dispatch_queue_t globalMethodSearchQueue;
@property (atomic) NSUInteger globalMethodSearchGeneration;

@end

@implementation DLGUnityHaxView

- (instancetype)init {
    UNITY_LOG(@"init called");
    self = [super init];
    if (self) {
        self.viewMode = UNITY_VIEW_MODE_CLASSES;
        self.classResults = NULL;
        self.methodResults = NULL;
        self.fieldResults = NULL;
        self.instanceResults = NULL;
        self.selectedClass = NULL;
        self.selectedInstance = NULL;
        self.globalMethodSearchQueue = dispatch_queue_create("com.mineek.memedit.il2cpp-method-search", DISPATCH_QUEUE_SERIAL);
        self.globalMethodSearchGeneration = 0;
        [self initViews];
    }
    return self;
}

- (void)dealloc {
    if (self.classResults) {
        il2cpp_free_enum_result(self.classResults);
    }
    if (self.methodResults) {
        il2cpp_free_method_enum_result(self.methodResults);
    }
    if (self.fieldResults) {
        il2cpp_free_field_enum_result(self.fieldResults);
    }
    if (self.instanceResults) {
        il2cpp_free_instance_enum_result(self.instanceResults);
    }
}

- (void)initViews {
    self.backgroundColor = [UIColor clearColor];
    self.translatesAutoresizingMaskIntoConstraints = NO;

    [self initBackgroundView];
    [self initContainerView];
    [self initTitleBar];
    [self initViewModeControl];
    [self initInstanceModeControl];
    [self initSearchBar];
    [self initTableView];
    [self initLoadingIndicator];
}

- (void)initBackgroundView {
    UIView *bg = [[UIView alloc] init];
    bg.translatesAutoresizingMaskIntoConstraints = NO;
    bg.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.8];
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

- (void)initContainerView {
    UIView *container = [[UIView alloc] init];
    container.translatesAutoresizingMaskIntoConstraints = NO;
    container.backgroundColor = [UIColor colorWithWhite:0.08 alpha:0.98];
    container.layer.cornerRadius = 16;
    container.layer.shadowColor = [UIColor blackColor].CGColor;
    container.layer.shadowOffset = CGSizeMake(0, 8);
    container.layer.shadowRadius = 24;
    container.layer.shadowOpacity = 0.7;
    [self addSubview:container];

    [NSLayoutConstraint activateConstraints:@[
        [container.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
        [container.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
        [container.leadingAnchor constraintGreaterThanOrEqualToAnchor:self.leadingAnchor constant:20],
        [container.trailingAnchor constraintLessThanOrEqualToAnchor:self.trailingAnchor constant:-20],
        [container.topAnchor constraintGreaterThanOrEqualToAnchor:self.topAnchor constant:40],
        [container.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor constant:-40],
        [container.widthAnchor constraintEqualToAnchor:self.widthAnchor multiplier:0.9 constant:0],
        [container.heightAnchor constraintEqualToAnchor:self.heightAnchor multiplier:0.85 constant:0]
    ]];

    NSLayoutConstraint *maxWidth = [container.widthAnchor constraintLessThanOrEqualToConstant:600];
    maxWidth.priority = UILayoutPriorityDefaultHigh;
    maxWidth.active = YES;

    NSLayoutConstraint *maxHeight = [container.heightAnchor constraintLessThanOrEqualToConstant:700];
    maxHeight.priority = UILayoutPriorityDefaultHigh;
    maxHeight.active = YES;

    self.containerView = container;
}

- (void)initTitleBar {
    UILabel *label = [[UILabel alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.text = @"Unity Hax";
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont systemFontOfSize:24 weight:UIFontWeightBold];
    label.textAlignment = NSTextAlignmentCenter;
    [self.containerView addSubview:label];

    [NSLayoutConstraint activateConstraints:@[
        [label.topAnchor constraintEqualToAnchor:self.containerView.topAnchor constant:20],
        [label.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:60],
        [label.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-60]
    ]];

    self.titleLabel = label;

    UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    closeBtn.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        [closeBtn setImage:[UIImage systemImageNamed:@"xmark.circle.fill"] forState:UIControlStateNormal];
    } else {
        [closeBtn setTitle:@"✕" forState:UIControlStateNormal];
    }
    closeBtn.tintColor = [UIColor whiteColor];
    [closeBtn addTarget:self action:@selector(onCloseButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:closeBtn];

    [NSLayoutConstraint activateConstraints:@[
        [closeBtn.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        [closeBtn.centerYAnchor constraintEqualToAnchor:label.centerYAnchor],
        [closeBtn.widthAnchor constraintEqualToConstant:32],
        [closeBtn.heightAnchor constraintEqualToConstant:32]
    ]];

    self.btnClose = closeBtn;

    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeSystem];
    backBtn.translatesAutoresizingMaskIntoConstraints = NO;
    if (@available(iOS 13.0, *)) {
        [backBtn setImage:[UIImage systemImageNamed:@"chevron.left.circle.fill"] forState:UIControlStateNormal];
    } else {
        [backBtn setTitle:@"←" forState:UIControlStateNormal];
    }
    backBtn.tintColor = [UIColor whiteColor];
    backBtn.hidden = YES;
    [backBtn addTarget:self action:@selector(onBackButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    [self.containerView addSubview:backBtn];

    [NSLayoutConstraint activateConstraints:@[
        [backBtn.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [backBtn.centerYAnchor constraintEqualToAnchor:label.centerYAnchor],
        [backBtn.widthAnchor constraintEqualToConstant:32],
        [backBtn.heightAnchor constraintEqualToConstant:32]
    ]];

    self.btnBack = backBtn;
}

- (void)initViewModeControl {
    UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:@[@"Classes", @"★ Favorites", @"Functions"]];
    control.translatesAutoresizingMaskIntoConstraints = NO;
    [control setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateNormal];
    [control setTitleTextAttributes:@{NSForegroundColorAttributeName:[UIColor whiteColor]} forState:UIControlStateSelected];
    control.selectedSegmentIndex = 0;
    [control addTarget:self action:@selector(onClassScopeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.containerView addSubview:control];

    [NSLayoutConstraint activateConstraints:@[
        [control.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:16],
        [control.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [control.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        [control.heightAnchor constraintEqualToConstant:32]
    ]];

    self.viewModeControl = control;
}

- (void)initInstanceModeControl {
    UISegmentedControl *control = [[UISegmentedControl alloc] initWithItems:@[@"Fields", @"Methods"]];
    control.translatesAutoresizingMaskIntoConstraints = NO;
    control.selectedSegmentIndex = 0;
    control.hidden = YES;
    [control addTarget:self action:@selector(onInstanceModeChanged:) forControlEvents:UIControlEventValueChanged];
    [self.containerView addSubview:control];

    [NSLayoutConstraint activateConstraints:@[
        [control.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:16],
        [control.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [control.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        [control.heightAnchor constraintEqualToConstant:32]
    ]];

    self.instanceModeControl = control;
}

- (void)initSearchBar {
    UISearchBar *searchBar = [[UISearchBar alloc] init];
    searchBar.translatesAutoresizingMaskIntoConstraints = NO;
    searchBar.placeholder = @"Search classes...";
    searchBar.delegate = self;
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.barTintColor = [UIColor colorWithWhite:0.15 alpha:1.0];
    [self.containerView addSubview:searchBar];

    [NSLayoutConstraint activateConstraints:@[
        [searchBar.topAnchor constraintEqualToAnchor:self.viewModeControl.bottomAnchor constant:8],
        [searchBar.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:12],
        [searchBar.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-12]
    ]];

    self.searchBar = searchBar;
}

- (void)initTableView {
    UITableView *tableView = [[UITableView alloc] init];
    tableView.translatesAutoresizingMaskIntoConstraints = NO;
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.backgroundColor = [UIColor clearColor];
    tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    tableView.separatorColor = [UIColor colorWithWhite:1.0 alpha:0.1];
    tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    [self.containerView addSubview:tableView];

    [NSLayoutConstraint activateConstraints:@[
        [tableView.topAnchor constraintEqualToAnchor:self.searchBar.bottomAnchor constant:8],
        [tableView.leadingAnchor constraintEqualToAnchor:self.containerView.leadingAnchor constant:20],
        [tableView.trailingAnchor constraintEqualToAnchor:self.containerView.trailingAnchor constant:-20],
        [tableView.bottomAnchor constraintEqualToAnchor:self.containerView.bottomAnchor constant:-20]
    ]];

    self.tableView = tableView;
}

- (void)initLoadingIndicator {
    UIActivityIndicatorView *indicator;
    if (@available(iOS 13.0, *)) {
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    } else {
        indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleLarge];
    }
    indicator.translatesAutoresizingMaskIntoConstraints = NO;
    indicator.color = [UIColor whiteColor];
    indicator.hidesWhenStopped = YES;
    [self.containerView addSubview:indicator];

    [NSLayoutConstraint activateConstraints:@[
        [indicator.centerXAnchor constraintEqualToAnchor:self.containerView.centerXAnchor],
        [indicator.centerYAnchor constraintEqualToAnchor:self.containerView.centerYAnchor]
    ]];

    self.loadingIndicator = indicator;
}


- (void)onCloseButtonTapped:(id)sender {
    [self hideAnimated:YES];
}

- (void)onBackButtonTapped:(id)sender {
    self.globalMethodSearchGeneration++;
    self.viewMode = UNITY_VIEW_MODE_CLASSES;
    self.selectedClass = NULL;
    self.selectedInstance = NULL;
    if (self.methodResults) {
        il2cpp_free_method_enum_result(self.methodResults);
        self.methodResults = NULL;
    }
    if (self.fieldResults) {
        il2cpp_free_field_enum_result(self.fieldResults);
        self.fieldResults = NULL;
    }
    self.btnBack.hidden = YES;
    self.instanceModeControl.hidden = YES;
    self.viewModeControl.hidden = NO;
    self.titleLabel.text = @"Unity Hax";
    self.searchBar.placeholder = @"Search classes...";

    [MEStore shared].lastClassFullName = nil;

    [self.tableView reloadData];
}

- (void)onBackgroundTapped:(id)sender {
    [self onCloseButtonTapped:sender];
}

- (void)onClassScopeChanged:(UISegmentedControl *)sender {
    self.globalMethodSearchGeneration++;
    if (sender.selectedSegmentIndex == 2) {
        self.viewMode = UNITY_VIEW_MODE_GLOBAL_METHODS;
        self.searchBar.placeholder = @"Search all functions by name...";
        [self reloadGlobalFunctionList];
    } else {
        self.viewMode = UNITY_VIEW_MODE_CLASSES;
        self.searchBar.placeholder = @"Search classes...";
        [self.loadingIndicator stopAnimating];
        self.tableView.hidden = NO;
        [self reloadClassList];
    }
}

- (void)reloadClassList {
    NSString *query = self.searchBar.text ?: @"";
    BOOL favoritesOnly = (self.viewModeControl.selectedSegmentIndex == 1);

    if (self.classResults) {
        il2cpp_free_enum_result(self.classResults);
        self.classResults = NULL;
    }

    if (favoritesOnly) {
        NSArray<NSDictionary *> *favs = [[MEStore shared] favoriteClasses];
        NSString *q = query.lowercaseString;
        NSMutableArray<NSString *> *names = [NSMutableArray array];
        for (NSDictionary *f in favs) {
            NSString *full = f[@"fullName"];
            if (full.length == 0) continue;
            if (q.length == 0 || [full.lowercaseString containsString:q]) {
                [names addObject:full];
            }
        }
        const char **cnames = NULL;
        if (names.count > 0) {
            cnames = (const char **)malloc(sizeof(char *) * names.count);
            for (NSUInteger i = 0; i < names.count; i++) {
                cnames[i] = [names[i] UTF8String];
            }
        }
        self.classResults = il2cpp_classes_from_names(cnames, (int)names.count);
        if (cnames) free(cnames);
    } else if (query.length == 0) {
        self.classResults = il2cpp_enumerate_classes();
    } else {
        self.classResults = il2cpp_search_classes([query UTF8String]);
    }

    [self.tableView reloadData];
}

- (void)reloadGlobalFunctionList {
    NSString *query = [self.searchBar.text stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSUInteger generation = ++self.globalMethodSearchGeneration;

    if (self.methodResults) {
        il2cpp_free_method_enum_result(self.methodResults);
        self.methodResults = NULL;
    }
    [self.tableView reloadData];

    if (query.length == 0) {
        [self.loadingIndicator stopAnimating];
        self.tableView.hidden = NO;
        return;
    }

    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;

    dispatch_async(self.globalMethodSearchQueue, ^{
        if (generation != self.globalMethodSearchGeneration) return;
        Il2CppMethodEnumResult *methods = il2cpp_search_all_methods([query UTF8String]);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (generation != self.globalMethodSearchGeneration ||
                self.viewMode != UNITY_VIEW_MODE_GLOBAL_METHODS) {
                if (methods) il2cpp_free_method_enum_result(methods);
                return;
            }

            self.methodResults = methods;
            [self.loadingIndicator stopAnimating];
            self.tableView.hidden = NO;
            [self.tableView reloadData];
        });
    });
}

- (void)onInstanceModeChanged:(UISegmentedControl *)sender {
    if (sender.selectedSegmentIndex == 0) {
        [self showFieldsForInstance:self.selectedInstance];
    } else {
        [self showMethodsForInstance:self.selectedInstance];
    }
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (self.viewMode == UNITY_VIEW_MODE_CLASSES) {
        return self.classResults ? self.classResults->class_count : 0;
    } else if (self.viewMode == UNITY_VIEW_MODE_METHODS ||
               self.viewMode == UNITY_VIEW_MODE_GLOBAL_METHODS) {
        return self.methodResults ? self.methodResults->method_count : 0;
    } else if (self.viewMode == UNITY_VIEW_MODE_FIELDS) {
        return self.fieldResults ? self.fieldResults->field_count : 0;
    } else if (self.viewMode == UNITY_VIEW_MODE_INSTANCES) {
        return self.instanceResults ? self.instanceResults->instance_count : 0;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"UnityHaxCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];

    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.backgroundColor = [UIColor colorWithWhite:0.1 alpha:0.5];
        cell.textLabel.textColor = [UIColor whiteColor];
        if (@available(iOS 13.0, *)) {
            cell.textLabel.font = [UIFont monospacedSystemFontOfSize:13 weight:UIFontWeightRegular];
        } else {
            cell.textLabel.font = [UIFont systemFontOfSize:13];
        }
        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
        cell.detailTextLabel.font = [UIFont systemFontOfSize:11];
        cell.selectionStyle = UITableViewCellSelectionStyleDefault;

        UIView *selectedBg = [[UIView alloc] init];
        selectedBg.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.1];
        cell.selectedBackgroundView = selectedBg;
    }

    if (self.viewMode == UNITY_VIEW_MODE_CLASSES) {
        if (self.classResults && indexPath.row < self.classResults->class_count) {
            Il2CppClassInfo info = self.classResults->classes[indexPath.row];
            NSString *name = [NSString stringWithUTF8String:info.name];
            NSString *fullName = [NSString stringWithUTF8String:info.full_name];
            BOOL favorited = [[MEStore shared] isClassFavorited:fullName];
            cell.textLabel.text = favorited ? [@"★ " stringByAppendingString:name] : name;
            if (strlen(info.namespace) > 0) {
                cell.detailTextLabel.text = [NSString stringWithUTF8String:info.namespace];
            } else {
                cell.detailTextLabel.text = @"(global)";
            }
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    } else if (self.viewMode == UNITY_VIEW_MODE_METHODS ||
               self.viewMode == UNITY_VIEW_MODE_GLOBAL_METHODS) {
        if (self.methodResults && indexPath.row < self.methodResults->method_count) {
            Il2CppMethodInfo info = self.methodResults->methods[indexPath.row];
            cell.textLabel.text = [NSString stringWithUTF8String:info.name];
            if (self.viewMode == UNITY_VIEW_MODE_GLOBAL_METHODS) {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%s • %s → %s",
                                             info.class_full_name,
                                             info.is_static ? "static" : "instance",
                                             info.return_type];
            } else {
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%s → %s",
                                             info.is_static ? "static" : "instance",
                                             info.return_type];
            }
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
        }
    } else if (self.viewMode == UNITY_VIEW_MODE_FIELDS) {
        if (self.fieldResults && indexPath.row < self.fieldResults->field_count) {
            Il2CppFieldInfo info = self.fieldResults->fields[indexPath.row];
            cell.textLabel.text = [NSString stringWithUTF8String:info.name];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%s%s",
                                         info.is_static ? "static " : "",
                                         info.type_name];
            cell.accessoryType = UITableViewCellAccessoryDetailButton;
        }
    } else if (self.viewMode == UNITY_VIEW_MODE_INSTANCES) {
        if (self.instanceResults && indexPath.row < self.instanceResults->instance_count) {
            Il2CppInstanceInfo info = self.instanceResults->instances[indexPath.row];
            cell.textLabel.text = [NSString stringWithFormat:@"Instance %ld", (long)indexPath.row];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"0x%lx", (unsigned long)info.instance];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }

    return cell;
}


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (self.viewMode == UNITY_VIEW_MODE_CLASSES) {
        if (self.classResults && indexPath.row < self.classResults->class_count) {
            Il2CppClassInfo info = self.classResults->classes[indexPath.row];
            [self showClassOptionsForClass:info.klass className:[NSString stringWithUTF8String:info.full_name]];
        }
    } else if (self.viewMode == UNITY_VIEW_MODE_METHODS ||
               self.viewMode == UNITY_VIEW_MODE_GLOBAL_METHODS) {
        if (self.methodResults && indexPath.row < self.methodResults->method_count) {
            Il2CppMethodInfo info = self.methodResults->methods[indexPath.row];
            if (self.viewMode == UNITY_VIEW_MODE_GLOBAL_METHODS) {
                self.selectedClass = info.klass;
                self.selectedInstance = NULL;
            }
            [self showMethodActionsForMethod:info];
        }
    } else if (self.viewMode == UNITY_VIEW_MODE_INSTANCES) {
        if (self.instanceResults && indexPath.row < self.instanceResults->instance_count) {
            Il2CppInstanceInfo info = self.instanceResults->instances[indexPath.row];
            [self showInstanceDetailsForInstance:info.instance];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    if (self.viewMode == UNITY_VIEW_MODE_METHODS ||
        self.viewMode == UNITY_VIEW_MODE_GLOBAL_METHODS) {
        if (self.methodResults && indexPath.row < self.methodResults->method_count) {
            Il2CppMethodInfo info = self.methodResults->methods[indexPath.row];
            [self showMethodDetails:info];
        }
    } else if (self.viewMode == UNITY_VIEW_MODE_FIELDS) {
        if (self.fieldResults && indexPath.row < self.fieldResults->field_count) {
            Il2CppFieldInfo info = self.fieldResults->fields[indexPath.row];
            [self showFieldDetails:info];
        }
    }
}


- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    [MEStore shared].lastSearchText = searchText;
    if (self.viewMode == UNITY_VIEW_MODE_CLASSES) {
        [self reloadClassList];
    } else if (self.viewMode == UNITY_VIEW_MODE_GLOBAL_METHODS) {
        [self reloadGlobalFunctionList];
    } else if (self.viewMode == UNITY_VIEW_MODE_METHODS && self.selectedClass) {
        if (self.methodResults) {
            il2cpp_free_method_enum_result(self.methodResults);
        }
        self.methodResults = searchText.length == 0
            ? il2cpp_enumerate_methods(self.selectedClass)
            : il2cpp_search_methods(self.selectedClass, [searchText UTF8String]);
        [self.tableView reloadData];
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    searchBar.text = @"";
    [MEStore shared].lastSearchText = nil;
    if (self.viewMode == UNITY_VIEW_MODE_CLASSES) {
        [self reloadClassList];
    } else if (self.viewMode == UNITY_VIEW_MODE_GLOBAL_METHODS) {
        [self reloadGlobalFunctionList];
    } else if (self.viewMode == UNITY_VIEW_MODE_METHODS && self.selectedClass) {
        if (self.methodResults) il2cpp_free_method_enum_result(self.methodResults);
        self.methodResults = il2cpp_enumerate_methods(self.selectedClass);
        [self.tableView reloadData];
    }
}


- (void)showMethodsForClass:(Il2CppClass *)klass className:(NSString *)className {
    self.globalMethodSearchGeneration++;
    self.selectedClass = klass;
    self.viewMode = UNITY_VIEW_MODE_METHODS;

    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Il2CppMethodEnumResult* methods = il2cpp_enumerate_methods(klass);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.methodResults) {
                il2cpp_free_method_enum_result(self.methodResults);
            }
            self.methodResults = methods;

            self.titleLabel.text = className;
            self.btnBack.hidden = NO;
            self.instanceModeControl.hidden = YES;
            self.viewModeControl.hidden = YES;
            self.searchBar.placeholder = @"Search methods...";

            [MEStore shared].lastClassFullName = className;
            [MEStore shared].lastSubPage = 0;

            [self.loadingIndicator stopAnimating];
            self.tableView.hidden = NO;
            [self.tableView reloadData];
        });
    });
}

- (void)showMethodDetails:(Il2CppMethodInfo)info {
    NSString *message = [NSString stringWithFormat:@"Signature:\n%s\n\nReturn Type: %s\nParameters: %d\nType: %s",
                         info.signature,
                         info.return_type,
                         info.param_count,
                         info.is_static ? "Static" : "Instance"];

    UIAlertController *alert = MECreateAlert(@"Method Details", message, nil, nil, @[@"OK"], nil);
    MEPresentAlert(alert, self, YES);
}

- (NSString *)fullNameForClass:(Il2CppClass *)klass {
    if (!klass) return @"";
    const char *cname = il2cpp_class_get_name(klass);
    const char *cns = il2cpp_class_get_namespace(klass);
    NSString *name = cname ? [NSString stringWithUTF8String:cname] : @"";
    NSString *ns = cns ? [NSString stringWithUTF8String:cns] : @"";
    if (ns.length > 0) return [NSString stringWithFormat:@"%@.%@", ns, name];
    return name;
}

- (void)showMethodActionsForMethod:(Il2CppMethodInfo)info {
    NSArray<NSString *> *buttonTitles;
    MEAlertHandler handler;
#if JAILED
    buttonTitles = @[@"Invoke Now", @"Save as Shortcut", @"Cancel"];
    handler = ^(UIAlertController *controller, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [self showInvokeOptionsForMethod:info];
        } else if (buttonIndex == 1) {
            [self saveShortcutForMethod:info];
        }
    };
#else
    void *methodPointer = info.method ? *(void **)info.method : NULL;
    __block BOOL alreadyHooked = NO;
    for (DLGUnityHook *hook in [[DLGUnityHookManager sharedManager] allHooks]) {
        if (hook.methodPointer == (intptr_t)methodPointer) {
            alreadyHooked = YES;
            break;
        }
    }

    buttonTitles = @[@"Invoke Now", @"Save as Shortcut",
                     alreadyHooked ? @"Remove Hook" : @"Hook",
                     @"Active Hooks", @"Cancel"];
    handler = ^(UIAlertController *controller, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [self showInvokeOptionsForMethod:info];
        } else if (buttonIndex == 1) {
            [self saveShortcutForMethod:info];
        } else if (buttonIndex == 2) {
            if (alreadyHooked) {
                [[DLGUnityHookManager sharedManager]
                    removeHookForMethodPointer:(intptr_t)methodPointer];
                [self showInfoMessage:[NSString stringWithFormat:
                    @"Hook removed from %s.", info.name]];
            } else {
                [self showHookMenuForMethod:info];
            }
        } else if (buttonIndex == 3) {
            [self showActiveHooks];
        }
    };
#endif
    UIAlertController *alert = MECreateAlert([NSString stringWithUTF8String:info.name],
                                             info.signature ? [NSString stringWithUTF8String:info.signature] : @"",
                                             nil,
                                             nil,
                                             buttonTitles,
                                             handler);
    MEPresentAlert(alert, self, YES);
}

#if !JAILED
- (void)showHookMenuForMethod:(Il2CppMethodInfo)info {
    NSMutableArray<NSString *> *buttons = [NSMutableArray arrayWithArray:@[
        @"Force Return True",
        @"Force Return False",
        @"Force Return 0",
        @"Force Return 9999"
    ]];
    NSMutableArray<NSNumber *> *callbackRegisters = [NSMutableArray array];

    int parameterCount = 0;
    Il2CppParamInfo *parameters = il2cpp_get_method_params(info.method, &parameterCount);
    int registerOffset = info.is_static ? 0 : 1;
    for (int index = 0; parameters && index < parameterCount; index++) {
        int registerIndex = index + registerOffset;
        if (registerIndex >= 8) break;
        if (parameters[index].type_enum != IL2CPP_TYPE_CLASS &&
            parameters[index].type_enum != IL2CPP_TYPE_OBJECT) continue;

        NSString *name = parameters[index].param_name &&
                         strlen(parameters[index].param_name) > 0
            ? [NSString stringWithUTF8String:parameters[index].param_name]
            : [NSString stringWithFormat:@"arg%d", index];
        [buttons addObject:[NSString stringWithFormat:@"Call %@ and Return", name]];
        [callbackRegisters addObject:@(registerIndex)];
    }
    if (parameters) il2cpp_free_param_info(parameters, parameterCount);
    [buttons addObject:@"Cancel"];

    UIAlertController *alert = MECreateAlert(@"Select Hook",
                                             [NSString stringWithFormat:@"Choose how to hook %s:", info.name],
                                             nil,
                                             nil,
                                             buttons,
                                             ^(UIAlertController *controller, NSInteger index) {
        if (index == (NSInteger)buttons.count - 1) return;

        DLGUnityHookType type;
        int callbackRegister = 0;
        if (index == 0) type = DLGUnityHookTypeForceTrue;
        else if (index == 1) type = DLGUnityHookTypeForceFalse;
        else if (index == 2) type = DLGUnityHookTypeForceZero;
        else if (index == 3) type = DLGUnityHookTypeForce9999;
        else {
            type = DLGUnityHookTypeCallbackShortCircuit;
            NSInteger callbackIndex = index - 4;
            if (callbackIndex < 0 || callbackIndex >= (NSInteger)callbackRegisters.count) return;
            callbackRegister = callbackRegisters[callbackIndex].intValue;
        }

        NSString *className = info.class_full_name
            ? [NSString stringWithUTF8String:info.class_full_name]
            : [self fullNameForClass:info.klass ?: self.selectedClass];
        BOOL installed = [[DLGUnityHookManager sharedManager]
            installHookForMethod:info.method
                       className:className
                      methodName:[NSString stringWithUTF8String:info.name]
                        hookType:type
              callbackParamIndex:callbackRegister];
        [self showInfoMessage:installed
            ? [NSString stringWithFormat:@"Hook installed on %s.", info.name]
            : @"Failed to install hook."];
    });
    MEPresentAlert(alert, self, YES);
}

- (void)showActiveHooks {
    NSArray<DLGUnityHook *> *hooks = [[DLGUnityHookManager sharedManager] allHooks];
    if (hooks.count == 0) {
        [self showInfoMessage:@"No active hooks."];
        return;
    }

    NSMutableString *message = [NSMutableString string];
    for (DLGUnityHook *hook in hooks) {
        NSString *type;
        switch (hook.hookType) {
            case DLGUnityHookTypeForceTrue: type = @"true"; break;
            case DLGUnityHookTypeForceFalse: type = @"false"; break;
            case DLGUnityHookTypeForceZero: type = @"0"; break;
            case DLGUnityHookTypeForce9999: type = @"9999"; break;
            case DLGUnityHookTypeCallbackShortCircuit:
                type = [NSString stringWithFormat:@"callback(x%d)", hook.callbackParamIndex];
                break;
        }
        [message appendFormat:@"• %@ → %@\n", hook.methodName, type];
    }

    UIAlertController *alert = MECreateAlert([NSString stringWithFormat:@"Active Hooks (%lu)",
                                              (unsigned long)hooks.count],
                                             message,
                                             nil,
                                             nil,
                                             @[@"Remove All", @"OK"],
                                             ^(UIAlertController *controller, NSInteger index) {
        if (index != 0) return;
        for (DLGUnityHook *hook in hooks) {
            [[DLGUnityHookManager sharedManager]
                removeHookForMethodPointer:hook.methodPointer];
        }
        [self showInfoMessage:@"All hooks removed."];
    });
    MEPresentAlert(alert, self, YES);
}
#endif

- (void)saveShortcutForMethod:(Il2CppMethodInfo)info {
    int param_count = 0;
    Il2CppParamInfo *params = il2cpp_get_method_params(info.method, &param_count);

    if (param_count == 0) {
        if (params) il2cpp_free_param_info(params, param_count);
        [self promptShortcutTitleForMethod:info paramValues:@[]];
        return;
    }

    NSMutableString *message = [NSMutableString stringWithString:@"Enter the argument values to save with this shortcut:\n\n"];
    NSMutableArray<NSString *> *placeholders = [NSMutableArray array];
    NSMutableArray *keyboardTypes = [NSMutableArray array];

    for (int i = 0; i < param_count; i++) {
        NSString *paramName = params[i].param_name && strlen(params[i].param_name) > 0
            ? [NSString stringWithUTF8String:params[i].param_name]
            : [NSString stringWithFormat:@"arg%d", i];
        [message appendFormat:@"%d. %s %@\n", i+1, params[i].type_name, paramName];

        NSString *placeholder = paramName;
        UIKeyboardType keyboardType = UIKeyboardTypeDefault;
        switch (params[i].type_enum) {
            case IL2CPP_TYPE_BOOLEAN:
                placeholder = [NSString stringWithFormat:@"%@ (true/false)", paramName];
                break;
            case IL2CPP_TYPE_I1:
            case IL2CPP_TYPE_I2:
            case IL2CPP_TYPE_I4:
            case IL2CPP_TYPE_I8:
            case IL2CPP_TYPE_U1:
            case IL2CPP_TYPE_U2:
            case IL2CPP_TYPE_U4:
            case IL2CPP_TYPE_U8:
                keyboardType = UIKeyboardTypeNumberPad;
                break;
            case IL2CPP_TYPE_R4:
            case IL2CPP_TYPE_R8:
                keyboardType = UIKeyboardTypeDecimalPad;
                break;
            default:
                keyboardType = UIKeyboardTypeDefault;
                break;
        }
        [placeholders addObject:placeholder];
        [keyboardTypes addObject:@(keyboardType)];
    }

    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = MECreateAlert(@"Shortcut Arguments",
                                             message,
                                             placeholders,
                                             keyboardTypes,
                                             @[@"Next", @"Cancel"],
                                             ^(UIAlertController *controller, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            NSMutableArray<NSString *> *values = [NSMutableArray array];
            for (UITextField *tf in controller.textFields) {
                [values addObject:tf.text ?: @""];
            }
            [weakSelf promptShortcutTitleForMethod:info paramValues:values];
        }
        if (params) il2cpp_free_param_info(params, param_count);
    });
    MEPresentAlert(alert, self, YES);
}

- (void)promptShortcutTitleForMethod:(Il2CppMethodInfo)info paramValues:(NSArray<NSString *> *)values {
    NSString *defaultTitle = [NSString stringWithUTF8String:info.name];
    NSString *classFullName = [self fullNameForClass:self.selectedClass];
    BOOL isStatic = info.is_static;
    int paramCount = info.param_count;
    NSString *methodName = [NSString stringWithUTF8String:info.name];
    NSString *signature = info.signature ? [NSString stringWithUTF8String:info.signature] : @"";

    __weak typeof(self) weakSelf = self;
    UIAlertController *alert = MECreateAlert(@"Shortcut Name",
                                             @"Name the button that will appear in-game:",
                                             @[defaultTitle],
                                             nil,
                                             @[@"Save", @"Cancel"],
                                             ^(UIAlertController *controller, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            UITextField *tf = controller.textFields.firstObject;
            NSString *title = tf.text.length ? tf.text : defaultTitle;

            MEShortcut *sc = [[MEShortcut alloc] init];
            sc.title = title;
            sc.classFullName = classFullName;
            sc.methodName = methodName;
            sc.paramCount = paramCount;
            sc.isStatic = isStatic;
            sc.signature = signature;
            sc.params = values;

            [[MEStore shared] addShortcut:sc];
            [weakSelf showInfoMessage:[NSString stringWithFormat:@"Saved \"%@\" to your in-game shortcuts.", title]];
        }
    });
    MEPresentAlert(alert, self, YES);
}

- (void)showInvokeOptionsForMethod:(Il2CppMethodInfo)info {
    UNITY_LOG(@"show invoke options for method %s", info.name);

    int param_count = 0;
    Il2CppParamInfo* params = il2cpp_get_method_params(info.method, &param_count);

    UNITY_LOG(@"invoke options got %d parameters", param_count);

    if (param_count == 0) {
        [self invokeMethodWithInfo:info params:NULL paramCount:0 paramInfo:NULL];
        if (params) il2cpp_free_param_info(params, param_count);
        return;
    }

    NSMutableString *message = [NSMutableString stringWithFormat:@"Method: %s\nParameters: %d\n\n", info.name, param_count];

    NSMutableArray<NSString *> *placeholders = [NSMutableArray array];
    NSMutableArray *keyboardTypes = [NSMutableArray array];

    for (int i = 0; i < param_count; i++) {
        NSString *paramName = params[i].param_name && strlen(params[i].param_name) > 0
            ? [NSString stringWithUTF8String:params[i].param_name]
            : [NSString stringWithFormat:@"arg%d", i];
        [message appendFormat:@"%d. %s %@\n", i+1, params[i].type_name, paramName];

        NSString *placeholder = paramName;
        UIKeyboardType keyboardType = UIKeyboardTypeDefault;

        switch (params[i].type_enum) {
            case IL2CPP_TYPE_BOOLEAN:
                placeholder = [NSString stringWithFormat:@"%@ (true/false)", paramName];
                break;
            case IL2CPP_TYPE_I1:
            case IL2CPP_TYPE_I2:
            case IL2CPP_TYPE_I4:
            case IL2CPP_TYPE_I8:
            case IL2CPP_TYPE_U1:
            case IL2CPP_TYPE_U2:
            case IL2CPP_TYPE_U4:
            case IL2CPP_TYPE_U8:
                keyboardType = UIKeyboardTypeNumberPad;
                break;
            case IL2CPP_TYPE_R4:
            case IL2CPP_TYPE_R8:
                keyboardType = UIKeyboardTypeDecimalPad;
                break;
            default:
                keyboardType = UIKeyboardTypeDefault;
                break;
        }

        [placeholders addObject:placeholder];
        [keyboardTypes addObject:@(keyboardType)];
    }

    UIAlertController *alert = MECreateAlert(@"Invoke Method",
                                             message,
                                             placeholders,
                                             keyboardTypes,
                                             @[@"Invoke", @"Cancel"],
                                             ^(UIAlertController *controller, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [self invokeMethodWithInfo:info params:controller.textFields paramCount:param_count paramInfo:params];
        }
        if (params) il2cpp_free_param_info(params, param_count);
    });
    MEPresentAlert(alert, self, YES);
}

- (void)invokeMethodWithInfo:(Il2CppMethodInfo)info params:(NSArray<UITextField *> *)textFields paramCount:(int)paramCount paramInfo:(Il2CppParamInfo *)paramInfo {
    UNITY_LOG(@"invoke method %s with %d params", info.name, paramCount);

    void** params = NULL;
    void* param_values[paramCount];

    if (paramCount > 0) {
        params = param_values;

        for (int i = 0; i < paramCount; i++) {
            NSString *input = textFields[i].text;
    UNITY_LOG(@"parameter %d: type=%d, value='%s'", i, paramInfo[i].type_enum, [input UTF8String]);

            switch (paramInfo[i].type_enum) {
                case IL2CPP_TYPE_BOOLEAN: {
                    static bool bval;
                    bval = [input.lowercaseString isEqualToString:@"true"] || [input intValue] != 0;
                    params[i] = &bval;
                    break;
                }
                case IL2CPP_TYPE_I1: {
                    static int8_t i1val;
                    i1val = (int8_t)[input intValue];
                    params[i] = &i1val;
                    break;
                }
                case IL2CPP_TYPE_U1: {
                    static uint8_t u1val;
                    u1val = (uint8_t)[input intValue];
                    params[i] = &u1val;
                    break;
                }
                case IL2CPP_TYPE_I2: {
                    static int16_t i2val;
                    i2val = (int16_t)[input intValue];
                    params[i] = &i2val;
                    break;
                }
                case IL2CPP_TYPE_U2: {
                    static uint16_t u2val;
                    u2val = (uint16_t)[input intValue];
                    params[i] = &u2val;
                    break;
                }
                case IL2CPP_TYPE_I4: {
                    static int32_t i4val;
                    i4val = (int32_t)[input intValue];
                    params[i] = &i4val;
                    break;
                }
                case IL2CPP_TYPE_U4: {
                    static uint32_t u4val;
                    u4val = (uint32_t)[input integerValue];
                    params[i] = &u4val;
                    break;
                }
                case IL2CPP_TYPE_I8: {
                    static int64_t i8val;
                    i8val = (int64_t)[input longLongValue];
                    params[i] = &i8val;
                    break;
                }
                case IL2CPP_TYPE_U8: {
                    static uint64_t u8val;
                    u8val = (uint64_t)[input longLongValue];
                    params[i] = &u8val;
                    break;
                }
                case IL2CPP_TYPE_R4: {
                    static float f4val;
                    f4val = [input floatValue];
                    params[i] = &f4val;
                    break;
                }
                case IL2CPP_TYPE_R8: {
                    static double f8val;
                    f8val = [input doubleValue];
                    params[i] = &f8val;
                    break;
                }
                case IL2CPP_TYPE_STRING: {
                    if (il2cpp_string_new) {
                        static Il2CppString* strval;
                        strval = il2cpp_string_new([input UTF8String]);
                        params[i] = strval;
                    } else {
                        params[i] = NULL;
                    }
                    break;
                }
                default:
                    UNITY_LOG(@"parameter type not support: %d", paramInfo[i].type_enum);
                    params[i] = NULL;
                    break;
            }
        }
    }

    void* obj = NULL;
    if (!info.is_static) {
        if (self.selectedInstance) {
            obj = self.selectedInstance;
        } else {
            UIAlertController *alert = MECreateAlert(@"Error",
                                                     @"Please run this on a live instance.",
                                                     nil,
                                                     nil,
                                                     @[@"OK"],
                                                     nil);
            MEPresentAlert(alert, self, YES);
            return;
        }
    }

    char* result = il2cpp_invoke_method(info.method, obj, params);
    NSString *resultStr = result ? [NSString stringWithUTF8String:result] : @"(null)";

    UIAlertController *alert = MECreateAlert(@"Method Result",
                                             [NSString stringWithFormat:@"Method: %s\n\nResult: %@", info.name, resultStr],
                                             nil,
                                             nil,
                                             @[@"OK"],
                                             nil);
    MEPresentAlert(alert, self, YES);

    if (result) free(result);
}

- (void)showClassOptionsForClass:(Il2CppClass *)klass className:(NSString *)className {
    BOOL favorited = [[MEStore shared] isClassFavorited:className];

    UIAlertController *alert = MECreateAlert(@"Class Options",
                                             [NSString stringWithFormat:@"What would you like to do with %@?", className],
                                             nil,
                                             nil,
                                             @[@"View Methods", @"View Fields", @"Find Instances",
                                               favorited ? @"★ Remove Favorite" : @"☆ Add Favorite", @"Cancel"],
                                             ^(UIAlertController *controller, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [self showMethodsForClass:klass className:className];
        } else if (buttonIndex == 1) {
            [self showFieldsForClass:klass className:className];
        } else if (buttonIndex == 2) {
            [self showInstanceOptionsForClass:klass className:className];
        } else if (buttonIndex == 3) {
            [self toggleFavoriteClass:klass fullName:className];
        }
    });
    MEPresentAlert(alert, self, YES);
}

- (void)toggleFavoriteClass:(Il2CppClass *)klass fullName:(NSString *)fullName {
    MEStore *store = [MEStore shared];
    if ([store isClassFavorited:fullName]) {
        [store removeFavoriteClass:fullName];
    } else {
        const char *cname = il2cpp_class_get_name(klass);
        const char *cns = il2cpp_class_get_namespace(klass);
        NSString *name = cname ? [NSString stringWithUTF8String:cname] : fullName;
        NSString *ns = cns ? [NSString stringWithUTF8String:cns] : @"";
        [store addFavoriteClassWithFullName:fullName name:name namespace:ns];
    }
    if (self.viewMode == UNITY_VIEW_MODE_CLASSES) {
        [self reloadClassList];
    }
}

- (void)showFieldsForClass:(Il2CppClass *)klass className:(NSString *)className {
    self.globalMethodSearchGeneration++;
    self.selectedClass = klass;
    self.viewMode = UNITY_VIEW_MODE_FIELDS;

    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Il2CppFieldEnumResult* fields = il2cpp_enumerate_fields(klass);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.fieldResults) {
                il2cpp_free_field_enum_result(self.fieldResults);
            }
            self.fieldResults = fields;

            self.titleLabel.text = className;
            self.btnBack.hidden = NO;
            self.instanceModeControl.hidden = YES;
            self.viewModeControl.hidden = YES;
            self.searchBar.placeholder = @"Search fields...";

            [MEStore shared].lastClassFullName = className;
            [MEStore shared].lastSubPage = 1;

            [self.loadingIndicator stopAnimating];
            self.tableView.hidden = NO;
            [self.tableView reloadData];
        });
    });
}

- (void)showInstanceOptionsForClass:(Il2CppClass *)klass className:(NSString *)className {
    self.selectedClass = klass;

    UIAlertController *alert = MECreateAlert(@"Find Instances",
                                             @"How would you like to get instances of this class?",
                                             nil,
                                             nil,
                                             @[@"Manual Entry", @"Scan Memory", @"Cancel"],
                                             ^(UIAlertController *controller, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [self showManualInstanceInput:klass className:className];
        } else if (buttonIndex == 1) {
            [self scanForInstances:klass className:className];
        }
    });
    MEPresentAlert(alert, self, YES);
}

- (void)showManualInstanceInput:(Il2CppClass *)klass className:(NSString *)className {
    UIAlertController *alert = MECreateAlert(@"Manual Instance Entry",
                                             @"Enter the object pointer address (eg, 0x1234abcd)",
                                             @[@"0x"],
                                             nil,
                                             @[@"Open", @"Cancel"],
                                             ^(UIAlertController *controller, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            UITextField *textField = controller.textFields.firstObject;
            NSString *input = textField.text;

            unsigned long long address = 0;
            NSScanner *scanner = [NSScanner scannerWithString:input];
            if ([scanner scanHexLongLong:&address]) {
                void *instance = (void *)address;
                [self showInstanceDetailsForInstance:instance];
            } else {
                [self showErrorMessage:@"Invalid address format"];
            }
        }
    });
    MEPresentAlert(alert, self, YES);
}

- (void)scanForInstances:(Il2CppClass *)klass className:(NSString *)className {
    self.selectedClass = klass;
    self.viewMode = UNITY_VIEW_MODE_INSTANCES;

    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Il2CppInstanceEnumResult* instances = il2cpp_find_instances(klass);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.instanceResults) {
                il2cpp_free_instance_enum_result(self.instanceResults);
            }
            self.instanceResults = instances;

            self.titleLabel.text = [NSString stringWithFormat:@"%@ Instances", className];
            self.btnBack.hidden = NO;
            self.viewModeControl.hidden = YES;

            [self.loadingIndicator stopAnimating];
            self.tableView.hidden = NO;
            [self.tableView reloadData];

            if (!instances || instances->instance_count == 0) {
                [self showInfoMessage:@"Nothing found."];
            }
        });
    });
}

- (void)showInstanceDetailsForInstance:(void *)instance {
    if (!instance || !self.selectedClass) return;

    self.selectedInstance = instance;
    self.instanceModeControl.hidden = NO;
    self.instanceModeControl.selectedSegmentIndex = 0;
    [self showFieldsForInstance:instance];
}

- (void)showFieldsForInstance:(void *)instance {
    self.selectedInstance = instance;
    self.viewMode = UNITY_VIEW_MODE_FIELDS;

    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Il2CppFieldEnumResult* fields = il2cpp_enumerate_fields(self.selectedClass);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.fieldResults) {
                il2cpp_free_field_enum_result(self.fieldResults);
            }
            self.fieldResults = fields;

            self.titleLabel.text = [NSString stringWithFormat:@"Instance 0x%lx", (unsigned long)instance];
            self.btnBack.hidden = NO;
            self.instanceModeControl.hidden = NO;
            self.viewModeControl.hidden = YES;
            self.instanceModeControl.selectedSegmentIndex = 0;

            [self.loadingIndicator stopAnimating];
            self.tableView.hidden = NO;
            [self.tableView reloadData];
        });
    });
}

- (void)showMethodsForInstance:(void *)instance {
    self.selectedInstance = instance;
    self.viewMode = UNITY_VIEW_MODE_METHODS;

    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        Il2CppMethodEnumResult* methods = il2cpp_enumerate_methods(self.selectedClass);

        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.methodResults) {
                il2cpp_free_method_enum_result(self.methodResults);
            }
            self.methodResults = methods;

            self.titleLabel.text = [NSString stringWithFormat:@"Instance 0x%lx", (unsigned long)instance];
            self.btnBack.hidden = NO;
            self.instanceModeControl.hidden = NO;
            self.viewModeControl.hidden = YES;
            self.instanceModeControl.selectedSegmentIndex = 1;
            self.searchBar.placeholder = @"Search methods...";

            [self.loadingIndicator stopAnimating];
            self.tableView.hidden = NO;
            [self.tableView reloadData];
        });
    });
}

- (void)showFieldDetails:(Il2CppFieldInfo)info {
    char* value_str = il2cpp_get_field_value_string(self.selectedInstance, info.field, self.selectedClass);
    NSString *valueString = value_str ? [NSString stringWithUTF8String:value_str] : @"(unable to read)";
    if (value_str) free(value_str);

    NSString *message = [NSString stringWithFormat:@"Field: %s\nType: %s\n%s\n\nCurrent Value:\n%@",
                         info.name,
                         info.type_name,
                         info.is_static ? "Static" : "Instance",
                         valueString];

    NSArray<NSString *> *buttonTitles;
    MEAlertHandler handler = nil;
    if (il2cpp_can_edit_field_type(info.type_enum)) {
        buttonTitles = @[@"Edit Value", @"Cancel"];
        handler = ^(UIAlertController *controller, NSInteger buttonIndex) {
            if (buttonIndex == 0) {
                [self showEditFieldDialog:info];
            }
        };
    } else {
        buttonTitles = @[@"OK"];
    }
    UIAlertController *alert = MECreateAlert(@"Field Details", message, nil, nil, buttonTitles, handler);
    MEPresentAlert(alert, self, YES);
}

- (void)showEditFieldDialog:(Il2CppFieldInfo)info {
    UIKeyboardType keyboardType = UIKeyboardTypeDefault;
    NSString *placeholder = @"value";

    switch (info.type_enum) {
        case IL2CPP_TYPE_BOOLEAN:
            placeholder = @"true/false";
            break;
        case IL2CPP_TYPE_I1:
        case IL2CPP_TYPE_I2:
        case IL2CPP_TYPE_I4:
        case IL2CPP_TYPE_I8:
        case IL2CPP_TYPE_U1:
        case IL2CPP_TYPE_U2:
        case IL2CPP_TYPE_U4:
        case IL2CPP_TYPE_U8:
            keyboardType = UIKeyboardTypeNumberPad;
            break;
        case IL2CPP_TYPE_R4:
        case IL2CPP_TYPE_R8:
            keyboardType = UIKeyboardTypeDecimalPad;
            break;
        default:
            break;
    }

    UIAlertController *alert = MECreateAlert(@"Edit Field Value",
                                             [NSString stringWithFormat:@"Enter new value for %s:", info.name],
                                             @[placeholder],
                                             @[@(keyboardType)],
                                             @[@"Set Value", @"Cancel"],
                                             ^(UIAlertController *controller, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            UITextField *textField = controller.textFields.firstObject;
            bool success = il2cpp_set_field_value_from_string(self.selectedInstance, info.field, self.selectedClass, [textField.text UTF8String], info.type_enum);
            if (success) {
                [self showInfoMessage:@"Value updated successfully!"];
                [self.tableView reloadData];
            } else {
                [self showErrorMessage:@"Failed to set value"];
            }
        }
    });
    MEPresentAlert(alert, self, YES);
}

- (void)showInfoMessage:(NSString *)message {
    UIAlertController *alert = MECreateAlert(@"Info", message, nil, nil, @[@"OK"], nil);
    MEPresentAlert(alert, self, YES);
}

- (void)showErrorMessage:(NSString *)message {
    UIAlertController *alert = MECreateAlert(@"Error", message, nil, nil, @[@"OK"], nil);
    MEPresentAlert(alert, self, YES);
}


- (void)restoreLastState {
    MEStore *store = [MEStore shared];

    NSString *lastSearch = store.lastSearchText;
    if (lastSearch.length > 0) {
        self.searchBar.text = lastSearch;
    }
    [self reloadClassList];
    self.tableView.hidden = NO;

    NSString *lastClass = store.lastClassFullName;
    if (lastClass.length > 0) {
        Il2CppClass *klass = il2cpp_find_class_by_full_name([lastClass UTF8String]);
        if (klass) {
            if (store.lastSubPage == 1) {
                [self showFieldsForClass:klass className:lastClass];
            } else {
                [self showMethodsForClass:klass className:lastClass];
            }
        }
    }
}


- (void)showInView:(UIView *)view animated:(BOOL)animated {
    if (!view) {
        return;
    }
    [view addSubview:self];

    [NSLayoutConstraint activateConstraints:@[
        [self.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [self.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        [self.topAnchor constraintEqualToAnchor:view.topAnchor],
        [self.bottomAnchor constraintEqualToAnchor:view.bottomAnchor]
    ]];

    [self.loadingIndicator startAnimating];
    self.tableView.hidden = YES;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        @try {
            bool success = il2cpp_helper_init();
            dispatch_async(dispatch_get_main_queue(), ^{
                if (success) {
                    [self restoreLastState];
                } else {
                    UIAlertController *alert = MECreateAlert(@"Error",
                                                             @"Failed to initialize IL2CPP. Make sure the target app is using IL2CPP.",
                                                             nil,
                                                             nil,
                                                             @[@"OK"],
                                                             ^(UIAlertController *controller, NSInteger buttonIndex) {
                        [self hideAnimated:YES];
                    });
                    MEPresentAlert(alert, self, YES);
                }
                [self.loadingIndicator stopAnimating];
            });
        } @catch (NSException *exception) {
            UNITY_LOG(@"init thread got exception: %@", exception);
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.loadingIndicator stopAnimating];
                UIAlertController *alert = MECreateAlert(@"Error",
                                                         [NSString stringWithFormat:@"Exception: %@", exception.reason],
                                                         nil,
                                                         nil,
                                                         @[@"OK"],
                                                         ^(UIAlertController *controller, NSInteger buttonIndex) {
                    [self hideAnimated:YES];
                });
                MEPresentAlert(alert, self, YES);
            });
        }
    });

    if (animated) {
        self.alpha = 0;
        self.containerView.transform = CGAffineTransformMakeScale(0.8, 0.8);

        [UIView animateWithDuration:0.3
                              delay:0
             usingSpringWithDamping:0.8
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionCurveEaseOut
                         animations:^{
            self.alpha = 1;
            self.containerView.transform = CGAffineTransformIdentity;
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
            self.containerView.transform = CGAffineTransformMakeScale(0.9, 0.9);
        } completion:^(BOOL finished) {
            [self removeFromSuperview];
        }];
    } else {
        [self removeFromSuperview];
    }
}

@end
