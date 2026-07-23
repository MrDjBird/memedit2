#import <Foundation/Foundation.h>
#import "DLGMem.h"
#import "MEStore.h"
#import "MESpeedHack.h"
#import "RemoteLog.h"
#if !JAILED
#import "il2cpp/il2cpp_helper.h"
#import "il2cpp/DLGUnityHookManager.h"
#endif

static bool shouldEnableForBundleIdentifier(NSString *bundleIdentifier)
{
#ifdef JAILED
    return true;
#else
    NSDictionary *preferences = [NSDictionary dictionaryWithContentsOfFile:@"/var/jb/var/mobile/Library/Preferences/dev.mineek.memedit.plist"];
    return [preferences[@"apps"] containsObject:bundleIdentifier];
#endif
}

__attribute__((constructor))
static void entry(void)
{
    NSString *bundleIdentifier = NSBundle.mainBundle.bundleIdentifier;
    if (!shouldEnableForBundleIdentifier(bundleIdentifier)) {
        return;
    }

    MEStore *store = MEStore.shared;
    MESpeedHackInstall();
    MESpeedHackSetMultiplier(store.speedMultiplier);
    MESpeedHackSetEnabled(store.speedEnabled);

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        RLog(@"tweak start, build from %@", @__DATE__);
        [[[DLGMem alloc] init] launchDLGMem];

#if !JAILED
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            if (il2cpp_helper_init()) {
                [[DLGUnityHookManager sharedManager] loadAndReinstallHooks];
            }
        });
#endif
    });
}
