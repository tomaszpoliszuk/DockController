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
- (void)_dismissFloatingDockIfPresentedAnimated:(bool)arg1 completionHandler:(id /* block */)arg2;
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
