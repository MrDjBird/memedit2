
#import "MEStore.h"

NSString * const MEStoreShortcutsChangedNotification = @"MEStoreShortcutsChangedNotification";
NSString * const MEStoreFavoritesChangedNotification = @"MEStoreFavoritesChangedNotification";

static NSString * const kFavoriteClassesKey = @"me_favorite_classes";
static NSString * const kShortcutsKey       = @"me_shortcuts";
static NSString * const kLastSearchKey      = @"me_last_search";
static NSString * const kLastClassKey       = @"me_last_class";
static NSString * const kLastSubPageKey     = @"me_last_subpage";
static NSString * const kSpeedMultiplierKey = @"me_speed_multiplier";
static NSString * const kSpeedEnabledKey    = @"me_speed_enabled";


@implementation MEShortcut

- (instancetype)init {
    self = [super init];
    if (self) {
        _params = @[];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation {
    return @{
        @"title": self.title ?: @"",
        @"classFullName": self.classFullName ?: @"",
        @"methodName": self.methodName ?: @"",
        @"paramCount": @(self.paramCount),
        @"isStatic": @(self.isStatic),
        @"signature": self.signature ?: @"",
        @"params": self.params ?: @[],
    };
}

+ (instancetype)shortcutWithDictionary:(NSDictionary *)dict {
    MEShortcut *s = [[MEShortcut alloc] init];
    s.title = dict[@"title"];
    s.classFullName = dict[@"classFullName"];
    s.methodName = dict[@"methodName"];
    s.paramCount = [dict[@"paramCount"] integerValue];
    s.isStatic = [dict[@"isStatic"] boolValue];
    s.signature = dict[@"signature"];
    s.params = dict[@"params"] ?: @[];
    return s;
}

@end


@implementation MEStore

+ (instancetype)shared {
    static MEStore *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[MEStore alloc] init];
    });
    return instance;
}

- (NSUserDefaults *)defaults {
    return [NSUserDefaults standardUserDefaults];
}

- (void)postOnMain:(NSString *)name {
    dispatch_block_t post = ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:name object:nil];
    };
    if ([NSThread isMainThread]) {
        post();
    } else {
        dispatch_async(dispatch_get_main_queue(), post);
    }
}


- (NSArray<NSDictionary *> *)favoriteClasses {
    NSArray *arr = [[self defaults] arrayForKey:kFavoriteClassesKey];
    return arr ?: @[];
}

- (BOOL)isClassFavorited:(NSString *)fullName {
    if (fullName.length == 0) return NO;
    for (NSDictionary *d in [self favoriteClasses]) {
        if ([d[@"fullName"] isEqualToString:fullName]) return YES;
    }
    return NO;
}

- (void)addFavoriteClassWithFullName:(NSString *)fullName name:(NSString *)name namespace:(NSString *)ns {
    if (fullName.length == 0) return;
    if ([self isClassFavorited:fullName]) return;

    NSMutableArray *favs = [[self favoriteClasses] mutableCopy];
    [favs addObject:@{
        @"fullName": fullName,
        @"name": name ?: fullName,
        @"namespace": ns ?: @"",
    }];
    [[self defaults] setObject:favs forKey:kFavoriteClassesKey];
    [self postOnMain:MEStoreFavoritesChangedNotification];
}

- (void)removeFavoriteClass:(NSString *)fullName {
    if (fullName.length == 0) return;
    NSMutableArray *favs = [[self favoriteClasses] mutableCopy];
    NSMutableArray *toRemove = [NSMutableArray array];
    for (NSDictionary *d in favs) {
        if ([d[@"fullName"] isEqualToString:fullName]) [toRemove addObject:d];
    }
    [favs removeObjectsInArray:toRemove];
    [[self defaults] setObject:favs forKey:kFavoriteClassesKey];
    [self postOnMain:MEStoreFavoritesChangedNotification];
}


- (NSString *)lastSearchText {
    return [[self defaults] stringForKey:kLastSearchKey];
}

- (void)setLastSearchText:(NSString *)lastSearchText {
    if (lastSearchText.length > 0) {
        [[self defaults] setObject:lastSearchText forKey:kLastSearchKey];
    } else {
        [[self defaults] removeObjectForKey:kLastSearchKey];
    }
}

- (NSString *)lastClassFullName {
    return [[self defaults] stringForKey:kLastClassKey];
}

- (void)setLastClassFullName:(NSString *)lastClassFullName {
    if (lastClassFullName.length > 0) {
        [[self defaults] setObject:lastClassFullName forKey:kLastClassKey];
    } else {
        [[self defaults] removeObjectForKey:kLastClassKey];
    }
}

- (NSInteger)lastSubPage {
    return [[self defaults] integerForKey:kLastSubPageKey];
}

- (void)setLastSubPage:(NSInteger)lastSubPage {
    [[self defaults] setInteger:lastSubPage forKey:kLastSubPageKey];
}


- (NSArray<MEShortcut *> *)shortcuts {
    NSArray *raw = [[self defaults] arrayForKey:kShortcutsKey];
    NSMutableArray<MEShortcut *> *result = [NSMutableArray array];
    for (NSDictionary *d in raw) {
        if ([d isKindOfClass:[NSDictionary class]]) {
            [result addObject:[MEShortcut shortcutWithDictionary:d]];
        }
    }
    return result;
}

- (void)saveShortcuts:(NSArray<MEShortcut *> *)shortcuts {
    NSMutableArray *raw = [NSMutableArray array];
    for (MEShortcut *s in shortcuts) {
        [raw addObject:[s dictionaryRepresentation]];
    }
    [[self defaults] setObject:raw forKey:kShortcutsKey];
    [self postOnMain:MEStoreShortcutsChangedNotification];
}

- (void)addShortcut:(MEShortcut *)shortcut {
    if (!shortcut) return;
    NSMutableArray *all = [[self shortcuts] mutableCopy];
    [all addObject:shortcut];
    [self saveShortcuts:all];
}

- (void)removeShortcutAtIndex:(NSInteger)index {
    NSMutableArray *all = [[self shortcuts] mutableCopy];
    if (index < 0 || index >= (NSInteger)all.count) return;
    [all removeObjectAtIndex:index];
    [self saveShortcuts:all];
}


- (double)speedMultiplier {
    if ([[self defaults] objectForKey:kSpeedMultiplierKey] == nil) return 1.0;
    double m = [[self defaults] doubleForKey:kSpeedMultiplierKey];
    return m > 0 ? m : 1.0;
}

- (void)setSpeedMultiplier:(double)speedMultiplier {
    [[self defaults] setDouble:speedMultiplier forKey:kSpeedMultiplierKey];
}

- (BOOL)speedEnabled {
    return [[self defaults] boolForKey:kSpeedEnabledKey];
}

- (void)setSpeedEnabled:(BOOL)speedEnabled {
    [[self defaults] setBool:speedEnabled forKey:kSpeedEnabledKey];
}

@end
