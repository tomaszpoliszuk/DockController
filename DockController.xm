NSString *domainString = @"com.tomaszpoliszuk.dockcontroller";

NSMutableDictionary *tweakSettings;

static BOOL haveFaceID;

static BOOL enableTweak;

static long long homeScreenRotationStyle;

static long long dockStyle;
static BOOL showDockBackground;
static BOOL showDockDivider;
static long long iconsLayoutFix;

static double iconScale = 0.75;


void TweakSettingsChanged() {
	haveFaceID = [[NSFileManager defaultManager] fileExistsAtPath:@"/var/lib/dpkg/info/gsc.pearl-i-d-capability.list"];

	NSUserDefaults *tweakSettings = [[NSUserDefaults alloc] initWithSuiteName:domainString];

	enableTweak = [([tweakSettings objectForKey:@"enableTweak"] ?: @(YES)) boolValue];

	dockStyle = [([tweakSettings valueForKey:@"dockStyle"] ?: @(0)) integerValue];
	showDockBackground = [([tweakSettings objectForKey:@"showDockBackground"] ?: @(YES)) boolValue];
	showDockDivider = [([tweakSettings objectForKey:@"showDockDivider"] ?: @(YES)) boolValue];

	iconsLayoutFix = [([tweakSettings valueForKey:@"iconsLayoutFix"] ?: @(1)) integerValue];
}

@interface SBDockView : UIView
@property (nonatomic, retain) UIView *backgroundView;
@end

@interface SBWallpaperEffectView : UIView
@end

@interface SBFloatingDockPlatterView : UIView
@end

@interface SBFTouchPassThroughView : UIView
@end
@interface SBFloatingDockView : SBFTouchPassThroughView
@end

@interface SBIconListGridLayoutConfiguration : NSObject
@property (nonatomic, assign) NSString *location;
- (NSString *)findLocation;
- (NSUInteger)numberOfPortraitRows;
- (NSUInteger)numberOfPortraitColumns;
- (NSUInteger)numberOfLandscapeRows;
- (NSUInteger)numberOfLandscapeColumns;
@end

@interface SBIconListView : UIView
- (id)iconLocation;
@end

@interface SBIconListPageControl : UIPageControl
@end

%hook SpringBoard
-(long long)homeScreenRotationStyle {
//	0 = iPhone (no rotation)
//	1 = iPad (rotate icons and dock)
//	2 = iPhone + (rotate icons, dock stays in place)
	long long origValue = %orig;
	homeScreenRotationStyle = origValue;
	return origValue;
}
%end

%hook SBFloatingDockController
+ (bool)isFloatingDockSupported {
	bool origValue = %orig;
	if ( enableTweak && dockStyle == 2 ) {
		return YES;
	} else {
		return origValue;
	}
}
%end

%hook UITraitCollection
- (CGFloat)displayCornerRadius {
	CGFloat origValue = %orig;
	if ( enableTweak && dockStyle == 1 && !haveFaceID ) {
		return 6;
	} else {
		return origValue;
	}
}
%end

%hook SBFloatingDockPlatterView
- (id)backgroundView {
	id origValue = %orig;
	if ( enableTweak && !showDockBackground ) {
		return nil;
	} else {
		return origValue;
	}
}
%end

%hook SBDockView
-(void)layoutSubviews {
	%orig();
	UIImageView *_backgroundImageView = MSHookIvar<UIImageView *>(self, "_backgroundImageView");
	if ( _backgroundImageView != nil && enableTweak && dockStyle == 0 && haveFaceID ) {
		_backgroundImageView.layer.cornerRadius = 0;
		CGRect frame = _backgroundImageView.frame;
		frame.origin.x = 0;
		frame.origin.y = 0;
		frame.size.width = self.frame.size.width + 20;
		frame.size.height = self.frame.size.height + 20;
		_backgroundImageView.frame = frame;
	}
	SBWallpaperEffectView *_backgroundView = MSHookIvar<SBWallpaperEffectView *>(self, "_backgroundView");
	if ( _backgroundView != nil && enableTweak && dockStyle == 0 && haveFaceID ) {
		_backgroundView.layer.cornerRadius = 0;
		CGRect frame = _backgroundView.frame;
		frame.origin.x = 0;
		frame.origin.y = 0;
		frame.size.width = self.frame.size.width + 20;
		frame.size.height = self.frame.size.height + 20;
		_backgroundView.frame = frame;
	}
}
- (id)backgroundView {
	id origValue = %orig;
	if ( enableTweak && !showDockBackground ) {
		return nil;
	} else {
		return origValue;
	}
}
- (void)setBackgroundAlpha:(double)arg1 {
	if ( enableTweak && !showDockBackground ) {
		%orig(0);
	} else {
		%orig;
	}
}
%end

