/* Dock Controller - Control Dock on iOS/iPadOS
 * Copyright (C) 2020 Tomasz Poliszuk
 *
 * Dock Controller is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * Dock Controller is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Dock Controller. If not, see <https://www.gnu.org/licenses/>.
 */


#import "DockController.h"

#define kIsiOS14AndUp (kCFCoreFoundationVersionNumber >= 1740.00)
#define kIsiOS13AndUp (kCFCoreFoundationVersionNumber >= 1665.15)

#define kIconController [%c(SBIconController) sharedInstance]
#define kFloatingDockController [kIconController floatingDockController]
#define kDismissFloatingDockIfPresented [kFloatingDockController _dismissFloatingDockIfPresentedAnimated:YES completionHandler:nil]
#define kPresentFloatingDockIfDismissed [kFloatingDockController _presentFloatingDockIfDismissedAnimated:YES completionHandler:nil]
#define kHomeScreenSupportsRotation [[%c(SpringBoard) sharedApplication] homeScreenSupportsRotation]
#define kMainSwitcherViewController [%c(SBMainSwitcherViewController) sharedInstance]
#define kIsMainSwitcherVisible [kMainSwitcherViewController isMainSwitcherVisible]

//	iOS12
#define kIsShowingSpotlightOrTodayView [kIconController isShowingSpotlightOrTodayView]
#define kIsVisible [kMainSwitcherViewController isVisible]
#define kFloatingDockController12 [%c(SBFloatingDockController) sharedInstance]
#define kDismissFloatingDockIfPresented12 [kFloatingDockController12 _dismissFloatingDockIfPresentedAnimated:YES completionHandler:nil]
#define kPresentFloatingDockIfDismissed12 [kFloatingDockController12 _presentFloatingDockIfDismissedAnimated:YES completionHandler:nil]

NSString *const domainString = @"com.tomaszpoliszuk.dockcontroller";

NSMutableDictionary *tweakSettings;

static bool haveFaceID;

static bool enableTweak;

static long long dockStyle;
static bool showDockBackground;
static bool allowMoreIcons;

static bool showDockDivider;
static bool showInAppSwitcher;
static long long numberOfRecents;
static int springboardIconsLayoutPortrait;
static int springboardIconsBottomSpacingPortrait;
static int springboardIconsLayoutLandscape;
static int springboardIconsBottomSpacingLandscape;

static bool gestureToShowDockInApps;

%hook SBHIconModel
- (bool)supportsDock {
	bool origValue = %orig;
	if ( dockStyle == 404 ) {
		return NO;
	}
	return origValue;
}
%end

%hook SBRootFolder
- (bool)supportsDock {
	bool origValue = %orig;
	if ( dockStyle == 404 ) {
		return NO;
	}
	return origValue;
}
%end

%hook SBRootFolderWithDock
- (bool)supportsDock {
	bool origValue = %orig;
	if ( dockStyle == 404 ) {
		return NO;
	}
	return origValue;
}
%end

%hook SBDockView
- (bool)isDockInset {
	bool origValue = %orig;
	if ( dockStyle == 0 && haveFaceID ) {
		return NO;
	} else if ( dockStyle == 1 && !haveFaceID ) {
		return YES;
	}
	return origValue;
}
- (void)_updateCornerRadii {
	%orig;
	if ( !showDockBackground ) {
		UIView *backgroundView = [self valueForKey:@"_backgroundView"];
		UIView *highlightView = [self valueForKey:@"_highlightView"];
		UIView *accessibilityBackgroundView = [self valueForKey:@"_accessibilityBackgroundView"];
		UIImageView *backgroundImageView = [self valueForKey:@"_backgroundImageView"];
		backgroundView.layer.hidden = YES;
		highlightView.layer.hidden = YES;
		accessibilityBackgroundView.layer.hidden = YES;
		backgroundImageView.layer.hidden = YES;
	} else if ( dockStyle == 1 ) {
		UIView *backgroundView = [self valueForKey:@"_backgroundView"];
		UIView *highlightView = [self valueForKey:@"_highlightView"];
		backgroundView.layer.cornerRadius = 30;
		highlightView.layer.hidden = YES;
	}
}
%end

