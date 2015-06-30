//
//  SSThemes.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import Foundation;

// All KVO-observable theme keypaths.
#define kThemeKeySet @[ kThemeFontColor, kThemeFontName, kThemeFontSize, kThemeBackgroundColor, kThemeLinkColor ]

@interface SSThemes : NSObject

// Access the shared themer. Sets up application themes on first init.
+ (instancetype) sharedThemer;

#pragma mark - Theme Access

// Syntax helper for current theme keys.
- (id) valueForThemeKey:(NSString *)key;

// A dictionary of theme properties for the theme at a given index.
- (NSDictionary *) themeAtIndex:(NSUInteger)index;

// Total number of themes available.
@property (nonatomic, readonly) NSUInteger themeCount;

// The currently active theme.
@property (nonatomic, readonly, copy) NSDictionary *currentTheme;

// The current font as selected by the user in Settings -> Themes
@property (nonatomic, readonly, copy) UIFont *currentFont;

// The index in the list of themes at which the currently active theme appears.
@property (nonatomic, readonly) NSUInteger indexOfCurrentBaseTheme;

// YES == this is a theme with a light font on a dark background
//  NO == this is a theme with a dark font on a light background
@property (nonatomic, readonly, getter=isUsingDarkTheme) BOOL usingDarkTheme;

// Apply theme
- (void) applyTheme:(NSDictionary *)newTheme;

// YES if there is an iCloud key-value store currently available
+ (BOOL) checkForCloud;

// Configures a cell or table to match our current theme.
+ (void) configureCell:(UITableViewCell *)cell;
+ (void) configureTable:(UITableView *)table;

@end
