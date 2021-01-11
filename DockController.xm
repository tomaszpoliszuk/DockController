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


#define isiOS14OrAbove (kCFCoreFoundationVersionNumber >= 1740.00)

@interface SBDockView : UIView
@property (nonatomic, retain) UIView *backgroundView;
@end

@interface SBIconListView : UIView
- (id)layout;
- (id)iconLocation;
@end

@interface SBIconListGridLayout : NSObject
@end
@interface SBIconListFlowLayout : SBIconListGridLayout
- (id)layoutConfiguration;
@end

@interface SBIconListGridLayoutConfiguration : NSObject
- (void)setNumberOfLandscapeColumns:(unsigned long long)arg1;
- (void)setNumberOfLandscapeRows:(unsigned long long)arg1;
- (void)setNumberOfPortraitColumns:(unsigned long long)arg1;
- (void)setNumberOfPortraitRows:(unsigned long long)arg1;
@end

@interface SBFloatingDockController : NSObject
@property (nonatomic, readonly) double floatingDockHeight;
@property (nonatomic, readonly) double preferredVerticalMargin;
- (bool)isFloatingDockPresented;
- (void)_dismissFloatingDockIfPresentedAnimated:(bool)arg1 completionHandler:(id /* block */)arg2;
//	- (void)_presentFloatingDockIfDismissedAnimated:(bool)arg1 completionHandler:(id /* block */)arg2;
@end

@interface SBIconController : UIViewController
@property (nonatomic, readonly) SBFloatingDockController *floatingDockController;
+ (id)sharedInstance;
@end

@interface BSPlatform : NSObject
+ (id)sharedInstance;
- (long long)homeButtonType;
@end

@interface UISystemShellApplication : UIApplication
@end
@interface SpringBoard : UISystemShellApplication
+ (id)sharedApplication;
- (bool)homeScreenSupportsRotation;
@end

@interface SBMainSwitcherViewController : UIViewController
+ (id)sharedInstance;
- (bool)isMainSwitcherVisible;
@end

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
static bool iPadIconsLayoutFixInPortrait;
static bool iPadIconsLayoutFixInLandscape;

static bool gestureToShowDockInApps;

void TweakSettingsChanged() {
	haveFaceID = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/gsc.pearl-i-d-capability.list"];

	NSUserDefaults *tweakSettings = [[NSUserDefaults alloc] initWithSuiteName:domainString];

	enableTweak = [([tweakSettings objectForKey:@"enableTweak"] ?: @(YES)) boolValue];

	dockStyle = [([tweakSettings valueForKey:@"dockStyle"] ?: @(999)) integerValue];
	showDockBackground = [([tweakSettings objectForKey:@"showDockBackground"] ?: @(YES)) boolValue];
	allowMoreIcons = [([tweakSettings objectForKey:@"allowMoreIcons"] ?: @(YES)) boolValue];
	if (isiOS14OrAbove) {
		allowMoreIcons = NO;
	}

	showDockDivider = [([tweakSettings objectForKey:@"showDockDivider"] ?: @(YES)) boolValue];
	showInAppSwitcher = [([tweakSettings objectForKey:@"showInAppSwitcher"] ?: @(YES)) boolValue];
	numberOfRecents = [([tweakSettings valueForKey:@"numberOfRecents"] ?: @(3)) integerValue];
	iPadIconsLayoutFixInPortrait = [([tweakSettings objectForKey:@"iPadIconsLayoutFixInPortrait"] ?: @(YES)) boolValue];
	iPadIconsLayoutFixInLandscape = [([tweakSettings objectForKey:@"iPadIconsLayoutFixInLandscape"] ?: @(NO)) boolValue];
	gestureToShowDockInApps = [([tweakSettings objectForKey:@"gestureToShowDockInApps"] ?: @(YES)) boolValue];
}

%hook SBFloatingDockController
+ (bool)isFloatingDockSupported {
	bool origValue = %orig;
	if ( enableTweak && dockStyle == 2 ) {
		return YES;
	}
	return origValue;
}
%end

