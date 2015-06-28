//
//  SSThemes.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import Foundation;

// All keypaths.

#define kThemeKeySet @[ kThemeFontColor, kThemeFontName, kThemeFontSize, kThemeBackgroundColor, kThemeLinkColor ]

// Themes

@interface SSThemes : NSObject

// Access the shared themer
+ (instancetype) sharedThemer;

// Called at app launch to setup app themes
- (void) applyAppThemes;

#pragma mark - Themes

// Syntax helper for current theme keys.
+ (id) valueForThemeKey:(NSString *)key;

@property (nonatomic, readonly) NSUInteger themeCount;
- (NSDictionary *) themeAtIndex:(NSUInteger)index;
@property (nonatomic, readonly, copy) NSDictionary *currentTheme;
+ (UIFont *) currentFont;
+ (NSUInteger) indexOfCurrentBaseTheme;
@property (nonatomic, getter=isUsingDarkTheme, readonly) BOOL usingDarkTheme;

// Apply theme
- (void) applyTheme:(NSDictionary *)newTheme;

// iCloud sync
+ (BOOL) checkForCloud;

// Configures a cell or table to match our current theme.
+ (void) configureCell:(UITableViewCell *)cell;
+ (void) configureTable:(UITableView *)table;

@end
