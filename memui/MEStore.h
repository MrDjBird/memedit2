
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString * const MEStoreShortcutsChangedNotification;
extern NSString * const MEStoreFavoritesChangedNotification;


@interface MEShortcut : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *classFullName;
@property (nonatomic, copy) NSString *methodName;
@property (nonatomic) NSInteger paramCount;
@property (nonatomic) BOOL isStatic;
@property (nonatomic, copy, nullable) NSString *signature;
@property (nonatomic, copy) NSArray<NSString *> *params;

- (NSDictionary *)dictionaryRepresentation;
+ (instancetype)shortcutWithDictionary:(NSDictionary *)dict;

@end


@interface MEStore : NSObject

+ (instancetype)shared;


- (NSArray<NSDictionary *> *)favoriteClasses;
- (BOOL)isClassFavorited:(NSString *)fullName;
- (void)addFavoriteClassWithFullName:(NSString *)fullName name:(NSString *)name namespace:(nullable NSString *)ns;
- (void)removeFavoriteClass:(NSString *)fullName;


@property (nonatomic, copy, nullable) NSString *lastSearchText;
@property (nonatomic, copy, nullable) NSString *lastClassFullName;
@property (nonatomic) NSInteger lastSubPage;


- (NSArray<MEShortcut *> *)shortcuts;
- (void)addShortcut:(MEShortcut *)shortcut;
- (void)removeShortcutAtIndex:(NSInteger)index;


@property (nonatomic) double speedMultiplier;
@property (nonatomic) BOOL speedEnabled;

@end

NS_ASSUME_NONNULL_END
