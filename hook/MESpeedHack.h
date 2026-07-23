
#ifndef MESpeedHack_h
#define MESpeedHack_h

#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

void MESpeedHackInstall(void);
bool MESpeedHackIsInstalled(void);

void   MESpeedHackSetMultiplier(double multiplier);
double MESpeedHackGetMultiplier(void);

void MESpeedHackSetEnabled(bool enabled);
bool MESpeedHackIsEnabled(void);

#ifdef __cplusplus
}
#endif

#endif
