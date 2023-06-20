/* Dock Controller - Control Dock on iOS/iPadOS
 * (c) Copyright 2020-2023 Tomasz Poliszuk
 *
 * Dock Controller is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3 of the License.
 *
 * Dock Controller is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with Dock Controller. If not, see <https://www.gnu.org/licenses/>.
 */


#import "headers/DockController.h"
#import <dlfcn.h>
#import <IconSupport/ISIconSupport.h>

UIView * backgroundColorView;

static bool enableTweak;

static long long dockType;
static bool isDockEnabled;

static bool isFloatingDock;

static long long dockBackgroundAppearanceStyle;
static long long dockBackgroundType;

static NSString *dockBackgroundColor;
static UIColor *dockBackgroundColorUIColor;

static bool iPadDockShowDivider;

static long long iPadDockMaximumItems = 20;
static long long iPadDockMaximumItemsInRecents;

static bool iPadDockShowInAppSwitcher;

static bool iPadDockGestureToShowInApps;

static long long iPhoneMaximumItems = 5;

void SettingsChanged() {

	NSUserDefaults *tweakSettings = [[NSUserDefaults alloc] initWithSuiteName:kPackage];

	enableTweak = [([tweakSettings objectForKey:@"enableTweak"] ?: @(YES)) boolValue];

	dockType = [([tweakSettings valueForKey:@"dockType"] ?: @(3)) integerValue];

	dockBackgroundType = [([tweakSettings valueForKey:@"dockBackgroundType"] ?: @(1)) integerValue];

	dockBackgroundAppearanceStyle = [([tweakSettings valueForKey:@"dockBackgroundAppearanceStyle"] ?: @(999)) integerValue];

	dockBackgroundColor = [tweakSettings objectForKey:@"dockBackgroundColor"];
	dockBackgroundColorUIColor = [UIColor _CPW_colorFromString:dockBackgroundColor];

	iPadDockShowDivider = [([tweakSettings objectForKey:@"iPadDockShowDivider"] ?: @(YES)) boolValue];

	iPadDockMaximumItemsInRecents = [([tweakSettings valueForKey:@"iPadDockMaximumItemsInRecents"] ?: @(3)) integerValue];

	iPadDockGestureToShowInApps = [([tweakSettings objectForKey:@"iPadDockGestureToShowInApps"] ?: @(YES)) boolValue];
	iPadDockShowInAppSwitcher = [([tweakSettings objectForKey:@"iPadDockShowInAppSwitcher"] ?: @(YES)) boolValue];

	isFloatingDock = ( dockType == 3 );

	isDockEnabled = dockType;

	[NSNotificationCenter.defaultCenter postNotificationName:@"com.tomaszpoliszuk.dockcontroller.settingschanged" object:nil];

}



%group noDock

%hook SBHDefaultIconListLayoutProvider
- (id)layoutForIconLocation:(NSString *)iconLocation {
	id origValue = %orig;
	if ( [iconLocation isEqual:@"SBIconLocationRoot"] ) {
		SBIconListGridLayoutConfiguration *layoutConfiguration = [origValue layoutConfiguration];
		UIEdgeInsets portraitLayoutInsets = [layoutConfiguration portraitLayoutInsets];
		UIEdgeInsets landscapeLayoutInsets = [layoutConfiguration landscapeLayoutInsets];
		[layoutConfiguration setPortraitLayoutInsets:UIEdgeInsetsMake(portraitLayoutInsets.top, portraitLayoutInsets.left, 53, portraitLayoutInsets.right)];
		[layoutConfiguration setLandscapeLayoutInsets:UIEdgeInsetsMake(landscapeLayoutInsets.top, landscapeLayoutInsets.left, 42, landscapeLayoutInsets.right)];
		if ([%c(SBIconListFlowExtendedLayout) class]) {
			return [[%c(SBIconListFlowExtendedLayout) alloc] initWithLayoutConfiguration:layoutConfiguration];
		} else {
			return [[%c(SBIconListFlowLayout) alloc] initWithLayoutConfiguration:layoutConfiguration];
		}
	}
	return origValue;
}

%end

%hook SBDockView
+ (double)defaultHeight {
	return 0;
}
- (double)dockHeight {
	return 0;
}
%end

%end



%group dockEnabledOrNot

%hook SBRootFolder
- (bool)supportsDock {
	return isDockEnabled;
}
%end

