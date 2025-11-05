//
//  SSThemes.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSThemes.h"
#import "DTCustomColoredAccessory.h"
#import "SSSettingsViewController.h"
#import "SSMudHistoryControl.h"

@interface SSThemes ()

- (instancetype) init;

- (void) updateFromCloud:(NSNotification *)notification;
- (void) updateToCloud:(NSNotification *)notification;

- (void) startSyncingToCloud;
- (void) loadThemeFromDefaults;

@property (nonatomic, copy) NSArray *themes;
@property (nonatomic, strong) NSMutableDictionary *curTheme;

@end

@implementation SSThemes

- (instancetype) init {
    if ((self = [super init])) {
        _themes = @[
                    @{
                       kThemeName : NSLocalizedString(@"THEME_ASPHALT",@"Asphalt Theme"),
                       kThemeFontColor : [UIColor whiteColor],
                       kThemeFontName  : kDefaultFontName,
                       kThemeFontSize  : @(kDefaultFontSize),
                       kThemeLinkColor : UIColorFromRGB(0x1797C0),
                       kThemeBackgroundColor : UIColorFromRGB(0x353538),
                       kThemeIsDark    : @YES,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_BLACK",@"Midnight Theme"),
                        kThemeFontColor : [UIColor whiteColor],
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : UIColorFromRGB(0x1797C0),
                        kThemeBackgroundColor : [UIColor blackColor],
                        kThemeIsDark    : @YES,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_WHITE",@"Snowblind Theme"),
                        kThemeFontColor : [UIColor darkTextColor],
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : UIColorFromRGB(0x1797C0),
                        kThemeBackgroundColor : [UIColor whiteColor],
                        kThemeIsDark    : @NO,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_BLUE",@"Baby Blue Theme"),
                        kThemeFontColor : [UIColor whiteColor],
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : [UIColor redColor],
                        kThemeBackgroundColor : UIColorFromRGB(0x0088bb),
                        kThemeIsDark    : @NO,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_JOLIE",@"Jolie Theme"),
                        kThemeFontColor : [UIColor darkTextColor],
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : UIColorFromRGB(0x1797C0),
                        kThemeBackgroundColor : UIColorFromRGB(0xFFD073),
                        kThemeIsDark    : @NO,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_ROSE",@"Rose Theme"),
                        kThemeFontColor : [UIColor darkTextColor],
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : [UIColor redColor],
                        kThemeBackgroundColor : UIColorFromRGB(0xDEAFC7),
                        kThemeIsDark    : @NO,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_AUTUMNAL",@"Autumnal Theme"),
                        kThemeFontColor : [UIColor whiteColor],
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : [UIColor cyanColor],
                        kThemeBackgroundColor : UIColorFromRGB(0xB35910),
                        kThemeIsDark    : @YES,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_PLUM",@"Plum Theme"),
                        kThemeFontColor : [UIColor whiteColor],
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : [UIColor cyanColor],
                        kThemeBackgroundColor : UIColorFromRGB(0x32127A),
                        kThemeIsDark    : @YES,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_HOMEBREW",@"Homebrew Theme"),
                        kThemeFontColor : UIColorFromRGB(0x0AF24F),
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : [UIColor whiteColor],
                        kThemeBackgroundColor : [UIColor blackColor],
                        kThemeIsDark    : @YES,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_HUMANE",@"Humane Theme"),
                        kThemeFontColor : [UIColor darkTextColor],
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : UIColorFromRGB(0x1797C0),
                        kThemeBackgroundColor : [UIColor colorWithRed:(225.0f/256.0f)
                                                                green:(205.0f/256.0f)
                                                                 blue:(177.0f/256.0f)
                                                                alpha:1.0f],
                        kThemeIsDark    : @NO,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_ASSASSIN",nil),
                        kThemeFontColor : UIColorFromRGB(0xD20000),
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : [UIColor whiteColor],
                        kThemeBackgroundColor : [UIColor blackColor],
                        kThemeIsDark    : @YES,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_REDSANDS",nil),
                        kThemeFontColor : UIColorFromRGB(0xD3C8A9),
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : [UIColor whiteColor],
                        kThemeBackgroundColor : UIColorFromRGB(0x8C342B),
                        kThemeIsDark    : @NO,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_GRASS",nil),
                        kThemeFontColor : UIColorFromRGB(0xFFF0A5),
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : [UIColor whiteColor],
                        kThemeBackgroundColor : UIColorFromRGB(0x1A763F),
                        kThemeIsDark    : @NO,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_SILVER",nil),
                        kThemeFontColor : [UIColor blackColor],
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : [UIColor whiteColor],
                        kThemeBackgroundColor : UIColorFromRGB(0x929292),
                        kThemeIsDark    : @NO,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_CHOCOLATE",nil),
                        kThemeFontColor : [UIColor whiteColor],
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : UIColorFromRGB(0x1797C0),
                        kThemeBackgroundColor : RGB(38,22,21),
                        kThemeIsDark    : @YES,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_BECCA",nil),
                        kThemeFontColor : [UIColor whiteColor],
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : [UIColor redColor],
                        kThemeBackgroundColor : UIColorFromRGB(0x663399),
                        kThemeIsDark    : @YES,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_AHLEENA",nil),
                        kThemeFontColor : UIColorFromRGB(0xC7B100),
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : [UIColor whiteColor],
                        kThemeBackgroundColor : [UIColor blackColor],
                        kThemeIsDark    : @YES,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_SUMMONER",nil),
                        kThemeFontColor : UIColorFromRGB(0xfdf6e3),
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : [UIColor whiteColor],
                        kThemeBackgroundColor : UIColorFromRGB(0x073642),
                        kThemeIsDark    : @YES,
                    },
                    @{
                        kThemeName : NSLocalizedString(@"THEME_AVIATOR",nil),
                        kThemeFontColor : UIColorFromRGB(0x5DC6F5),
                        kThemeFontName  : kDefaultFontName,
                        kThemeFontSize  : @(kDefaultFontSize),
                        kThemeLinkColor : [UIColor whiteColor],
                        kThemeBackgroundColor : [UIColor blackColor],
                        kThemeIsDark    : @YES,
                    },
        ];

        NSUInteger themeIndex = [[[NSUserDefaults standardUserDefaults]
                                  objectForKey:kPrefCurrentThemeIndex] unsignedIntegerValue];

        _curTheme = [NSMutableDictionary dictionaryWithDictionary:self.themes[themeIndex]];

        [self applyAppThemes];
    }

    return self;
}

