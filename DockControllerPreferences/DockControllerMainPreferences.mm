//#import <Preferences/PSViewController.h>
#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#include <spawn.h>

@interface PSControlTableCell : PSTableCell
- (UIControl *)control;
@end

@interface PSSwitchTableCell : PSControlTableCell
@end

@interface PSListController (DockController)
-(BOOL)containsSpecifier:(id)arg1;
@end

@interface DockControllerMainPreferences : PSListController
@property (nonatomic, retain) NSMutableDictionary *savedSpecifiers;
@end

@implementation DockControllerMainPreferences
-(NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Root" target:self];
	}
	return _specifiers;
}

-(void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	UIBarButtonItem *applyButton = [[UIBarButtonItem alloc] initWithTitle:@"Respring" style:UIBarButtonItemStylePlain target:self action:@selector(respringDevice)];
	self.navigationItem.rightBarButtonItem = applyButton;
}

-(void)respringDevice {
	UIAlertController *confirmRespringAlert = [UIAlertController alertControllerWithTitle:@"Respring Device" message:nil preferredStyle:UIAlertControllerStyleAlert];

	UIAlertAction *confirm = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
		pid_t pid;
		const char *argv[] = {"sbreload", NULL};
		posix_spawn(&pid, "/usr/bin/sbreload", NULL, NULL, (char* const*)argv, NULL);
	}];

	UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:nil];

	[confirmRespringAlert addAction:cancel];
	[confirmRespringAlert addAction:confirm];

	[self presentViewController:confirmRespringAlert animated:YES completion:nil];
}

-(void)sourceCode {
	NSURL *sourceCode = [NSURL URLWithString:@"https://github.com/tomaszpoliszuk/DockController"];
	[[UIApplication sharedApplication] openURL:sourceCode options:@{} completionHandler:nil];
}

-(void)reportIssueAtGithub {
	NSURL *reportIssueAtGithub = [NSURL URLWithString:@"https://github.com/tomaszpoliszuk/DockController/issues/new"];
	[[UIApplication sharedApplication] openURL:reportIssueAtGithub options:@{} completionHandler:nil];
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