%hook SBRootFolderWithDock
- (bool)supportsDock {
	return isDockEnabled;
}
%end

%end



%group iPhoneOriPadDock

%hook SBFloatingDockController
+ (bool)isFloatingDockSupported {
	return isFloatingDock;
}
%end

%end



%group floatingDockMaximumItems

%hook SBFloatingDockIconListView
+ (unsigned long long)maxIcons {
	return iPadDockMaximumItems;
}
- (unsigned long long)iconColumnsForCurrentOrientation {
	return iPadDockMaximumItems;
}
- (unsigned long long)iconsInRowForSpacingCalculation {
	return [self visibleIcons].count;
}
%end

%hook SBIconListModel
- (id)initWithFolder:(id)folder maxIconCount:(unsigned long long)arg2 {
	id origValue = %orig;
	if ( [folder isMemberOfClass:%c(SBRootFolderWithDock)] ) {
		return %orig(folder, iPadDockMaximumItems);
	}
	return origValue;
}
%end

%hook SBHDefaultIconListLayoutProvider
- (id)layoutForIconLocation:(NSString *)iconLocation {
	id origValue = %orig;
	if ( [iconLocation isEqual:@"SBIconLocationFloatingDock"] ) {
		SBIconListGridLayoutConfiguration *layoutConfiguration = [origValue layoutConfiguration];
		[layoutConfiguration setNumberOfPortraitColumns:iPadDockMaximumItems];
		return [[%c(SBIconListFlowLayout) alloc] initWithLayoutConfiguration:layoutConfiguration];
	}
	return origValue;
}
%end

%end



%group floatingDockMaximumSuggestionsItems

%hook SBFloatingDockSuggestionsViewController
- (unsigned long long)maxNumberOfIcons {
	return iPadDockMaximumItemsInRecents;
}
- (id)initWithNumberOfRecents:(unsigned long long)arg1 iconController:(id)arg2 applicationController:(id)arg3 transitionCoordinator:(id)arg4 suggestionsModel:(id)arg5 {
	return %orig(iPadDockMaximumItemsInRecents, arg2, arg3, arg4, arg5);
}
%end

%hook SBRecentDisplayItemsController
- (id)initWithRemovalPersonality:(long long)arg1 movePersonality:(long long)arg2 transitionFromSources:(id)arg3 maxDisplayItems:(unsigned long long)arg4 eventSource:(id)arg5 applicationController:(id)arg6 {
	return %orig(arg1, arg2, arg3, iPadDockMaximumItemsInRecents, arg5, arg6);
}
%end

%hook SBHDefaultIconListLayoutProvider
- (id)layoutForIconLocation:(NSString *)iconLocation {
	id origValue = %orig;
	if ( [iconLocation isEqual:@"SBIconLocationFloatingDockSuggestions"] ) {
		SBIconListGridLayoutConfiguration *layoutConfiguration = [origValue layoutConfiguration];
		[layoutConfiguration setNumberOfPortraitRows:1];
		[layoutConfiguration setNumberOfPortraitColumns:iPadDockMaximumItemsInRecents];
		return [[%c(SBIconListFlowLayout) alloc] initWithLayoutConfiguration:layoutConfiguration];
	}
	return origValue;
}
%end

%hook SBDockSuggestionsIconListView
+ (unsigned long long)maxIcons {
	return iPadDockMaximumItemsInRecents;
}
- (SBIconListFlowLayout *)layout {
	return [[%c(SBHDefaultIconListLayoutProvider) frameworkFallbackInstance] layoutForIconLocation:[self iconLocation]];
}
- (id)initWithModel:(SBIconListModel *)model layoutProvider:(id)layoutProvider iconLocation:(id)iconLocation orientation:(long long)orientation iconViewProvider:(id)iconViewProvider {
	SBIconListModel *listModel = [[%c(SBIconListModel) alloc] initWithFolder:nil maxIconCount:iPadDockMaximumItemsInRecents];
	return %orig(listModel, layoutProvider, iconLocation, orientation, iconViewProvider);
}
%end