//	%hook SBFloatingDockViewController
//	- (void)setDockOffscreenProgress:(double)arg1 {
//	//	works but without animation, animating is possible but i had bugs with it so far :/
//		if ( enableTweak && !showInAppSwitcher && [[%c(SBMainSwitcherViewController) sharedInstance] isMainSwitcherVisible] ) {
//			arg1 = 1;
//		}
//		%orig;
//	}
//	%end

//		%hook SBMainSwitcherViewControlle
//		- (bool)isMainSwitcherVisible {
//	//	works but triggers after switcher is visible :(
//			bool origValue = %orig;
//			if ( enableTweak && !showInAppSwitcher && origValue && [[[%c(SBIconController) sharedInstance] floatingDockController] isFloatingDockPresented] ) {
//				[[[%c(SBIconController) sharedInstance] floatingDockController] _dismissFloatingDockIfPresentedAnimated:YES completionHandler:nil];
//			}
//			return origValue;
//		}
//		%end

%hook SBDeckSwitcherModifier
- (bool)shouldConfigureInAppDockHiddenAssertion {
//	works only for deck switcher
	bool origValue = %orig;
	if ( enableTweak && !showInAppSwitcher ) {
		return YES;
	}
	return origValue;
}
%end

%hook _SBGridFloorSwitcherModifier
- (bool)shouldConfigureInAppDockHiddenAssertion {
	bool origValue = %orig;
//	should work for grid switcher based on code for deck switcher but it doesn't :(
//	if ( enableTweak && !showInAppSwitcher ) {
//		return YES;
//	}
//	so instead dismiss floating dock using this code (but in this case when toggling from app using home button dock shows for a moment and then hides) :(
	if ( enableTweak && !showInAppSwitcher && [[%c(SBMainSwitcherViewController) sharedInstance] isMainSwitcherVisible] ) {
		[[[%c(SBIconController) sharedInstance] floatingDockController] _dismissFloatingDockIfPresentedAnimated:YES completionHandler:nil];
	}
	return origValue;
}
%end

%hook SBHomeHardwareButton
- (bool)_processDoubleDownAndDoubleUpSimultaneously {
	bool origValue = %orig;
//	so we prevent this using this code - it works but somehow feels wrong ¯\_(ツ)_/¯ and still dock shows for a moment when invoking app switcher from activator ;(
	if ( enableTweak && !showInAppSwitcher && [[%c(SBMainSwitcherViewController) sharedInstance] isMainSwitcherVisible] ) {
		[[[%c(SBIconController) sharedInstance] floatingDockController] _dismissFloatingDockIfPresentedAnimated:YES completionHandler:nil];
	}
	return origValue;
}
%end

%hook SBFloatingDockPlatterView
- (id)backgroundView {
	id origValue = %orig;
	if ( enableTweak && !showDockBackground ) {
		return nil;
	}
	return origValue;
}
%end

%hook SBDockView
- (bool)isDockInset {
	bool origValue = %orig;
	if ( enableTweak && dockStyle == 0 && haveFaceID ) {
		return NO;
	} else if ( enableTweak && dockStyle == 1 && !haveFaceID ) {
		return YES;
	}
	return origValue;
}
- (id)backgroundView {
	id origValue = %orig;
	if ( enableTweak && !showDockBackground ) {
		return nil;
	}
	return origValue;
}
- (void)setBackgroundAlpha:(double)arg1 {
	if ( enableTweak && !showDockBackground ) {
		arg1 = 0;
	}
	%orig;
}
- (void)_updateCornerRadii {
	if ( enableTweak && dockStyle == 1 && !haveFaceID ) {
	%orig;
		self.backgroundView.layer.cornerRadius = 30;
	}
}
%end