+ (instancetype)sharedThemer {
    static dispatch_once_t predicate;
	static SSThemes *shared;

	dispatch_once(&predicate, ^{
		shared = [[SSThemes alloc] init];
	});

	return shared;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    [self.curTheme removeAllObjects];
    _themes = nil;
}

#pragma mark - app themes

- (id)valueForThemeKey:(NSString *)key {
    return [self currentTheme][key];
}

- (BOOL)isUsingDarkTheme {
    return [(self.curTheme)[kThemeIsDark] boolValue];
}

- (void)applyAppThemes {
    [self startSyncingToCloud];
    [self loadThemeFromDefaults];

    // Navbar/toolbar background
    UIImage *bgImage = [SPLImagesCatalog navBackgroundImage];

    // UINavigationBar
    NSShadow *titleShadow = [NSShadow new];
    [titleShadow setShadowColor:[UIColor darkTextColor]];
    [titleShadow setShadowOffset:CGSizeMake(0, 1)];
    [[UINavigationBar appearance] setTitleTextAttributes:@{
           NSForegroundColorAttributeName : [UIColor whiteColor],
           NSShadowAttributeName : titleShadow,
           NSFontAttributeName : [UIFont boldSystemFontOfSize:([[UIDevice currentDevice] isIPad]
                                                               ? 18.0f
                                                               : 16.0f)]
    }];
    [[UINavigationBar appearance] setBackgroundImage:bgImage
                                       forBarMetrics:UIBarMetricsDefault];

    // iPad navbar
    NSShadow *iPadShadow = [NSShadow new];
    [iPadShadow setShadowColor:[UIColor whiteColor]];
    [iPadShadow setShadowOffset:CGSizeMake(0, 1)];
    [[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil]
     setBackgroundImage:nil
     forBarMetrics:UIBarMetricsDefault];
    [[UINavigationBar appearanceWhenContainedIn:[UIPopoverController class], nil]
     setTitleTextAttributes:@{
          NSForegroundColorAttributeName : [UIColor darkTextColor],
          NSShadowAttributeName : iPadShadow
    }];

    if ([UIPopoverPresentationController class]) {
        [[UINavigationBar appearanceWhenContainedIn:[UIPopoverPresentationController class], nil]
         setBackgroundImage:nil
         forBarMetrics:UIBarMetricsDefault];
        [[UINavigationBar appearanceWhenContainedIn:[UIPopoverPresentationController class], nil]
         setTitleTextAttributes:@{
              NSForegroundColorAttributeName : [UIColor darkTextColor],
              NSShadowAttributeName : iPadShadow
          }];
    }

    // UIToolbar
    [[UIToolbar appearance] setBackgroundImage:bgImage
                            forToolbarPosition:UIBarPositionAny
                                    barMetrics:UIBarMetricsDefault];
    [[UIToolbar appearance] setBarTintColor:[UIColor whiteColor]];

    // UIStatusBar
    // In iOS 7, this relies on UIViewControllerBasedStatusBarAppearance
    // in Info.plist being set to NO.
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    // UISwitch - reapplied upon each theme change
    [[UISwitch appearance] setOnTintColor:[self valueForThemeKey:kThemeFontColor]];

    // History control
    [[SSMudHistoryControl appearance] setBackgroundImage:[SPLImagesCatalog transparentImage]
                                                forState:UIControlStateNormal
                                              barMetrics:UIBarMetricsDefault];
    [[SSMudHistoryControl appearance] setDividerImage:[SPLImagesCatalog transparentImage]
                                  forLeftSegmentState:UIControlStateNormal
                                    rightSegmentState:UIControlStateNormal
                                           barMetrics:UIBarMetricsDefault];
}