%hook SBFloatingDockController
+ (bool)isFloatingDockSupported {
	bool origValue = %orig;
	if ( dockStyle == 2 ) {
		return YES;
	}
	return origValue;
}
%end

%hook SBFloatingDockPlatterView
- (id)backgroundView {
	id origValue = %orig;
	if ( !showDockBackground ) {
		return nil;
	}
	return origValue;
}
%end

%hook SBFloatingDockView
- (void)updateDividerVisualStyling {
	if ( !showDockDivider && dockStyle == 2 ) {
		return;
	}
	%orig;
}
%end

%hook SBIconListView
- (unsigned long long)maximumIconCount {
	unsigned long long origValue = %orig;
	if ( [ self.iconLocation isEqual:@"SBIconLocationDock" ] && ( ( dockStyle == 1 ) || ( dockStyle == 2 ) ) && allowMoreIcons ) {
		return 5;
	}
	return origValue;
}
%end

%hook SBIconListGridLayoutConfiguration
- (unsigned long long)numberOfPortraitColumns {
	unsigned long long origValue = %orig;
	if ( [self numberOfPortraitRows] == 1 && allowMoreIcons && origValue == 4 && dockStyle == 2 ) {
		return 8;
	} else if ( [self numberOfPortraitRows] == 1 && allowMoreIcons && origValue == 4 && ( ( dockStyle == 1 ) || ( dockStyle == 2 ) ) ) {
		return 5;
	}
	return origValue;
}
- (unsigned long long)numberOfLandscapeColumns {
	unsigned long long origValue = %orig;
	if ( [self numberOfPortraitRows] == 6 && [self numberOfPortraitColumns] == 4 && dockStyle == 2 && springboardIconsLayoutLandscape ) {
		[self setNumberOfLandscapeRows:3];
		return 8;
	}
	return origValue;
}
%end

%hook SBHomeGestureSettings
- (void)setHomeGestureEnabled:(bool)arg1 {
	BSPlatform *platform = [NSClassFromString(@"BSPlatform") sharedInstance];
	if ( platform.homeButtonType == 1 && dockStyle == 2 ) {
		%orig(gestureToShowDockInApps);
		return;
	}
	%orig;
}
%end

%hook SBFluidSwitcherViewController
- (bool)isFloatingDockGesturePossible {
	bool origValue = %orig;
	BSPlatform *platform = [NSClassFromString(@"BSPlatform") sharedInstance];
	if ( platform.homeButtonType == 2 && dockStyle == 2 ) {
		return gestureToShowDockInApps;
	}
	return origValue;
}
%end

%group iOSRecents