%hook SBFloatingDockView
- (void)updateDividerVisualStyling {
	if ( enableTweak && !showDockDivider && dockStyle == 2 ) {
		return;
	}
	%orig;
}
- (double)maximumInterIconSpacing {
	double origValue = %orig;
	if ( enableTweak && dockStyle == 2 && UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) && [[%c(SpringBoard) sharedApplication] homeScreenSupportsRotation] && iPadIconsLayoutFixInLandscape ) {
		return 13;
	}
	return origValue;
}
- (double)platterVerticalMargin {
	double origValue = %orig;
	if ( enableTweak && dockStyle == 2 && UIDeviceOrientationIsLandscape([UIDevice currentDevice].orientation) && [[%c(SpringBoard) sharedApplication] homeScreenSupportsRotation] && iPadIconsLayoutFixInLandscape ) {
		return 5;
	}
	return origValue;
}
- (double)contentHeight {
	double origValue = %orig;
	if ( enableTweak && dockStyle == 2 ) {
		return origValue - 10;
	}
	return origValue;
}
%end

%hook SBIconListView
- (void)didMoveToWindow {
	if ( enableTweak ) {
		if ( [ self.iconLocation isEqual:@"SBIconLocationRoot" ] && dockStyle == 2 && iPadIconsLayoutFixInLandscape ) {
			SBIconListFlowLayout *iconListFlowLayout = [self layout];
			if ( [iconListFlowLayout isKindOfClass:%c(SBIconListFlowLayout)] ) {
				SBIconListGridLayoutConfiguration *iconListGridLayoutConfiguration = iconListFlowLayout.layoutConfiguration;
				if ( [iconListGridLayoutConfiguration isKindOfClass:%c(SBIconListGridLayoutConfiguration)] ) {
					[iconListGridLayoutConfiguration setNumberOfLandscapeRows:3];
					[iconListGridLayoutConfiguration setNumberOfLandscapeColumns:8];
				}
			}
		}
		if ( [ self.iconLocation isEqual:@"SBIconLocationDock" ] && dockStyle != 2 && allowMoreIcons ) {
			SBIconListFlowLayout *iconListFlowLayout = [self layout];
			if ( [iconListFlowLayout isKindOfClass:%c(SBIconListFlowLayout)] ) {
				SBIconListGridLayoutConfiguration *iconListGridLayoutConfiguration = iconListFlowLayout.layoutConfiguration;
				if ( [iconListGridLayoutConfiguration isKindOfClass:%c(SBIconListGridLayoutConfiguration)] ) {
					[iconListGridLayoutConfiguration setNumberOfPortraitColumns:5];
					[iconListGridLayoutConfiguration setNumberOfLandscapeRows:5];
				}
			}
		}
		if ( [ self.iconLocation isEqual:@"SBIconLocationFloatingDock" ] && dockStyle == 2 && allowMoreIcons ) {
			SBIconListFlowLayout *iconListFlowLayout = [self layout];
			if ( [iconListFlowLayout isKindOfClass:%c(SBIconListFlowLayout)] ) {
				SBIconListGridLayoutConfiguration *iconListGridLayoutConfiguration = iconListFlowLayout.layoutConfiguration;
				if ( [iconListGridLayoutConfiguration isKindOfClass:%c(SBIconListGridLayoutConfiguration)] ) {
					[iconListGridLayoutConfiguration setNumberOfPortraitRows:1];
					[iconListGridLayoutConfiguration setNumberOfPortraitColumns:8];
					[iconListGridLayoutConfiguration setNumberOfLandscapeRows:1];
					[iconListGridLayoutConfiguration setNumberOfLandscapeColumns:8];
				}
			}
		}
		if ( [ self.iconLocation isEqual:@"SBIconLocationFloatingDockSuggestions" ] && dockStyle == 2 && numberOfRecents > 0) {
			SBIconListFlowLayout *iconListFlowLayout = [self layout];
			if ( [iconListFlowLayout isKindOfClass:%c(SBIconListFlowLayout)] ) {
				SBIconListGridLayoutConfiguration *iconListGridLayoutConfiguration = iconListFlowLayout.layoutConfiguration;
				if ( [iconListGridLayoutConfiguration isKindOfClass:%c(SBIconListGridLayoutConfiguration)] ) {
					[iconListGridLayoutConfiguration setNumberOfPortraitRows:1];
					[iconListGridLayoutConfiguration setNumberOfPortraitColumns:numberOfRecents];
					[iconListGridLayoutConfiguration setNumberOfLandscapeRows:1];
					[iconListGridLayoutConfiguration setNumberOfLandscapeColumns:numberOfRecents];
				}
			}
		}
	}
	%orig;
}
- (unsigned long long)maximumIconCount {
	unsigned long long origValue = %orig;
	if ( enableTweak ) {
		if ( [ self.iconLocation isEqual:@"SBIconLocationDock" ] && dockStyle != 2 && allowMoreIcons ) {
			return 5;
		}
		if ( [ self.iconLocation isEqual:@"SBIconLocationFloatingDockSuggestions" ] && dockStyle == 2 && numberOfRecents > 0 ) {
			return numberOfRecents;
		}
	}
	return origValue;
}
- (unsigned long long)iconColumnsForCurrentOrientation {
	unsigned long long origValue = %orig;
	if ( enableTweak ) {
		if ( [ self.iconLocation isEqual:@"SBIconLocationDock" ] && dockStyle != 2 && allowMoreIcons ) {
			return 5;
		}
		if ( [ self.iconLocation isEqual:@"SBIconLocationFloatingDockSuggestions" ] && dockStyle == 2 && numberOfRecents > 0 ) {
			return numberOfRecents;
		}
	}
	return origValue;
}
- (unsigned long long)iconsInRowForSpacingCalculation {
	unsigned long long origValue = %orig;
	if ( enableTweak ) {
		if ( [ self.iconLocation isEqual:@"SBIconLocationDock" ] && dockStyle != 2 && allowMoreIcons ) {
			return 5;
		}
		if ( [ self.iconLocation isEqual:@"SBIconLocationFloatingDockSuggestions" ] && dockStyle == 2 && numberOfRecents > 0 ) {
			return numberOfRecents;
		}
	}
	return origValue;
}
%end