- (void)startSyncingToCloud {
    if( [[self class] checkForCloud] ) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateFromCloud:)
                                                     name:NSUbiquitousKeyValueStoreDidChangeExternallyNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateToCloud:)
                                                     name:NSUserDefaultsDidChangeNotification object:nil];
    }
}

- (void)loadThemeFromDefaults {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *themeToApply = [NSMutableDictionary dictionary];
    NSUInteger indexOfSelectedTheme = 0;

    // 1. Font size
    id fontSize = [defaults objectForKey:kPrefCurrentFontSize];

    if( !fontSize || [fontSize isKindOfClass:[NSNull class]] )
        fontSize = @(kDefaultFontSize);

    themeToApply[kThemeFontSize] = fontSize;

    // 2. Index of theme to use
    indexOfSelectedTheme = [[defaults objectForKey:kPrefCurrentThemeIndex] unsignedIntegerValue];

    // 3. Apply base theme
    NSDictionary *base = [self themeAtIndex:indexOfSelectedTheme];

    // 4. font name
    id fontName = [defaults objectForKey:kPrefCurrentFontName];

    if( !fontName || [fontName isKindOfClass:[NSNull class]] )
        fontName = base[kThemeFontName];

    themeToApply[kThemeName] = base[kThemeName];
    themeToApply[kThemeBackgroundColor] = base[kThemeBackgroundColor];
    themeToApply[kThemeLinkColor] = base[kThemeLinkColor];
    themeToApply[kThemeFontColor] = base[kThemeFontColor];
    themeToApply[kThemeFontName] = fontName;

    [self applyTheme:themeToApply];
}

#pragma mark - KVO

+ (BOOL)automaticallyNotifiesObserversForKey:(NSString *)theKey {
    if([kThemeKeySet containsObject:theKey])
        return NO;

    return [super automaticallyNotifiesObserversForKey:theKey];
}

- (id)valueForKey:(NSString *)key {
    return (self.curTheme)[key];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    (self.curTheme)[key] = value;
}

#pragma mark - themes

- (NSUInteger)themeCount {
    return [self.themes count];
}

- (NSDictionary *)themeAtIndex:(NSUInteger)index {
    if( index >= [self.themes count] )
        index = 0;

    return self.themes[index];
}

- (NSDictionary *) currentTheme {
    return self.curTheme;
}

- (void)applyTheme:(NSDictionary *)newTheme {
    for (NSString *key in [newTheme allKeys]) {
        if (newTheme[key]) {
            (self.curTheme)[key] = newTheme[key];
        }
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:@([self indexOfCurrentBaseTheme])
                 forKey:kPrefCurrentThemeIndex];
    [defaults setObject:[self valueForThemeKey:kThemeFontSize]
                 forKey:kPrefCurrentFontSize];
    [defaults setObject:[self valueForThemeKey:kThemeFontName]
                 forKey:kPrefCurrentFontName];

    // Re-theme switches
    [[UISwitch appearance] setOnTintColor:[self valueForThemeKey:kThemeFontColor]];
}

- (UIFont *)currentFont {
    NSString *fontName = [self valueForThemeKey:kThemeFontName];
    NSNumber *fontSize = [self valueForThemeKey:kThemeFontSize];

    if( !fontName || !fontSize ) {
        return [UIFont fontWithName:kDefaultFontName
                               size:kDefaultFontSize];
    }

    UIFont *newFont = [UIFont fontWithName:fontName
                                      size:[fontSize floatValue]];

    if( newFont ) {
        return newFont;
    }

    return [UIFont fontWithName:kDefaultFontName
                           size:kDefaultFontSize];
}

