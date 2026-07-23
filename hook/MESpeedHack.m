
#import "MESpeedHack.h"
#import <Foundation/Foundation.h>

#include <math.h>
#include <stdio.h>
#include <stdlib.h>
#include "il2cpp_helper.h"

static double g_multiplier = 1.0;
static bool g_enabled = false;
static bool g_installed = false;
static bool g_needsRestore = false;

static bool g_il2cppReady = false;
static Il2CppClass *g_timeClass = NULL;
static const MethodInfo *g_setTimeScale = NULL;

static dispatch_source_t g_timer;

static double effectiveMultiplier(void)
{
    return g_enabled ? g_multiplier : 1.0;
}

static bool resolveTimeScaleSetter(void)
{
    if (g_setTimeScale) {
        return true;
    }

    if (!g_il2cppReady) {
        g_il2cppReady = il2cpp_helper_init();
        if (!g_il2cppReady) {
            return false;
        }
    }

    if (!g_timeClass) {
        g_timeClass = il2cpp_find_class_by_full_name("UnityEngine.Time");
    }
    if (!g_timeClass) {
        return false;
    }

    g_setTimeScale = il2cpp_find_method_by_name(g_timeClass, "set_timeScale", 1);
    return g_setTimeScale != NULL;
}

static bool applyTimeScale(double value)
{
    if (!resolveTimeScaleSetter()) {
        return false;
    }

    char valueString[64];
    snprintf(valueString, sizeof(valueString), "%f", value);
    const char *arguments[] = { valueString };
    char *result = il2cpp_invoke_method_with_args(g_setTimeScale, NULL, arguments, 1);
    free(result);
    return true;
}

static void updateTimeScale(void)
{
    if (g_enabled) {
        if (applyTimeScale(effectiveMultiplier())) {
            g_needsRestore = true;
        }
        return;
    }

    if (g_needsRestore && applyTimeScale(1.0)) {
        g_needsRestore = false;
    }
}

static void updateTimeScaleOnMainQueue(void)
{
    if ([NSThread isMainThread]) {
        updateTimeScale();
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
            updateTimeScale();
        });
    }
}

static void startUpdateTimer(void)
{
    if (g_timer) {
        return;
    }

    g_timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
    dispatch_source_set_timer(g_timer,
                              dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)),
                              (uint64_t)(0.5 * NSEC_PER_SEC),
                              (uint64_t)(0.1 * NSEC_PER_SEC));
    dispatch_source_set_event_handler(g_timer, ^{
        updateTimeScale();
    });
    dispatch_resume(g_timer);
}


void MESpeedHackInstall(void)
{
    if (g_installed) {
        return;
    }

    g_installed = true;
    dispatch_async(dispatch_get_main_queue(), ^{
        startUpdateTimer();
        updateTimeScale();
    });
}

bool MESpeedHackIsInstalled(void)
{
    return g_installed;
}

void MESpeedHackSetMultiplier(double multiplier)
{
    g_multiplier = fmax(0.01, fmin(multiplier, 100.0));
    updateTimeScaleOnMainQueue();
}

double MESpeedHackGetMultiplier(void)
{
    return g_multiplier;
}

void MESpeedHackSetEnabled(bool enabled)
{
    g_enabled = enabled;
    updateTimeScaleOnMainQueue();
}

bool MESpeedHackIsEnabled(void)
{
    return g_enabled;
}