%hook SBFloatingDockSuggestionsModel
- (id)initWithMaximumNumberOfSuggestions:(unsigned long long)arg1 iconController:(id)arg2 recentsController:(id)arg3 recentsDataStore:(id)arg4 recentsDefaults:(id)arg5 floatingDockDefaults:(id)arg6 appSuggestionManager:(id)arg7 analyticsClient:(id)arg8 applicationController:(id)arg9 {
//	this one can't be wrapped in if statement - that's why this code didn't worked before when I was testing it, so credits go to brian9206 - developer of HomeDockX - for make me realise that this is correct place but need to be implemented in specific way
	return %orig(numberOfRecents, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
}
%end

%end

%group iOSNoRecents

%hook SBFloatingDockSuggestionsModel
- (void)_setRecentsEnabled:(bool)arg1 {
	%orig(NO);
}
%end

%end

%group iOS13

%hook SBHRootFolderVisualConfiguration
- (UIEdgeInsets)dockBackgroundViewInsets {
	UIEdgeInsets origValue = %orig;
	if ( dockStyle == 1 && !haveFaceID ) {
		origValue.top = origValue.top - 7;
		origValue.left = origValue.left + 7;
		origValue.bottom = origValue.bottom + 7;
		origValue.right = origValue.right + 7;
	}
	return origValue;
}
- (UIEdgeInsets)dockListViewInsets {
	UIEdgeInsets origValue = %orig;
	if ( dockStyle == 1 && !haveFaceID ) {
		origValue.top = origValue.top - 7;
		origValue.left = origValue.left + 7;
		origValue.bottom = origValue.bottom + 7;
		origValue.right = origValue.right + 7;
	}
	return origValue;
}
%end

%hook SBIconListView
- (UIEdgeInsets)layoutInsetsForOrientation:(long long)arg1 {
	UIEdgeInsets origValue = %orig;
	if ( [self.iconLocation isEqual:@"SBIconLocationRoot"] ) {
		if ( dockStyle == 2 ) {
			if ( UIDeviceOrientationIsPortrait(arg1) ) {
				if ( springboardIconsLayoutPortrait == 2 ) {
					origValue.bottom = kFloatingDockController.floatingDockHeight + kFloatingDockController.preferredVerticalMargin + springboardIconsBottomSpacingPortrait;
				} else if ( springboardIconsLayoutPortrait == 1 ) {
					origValue.bottom = springboardIconsBottomSpacingPortrait;
				}
			} else if ( UIDeviceOrientationIsLandscape(arg1) ) {
				if ( springboardIconsLayoutLandscape == 2 ) {
					origValue.bottom = kFloatingDockController.floatingDockHeight + kFloatingDockController.preferredVerticalMargin + springboardIconsBottomSpacingLandscape;
				} else if ( springboardIconsLayoutLandscape == 1 ) {
					origValue.bottom = springboardIconsBottomSpacingLandscape;
				}
			}
		}
		if ( ( ( ( dockStyle == 0 ) || ( dockStyle == 1 ) ) && UIDeviceOrientationIsLandscape(arg1) ) || dockStyle == 404 ) {
			origValue.bottom = 37;
		}
	}
	return origValue;
}
%end

%hook SBFloatingDockView
- (double)maximumInterIconSpacing {
	double origValue = %orig;
	if ( dockStyle == 2 && UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) && kHomeScreenSupportsRotation && springboardIconsLayoutLandscape ) {
		return 13;
	}
	return origValue;
}
- (double)platterVerticalMargin {
	double origValue = %orig;
	if ( dockStyle == 2 && UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) && kHomeScreenSupportsRotation && springboardIconsLayoutLandscape ) {
		return 5;
	}
	return origValue;
}
- (double)contentHeight {
	double origValue = %orig;
	if ( dockStyle == 2 ) {
		return origValue - 10;
	}
	return origValue;
}
%end

%hook SBDeckSwitcherModifier
- (bool)shouldConfigureInAppDockHiddenAssertion {
//	works only for deck switcher
	bool origValue = %orig;
	if ( !showInAppSwitcher ) {
		return YES;
	}
	return origValue;
}
%end

%hook SBGridSwitcherViewController
- (bool)isWindowVisible {
//	triggers correctly but when grid switcher is opened from today/spotlight/library dock is showing back
	bool origValue = %orig;
	if ( !showInAppSwitcher ) {
		if ( origValue ) {
			if ( kIsMainSwitcherVisible ) {
				kDismissFloatingDockIfPresented;
			}
		}
	}
	return origValue;
}
%end

%hook SBMainSwitcherViewController
- (bool)isMainSwitcherVisible {
//	works but triggers after switcher is visible - using this one to prevent reappearing of dock when grid switcher is opened from today/spotlight/library
	bool origValue = %orig;
	if ( !showInAppSwitcher ) {
		if (origValue) {
			kDismissFloatingDockIfPresented;
		}
	}
	return origValue;
}
%end