%hook SBFloatingDockSuggestionsViewController
- (struct CGPoint)originForIconAtCoordinate:(struct SBIconCoordinate*)arg1 numberOfIcons:(unsigned long long)arg2 {
	struct CGPoint origValue = %orig;
	if ( enableTweak && dockStyle == 2 && numberOfRecents > 0 ) {
		arg2 = numberOfRecents;
	}
	return origValue;
}
- (id)initWithNumberOfRecents:(unsigned long long)arg1 iconController:(id)arg2 applicationController:(id)arg3 layoutStateTransitionCoordinator:(id)arg4 suggestionsModel:(id)arg5 iconViewProvider:(id)arg6 {
	id origValue = %orig;
	if ( enableTweak && dockStyle == 2 && numberOfRecents > 0 ) {
		return %orig(numberOfRecents, arg2, arg3, arg4, arg5, arg6);
	}
	if ( enableTweak && dockStyle == 2 && numberOfRecents == 0 ) {
		return nil;
	}
	return origValue;
}
- (bool)allowsAddingIconCount:(unsigned long long)arg1 {
	bool origValue = %orig;
	if ( enableTweak && dockStyle == 2 && numberOfRecents > 0 ) {
		arg1 = numberOfRecents;
		return YES;
	}
	return origValue;
}
%end

%hook SBFloatingDockSuggestionsModel
- (bool)recentsEnabled {
	bool origValue = %orig;
	if ( enableTweak && dockStyle == 2 && numberOfRecents == 0 ) {
		return NO;
	}
	return origValue;
}
%end

