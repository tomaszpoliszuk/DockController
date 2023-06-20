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


#import <UIKit/UIKit.h>
#import <SpringBoardServices/SBSRestartRenderServerAction.h>
#import <FrontBoardServices/FBSSystemService.h>
#import <libprefs/prefs.h>

struct SBIconCoordinate {
	long long row;
	long long col;
};

@interface BSPlatform : NSObject
@property (nonatomic, readonly) long long homeButtonType;
+ (id)sharedInstance;
@end

@interface SBHDefaultIconListLayoutProvider : NSObject
+ (id)frameworkFallbackInstance;
- (id)layoutForIconLocation:(id)arg1;
@end

@interface SBIconListModel : NSObject
- (id)initWithFolder:(id)arg1 maxIconCount:(unsigned long long)arg2;
@end

@interface SBLockScreenManager : NSObject
@property (readonly) bool isLockScreenVisible;
+ (id)sharedInstanceIfExists;
@end

@interface SBFloatingDockController : NSObject
@property (nonatomic, readonly) double maximumFloatingDockHeight;
- (void)_dismissFloatingDockIfPresentedAnimated:(bool)arg1 completionHandler:(id /* block */)arg2;
- (void)_presentFloatingDockIfDismissedAnimated:(bool)arg1 completionHandler:(id /* block */)arg2;
@end

@interface SBHIconManager : NSObject
@property (getter=isShowingSpotlightOrTodayView, nonatomic, readonly) bool showingSpotlightOrTodayView;
@end

@interface SBIconListGridLayoutConfiguration : NSObject
@property (nonatomic) struct UIEdgeInsets portraitLayoutInsets;
@property (nonatomic) struct UIEdgeInsets landscapeLayoutInsets;
@property (nonatomic) unsigned long long numberOfPortraitColumns;
@property (nonatomic) unsigned long long numberOfPortraitRows;
@property (nonatomic) unsigned long long numberOfLandscapeColumns;
@property (nonatomic) unsigned long long numberOfLandscapeRows;
@end

@interface SBIconListGridLayout : NSObject
@property (nonatomic, readonly, copy) SBIconListGridLayoutConfiguration *layoutConfiguration;
- (id)initWithLayoutConfiguration:(id)arg1;
@end

@interface SBFloatingDockPlatterView : UIView
@property (nonatomic, retain) UIView *backgroundView;
@end

@interface SBDockView : UIView
@property (nonatomic, retain) UIView *backgroundView;
@end

@interface SBIconListView : UIView
@property (nonatomic, readonly, copy) NSArray *visibleIcons;
@property (nonatomic, copy) NSString *iconLocation;
@property (nonatomic, readonly) unsigned long long iconsInRowForSpacingCalculation;
@property (nonatomic) long long orientation;
@end

@interface SBDockIconListView : SBIconListView
- (struct CGPoint)originForIconAtCoordinate:(struct SBIconCoordinate)arg1 numberOfIcons:(unsigned long long)arg2;
@end

@interface SBFloatingDockIconListView : SBDockIconListView
@end

@interface SBDockSuggestionsIconListView : SBFloatingDockIconListView
@end

@interface SBRootFolderDockIconListView : SBDockIconListView
@end

@interface SBRootIconListView : SBIconListView
@end

@interface SBFTouchPassThroughView : UIView
@end

@interface SBFloatingDockView : SBFTouchPassThroughView
@property (nonatomic, retain) UIView *dividerView;
@property (nonatomic, retain) SBFloatingDockPlatterView *mainPlatterView;
@property (nonatomic, retain) SBDockIconListView *userIconListView;
@property (nonatomic, retain) SBDockIconListView *recentIconListView;
@end

@interface SBFolderView : UIView
@property (nonatomic) long long orientation;
@end

@interface SBRootFolderView : SBFolderView
@end

@interface SBIconController : UIViewController
@property	(nonatomic, readonly) SBIconListView *floatingDockSuggestionsListView;
@property (nonatomic, readonly) SBFloatingDockController *floatingDockController;
@property (nonatomic, readonly) bool isAnySearchVisibleOrTransitioning;
@property (nonatomic, readonly) SBHIconManager *iconManager;
+ (id)sharedInstanceIfExists;
- (bool)isTodayOverlayPresented;
- (bool)isLibraryOverlayPresented;
@end

@interface SBMainSwitcherViewController : UIViewController
+ (id)sharedInstanceIfExists;
- (bool)isAnySwitcherVisible;
@end

@interface UIView ()
@property (setter=_setCornerRadius:, nonatomic) double _cornerRadius;
@property (setter=_setContinuousCornerRadius:, nonatomic) double _continuousCornerRadius;
@end

@interface PSListController ()
- (bool)containsSpecifier:(id)arg1;
@end