%hook _SBGridFloorSwitcherModifier
- (id)appLayoutToScrollToBeforeTransitioning {
//	present dock back when last app was closed or when grid app switcher is empty
	id origValue = %orig;
	if ( !showInAppSwitcher && !origValue ) {
		if (kIsiOS14AndUp) {
			if (![kIconController isTodayOverlayPresented] && ![kIconController isLibraryOverlayPresented] && ![kIconController isAnySearchVisibleOrTransitioning]) {
				kPresentFloatingDockIfDismissed;
			}
		} else {
			if ( ![[kIconController iconManager] isShowingSpotlightOrTodayView] ) {
				kPresentFloatingDockIfDismissed;
			}
		}
	}
	return origValue;
}
%end

%end

%group iOS12

%hook SBDockView
- (double)dockHeight {
	double origValue = %orig;
	if ( dockStyle == 404 ) {
		return 0;
	}
	return origValue;
}
%end

%hook SBRootFolderView
- (CGRect)_iconListFrameForPageRect:(CGRect)arg1 atIndex:(unsigned long long)arg2 {
	CGRect origValue = %orig;
	UIInterfaceOrientation orientation = [(SpringBoard*)[UIApplication sharedApplication] activeInterfaceOrientation];
	if ( dockStyle == 2 ) {
		if ( UIDeviceOrientationIsPortrait(orientation) ) {
			if ( springboardIconsLayoutPortrait == 2 ) {
				origValue.size.height = [UIScreen mainScreen].bounds.size.height - springboardIconsBottomSpacingPortrait - [kFloatingDockController12 floatingDockHeight] - [kFloatingDockController12 preferredVerticalMargin];
			} else if ( springboardIconsLayoutPortrait == 1 ) {
				origValue.size.height = [UIScreen mainScreen].bounds.size.height - springboardIconsBottomSpacingPortrait;
			}
		} else if ( UIDeviceOrientationIsLandscape(orientation) ) {
			if ( springboardIconsLayoutLandscape == 2 ) {
				origValue.size.height = [UIScreen mainScreen].bounds.size.height - springboardIconsBottomSpacingLandscape - [kFloatingDockController12 floatingDockHeight] - [kFloatingDockController12 preferredVerticalMargin];
			} else if ( springboardIconsLayoutLandscape == 1 ) {
				origValue.size.height = [UIScreen mainScreen].bounds.size.height - springboardIconsBottomSpacingLandscape;
			}
		}
		if ( UIDeviceOrientationIsLandscape(orientation) && springboardIconsLayoutLandscape ) {
			origValue.size.width = [UIScreen mainScreen].bounds.size.width;
		}
	}
	if ( ( ( ( dockStyle == 0 ) || ( dockStyle == 1 ) ) && UIDeviceOrientationIsLandscape(orientation) ) || dockStyle == 404 ) {
		origValue.size.height = [UIScreen mainScreen].bounds.size.height - 37;
	}
	return origValue;
}
%end

%hook SBDockIconListView
+ (unsigned long long)maxIcons {
	unsigned long long origValue = %orig;
	if ( allowMoreIcons && ( ( dockStyle == 1 ) || ( dockStyle == 2 ) ) ) {
		return 5;
	}
	return origValue;
}
- (unsigned long long)iconColumnsForCurrentOrientation {
	unsigned long long origValue = %orig;
	if ( allowMoreIcons && ( ( dockStyle == 1 ) || ( dockStyle == 2 ) ) ) {
		return 5;
	}
	return origValue;
}
%end

%hook SBFloatingDockIconListView
+ (unsigned long long)maxIcons {
	unsigned long long origValue = %orig;
	if ( allowMoreIcons && dockStyle == 2 ) {
		return 8;
	}
	return origValue;
}
- (unsigned long long)iconColumnsForCurrentOrientation {
	unsigned long long origValue = %orig;
	if ( allowMoreIcons && dockStyle == 2 ) {
		return 8;
	}
	return origValue;
}
%end