%hook SBFloatingDockView
- (void)updateDividerVisualStyling {
	if ( enableTweak && !showDockDivider && dockStyle == 2 ) {
	} else {
		%orig;
	}
}
%end

%hook SBIconListGridLayoutConfiguration
%property (nonatomic, assign) NSString *location;

%new // findLocation was taken (with the consent of [Burrit0z](https://github.com/Burrit0z)) from https://github.com/Burrit0z/Dockify_Source/blob/4f73f8fdb75f98883b3016a704605d6cd16c7eaa/Dockify.xm#L118-L137 which was Modeled off of Kritanta's solution with ivars - AFAIK one that was used in HomePlus
- (NSString *)findLocation {
	if ( self.location ) {
		return self.location;
	} else {
		NSUInteger rows = MSHookIvar<NSUInteger>( self, "_numberOfPortraitRows" );
		NSUInteger columns = MSHookIvar<NSUInteger>( self, "_numberOfPortraitColumns" );
		if ( rows < 3 && columns == 4 ) {
			self.location =  @"Dock";
		} else if ( ( rows == 3 && columns == 3 ) || ( rows == 4 && columns == 4 ) ) {
			self.location =  @"Folder";
		} else {
			self.location =  @"Root";
		}
	}
	return self.location;
}
- (NSUInteger)numberOfLandscapeRows {
	[self findLocation];
	if ( enableTweak && ( ( homeScreenRotationStyle == 1 || homeScreenRotationStyle == 2 ) && dockStyle == 2 ) && [self.location isEqualToString:@"Root"] ) {
		return ( 3 );
	} else {
		return ( %orig );
	}
}
- (NSUInteger)numberOfLandscapeColumns {
	[self findLocation];
	if ( enableTweak && ( ( homeScreenRotationStyle == 1 || homeScreenRotationStyle == 2 ) && dockStyle == 2 ) && [self.location isEqualToString:@"Root"] ) {
		return ( 8 );
	} else {
		return ( %orig );
	}
}
- (UIEdgeInsets)portraitLayoutInsets {
	UIEdgeInsets origValue = %orig;
	[self findLocation];
	if ( enableTweak && dockStyle == 2 && [self.location isEqualToString:@"Root"] && iconsLayoutFix == 2 ) {
		UIEdgeInsets newValue = UIEdgeInsetsMake(
			origValue.top,
			origValue.left,
			origValue.bottom + 140,
			origValue.right
		);
		return newValue;
	} else {
		return origValue;
	}
}
- (UIEdgeInsets)landscapeLayoutInsets {
	UIEdgeInsets origValue = %orig;
	[self findLocation];
	if ( enableTweak && dockStyle == 2 && [self.location isEqualToString:@"Root"] && iconsLayoutFix == 2 ) {
		UIEdgeInsets newValue = UIEdgeInsetsMake(
			origValue.top - 10,
			origValue.left,
			origValue.bottom + 135,
			origValue.right
		);
		return newValue;
	} else {
		return origValue;
	}
}
%end

%hook SBIconListPageControl
- (id)initWithFrame:(CGRect)arg1 {
	id origValue = %orig;
	if ( enableTweak && iconsLayoutFix == 1 ) {
		return NULL;
	} else {
		return origValue;
	}
}
%end

%hook SBFloatingDockView
+ (void)getMetrics:(CGRect*)arg1 forBounds:(CGRect)arg2 numberOfUserIcons:(unsigned long long)arg3 numberOfRecentIcons:(unsigned long long)arg4 paddingEdgeInsets:(UIEdgeInsets)arg5 referenceIconSize:(CGSize)arg6 maximumIconSize:(CGSize)arg7 referenceInterIconSpacing:(double)arg8 maximumInterIconSpacing:(double)arg9 platterVerticalMargin:(double)arg10 {
	if ( enableTweak && dockStyle == 2 && iconsLayoutFix == 1 ) {
		%orig(arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8 * iconScale, arg9 * iconScale, arg10);
	} else {
		%orig;
	}
}
%end

%hook SBIconListView
-(unsigned long long)iconRowsForCurrentOrientation {
	long long origValue = %orig;
	if ( enableTweak && dockStyle == 2 && [self.iconLocation containsString:@"SBIconLocationRoot"] && iconsLayoutFix == 1 ) {
		return origValue + 1;
	} else {
		return origValue;
	}
}
%end

%ctor {
	TweakSettingsChanged();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)TweakSettingsChanged, CFSTR("com.tomaszpoliszuk.dockcontroller.settingschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	%init;
}
