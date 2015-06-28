//
//  SSMRConstants.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/10/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSMRConstants.h"

NSString * const kStoreName                     = @"Worlds.sqlite";

// Themes
NSString * const kDefaultFontName               = @"Menlo";
CGFloat const kDefaultFontSize                  = 12.0f;

// Theme properties/keypaths to observe
NSString * const kThemeName                     = @"kThemeName";
NSString * const kThemeFontColor                = @"kThemeFontColor";
NSString * const kThemeFontName                 = @"kThemeFontName";
NSString * const kThemeFontSize                 = @"kThemeFontSize";
NSString * const kThemeBackgroundColor          = @"kThemeBackgroundColor";
NSString * const kThemeLinkColor                = @"kThemeLinkColor";
NSString * const kThemeIsDark                   = @"kThemeIsDark";

// Preferences
NSString * const kPrefInitialWorldsCreated      = @"InitialWorldsCreated";
NSString * const kPrefInitialSetupComplete      = @"InitialSetupComplete";
NSString * const kPrefCurrentThemeIndex         = @"CurrentThemeIndex";
NSString * const kPrefCurrentFontSize           = @"CurrentFontSize";
NSString * const kPrefCurrentFontName           = @"CurrentFontName";
NSString * const kPrefSimpleTelnetMode          = @"SimpleTelnetMode";
NSString * const kPrefInputAccessoryBar         = @"InputAccessoryBar";
NSString * const kPrefInputKeepsCommands        = @"InputKeepsCommands";
NSString * const kPrefKeyboardStyle             = @"Keyboard-Style";
NSString * const kPrefRadialControl             = @"Radial-Control";
NSString * const kPrefRadialCommands            = @"Radial-Commands";
NSString * const kPrefAutocorrect               = @"Autocorrect-Enabled";
NSString * const kPrefMoveControl               = @"MovementControl";
NSString * const kPrefLocalEcho                 = @"Local-Echo";
NSString * const kPrefLogging                   = @"Logging-Enabled";
NSString * const kPrefConnectOnStartup          = @"Connect-On-Startup";
NSString * const kPrefStringEncoding            = @"String-Encoding";
NSString * const kPrefTopBarAlwaysVisible       = @"Top-Bar-Always-Visible";
NSString * const kPrefAutocapitalization        = @"MRAutocapitalization";
NSString * const kPrefBTKeyboard                = @"BTKeyboard";

NSString * const kPrefSemicolonCommands         = @"Semicolon-Commands";
NSString * const kPrefSemicolonCommandDelimiter = @"Semicolon-Command-Delimiter";
NSString * const kPrefSemicolonDefaultDelimiter = @";";

NSString * SPLCurrentCommandDelimiter(void) {
    NSString * delimPref = [[NSUserDefaults standardUserDefaults] stringForKey:kPrefSemicolonCommandDelimiter];

    if ([delimPref length] > 0) {
        return delimPref;
    }

    return kPrefSemicolonDefaultDelimiter;
};

// Notifications
NSString * const kNotificationWorldChanged = @"WorldChanged";
NSString * const kNotificationURLTapped    = @"URL-Tapped";

// Clients
NSInteger const kMaximumOpenClients        = 4;
NSTimeInterval const kConnectCommandsDelay = 5;

// Old leftie pref
NSString * const kPrefLeftHanded           = @"Leftie-Movement";

// URLs
NSString * const kMUDRammerHelpURL         = @"http://splinesoft.net/mudrammer/";
NSString * const kMUDRammerSupportEmail    = @"mudrammer@splinesoft.net";
