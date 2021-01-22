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


@interface BSPlatform : NSObject
+ (id)sharedInstance;
- (long long)homeButtonType;
@end

@interface SpringBoard : UIApplication
+ (id)sharedApplication;
- (bool)homeScreenSupportsRotation;
- (UIInterfaceOrientation)activeInterfaceOrientation;
@end

@interface SBMainSwitcherViewController : UIViewController
+ (id)sharedInstance;
- (bool)isMainSwitcherVisible;
@end

@interface SBDockView : UIView
@end

@interface SBIconListView : UIView
- (id)iconLocation;
@end

@interface SBHIconManager : NSObject
- (bool)isShowingSpotlightOrTodayView;
@end

@interface SBIconListGridLayoutConfiguration : NSObject
@property (nonatomic) unsigned long long numberOfPortraitRows;
@property (nonatomic) unsigned long long numberOfPortraitColumns;
- (void)setNumberOfLandscapeRows:(unsigned long long)arg1;
@end

@interface SBFloatingDockController : NSObject
@property (nonatomic, readonly) double floatingDockHeight;
@property (nonatomic, readonly) double preferredVerticalMargin;
@property (readonly, nonatomic) double maximumFloatingDockHeight;
- (void)_dismissFloatingDockIfPresentedAnimated:(bool)arg1 completionHandler:(id /* block */)arg2;
- (void)_presentFloatingDockIfDismissedAnimated:(bool)arg1 completionHandler:(id /* block */)arg2;
@end

@interface SBIconController : UIViewController
@property (nonatomic, readonly) SBHIconManager *iconManager;
@property (nonatomic, readonly) SBFloatingDockController *floatingDockController;
- (bool)isTodayOverlayPresented;
- (bool)isLibraryOverlayPresented;
- (bool)isAnySearchVisibleOrTransitioning;
@end
