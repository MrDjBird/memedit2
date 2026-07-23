#ifndef DLGUnityHookManager_h
#define DLGUnityHookManager_h

#import <Foundation/Foundation.h>
#include "il2cpp_helper.h"

typedef NS_ENUM(NSInteger, DLGUnityHookType) {
    DLGUnityHookTypeForceTrue = 0,
    DLGUnityHookTypeForceFalse,
    DLGUnityHookTypeForce9999,
    DLGUnityHookTypeCallbackShortCircuit,
    DLGUnityHookTypeForceZero,
};

@interface DLGUnityHook : NSObject

@property (nonatomic, copy) NSString *methodName;
@property (nonatomic, copy) NSString *className;
@property (nonatomic, copy) NSString *rawMethodName;
@property (nonatomic) NSInteger parameterCount;
@property (nonatomic) intptr_t methodPointer;
@property (nonatomic) DLGUnityHookType hookType;
@property (nonatomic) int callbackParamIndex;
@property (nonatomic) void *originalPointer;

@end

@interface DLGUnityHookManager : NSObject

+ (instancetype)sharedManager;

- (BOOL)installHookForMethod:(const MethodInfo *)method
                   className:(NSString *)className
                  methodName:(NSString *)methodName
                    hookType:(DLGUnityHookType)hookType
          callbackParamIndex:(int)paramIdx;
- (BOOL)removeHookForMethodPointer:(intptr_t)ptr;
- (void)changeHookType:(DLGUnityHookType)newType
    callbackParamIndex:(int)paramIdx
      forMethodPointer:(intptr_t)ptr;
- (NSArray<DLGUnityHook *> *)allHooks;
- (void)saveHooks;
- (void)loadAndReinstallHooks;

@end

#endif