- (NSUInteger)indexOfCurrentBaseTheme {
    NSString *themeName = [self currentTheme][kThemeName];

    for (NSUInteger i = 0; i < [self themeCount]; i++) {
        NSDictionary *theme = [self themeAtIndex:i];

        if ([theme[kThemeName] isEqualToString:themeName]) {
            return i;
        }
    }

    return 0;
}

#pragma mark - icloud K/V

+ (BOOL)checkForCloud {
    return [NSUbiquitousKeyValueStore defaultStore] != nil;
}

- (void)updateFromCloud:(NSNotification *)notification {
    NSUbiquitousKeyValueStore *cloud = [NSUbiquitousKeyValueStore defaultStore];
    NSDictionary *userinfo = [notification userInfo];

    NSArray *changedKeys = userinfo[NSUbiquitousKeyValueStoreChangedKeysKey];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSUserDefaultsDidChangeNotification
                                                  object:nil];

    for (NSString *key in changedKeys) {
        [[NSUserDefaults standardUserDefaults] setObject:[cloud objectForKey:key] forKey:key];
    }

    [self loadThemeFromDefaults];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateToCloud:)
                                                 name:NSUserDefaultsDidChangeNotification object:nil];
}

- (void)updateToCloud:(NSNotification *)notification {
    NSUbiquitousKeyValueStore *cloud = [NSUbiquitousKeyValueStore defaultStore];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    static NSArray *boolPrefs, *objectPrefs;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        boolPrefs = @[kPrefAutocapitalization, kPrefTopBarAlwaysVisible, kPrefSemicolonCommands, kPrefInputKeepsCommands,
                      kPrefInputAccessoryBar, kPrefLogging, kPrefSimpleTelnetMode,
                      kPrefLocalEcho, kPrefAutocorrect, kPrefKeyboardStyle, kPrefConnectOnStartup, kPrefBTKeyboard];

        objectPrefs = @[kPrefMoveControl, kPrefRadialControl, kPrefStringEncoding, kPrefRadialCommands, kPrefSemicolonCommandDelimiter];
    });

    [cloud setObject:@([self indexOfCurrentBaseTheme]) forKey:kPrefCurrentThemeIndex];
    //[cloud setObject:[[SSThemes currentTheme] objectForKey:kThemeFontSize] forKey:kPrefCurrentFontSize];
    [cloud setObject:[self currentTheme][kThemeFontName] forKey:kPrefCurrentFontName];

    // Sync boolean prefs
    [boolPrefs bk_each:^(NSString *boolPref) {
        [cloud setBool:[defaults boolForKey:boolPref] forKey:boolPref];
    }];

    // Sync object prefs
    [objectPrefs bk_each:^(NSString *objectPref) {
        id value = [defaults objectForKey:objectPref];

        if (value) {
            [cloud setObject:value forKey:objectPref];
        }
    }];

    [cloud synchronize];
}

#pragma mark - table configure

+ (void)configureTable:(UITableView *)tableView {
    if (tableView.style == UITableViewStylePlain) {
        tableView.backgroundColor = [[SSThemes sharedThemer] valueForThemeKey:kThemeBackgroundColor];

        if (![[UIDevice currentDevice] isIPad]) {
            [tableView addCenteredFooterWithImage:([[self sharedThemer] isUsingDarkTheme]
                                                   ? [SPLImagesCatalog tildeWhiteImage]
                                                   : [SPLImagesCatalog tildeDarkImage])
                                            alpha:0.5f];
        }
    } else if (tableView.style == UITableViewStyleGrouped) {
        tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    }

    tableView.separatorColor = [UIColor lightGrayColor];
}

+ (void)configureCell:(UITableViewCell *)cell {
    NSDictionary *theme = [[self sharedThemer] currentTheme];

    cell.backgroundColor = theme[kThemeBackgroundColor];

    if( cell.selectionStyle != UITableViewCellSelectionStyleNone )
        cell.selectionStyle = UITableViewCellSelectionStyleGray;

    cell.textLabel.backgroundColor = [UIColor clearColor];
    cell.textLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    cell.textLabel.textColor = theme[kThemeFontColor];

    cell.detailTextLabel.backgroundColor = [UIColor clearColor];
    cell.detailTextLabel.textColor = theme[kThemeFontColor];

    if( cell.accessoryType == UITableViewCellAccessoryDisclosureIndicator ) {
        cell.accessoryType = UITableViewCellAccessoryNone;

        cell.accessoryView = [DTCustomColoredAccessory accessoryWithColor:theme[kThemeFontColor]];
    }
}

@end
