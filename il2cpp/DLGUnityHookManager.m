#import "DLGUnityHookManager.h"
#import "../RemoteLog.h"
#import <substrate.h>
#include <string.h>

#define HOOK_LOG(fmt, ...) RLog(@"[unity hook] " fmt, ##__VA_ARGS__)
#define HOOKS_PLIST @"/var/jb/var/mobile/Library/Preferences/dev.mineek.memedit.hooks.plist"

@implementation DLGUnityHook
@end

typedef void *(*DLGUnityStub)(void *, void *, void *, void *,
                              void *, void *, void *, void *);

static void *stub_force_true(void *a0, void *a1, void *a2, void *a3,
                             void *a4, void *a5, void *a6, void *a7) {
    return (void *)1;
}

static void *stub_force_false(void *a0, void *a1, void *a2, void *a3,
                              void *a4, void *a5, void *a6, void *a7) {
    return NULL;
}

static void *stub_force_zero(void *a0, void *a1, void *a2, void *a3,
                             void *a4, void *a5, void *a6, void *a7) {
    return NULL;
}

static void *stub_force_9999(void *a0, void *a1, void *a2, void *a3,
                             void *a4, void *a5, void *a6, void *a7) {
    return (void *)9999;
}

static void invoke_il2cpp_delegate(void *delegateObject) {
    if (!delegateObject || !il2cpp_class_get_methods ||
        !il2cpp_method_get_name || !il2cpp_runtime_invoke) return;

    Il2CppClass *klass = *(Il2CppClass **)delegateObject;
    if (!klass) return;

    void *iter = NULL;
    const MethodInfo *method = NULL;
    while ((method = il2cpp_class_get_methods(klass, &iter))) {
        const char *name = il2cpp_method_get_name(method);
        if (name && strcmp(name, "Invoke") == 0) {
            Il2CppObject *exception = NULL;
            il2cpp_runtime_invoke(method, delegateObject, NULL, &exception);
            return;
        }
    }
}

#define MAKE_CALLBACK_STUB(N) \
static void *callback_stub_##N(void *a0, void *a1, void *a2, void *a3, \
                               void *a4, void *a5, void *a6, void *a7) { \
    void *args[] = { a0, a1, a2, a3, a4, a5, a6, a7 }; \
    invoke_il2cpp_delegate(args[N]); \
    return NULL; \
}

MAKE_CALLBACK_STUB(0)
MAKE_CALLBACK_STUB(1)
MAKE_CALLBACK_STUB(2)
MAKE_CALLBACK_STUB(3)
MAKE_CALLBACK_STUB(4)
MAKE_CALLBACK_STUB(5)
MAKE_CALLBACK_STUB(6)
MAKE_CALLBACK_STUB(7)

static DLGUnityStub callback_stubs[] = {
    callback_stub_0, callback_stub_1, callback_stub_2, callback_stub_3,
    callback_stub_4, callback_stub_5, callback_stub_6, callback_stub_7
};

@interface DLGUnityHookManager ()
@property (nonatomic) NSMutableArray<DLGUnityHook *> *hooks;
@property (nonatomic) dispatch_queue_t queue;
@end

@implementation DLGUnityHookManager