%hook SBDeckSwitcherPersonality
- (bool)_isPerformingSlideOffTransitionFromSwitcherToHomeScreen {
//	0 = home to switcher, switcher to app (tap), switcher to app (button), app to switcher, close app, close last app,
//	1 = switcher to home (tap), switcher to home (button),
//	nil = home to empty
	bool origValue = %orig;
	if ( !showInAppSwitcher && origValue && !kIsShowingSpotlightOrTodayView ) {
//	show dock when user switches back to homescreen and today view or spotlight search are not open
		kPresentFloatingDockIfDismissed12;
	} else if ( !showInAppSwitcher && kIsVisible ) {
//	hide dock when user opens deck app switcher
		kDismissFloatingDockIfPresented12;
	}
	return origValue;
}
- (id)topMostAppLayout {
//	show dock after last app is closed
	id origValue = %orig;
	if ( !showInAppSwitcher && !origValue && !kIsShowingSpotlightOrTodayView ) {
		kPresentFloatingDockIfDismissed12;
	}
	return origValue;
}
%end

%hook SBGridSwitcherPersonality
- (bool)_isPerformingSlideOffTransitionFromSwitcherToHomeScreen {
//	0 = home to switcher, switcher to app (tap), switcher to app (button), app to switcher, close app, close last app,
//	1 = switcher to home (tap), switcher to home (button),
//	nil = home to empty
	bool origValue = %orig;
	if ( !showInAppSwitcher && origValue && !kIsShowingSpotlightOrTodayView ) {
//	show dock when user switches back to homescreen and today view or spotlight search are not open
		kPresentFloatingDockIfDismissed12;
	} else if ( !showInAppSwitcher && kIsVisible ) {
//	hide dock when user opens grid app switcher
		kDismissFloatingDockIfPresented12;
	}
	return origValue;
}
%end

%end

void SettingsChanged() {
	haveFaceID = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/gsc.pearl-i-d-capability.list"];

	NSUserDefaults *tweakSettings = [[NSUserDefaults alloc] initWithSuiteName:domainString];

	enableTweak = [([tweakSettings objectForKey:@"enableTweak"] ?: @(YES)) boolValue];

	dockStyle = [([tweakSettings valueForKey:@"dockStyle"] ?: @(999)) integerValue];
	showDockBackground = [([tweakSettings objectForKey:@"showDockBackground"] ?: @(YES)) boolValue];
	allowMoreIcons = [([tweakSettings objectForKey:@"allowMoreIcons"] ?: @(YES)) boolValue];

	showDockDivider = [([tweakSettings objectForKey:@"showDockDivider"] ?: @(YES)) boolValue];
	showInAppSwitcher = [([tweakSettings objectForKey:@"showInAppSwitcher"] ?: @(YES)) boolValue];
	numberOfRecents = [([tweakSettings valueForKey:@"numberOfRecents"] ?: @(3)) integerValue];
	springboardIconsLayoutPortrait = [([tweakSettings valueForKey:@"springboardIconsLayoutPortrait"] ?: @(2)) integerValue];
	springboardIconsBottomSpacingPortrait = [([tweakSettings valueForKey:@"springboardIconsBottomSpacingPortrait"] ?: @(37)) integerValue];
	springboardIconsLayoutLandscape = [([tweakSettings valueForKey:@"springboardIconsLayoutLandscape"] ?: @(0)) integerValue];
	springboardIconsBottomSpacingLandscape = [([tweakSettings valueForKey:@"springboardIconsBottomSpacingLandscape"] ?: @(37)) integerValue];
	gestureToShowDockInApps = [([tweakSettings objectForKey:@"gestureToShowDockInApps"] ?: @(YES)) boolValue];
}

%ctor {
	SettingsChanged();
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		(CFNotificationCallback)SettingsChanged,
		CFSTR("com.tomaszpoliszuk.dockcontroller.settingschanged"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately
	);
	if ( enableTweak ) {
		if (dockStyle == 2 ) {
			if ( numberOfRecents == 0) {
				%init(iOSNoRecents);
			} else {
				%init(iOSRecents);
			}
		}
		if ( kIsiOS13AndUp ) {
			%init(iOS13);
		} else {
			%init(iOS12);
		}
		%init(_ungrouped);
	}
}
