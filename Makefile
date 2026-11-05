TARGET := iphone:clang:latest:16.0
ARCHS = arm64 arm64e
THEOS_PACKAGE_SCHEME = rootless
INSTALL_TARGET_PROCESSES = Music

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = AppleMusicTimbreProbe
AppleMusicTimbreProbe_FILES = Tweak.xm
AppleMusicTimbreProbe_CFLAGS = -fobjc-arc
AppleMusicTimbreProbe_FRAMEWORKS = Foundation AVFoundation UIKit
AppleMusicTimbreProbe_CFLAGS += -Wno-deprecated-declarations
AppleMusicTimbreProbe_INSTALL_PATH = /Library/MobileSubstrate/DynamicLibraries

include $(THEOS_MAKE_PATH)/tweak.mk
