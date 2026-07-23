TARGET := iphone:clang:16.5:15.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = memeditPrefs

memeditPrefs_FILES = MEPRootListController.m
memeditPrefs_FRAMEWORKS = UIKit
memeditPrefs_PRIVATE_FRAMEWORKS = Preferences
memeditPrefs_INSTALL_PATH = /Library/PreferenceBundles
memeditPrefs_CFLAGS = -fobjc-arc
memeditPrefs_EXTRA_FRAMEWORKS = AltList

include $(THEOS_MAKE_PATH)/bundle.mk