%hook SBFloatingDockSuggestionsModel
- (id)initWithMaximumNumberOfSuggestions:(unsigned long long)arg1 iconController:(id)arg2 recentsController:(id)arg3 recentsDataStore:(id)arg4 recentsDefaults:(id)arg5 floatingDockDefaults:(id)arg6 appSuggestionManager:(id)arg7 analyticsClient:(id)arg8 {
	return %orig(iPadDockMaximumItemsInRecents, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
}
- (id)initWithMaximumNumberOfSuggestions:(unsigned long long)arg1 iconController:(id)arg2 recentsController:(id)arg3 recentsDataStore:(id)arg4 recentsDefaults:(id)arg5 floatingDockDefaults:(id)arg6 appSuggestionManager:(id)arg7 analyticsClient:(id)arg8 applicationController:(id)arg9 {
	return %orig(iPadDockMaximumItemsInRecents, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9);
}
- (id)initWithMaximumNumberOfSuggestions:(unsigned long long)arg1 iconController:(id)arg2 recentsController:(id)arg3 recentsDataStore:(id)arg4 recentsDefaults:(id)arg5 floatingDockDefaults:(id)arg6 appSuggestionManager:(id)arg7 applicationController:(id)arg8 {
	return %orig(iPadDockMaximumItemsInRecents, arg2, arg3, arg4, arg5, arg6, arg7, arg8);
}
%end

%end



%group iPhoneDockMaximumItems

%hook SBRootFolderDockIconListView
+ (unsigned long long)maxIcons {
	return iPhoneMaximumItems;
}
+ (unsigned long long)maxVisibleIconRowsInterfaceOrientation:(long long)orientation {
	unsigned long long origValue = %orig;
	if ( UIDeviceOrientationIsLandscape(orientation) ) {
		return iPhoneMaximumItems;
	}
	return origValue;
}
- (unsigned long long)iconsInRowForSpacingCalculation {
	return [self visibleIcons].count;
}
%end

%hook SBIconListModel
- (id)initWithFolder:(id)folder maxIconCount:(unsigned long long)maxIconCount {
	id origValue = %orig;
	if ( [folder isMemberOfClass:%c(SBRootFolderWithDock)] && maxIconCount == 4 ) {
		return %orig(folder, iPhoneMaximumItems);
	}
	return origValue;
}
%end

%hook SBHDefaultIconListLayoutProvider
- (id)layoutForIconLocation:(NSString *)iconLocation {
	id origValue = %orig;
	if ( [iconLocation isEqual:@"SBIconLocationDock"] ) {
		SBIconListGridLayoutConfiguration *layoutConfiguration = [origValue layoutConfiguration];
		[layoutConfiguration setNumberOfPortraitColumns:iPhoneMaximumItems];
		return [[%c(SBIconListFlowLayout) alloc] initWithLayoutConfiguration:layoutConfiguration];
	}
	return origValue;
}
%end

%end



%group floatingDockDivider

%hook SBFloatingDockView
%new
- (void)_DC_updateDividerVisualStyling {
	UIView *dividerView = [self dividerView];
	[dividerView setHidden:!iPadDockShowDivider];
}
- (id)initWithFrame:(CGRect)frame {
	if ( ( self = %orig ) ) {
		[self _DC_updateDividerVisualStyling];
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_DC_updateDividerVisualStyling) name:@"com.tomaszpoliszuk.dockcontroller.settingschanged" object:nil];
	}
	return self;
}
%end

%end



%group floatingDockBackground

