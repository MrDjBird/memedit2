TARGET := iphone:clang:16.5:15.0
INSTALL_TARGET_PROCESSES = SpringBoard
ARCHS = arm64 arm64e
THEOS_DEVICE_IP = 127.0.0.1
THEOS_DEVICE_PORT = 2222

ifneq ($(filter 1 yes true,$(JAILED)),)
	PACKAGE_FORMAT = none
	memedit_INSTALL = 0
else
	THEOS_PACKAGE_SCHEME = rootless
endif

SRCS = $(shell find il2cpp mem memui hook -type f -name '*.m' -o -name '*.c')
SRCS_INCLUDE_DIRS = $(shell find il2cpp mem memui hook -type d)
SRCS_INCLUDE_FLAGS = $(addprefix -I, $(SRCS_INCLUDE_DIRS))

TBD_CFLAGS = -Wno-error

ifneq ($(filter 1 yes true,$(JAILED)),)
	TBD_CFLAGS += -DJAILED
endif

ifdef MEMEDIT_RELEASE_BUILD
	TBD_CFLAGS += -DRELEASE_BUILD
	FINALPACKAGE = 1
	DEBUG = 0
else
	TBD_CFLAGS += -DREMOTE_LOG_IP='"192.168.3.101"'
endif

$(info Building in $(if $(MEMEDIT_RELEASE_BUILD),Release,Debug) mode ($(if $(filter 1 yes true,$(JAILED)),jailed dylib,tweak package)))

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = memedit

memedit_FILES = Tweak.m $(SRCS)
memedit_CFLAGS = -fobjc-arc $(SRCS_INCLUDE_FLAGS) $(TBD_CFLAGS)

ifneq ($(filter 1 yes true,$(JAILED)),)
	memedit_FILES = Tweak.m $(filter-out il2cpp/DLGUnityHookManager.m memui/views/DLGUnityHooksView.m,$(SRCS))
else
	memedit_EXTRA_FRAMEWORKS = CydiaSubstrate
endif

include $(THEOS_MAKE_PATH)/tweak.mk
ifeq ($(filter 1 yes true,$(JAILED)),)
	SUBPROJECTS += memeditPrefs
endif
include $(THEOS_MAKE_PATH)/aggregate.mk

TARGET_TEST_APP = /Users/mineek/Library/Containers/io.playcover.PlayCover/Applications/com.amanotes.bh.app/TilesHop
TARGET_TEST_APP_ROOT = $(shell dirname $(TARGET_TEST_APP))

testinjectprep: insert_dylib
	./tools/insert_dylib "@executable_path/memedit.dylib" $(TARGET_TEST_APP) --inplace
	ldid -e $(TARGET_TEST_APP) > entitlements.xml
	codesign -f -s - --entitlements entitlements.xml $(TARGET_TEST_APP)
	rm entitlements.xml

testinject: memedit.dylib
	cp ./.theos/obj/memedit.dylib $(TARGET_TEST_APP_ROOT)/memedit.dylib
	vtool -set-build-version 6 15 15 -replace -output $(TARGET_TEST_APP_ROOT)/memedit.dylib $(TARGET_TEST_APP_ROOT)/memedit.dylib
	codesign -f -s - $(TARGET_TEST_APP_ROOT)/memedit.dylib

insert_dylib:
	clang -o tools/insert_dylib tools/insert_dylib.c

clean::
	rm -f tools/insert_dylib