%hook SBIconListView
- (UIEdgeInsets)layoutInsetsForOrientation:(long long)arg1 {
	UIEdgeInsets origValue = %orig;
	if ( enableTweak && dockStyle == 2 && [self.iconLocation containsString:@"SBIconLocationRoot"] && ( iPadIconsLayoutFixInPortrait || iPadIconsLayoutFixInLandscape ) ) {
//		double pageControlHeight = [[[%c(SBIconController) sharedInstance] _rootFolderController] pageControl].defaultHeight;
//		returns 37 on iOS13 but it's unaccessible on iOS14 so - at least for now - I'm using 37 without reading this value
		double pageControlHeight = 37;
		double floatingDockHeight = [[%c(SBIconController) sharedInstance] floatingDockController].floatingDockHeight;
		double preferredVerticalMargin = [[%c(SBIconController) sharedInstance] floatingDockController].preferredVerticalMargin;
		double dockHeightTotal = pageControlHeight + floatingDockHeight + preferredVerticalMargin;
		if ( UIDeviceOrientationIsPortrait(arg1) && iPadIconsLayoutFixInPortrait ) {
			origValue.bottom = dockHeightTotal;
		}
		if ( UIDeviceOrientationIsLandscape(arg1) && iPadIconsLayoutFixInLandscape ) {
			origValue.bottom = dockHeightTotal;
		}
	}
	return origValue;
}
%end

%hook SBHIconModel
- (bool)supportsDock {
	bool origValue = %orig;
	if ( enableTweak && dockStyle == 404 ) {
		return NO;
	}
	return origValue;
}
%end

%hook SBRootFolder
- (bool)supportsDock {
	bool origValue = %orig;
	if ( enableTweak && dockStyle == 404 ) {
		return NO;
	}
	return origValue;
}
%end

%hook SBRootFolderWithDock
- (bool)supportsDock {
	bool origValue = %orig;
	if ( enableTweak && dockStyle == 404 ) {
		return NO;
	}
	return origValue;
}
%end

%hook SBHomeGestureSettings
- (bool)isHomeGestureEnabled {
	bool origValue = %orig;
	BSPlatform *platform = [NSClassFromString(@"BSPlatform") sharedInstance];
	if ( enableTweak && platform.homeButtonType == 1 && dockStyle == 2 ) {
		return gestureToShowDockInApps;
	}
	return origValue;
}
%end

%hook SBFluidSwitcherViewController
- (bool)isFloatingDockGesturePossible {
	bool origValue = %orig;
	BSPlatform *platform = [NSClassFromString(@"BSPlatform") sharedInstance];
	if ( enableTweak && platform.homeButtonType == 2 && dockStyle == 2 ) {
		return gestureToShowDockInApps;
	}
	return origValue;
}
%end

%hook SBHRootFolderVisualConfiguration
- (UIEdgeInsets)dockBackgroundViewInsets {
	UIEdgeInsets origValue = %orig;
	if ( enableTweak && dockStyle == 1 && !haveFaceID ) {
		origValue.top = origValue.top - 7;
		origValue.left = origValue.left + 7;
		origValue.bottom = origValue.bottom + 7;
		origValue.right = origValue.right + 7;
	}
	return origValue;
}
- (UIEdgeInsets)dockListViewInsets {
	UIEdgeInsets origValue = %orig;
	if ( enableTweak && dockStyle == 1 && !haveFaceID ) {
		origValue.top = origValue.top - 7;
		origValue.left = origValue.left + 7;
		origValue.bottom = origValue.bottom + 7;
		origValue.right = origValue.right + 7;
	}
	return origValue;
}
%end

%ctor {
	TweakSettingsChanged();
	CFNotificationCenterAddObserver(
		CFNotificationCenterGetDarwinNotifyCenter(),
		NULL,
		(CFNotificationCallback)TweakSettingsChanged,
		CFSTR("com.tomaszpoliszuk.dockcontroller.settingschanged"),
		NULL,
		CFNotificationSuspensionBehaviorDeliverImmediately
	);
	%init;
}
