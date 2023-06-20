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


#import "system.h"
#import <ColorPickerWell/UIColor+ColorPickerWell.h>

#define kPackage @"com.tomaszpoliszuk.dockcontroller"
#define kSettingsChanged @"com.tomaszpoliszuk.dockcontroller.settingschanged"

@interface DockControllerRootSettings : PSListController
@property (nonatomic, strong) NSMutableArray *backgroundSpecifiers;
@property (nonatomic, strong) NSMutableArray *nativeBackgroundSpecifiers;
@property (nonatomic, strong) NSMutableArray *customBackgroundSpecifiers;
@property (nonatomic, strong) NSMutableArray *iPadDockSpecifiers;
@property (nonatomic, strong) NSMutableArray *iPadDockRecentSpecifiers;
@end

@interface SBFloatingDockView (DockController)
- (void)_DC_updateDividerVisualStyling;
- (void)_DC_updateBackgroundVisualStyling;
- (void)_DC_updateBackgroundUserInterfaceStyle;
@end

@interface SBFloatingDockPlatterView (DockController)
- (void)_DC_createBackgroundColorView;
- (void)_DC_updateBackgroundColorView;
@end

@interface SBDockView (DockController)
- (void)_DC_updateBackgroundVisualStyling;
- (void)_DC_updateBackgroundUserInterfaceStyle;
- (void)_DC_createBackgroundColorView;
- (void)_DC_updateBackgroundColorView;
@end
