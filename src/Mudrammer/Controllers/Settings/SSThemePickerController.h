//
//  SSThemePickerController.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import "CMFontSelectTableViewController.h"

@interface SSThemePickerController : UITableViewController <CMFontSelectTableViewControllerDelegate>

+ (SSThemePickerController *) themePickerController;

typedef NS_ENUM( NSUInteger, SSThemeTableSection ) {
    ThemeTableSectionFontPicker = 0,
    ThemeTableSectionThemePicker,
    ThemeTableNumSections
};

typedef NS_ENUM( NSUInteger, SSFontRow ) {
    FontRowFontSize = 0,
    FontRowFontName,
    FontNumRows
};

@end
