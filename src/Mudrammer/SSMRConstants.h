//
//  SSMRConstants.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/10/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#pragma once

@import Foundation;

// Enable/disable sending parsing logs to console
//#define __PARSE_ECHO__

// https://mikeash.com/pyblog/friday-qa-2010-06-18-implementing-equality-and-hashing.html
#define NSUINT_BIT (CHAR_BIT * sizeof(NSUInteger))
#define NSUINTROTATE(val, howmuch) ((((NSUInteger)val) << howmuch) | (((NSUInteger)val) >> (NSUINT_BIT - howmuch)))

//#define __MUDRAMMER_SYNC_WORLDS_TO_ICLOUD__

// Sqlite store
extern NSString * const kStoreName;

// Theme defaults
extern NSString * const kDefaultFontName;
extern CGFloat const kDefaultFontSize;

// Theme properties/keypaths to observe
extern NSString * const kThemeName;
extern NSString * const kThemeFontColor;
extern NSString * const kThemeFontName;
extern NSString * const kThemeFontSize;
extern NSString * const kThemeBackgroundColor;
extern NSString * const kThemeLinkColor;
extern NSString * const kThemeIsDark;

// Preferences
extern NSString * const kPrefInitialWorldsCreated;
extern NSString * const kPrefInitialSetupComplete;
extern NSString * const kPrefCurrentThemeIndex;
extern NSString * const kPrefCurrentFontSize;
extern NSString * const kPrefCurrentFontName;
extern NSString * const kPrefSimpleTelnetMode;
extern NSString * const kPrefInputAccessoryBar;
extern NSString * const kPrefInputKeepsCommands;
extern NSString * const kPrefKeyboardStyle;
extern NSString * const kPrefAutocorrect;
extern NSString * const kPrefMoveControl;
extern NSString * const kPrefLocalEcho;
extern NSString * const kPrefLogging;
extern NSString * const kPrefConnectOnStartup;
extern NSString * const kPrefStringEncoding;
extern NSString * const kPrefRadialControl;
extern NSString * const kPrefRadialCommands;
extern NSString * const kPrefTopBarAlwaysVisible;
extern NSString * const kPrefAutocapitalization;
extern NSString * const kPrefBTKeyboard;

extern NSString * const kPrefSemicolonCommands;
extern NSString * const kPrefSemicolonCommandDelimiter;
extern NSString * const kPrefSemicolonDefaultDelimiter; // ";"

extern NSString * SPLCurrentCommandDelimiter(void); // read from prefs, or ";"

// Notifications
extern NSString * const kNotificationWorldChanged;
extern NSString * const kNotificationURLTapped;

// Clients
extern NSInteger const kMaximumOpenClients;
extern NSTimeInterval const kConnectCommandsDelay;

// Old leftie pref
extern NSString * const kPrefLeftHanded;

// URLs
extern NSString * const kMUDRammerHelpURL;
extern NSString * const kMUDRammerSupportEmail;
