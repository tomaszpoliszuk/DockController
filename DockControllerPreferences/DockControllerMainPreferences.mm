#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>

#define isiOS14OrAbove (kCFCoreFoundationVersionNumber >= 1740.00)

//typedef enum {
//	None					= 0,
//	RestartRenderServer		= (1 << 0), // 1 in decimal, also relaunch backboardd
//	SnapshotTransition		= (1 << 1), // 2 in decimal
//	FadeToBlackTransition	= (1 << 2), // 4 in decimal
//} SBSRelaunchActionStyle;

NSString *const domainString = @"com.tomaszpoliszuk.dockcontroller";

@interface BSAction : NSObject
@end
@interface SBSRelaunchAction : BSAction
+ (id)actionWithReason:(id)arg1 options:(unsigned long long)arg2 targetURL:(id)arg3;
@end

@interface FBSSystemService : NSObject
+ (id)sharedService;
- (void)sendActions:(id)arg1 withResult:(id /* block */)arg2;
@end

@interface DockControllerTableCell : PSTableCell
@end

@interface PSControlTableCell : PSTableCell
- (UIControl *)control;
@end

@interface PSSwitchTableCell : PSControlTableCell
@end

@interface DockControllerSwitchTableCell : PSSwitchTableCell
@end

@interface PSListController (DockController)
-(BOOL)containsSpecifier:(id)arg1;
@end

@interface DockControllerMainPreferences : PSListController {
	NSMutableArray *removeSpecifiers;
}
@property (nonatomic, retain) NSMutableDictionary *savedSpecifiers;
@end

@implementation DockControllerTableCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(id)specifier {
	return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];
}
- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];
	NSString *sublabel = [specifier propertyForKey:@"sublabel"];
	if (sublabel) {
		self.detailTextLabel.text = [sublabel description];
		self.detailTextLabel.textColor = [UIColor grayColor];
	}
}
@end

@implementation DockControllerSwitchTableCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(id)identifier specifier:(id)specifier {
	return [super initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:identifier specifier:specifier];
}
- (void)refreshCellContentsWithSpecifier:(PSSpecifier *)specifier {
	[super refreshCellContentsWithSpecifier:specifier];
	NSString *sublabel = [specifier propertyForKey:@"sublabel"];
	if (sublabel) {
		self.detailTextLabel.text = [sublabel description];
		self.detailTextLabel.textColor = [UIColor grayColor];
	}
}
@end

@implementation DockControllerMainPreferences
-(NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
		if ( isiOS14OrAbove ) {
			removeSpecifiers = [[NSMutableArray alloc]init];
			for(PSSpecifier* specifier in _specifiers) {
				NSString* key = [specifier propertyForKey:@"key"];
				if(
					[key isEqual:@"allowMoreIcons"]
				) {
					[removeSpecifiers addObject:specifier];
				}

			}
			[_specifiers removeObjectsInArray:removeSpecifiers];
		}
	}
	return _specifiers;
}
- (instancetype)init {
	self = [super init];
	if (self) {
		UIBarButtonItem *applyButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(respringDevice)];
		self.navigationItem.rightBarButtonItem = applyButton;
	}
	return self;
}
-(void)respringDevice {
	UIAlertController *confirmRespringAlert = [UIAlertController alertControllerWithTitle:@"Respring Device" message:@"Do you want to respring device?" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		SBSRelaunchAction *respringAction = [NSClassFromString(@"SBSRelaunchAction") actionWithReason:@"RestartRenderServer" options:4 targetURL:[NSURL URLWithString:@"prefs:root=Dock%20Controller"]];
		FBSSystemService *frontBoardService = [NSClassFromString(@"FBSSystemService") sharedService];
		NSSet *actions = [NSSet setWithObject:respringAction];
		[frontBoardService sendActions:actions withResult:nil];
	}];
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	[confirmRespringAlert addAction:cancel];
	[confirmRespringAlert addAction:confirm];
	[self presentViewController:confirmRespringAlert animated:YES completion:nil];
}
- (void)resetSettings {
	NSUserDefaults *tweakSettings = [[NSUserDefaults alloc] initWithSuiteName:domainString];
	UIAlertController *resetSettingsAlert = [UIAlertController alertControllerWithTitle:@"Reset Dock Controller Settings" message:@"Do you want to reset settings?" preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"Confirm" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
		for(NSString* key in [[tweakSettings dictionaryRepresentation] allKeys]) {
			[tweakSettings removeObjectForKey:key];
		}
		[tweakSettings synchronize];
		[self reloadSpecifiers];
		[self respringDevice];
	}];
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];
	[resetSettingsAlert addAction:cancel];
	[resetSettingsAlert addAction:confirm];
	[self presentViewController:resetSettingsAlert animated:YES completion:nil];
}
-(void)sourceCode {
	NSURL *sourceCode = [NSURL URLWithString:@"https://github.com/tomaszpoliszuk/DockController"];
	[[UIApplication sharedApplication] openURL:sourceCode options:@{} completionHandler:nil];
}
-(void)knownIssues {
	NSURL *knownIssues = [NSURL URLWithString:@"https://github.com/tomaszpoliszuk/DockController/issues"];
	[[UIApplication sharedApplication] openURL:knownIssues options:@{} completionHandler:nil];
}
-(void)TomaszPoliszukAtBigBoss {
	UIApplication *application = [UIApplication sharedApplication];
	NSString *tweakName = @"Dock+Controller";
	NSURL *twitterWebsite = [NSURL URLWithString:[@"http://apt.thebigboss.org/developer-packages.php?name=" stringByAppendingString:tweakName]];
	[application openURL:twitterWebsite options:@{} completionHandler:nil];
}
-(void)TomaszPoliszukAtGithub {
	UIApplication *application = [UIApplication sharedApplication];
	NSString *username = @"tomaszpoliszuk";
	NSURL *githubWebsite = [NSURL URLWithString:[@"https://github.com/" stringByAppendingString:username]];
	[application openURL:githubWebsite options:@{} completionHandler:nil];
}
-(void)TomaszPoliszukAtTwitter {
	UIApplication *application = [UIApplication sharedApplication];
	NSString *username = @"tomaszpoliszuk";
	NSURL *twitterWebsite = [NSURL URLWithString:[@"https://mobile.twitter.com/" stringByAppendingString:username]];
	[application openURL:twitterWebsite options:@{} completionHandler:nil];
}
@end
