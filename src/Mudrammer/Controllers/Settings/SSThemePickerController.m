//
//  SSThemePickerController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSThemePickerController.h"
#import "SSThemeCell.h"
#import "CMFontSelectTableViewController.h"
#import <SSDataSources.h>
#import "SPLCheckMarkView.h"

@interface SSThemePickerController ()
- (SSThemePickerController *) init;

- (void) configureThemeCell:(SSThemeCell *)cell atIndex:(NSUInteger)index;
@end

@implementation SSThemePickerController {
    SSSectionedDataSource *dataSource;
}

- (SSThemePickerController *)init {
    if( ( self = [self initWithStyle:UITableViewStyleGrouped] ) ) {
        self.title = NSLocalizedString(@"THEMES", @"Themes");
        self.clearsSelectionOnViewWillAppear = YES;

        [SSThemes configureTable:self.tableView];

        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;

        // 1st section - font
        dataSource = [[SSSectionedDataSource alloc] initWithSection:
                      [SSSection sectionWithNumberOfItems:FontNumRows]];
        dataSource.tableActionBlock = ^BOOL(SSCellActionType action,
                                            UITableView *tableView,
                                            NSIndexPath *indexPath) {
            return NO;
        };

        // 2nd section - themes
        [dataSource appendSection:[SSSection sectionWithNumberOfItems:
                                   [[SSThemes sharedThemer] themeCount]]];

        // cell creation
        @weakify(self);
        dataSource.cellCreationBlock = ^id(NSNumber *row,
                                           UITableView *tableView,
                                           NSIndexPath *indexPath) {
            @strongify(self);
            switch( indexPath.section ) {
                case ThemeTableSectionFontPicker: {
                    switch( indexPath.row ) {
                        case FontRowFontName: {
                            SSFontCell *fontCell = [SSFontCell cellForTableView:tableView];

                            fontCell.detailTextLabel.font = [UIFont fontWithName:[SSThemes sharedThemer].currentFont.fontName
                                                                            size:16.];
                            fontCell.detailTextLabel.text = [[SSThemes sharedThemer].currentFont familyName];
                            fontCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

                            [SSThemes configureCell:fontCell];

                            return fontCell;
                        }
                        case FontRowFontSize: {
                            SSFontSizeCell *sizeCell = [SSFontSizeCell cellForTableView:tableView];

                            [SSThemes configureCell:sizeCell];

                            return sizeCell;
                        }
                    }
                    break;
                }
                case ThemeTableSectionThemePicker: {
                    SSThemeCell *cell = [SSThemeCell cellForTableView:tableView];
                    [self configureThemeCell:cell atIndex:(NSUInteger)indexPath.row];
                    return cell;
                }
            }

            return nil;
        };

        dataSource.tableView = self.tableView;
    }

    return self;
}

+ (SSThemePickerController *)themePickerController {
    return [[SSThemePickerController alloc] init];
}

- (CGSize)preferredContentSize {
    return [self.tableView sizeThatFits:CGSizeMake(320, CGFLOAT_MAX)];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if( indexPath.section == ThemeTableSectionFontPicker && indexPath.row == FontRowFontSize )
        return 75;

    return tableView.rowHeight;
}

- (void)configureThemeCell:(SSThemeCell *)cell atIndex:(NSUInteger)index {
    SSThemes *themer = [SSThemes sharedThemer];
    NSDictionary *theme = [themer themeAtIndex:index];

    NSDictionary *attributes = @{
         NSForegroundColorAttributeName : theme[kThemeFontColor],
         NSFontAttributeName : [UIFont fontWithName:themer.currentFont.fontName
                                               size:18.]
    };

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
    cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:theme[kThemeName]
                                                                    attributes:attributes];

    cell.backgroundColor = theme[kThemeBackgroundColor];

    // current theme?
    if ([[themer valueForThemeKey:kThemeName] isEqualToString:theme[kThemeName]]) {
        cell.accessoryView = [SPLCheckMarkView checkWithColor:theme[kThemeFontColor]];
    } else {
        cell.accessoryView = nil;
    }
#pragma clang diagnostic pop
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    switch( indexPath.section ) {
        case ThemeTableSectionThemePicker: {
            NSUInteger currentIndex = [[SSThemes sharedThemer] indexOfCurrentBaseTheme];

            if( currentIndex == (NSUInteger)indexPath.row ) {
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
                return;
            }

            NSDictionary *theme = [[SSThemes sharedThemer] themeAtIndex:(NSUInteger)indexPath.row];

            [[SSThemes sharedThemer] applyTheme:@{
                         kThemeBackgroundColor : theme[kThemeBackgroundColor],
                               kThemeLinkColor : theme[kThemeLinkColor],
                               kThemeFontColor : theme[kThemeFontColor],
                                    kThemeName : theme[kThemeName],
                                  kThemeIsDark : theme[kThemeIsDark],
             }];

            [tableView reloadRowsAtIndexPaths:@[ indexPath,
                                                 [NSIndexPath indexPathForRow:(NSInteger)currentIndex
                                                                    inSection:ThemeTableSectionThemePicker],
             [NSIndexPath indexPathForRow:FontRowFontName inSection:ThemeTableSectionFontPicker],
             [NSIndexPath indexPathForRow:FontRowFontSize inSection:ThemeTableSectionFontPicker] ]
                             withRowAnimation:UITableViewRowAnimationFade];

            break;
        }
        case ThemeTableSectionFontPicker:
            switch( indexPath.row ) {
                case FontRowFontName: {
                    CMFontSelectTableViewController *fontSelectTableViewController = [CMFontSelectTableViewController new];
                    fontSelectTableViewController.delegate = self;
                    fontSelectTableViewController.title = NSLocalizedString(@"FONT", @"Font");
                    fontSelectTableViewController.selectedFont = [SSThemes sharedThemer].currentFont;
                    fontSelectTableViewController.fontFamilyNames = @[
                        // Mono
                        @"Courier", @"Courier New",

                        // Mono custom
                        @"Courier Prime", @"Anonymous Pro Minus", @"Larabiefont", @"Monofonto", @"Unispace",
                        @"Source Code Pro",
                        @"Bitstream Vera Sans Mono",
                        @"monofur",
                        @"Monkey",
                        @"spacefurs-mono",
                        @"saxMono",
                        @"Menlo",
                        @"FantasqueSansMono-Regular",
                        @"Luculent",
                        @"Lekton",
                        @"Inconsolata",
                        @"M+ 1m",
                        @"AndaleMono",
                        @"FiraMono-Regular",
                        @"SkyhookMono",

                        // Not mono?
                        //@"Futura",
                      ];

                    [self.navigationController pushViewController:fontSelectTableViewController
                                                         animated:YES];

                    break;
                }
                default:
                    break;
            }

            break;
    }
}

#pragma mark - font selection

- (void)fontSelectTableViewController:(CMFontSelectTableViewController *)fontSelectTableViewController didSelectFont:(UIFont *)selectedFont {
    SSThemes *themer = [SSThemes sharedThemer];

    if (!selectedFont) {
        selectedFont = themer.currentFont;
    }

    [themer applyTheme:@{
            kThemeFontName : [selectedFont fontName],
     }];

    [self.tableView reloadData];
}

@end
