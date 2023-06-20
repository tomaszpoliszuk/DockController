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


#import "../headers/DockController.h"

@implementation DockControllerRootSettings
- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [NSMutableArray new];
		_backgroundSpecifiers = [NSMutableArray new];
		_nativeBackgroundSpecifiers = [NSMutableArray new];
		_iPadDockSpecifiers = [NSMutableArray new];
		_iPadDockRecentSpecifiers = [NSMutableArray new];
		NSMutableArray *removeSpecifiers = [NSMutableArray new];
		for( PSSpecifier *specifier in [self loadSpecifiersFromPlistName:@"DockController" target:self] ) {
			if ( [PSSpecifier environmentPassesPreferenceLoaderFilter:[specifier propertyForKey:@"pl_filter"]] ) {
				[_specifiers addObject:specifier];
			}
		}
		for( PSSpecifier *specifier in _specifiers) {
			NSString *key = [specifier propertyForKey:@"key"];
			if ( [key hasPrefix:@"dockType"] && [[[NSClassFromString(@"UIDevice") currentDevice] model] rangeOfString:@"iPad"].location != NSNotFound ) {
				[removeSpecifiers addObject:specifier];
			}
			if ( [key isEqual:@"dockBackgroundGroup"] || [key isEqual:@"dockBackgroundType"] ) {
				[_backgroundSpecifiers addObject:specifier];
			}
			if ( [key isEqual:@"dockBackgroundAppearanceStyle"] ) {
				[_nativeBackgroundSpecifiers addObject:specifier];
			}
			if ( ( [key hasPrefix:@"iPadDock"] || [key isEqual:@"SBAppLibraryInDockEnabled"] || [key isEqual:@"SBRecentsEnabled"] ) && ![key isEqual:@"iPadDockMaximumItemsInRecents"] ) {
				[_iPadDockSpecifiers addObject:specifier];
			}
			if ( [key isEqual:@"iPadDockMaximumItemsInRecents"] ) {
				[_iPadDockRecentSpecifiers addObject:specifier];
			}
		}
		PSSpecifier *dockType = [self specifierForID:@"dockType"];
		if ( [[self readPreferenceValue:dockType] isEqual:@"0"] ) {
			[removeSpecifiers addObjectsFromArray:_backgroundSpecifiers];
			[removeSpecifiers addObjectsFromArray:_nativeBackgroundSpecifiers];
			[removeSpecifiers addObjectsFromArray:_iPadDockSpecifiers];
			[removeSpecifiers addObjectsFromArray:_iPadDockRecentSpecifiers];
		} else if ( [[self readPreferenceValue:dockType] isEqual:@"1"] ) {
			[removeSpecifiers addObjectsFromArray:_iPadDockSpecifiers];
			[removeSpecifiers addObjectsFromArray:_iPadDockRecentSpecifiers];
		}
		PSSpecifier *iPadDockRecentApplicationsEnabled = [self specifierForID:@"ALLOW_RECENTS"];
		if ( [[self readPreferenceValue:iPadDockRecentApplicationsEnabled] isEqual:@NO] ) {
			[removeSpecifiers addObject:[self specifierForID:@"iPadDockMaximumItemsInRecents"]];
		}
		PSSpecifier *dockBackgroundType = [self specifierForID:@"dockBackgroundType"];
		if ( [[self readPreferenceValue:dockBackgroundType] isEqual:@"0"] ) {
			[removeSpecifiers addObjectsFromArray:_nativeBackgroundSpecifiers];
		}
		[_specifiers removeObjectsInArray:removeSpecifiers];
	}
	return _specifiers;
}
- (void)setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	[super setPreferenceValue:value specifier:specifier];
	PSSpecifier *dockType = [self specifierForID:@"dockType"];
	PSSpecifier *dockBackgroundType = [self specifierForID:@"dockBackgroundType"];
	PSSpecifier *iPadDockRecentApplicationsEnabled = [self specifierForID:@"ALLOW_RECENTS"];
	if ( specifier == dockBackgroundType) {
		if ( [[self readPreferenceValue:dockBackgroundType] isEqual:@"0"] ) {
			[self removeContiguousSpecifiers:_nativeBackgroundSpecifiers animated:YES];
		} else if ( [[self readPreferenceValue:dockBackgroundType] isEqual:@"1"] ) {
			if ( ![self containsSpecifier:[self specifierForID:@"dockBackgroundAppearanceStyle"]] ) {
				[self insertContiguousSpecifiers:_nativeBackgroundSpecifiers afterSpecifierID:@"dockBackgroundType" animated:YES];
			}
		}
	}
	if ( specifier == iPadDockRecentApplicationsEnabled) {
		if ( [[self readPreferenceValue:iPadDockRecentApplicationsEnabled] isEqual:@YES] ) {
			if ( ![self containsSpecifier:[self specifierForID:@"iPadDockMaximumItemsInRecents"]] ) {
				[self insertContiguousSpecifiers:_iPadDockRecentSpecifiers afterSpecifierID:@"ALLOW_RECENTS" animated:YES];
			}
		} else {
			[self removeContiguousSpecifiers:_iPadDockRecentSpecifiers animated:YES];
		}
	}
	if ( specifier == dockType ) {
		if ( [[self readPreferenceValue:dockType] isEqual:@"0"] ) {
			[self removeContiguousSpecifiers:_backgroundSpecifiers animated:YES];
			[self removeContiguousSpecifiers:_nativeBackgroundSpecifiers animated:YES];
			[self removeContiguousSpecifiers:_iPadDockSpecifiers animated:YES];
			[self removeContiguousSpecifiers:_iPadDockRecentSpecifiers animated:YES];
		} else if ( [[self readPreferenceValue:dockType] isEqual:@"1"] ) {
			if ( ![self containsSpecifier:[self specifierForID:@"dockBackgroundGroup"]] ) {
				[self insertContiguousSpecifiers:_backgroundSpecifiers atEndOfGroup:1 animated:YES];
			}
			if ( ![self containsSpecifier:[self specifierForID:@"dockBackgroundAppearanceStyle"]] ) {
				if ( [[self readPreferenceValue:[self specifierForID:@"dockBackgroundType"]] isEqual:@"1"] ) {
					[self insertContiguousSpecifiers:_nativeBackgroundSpecifiers atEndOfGroup:2 animated:YES];
				}
			}
			[self removeContiguousSpecifiers:_iPadDockSpecifiers animated:YES];
			[self removeContiguousSpecifiers:_iPadDockRecentSpecifiers animated:YES];
		} else if ( [[self readPreferenceValue:dockType] isEqual:@"3"] ) {
			if ( ![self containsSpecifier:[self specifierForID:@"dockBackgroundGroup"]] ) {
				[self insertContiguousSpecifiers:_backgroundSpecifiers atEndOfGroup:1 animated:YES];
			}
			if ( ![self containsSpecifier:[self specifierForID:@"dockBackgroundAppearanceStyle"]] ) {
				if ( [[self readPreferenceValue:[self specifierForID:@"dockBackgroundType"]] isEqual:@"1"] ) {
					[self insertContiguousSpecifiers:_nativeBackgroundSpecifiers atEndOfGroup:2 animated:YES];
				}
			}
			if ( ![self containsSpecifier:[self specifierForID:@"iPadDockGroup"]] ) {
				[self insertContiguousSpecifiers:_iPadDockSpecifiers atEndOfGroup:2 animated:YES];
			}
			if ( ![self containsSpecifier:[self specifierForID:@"iPadDockMaximumItemsInRecents"]] ) {
				if ( [[self readPreferenceValue:[self specifierForID:@"ALLOW_RECENTS"]] isEqual:@YES] ) {
					[self insertContiguousSpecifiers:_iPadDockRecentSpecifiers atEndOfGroup:3 animated:YES];
				}
			}
		}
	}
}
- (instancetype)init {
	self = [super init];
	if (self) {
		UIBarButtonItem *applyButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(alertForRespringDevice)];
		self.navigationItem.rightBarButtonItem = applyButton;
	}
	return self;
}
- (void)respringDevice {
//	typedef enum {
//		None					= 0,
//		RestartRenderServer		= (1 << 0), // 1 in decimal, also relaunch backboardd
//		SnapshotTransition		= (1 << 1), // 2 in decimal
//		FadeToBlackTransition	= (1 << 2), // 4 in decimal
//	} SBSRelaunchActionStyle;
	Class ClassSBSRelaunchAction = NSClassFromString(@"SBSRelaunchAction");
	Class ClassFBSSystemService = NSClassFromString(@"FBSSystemService");
	if (ClassSBSRelaunchAction && ClassFBSSystemService) {
		SBSRelaunchAction *relaunchAction = [ClassSBSRelaunchAction actionWithReason:@"RestartRenderServer" options:4 targetURL:[NSURL URLWithString:@"prefs:root=DockController"]];
		FBSSystemService *frontBoardSystemService = [ClassFBSSystemService sharedService];
		[frontBoardSystemService sendActions:[NSSet setWithObject:relaunchAction] withResult:nil];
	}
}
- (void)alertForRespringDevice {
	UIAlertController *confirmRespringAlert = [UIAlertController alertControllerWithTitle:@"Respring Device" message:@"Do you want to respring device?" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction *_Nonnull action) {
		[self respringDevice];
	}];
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	[confirmRespringAlert addAction:cancel];
	[confirmRespringAlert addAction:confirm];
	[self presentViewController:confirmRespringAlert animated:YES completion:nil];
}
- (void)resetSettings {
	NSUserDefaults *tweakSettings = [[NSUserDefaults alloc] initWithSuiteName:kPackage];
	UIAlertController *resetSettingsAlert = [UIAlertController alertControllerWithTitle:@"Reset Dock Controller Settings" message:@"Do you want to reset settings?" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *_Nonnull action) {
		for(NSString *key in [[tweakSettings dictionaryRepresentation] allKeys]) {
			[tweakSettings removeObjectForKey:key];
		}
		[tweakSettings synchronize];
		[self reloadSpecifiers];
		[self alertForRespringDevice];
	}];
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	[resetSettingsAlert addAction:cancel];
	[resetSettingsAlert addAction:confirm];
	[self presentViewController:resetSettingsAlert animated:YES completion:nil];
}
- (void)sourceCode {
	NSURL *sourceCode = [NSURL URLWithString:@"https://github.com/tomaszpoliszuk/DockController"];
	[[UIApplication sharedApplication] openURL:sourceCode options:@{} completionHandler:nil];
}
- (void)knownIssues {
	NSURL *knownIssues = [NSURL URLWithString:@"https://github.com/tomaszpoliszuk/DockController/issues"];
	[[UIApplication sharedApplication] openURL:knownIssues options:@{} completionHandler:nil];
}
- (void)TomaszPoliszukAtBigBoss {
	UIApplication *application = [UIApplication sharedApplication];
	NSString *tweakName = @"Dock Controller";
	tweakName = [tweakName stringByReplacingOccurrencesOfString:@" " withString:@"+"];
	NSURL *packageDescriptionURL = [NSURL URLWithString:[@"http://apt.thebigboss.org/developer-packages.php?name=" stringByAppendingString:tweakName]];
	[application openURL:packageDescriptionURL options:@{} completionHandler:nil];
}
- (void)TomaszPoliszukAtGithub {
	UIApplication *application = [UIApplication sharedApplication];
	NSURL *githubProfileURL = [NSURL URLWithString:@"https://github.com/tomaszpoliszuk/"];
	[application openURL:githubProfileURL options:@{} completionHandler:nil];
}
@end