+ (instancetype)sharedManager {
    static DLGUnityHookManager *manager;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        manager = [[DLGUnityHookManager alloc] init];
    });
    return manager;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        _hooks = [NSMutableArray array];
        _queue = dispatch_queue_create("dev.mineek.memedit.unity-hooks", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (DLGUnityStub)stubForType:(DLGUnityHookType)type callbackIndex:(int)index {
    switch (type) {
        case DLGUnityHookTypeForceTrue:
            return stub_force_true;
        case DLGUnityHookTypeForceFalse:
            return stub_force_false;
        case DLGUnityHookTypeForceZero:
            return stub_force_zero;
        case DLGUnityHookTypeForce9999:
            return stub_force_9999;
        case DLGUnityHookTypeCallbackShortCircuit:
            return callback_stubs[index >= 0 && index < 8 ? index : 0];
    }
    return stub_force_true;
}

- (BOOL)installHookForMethod:(const MethodInfo *)method
                   className:(NSString *)className
                  methodName:(NSString *)methodName
                    hookType:(DLGUnityHookType)hookType
          callbackParamIndex:(int)paramIdx {
    if (!method) return NO;

    void *methodPointer = *(void **)method;
    if (!methodPointer) {
        HOOK_LOG(@"native pointer missing for %@.%@", className, methodName);
        return NO;
    }

    intptr_t pointerValue = (intptr_t)methodPointer;
    __block BOOL installed = NO;
    dispatch_sync(self.queue, ^{
        for (DLGUnityHook *hook in self.hooks) {
            if (hook.methodPointer == pointerValue) {
                installed = YES;
                return;
            }
        }

        void *original = NULL;
        DLGUnityStub stub = [self stubForType:hookType callbackIndex:paramIdx];
        MSHookFunction(methodPointer, (void *)stub, &original);
        if (!original) {
            HOOK_LOG(@"substrate gave no trampoline for %@.%@", className, methodName);
            return;
        }

        DLGUnityHook *hook = [[DLGUnityHook alloc] init];
        hook.methodName = [NSString stringWithFormat:@"%@.%@", className, methodName];
        hook.className = className;
        hook.rawMethodName = methodName;
        hook.parameterCount = il2cpp_method_get_param_count
            ? il2cpp_method_get_param_count(method) : 0;
        hook.methodPointer = pointerValue;
        hook.hookType = hookType;
        hook.callbackParamIndex = paramIdx;
        hook.originalPointer = original;
        [self.hooks addObject:hook];
        installed = YES;
    });

    if (installed) [self saveHooks];
    return installed;
}

- (BOOL)removeHookForMethodPointer:(intptr_t)pointer {
    __block BOOL removed = NO;
    dispatch_sync(self.queue, ^{
        for (NSUInteger index = 0; index < self.hooks.count; index++) {
            DLGUnityHook *hook = self.hooks[index];
            if (hook.methodPointer != pointer) continue;

            if (hook.originalPointer) {
                void *unused = NULL;
                MSHookFunction((void *)pointer, hook.originalPointer, &unused);
            }
            [self.hooks removeObjectAtIndex:index];
            removed = YES;
            break;
        }
    });
    if (removed) [self saveHooks];
    return removed;
}

- (void)changeHookType:(DLGUnityHookType)newType
    callbackParamIndex:(int)paramIdx
      forMethodPointer:(intptr_t)pointer {
    __block DLGUnityHook *oldHook = nil;
    dispatch_sync(self.queue, ^{
        for (DLGUnityHook *hook in self.hooks) {
            if (hook.methodPointer == pointer) {
                oldHook = hook;
                break;
            }
        }
        if (!oldHook) return;

        if (oldHook.originalPointer) {
            void *unused = NULL;
            MSHookFunction((void *)pointer, oldHook.originalPointer, &unused);
        }
        [self.hooks removeObject:oldHook];

        void *original = NULL;
        DLGUnityStub stub = [self stubForType:newType callbackIndex:paramIdx];
        MSHookFunction((void *)pointer, (void *)stub, &original);
        oldHook.originalPointer = original;
        oldHook.hookType = newType;
        oldHook.callbackParamIndex = paramIdx;
        [self.hooks addObject:oldHook];
    });
    if (oldHook) [self saveHooks];
}

- (NSArray<DLGUnityHook *> *)allHooks {
    __block NSArray<DLGUnityHook *> *result;
    dispatch_sync(self.queue, ^{
        result = [self.hooks copy];
    });
    return result;
}

- (void)saveHooks {
    NSMutableArray *storedHooks = [NSMutableArray array];
    for (DLGUnityHook *hook in [self allHooks]) {
        [storedHooks addObject:@{
            @"className": hook.className ?: @"",
            @"rawMethodName": hook.rawMethodName ?: @"",
            @"parameterCount": @(hook.parameterCount),
            @"hookType": @(hook.hookType),
            @"callbackParamIndex": @(hook.callbackParamIndex)
        }];
    }

    NSString *directory = [HOOKS_PLIST stringByDeletingLastPathComponent];
    [[NSFileManager defaultManager] createDirectoryAtPath:directory
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];
    [storedHooks writeToFile:HOOKS_PLIST atomically:YES];
}

- (void)loadAndReinstallHooks {
    NSArray<NSDictionary *> *storedHooks = [NSArray arrayWithContentsOfFile:HOOKS_PLIST];
    if (storedHooks.count == 0) return;

    for (NSDictionary *entry in storedHooks) {
        NSString *className = entry[@"className"];
        NSString *methodName = entry[@"rawMethodName"];
        NSInteger parameterCount = [entry[@"parameterCount"] integerValue];
        if (className.length == 0 || methodName.length == 0) continue;

        Il2CppClass *klass = il2cpp_find_class_by_full_name(className.UTF8String);
        if (!klass) continue;

        const MethodInfo *method = il2cpp_find_method_by_name(
            klass, methodName.UTF8String, (int)parameterCount);
        if (!method) continue;

        [self installHookForMethod:method
                         className:className
                        methodName:methodName
                          hookType:(DLGUnityHookType)[entry[@"hookType"] integerValue]
                callbackParamIndex:[entry[@"callbackParamIndex"] intValue]];
    }
}

@end