%hook SBFloatingDockView
- (id)initWithFrame:(CGRect)frame {
	if ( ( self = %orig ) ) {
		[self _DC_updateBackgroundVisualStyling];
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_DC_updateBackgroundVisualStyling) name:@"com.tomaszpoliszuk.dockcontroller.settingschanged" object:nil];
	}
	return self;
}
%new
- (void)_DC_updateBackgroundVisualStyling {
	SBFloatingDockPlatterView *mainPlatterView = [self mainPlatterView];
	UIView *backgroundView = [mainPlatterView backgroundView];
	[backgroundView setHidden:(dockBackgroundType != 1)];
	[backgroundColorView setHidden:(dockBackgroundType != 2)];
	[self _DC_updateBackgroundUserInterfaceStyle];
}
%new
- (void)_DC_updateBackgroundUserInterfaceStyle {
	if ( @available(iOS 13, *) ) {
		SBFloatingDockPlatterView *mainPlatterView = [self mainPlatterView];
		UIView *backgroundView = [mainPlatterView backgroundView];
		if ( dockBackgroundAppearanceStyle == 96 ) {
			if ( [UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark ) {
				[backgroundView setOverrideUserInterfaceStyle:1];
			} else if ( [UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleLight ) {
				[backgroundView setOverrideUserInterfaceStyle:2];
			}
		} else if ( dockBackgroundAppearanceStyle == 999 ) {
			[backgroundView setOverrideUserInterfaceStyle:[UITraitCollection currentTraitCollection].userInterfaceStyle];
		} else if ( dockBackgroundAppearanceStyle != 999 ) {
			[backgroundView setOverrideUserInterfaceStyle:dockBackgroundAppearanceStyle];
		}
	}
}
- (void)_dynamicUserInterfaceTraitDidChange {
	%orig;
	[self _DC_updateBackgroundVisualStyling];
}
- (void)setNeedsLayout {
	%orig;
	[self _DC_updateBackgroundUserInterfaceStyle];
}
- (void)layoutSubviews {
	%orig;
	backgroundColorView.frame = [self mainPlatterView].bounds;
}
%end

%hook SBFloatingDockPlatterView
%new
- (void)_DC_createBackgroundColorView {
	backgroundColorView = [[UIView alloc] initWithFrame:[self backgroundView].bounds];
	backgroundColorView.translatesAutoresizingMaskIntoConstraints = false;
	backgroundColorView.layer.masksToBounds = true;
	[self insertSubview:backgroundColorView atIndex:0];
	if ( @available(iOS 13, *) ) {
		[backgroundColorView.topAnchor    constraintEqualToAnchor: self.topAnchor    ].active = true;
		[backgroundColorView.bottomAnchor constraintEqualToAnchor: self.bottomAnchor ].active = true;
		[backgroundColorView.leftAnchor   constraintEqualToAnchor: self.leftAnchor   ].active = true;
		[backgroundColorView.rightAnchor  constraintEqualToAnchor: self.rightAnchor  ].active = true;
	}
	backgroundColorView._cornerRadius = [self backgroundView]._cornerRadius;
	backgroundColorView._continuousCornerRadius = [self backgroundView]._continuousCornerRadius;
	[self _DC_updateBackgroundColorView];
}
%new
- (void)_DC_updateBackgroundColorView {
	backgroundColorView.backgroundColor = dockBackgroundColorUIColor;
	backgroundColorView._cornerRadius = [self backgroundView]._cornerRadius;
	backgroundColorView._continuousCornerRadius = [self backgroundView]._continuousCornerRadius;
}
- (id)initWithFrame:(CGRect)arg1 {
	id origValue = %orig;
	if ( self ) {
		[self _DC_createBackgroundColorView];
	}
	return origValue;
}
- (void)layoutSubviews {
	%orig;
	[self _DC_updateBackgroundColorView];
}
- (void)setHasShadow:(bool)arg1 {
	%orig;
	[self _DC_updateBackgroundColorView];
}
- (void)setBackgroundView:(UIView *)backgroundView {
	%orig;
	backgroundView.clipsToBounds = YES;
}
%end

%end



%group iPhoneDockBackground

%hook SBDockView

- (id)initWithDockListView:(id)arg1 forSnapshot:(bool)arg2 {
	if ( ( self = %orig ) ) {
		[NSNotificationCenter.defaultCenter addObserver:self selector:@selector(_DC_updateBackgroundVisualStyling) name:@"com.tomaszpoliszuk.dockcontroller.settingschanged" object:nil];
	}
	return self;
}
- (void)willMoveToWindow:(id)arg1 {
	%orig;
	[self _DC_createBackgroundColorView];
	[self _DC_updateBackgroundVisualStyling];
}
- (void)_dynamicUserInterfaceTraitDidChange {
	%orig;
	[self _DC_updateBackgroundVisualStyling];
}
- (void)layoutSubviews {
	%orig;
	[self _DC_updateBackgroundVisualStyling];
}
%new
- (void)_DC_createBackgroundColorView {
	UIView *backgroundView;
	if ( [self respondsToSelector:@selector(backgroundView)] ) {
		backgroundView = [self backgroundView];
	} else {
		backgroundView = [self valueForKey:@"_backgroundView"];
	}
	if ( !backgroundColorView ) {
		backgroundColorView = [[UIView alloc] initWithFrame:backgroundView.frame];
	}
	backgroundColorView.translatesAutoresizingMaskIntoConstraints = NO;
	backgroundColorView.layer.masksToBounds = YES;
	[self insertSubview:backgroundColorView atIndex:0];
	if ( @available(iOS 13, *) ) {
		[backgroundColorView.topAnchor    constraintEqualToAnchor: backgroundView.topAnchor    ].active = YES;
		[backgroundColorView.bottomAnchor constraintEqualToAnchor: backgroundView.bottomAnchor ].active = YES;
		[backgroundColorView.leftAnchor   constraintEqualToAnchor: backgroundView.leftAnchor   ].active = YES;
		[backgroundColorView.rightAnchor  constraintEqualToAnchor: backgroundView.rightAnchor  ].active = YES;
	}
	backgroundColorView._cornerRadius = backgroundView._cornerRadius;
	backgroundColorView._continuousCornerRadius = backgroundView._continuousCornerRadius;
	[self _DC_updateBackgroundColorView];
}
%new
- (void)_DC_updateBackgroundVisualStyling {
	UIView *backgroundView;
	if ( [self respondsToSelector:@selector(backgroundView)] ) {
		backgroundView = [self backgroundView];
	} else {
		backgroundView = [self valueForKey:@"_backgroundView"];
	}
	UIView *highlightView = [self valueForKey:@"_highlightView"];
	backgroundView.layer.masksToBounds = YES;
	backgroundColorView.layer.masksToBounds = YES;

	[backgroundView setHidden:(dockBackgroundType != 1)];
	[highlightView setHidden:(dockBackgroundType != 1)];
	[backgroundColorView setHidden:(dockBackgroundType != 2)];
	[self _DC_updateBackgroundUserInterfaceStyle];
	[self _DC_updateBackgroundColorView];

	CGRect backgroundViewFrame = backgroundView.frame;

	backgroundColorView.layer.cornerRadius = backgroundView.layer.cornerRadius;
	backgroundColorView._continuousCornerRadius = backgroundView._continuousCornerRadius;

	backgroundView.frame = backgroundViewFrame;
	backgroundColorView.frame = backgroundViewFrame;

}
%new
- (void)_DC_updateBackgroundUserInterfaceStyle {
	if ( @available(iOS 13, *) ) {
		UIView *backgroundView = [self backgroundView];
		if ( dockBackgroundAppearanceStyle == 96 ) {
 			if ( [UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleDark ) {
				[backgroundView setOverrideUserInterfaceStyle:1];
			} else if ( [UITraitCollection currentTraitCollection].userInterfaceStyle == UIUserInterfaceStyleLight ) {
				[backgroundView setOverrideUserInterfaceStyle:2];
			}
		} else if ( dockBackgroundAppearanceStyle == 999 ) {
			[backgroundView setOverrideUserInterfaceStyle:[UITraitCollection currentTraitCollection].userInterfaceStyle];
		} else if ( dockBackgroundAppearanceStyle != 999 ) {
			[backgroundView setOverrideUserInterfaceStyle:dockBackgroundAppearanceStyle];
		}
	}
}
%new
- (void)_DC_updateBackgroundColorView {
	UIView *backgroundView;
	if ( [self respondsToSelector:@selector(backgroundView)] ) {
		backgroundView = [self backgroundView];
	} else {
		backgroundView = [self valueForKey:@"_backgroundView"];
	}
	backgroundColorView.frame = backgroundView.frame;
	backgroundColorView.backgroundColor = dockBackgroundColorUIColor;
	backgroundColorView._cornerRadius = backgroundView._cornerRadius;
	backgroundColorView._continuousCornerRadius = backgroundView._continuousCornerRadius;
}
%end

%end



%group floatingDockGestureInAppsModern

%hook SBFluidSwitcherViewController
- (bool)isFloatingDockGesturePossible {
	if ( [[%c(SBMainSwitcherViewController) sharedInstanceIfExists] isAnySwitcherVisible] ) {
		return NO;
	}
	return iPadDockGestureToShowInApps;
}
- (bool)isFloatingDockSupported {
	return iPadDockGestureToShowInApps;
}
%end

%end



%group floatingDockGestureInAppsModernForHome

%hook SBHomeGestureSettings
- (bool)isHomeGestureEnabled {
	if ( [[%c(SBLockScreenManager) sharedInstanceIfExists] isLockScreenVisible] ) {
		return NO;
	}
	return iPadDockGestureToShowInApps;
}
%end

%end



%group floatingDockInAppSwitcherModern

%hook SBDeckSwitcherModifier
- (bool)shouldConfigureInAppDockHiddenAssertion {
//	works only for deck switcher
	return !iPadDockShowInAppSwitcher;
}
%end

%hook SBGridSwitcherViewController
- (bool)isWindowVisible {
//	triggers correctly but when grid switcher is opened from today/spotlight/library dock is showing back
	bool origValue = %orig;
	if ( !iPadDockShowInAppSwitcher && origValue && [[%c(SBMainSwitcherViewController) sharedInstanceIfExists] isAnySwitcherVisible] ) {
		[[[%c(SBIconController) sharedInstanceIfExists] floatingDockController] _dismissFloatingDockIfPresentedAnimated:YES completionHandler:nil];
	}
	return origValue;
}
%end

%hook SBMainSwitcherViewController
- (bool)isMainSwitcherVisible {
//	works but triggers after switcher is visible - using this one to prevent reappearing of dock when grid switcher is opened from today/spotlight/library
	bool origValue = %orig;
	if ( !iPadDockShowInAppSwitcher && origValue) {
		[[[%c(SBIconController) sharedInstanceIfExists] floatingDockController] _dismissFloatingDockIfPresentedAnimated:YES completionHandler:nil];
	}
	return origValue;
}
%end

%hook _SBGridFloorSwitcherModifier
- (id)appLayoutToScrollToBeforeTransitioning {
//	present dock back when last app was closed or when grid app switcher is empty
	id origValue = %orig;
	if ( !iPadDockShowInAppSwitcher && !origValue ) {
		SBIconController *iconController = [%c(SBIconController) sharedInstanceIfExists];
		if ( @available(iOS 14, *) ) {
			if (![iconController isTodayOverlayPresented] && ![iconController isLibraryOverlayPresented] && ![iconController isAnySearchVisibleOrTransitioning]) {
				[[iconController floatingDockController] _presentFloatingDockIfDismissedAnimated:YES completionHandler:nil];
			}
		} else {
			if ( ![[iconController iconManager] isShowingSpotlightOrTodayView] ) {
				[[iconController floatingDockController] _presentFloatingDockIfDismissedAnimated:YES completionHandler:nil];
			}
		}
	}
	return origValue;
}
%end

%end



%group floatingDockLayoutFixModern

%hook SBFloatingDockView
- (double)maximumInterIconSpacing {
	return 12;
}
- (double)contentHeight {
	double origValue = %orig;
	return origValue - 8;
}
%end

%end



%group floatingDockLayoutSmallScreenFixLegacy

%hook SBFloatingDockIconListView
- (UIEdgeInsets)layoutInsets {
	UIEdgeInsets origValue = %orig;
	if ( [[%c(UIScreen) mainScreen] bounds].size.width < 375 && [self isMemberOfClass:%c(SBFloatingDockIconListView)] ) {
		double userIcons = [self visibleIcons].count;
		double recentIIcons = [[%c(SBIconController) sharedInstanceIfExists] floatingDockSuggestionsListView].visibleIcons.count;
		double totalIcons = userIcons + recentIIcons;
		if ( userIcons > 2 && recentIIcons == 0 ) {
		} else if ( userIcons == 2 && recentIIcons == 0 ) {
			origValue.left = 80;
			origValue.right = 80;
		} else if ( userIcons < 4 && recentIIcons == 0 ) {
			origValue.left = 50;
			origValue.right = 50;
		} else if ( totalIcons < 4 ) {
			origValue.left = 30;
		}
	}
	return origValue;
}
%end

%hook SBFloatingDockView
- (unsigned long long)minimumUserIconSpaces {
	unsigned long long origValue = %orig;
	if ( [[%c(UIScreen) mainScreen] bounds].size.width < 375 ) {
		double userIcons = [self userIconListView].visibleIcons.count;
		double recentIIcons = [self recentIconListView].visibleIcons.count;
		if ( userIcons < 4 ) {
			return 4 - recentIIcons;
		}
	}
	return origValue;
}
%end

%end



%group iOS13OnlyFloatingDockHomeScreenLayoutFix

%hook SBHDefaultIconListLayoutProvider
- (id)layoutForIconLocation:(NSString *)iconLocation {
	id origValue = %orig;
	if ( [iconLocation isEqual:@"SBIconLocationRoot"] ) {
		SBIconListGridLayoutConfiguration *layoutConfiguration = [origValue layoutConfiguration];
		UIEdgeInsets portraitLayoutInsets = [layoutConfiguration portraitLayoutInsets];
		double fixedBottom = [[%c(UIScreen) mainScreen] bounds].size.height / 3.9;
		[layoutConfiguration setPortraitLayoutInsets:UIEdgeInsetsMake(portraitLayoutInsets.top, portraitLayoutInsets.left, fixedBottom, portraitLayoutInsets.right)];
		if ([%c(SBIconListFlowExtendedLayout) class]) {
			return [[%c(SBIconListFlowExtendedLayout) alloc] initWithLayoutConfiguration:layoutConfiguration];
		} else {
			return [[%c(SBIconListFlowLayout) alloc] initWithLayoutConfiguration:layoutConfiguration];
		}
	}
	return origValue;
}
%end

%end



%group iPhoneDockHomeScreenLayoutFix

%hook SBRootFolderView
- (double)additionalScrollWidthToKeepVisibleInOneDirection {
	return 0;
}
%end

%end



%group floatingDockHomeScreenLayoutFixLegacy

%hook SBRootFolderView
- (CGRect)_iconListFrameForPageRect:(CGRect)arg1 atIndex:(unsigned long long)arg2 {
	CGRect origValue = %orig;
	if ( [%c(SBFloatingDockController) respondsToSelector:@selector(sharedInstance)] ) {
		SBFloatingDockController *floatingDockController = [%c(SBFloatingDockController) sharedInstance];
		double maximumFloatingDockHeight = [floatingDockController maximumFloatingDockHeight];
		if ( UIDeviceOrientationIsPortrait([self orientation]) ) {
			origValue.size.height = [[%c(UIScreen) mainScreen] bounds].size.height - maximumFloatingDockHeight;
		}
	}
	return origValue;
}
%end

%end



%group floatingDockHomeScreenLandscapeLayoutFixModern

%hook SBHDefaultIconListLayoutProvider
- (id)layoutForIconLocation:(NSString *)iconLocation {
	id origValue = %orig;
	if ( [iconLocation isEqual:@"SBIconLocationRoot"] ) {
		SBIconListGridLayoutConfiguration *layoutConfiguration = [origValue layoutConfiguration];
		[layoutConfiguration setNumberOfLandscapeRows:3];
		[layoutConfiguration setNumberOfLandscapeColumns:8];
		if ([%c(SBIconListFlowExtendedLayout) class]) {
			return [[%c(SBIconListFlowExtendedLayout) alloc] initWithLayoutConfiguration:layoutConfiguration];
		} else {
			return [[%c(SBIconListFlowLayout) alloc] initWithLayoutConfiguration:layoutConfiguration];
		}
	}
	return origValue;
}
%end

%hook SBIconListView
- (UIEdgeInsets)layoutInsetsForOrientation:(long long)orientation {
	UIEdgeInsets origValue = %orig;
	if ( [self.iconLocation isEqual:@"SBIconLocationRoot"] ) {
		SBFloatingDockController *floatingDockController = [[%c(SBIconController) sharedInstanceIfExists] floatingDockController];
		double maximumFloatingDockHeight = [floatingDockController maximumFloatingDockHeight];
		if ( UIDeviceOrientationIsLandscape(orientation) ) {
			origValue.bottom = maximumFloatingDockHeight;
		}
	}
	return origValue;
}
%end

%end



%group floatingDockHomeScreenLandscapeLayoutFixLegacy

%hook SBRootFolderView
- (CGRect)_scrollViewFrameForDockEdge:(unsigned long long)arg1 {
	CGRect origValue = %orig;
	origValue.size.width = [[%c(UIScreen) mainScreen] bounds].size.width;
	return origValue;
}
%end

%hook SBRootIconListView
+ (unsigned long long)iconColumnsForInterfaceOrientation:(long long)orientation {
	unsigned long long origValue = %orig;
	if ( UIDeviceOrientationIsLandscape(orientation) && ( origValue == 6 || origValue == 5 ) ) {
		return 8;
	}
	return origValue;
}
+ (unsigned long long)maxVisibleIconRowsInterfaceOrientation:(long long)orientation {
	unsigned long long origValue = %orig;
	if ( UIDeviceOrientationIsLandscape(orientation) && origValue == 4 ) {
		return 3;
	}
	return origValue;
}
+ (unsigned long long)iconRowsForInterfaceOrientation:(long long)orientation {
	unsigned long long origValue = %orig;
	if ( UIDeviceOrientationIsLandscape(orientation) && origValue == 4 ) {
		return 3;
	}
	return origValue;
}
- (unsigned long long)iconColumnsForCurrentOrientation {
	unsigned long long origValue = %orig;
	if ( ( origValue == 6 || origValue == 5 ) && UIDeviceOrientationIsLandscape([self orientation]) ) {
		return 8;
	}
	return origValue;
}
- (unsigned long long)iconRowsForCurrentOrientation {
	unsigned long long origValue = %orig;
	if ( origValue == 4 && UIDeviceOrientationIsLandscape([self orientation]) ) {
		return 3;
	}
	return origValue;
}
%end

%end



%group iPhoneDockMaximumItemsLayoutFixBelow15

%hook SBRootFolderDockIconListView
- (CGSize)iconSpacing {
	CGSize origValue = %orig;
	if ( [self visibleIcons].count > 4 ) {
		double newSize = [[%c(UIScreen) mainScreen] bounds].size.width / 40;
		origValue.width = newSize;
		origValue.height = newSize;
	}
	return origValue;
}
%end

%end



%group iPhoneDockMaximumItemsLayoutFixLegacy

%hook SBRootFolderDockIconListView
- (CGPoint)originForIconAtCoordinate:(SBIconCoordinate)coordinate {
	return [self originForIconAtCoordinate:coordinate numberOfIcons:[self iconsInRowForSpacingCalculation]];
}
%end

%end



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
		%init(dockEnabledOrNot);
		if ( @available(iOS 13, *) ) {
		} else {
			if ( [[NSFileManager defaultManager] fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/IconSupport.dylib"] ) {
				dlopen("/Library/MobileSubstrate/DynamicLibraries/IconSupport.dylib", RTLD_NOW);
				[[objc_getClass("ISIconSupport") sharedInstance] addExtension:@"dockcontroller"];
			}
		}
		if ( isDockEnabled ) {
			%init(iPhoneOriPadDock);
			if ( isFloatingDock ) {
				%init(floatingDockMaximumItems);
				%init(floatingDockMaximumSuggestionsItems);
				%init(floatingDockDivider);
				%init(floatingDockBackground);
				if ( @available(iOS 13, *) ) {
					%init(floatingDockGestureInAppsModern);
					if ( [[%c(BSPlatform) sharedInstance] homeButtonType] != 2 ) {
						%init(floatingDockGestureInAppsModernForHome);
					}
					%init(floatingDockInAppSwitcherModern);
					if ( @available(iOS 14, *) ) {
					} else {
						%init(iOS13OnlyFloatingDockHomeScreenLayoutFix);
					}
					if ( [[[%c(UIDevice) currentDevice] model] rangeOfString:@"iPad"].location == NSNotFound ) {
						%init(floatingDockHomeScreenLandscapeLayoutFixModern);
						if ( [[%c(BSPlatform) sharedInstance] homeButtonType] != 2 ) {
							%init(floatingDockLayoutFixModern);
						}
					}
				} else {
					if ( [[[%c(UIDevice) currentDevice] model] rangeOfString:@"iPad"].location == NSNotFound ) {
						%init(floatingDockHomeScreenLayoutFixLegacy);
						%init(floatingDockHomeScreenLandscapeLayoutFixLegacy);
						if ( [[%c(BSPlatform) sharedInstance] homeButtonType] != 2 ) {
							%init(floatingDockLayoutSmallScreenFixLegacy);
						}
					}
				}
			} else {
				%init(iPhoneDockMaximumItems);
				%init(iPhoneDockBackground);
				%init(iPhoneDockHomeScreenLayoutFix);
				if ( @available(iOS 15, *) ) {
				} else {
					%init(iPhoneDockMaximumItemsLayoutFixBelow15);
				}
				if ( @available(iOS 13, *) ) {
				} else {
					%init(iPhoneDockMaximumItemsLayoutFixLegacy);
				}
			}
		} else {
			%init(noDock);
		}
	}
}



