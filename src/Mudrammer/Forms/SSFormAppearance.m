//
//  SSFormAppearance.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/1/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSFormAppearance.h"

@implementation SSFormAppearance

+ (instancetype)appearance {
    SSFormAppearance *theme = [SSFormAppearance new];

    theme.backgroundColorEnabled = [SSThemes valueForThemeKey:kThemeBackgroundColor];
    theme.backgroundColorDisabled = theme.backgroundColorEnabled;

    theme.entryTextColorEnabled = [SSThemes valueForThemeKey:kThemeFontColor];
    theme.entryTextColorDisabled = theme.entryTextColorEnabled;

    theme.valueColorEnabled = [SSThemes valueForThemeKey:kThemeFontColor];
    theme.valueColorDisabled = theme.valueColorEnabled;

    theme.labelColorEnabled = [SSThemes valueForThemeKey:kThemeFontColor];
    theme.labelColorDisabled = theme.labelColorEnabled;

    theme.actionColorEnabled = [SSThemes valueForThemeKey:kThemeFontColor];
    theme.actionColorDisabled = theme.actionColorEnabled;

    theme.entryAlignment = NSTextAlignmentRight;
    theme.labelAlignment = NSTextAlignmentLeft;
    theme.valueAlignment = NSTextAlignmentRight;
    theme.buttonAlignment = NSTextAlignmentCenter;

    theme.tableSeparatorColor = [UIColor lightGrayColor];
    theme.tableBackgroundColor = [SSThemes valueForThemeKey:kThemeBackgroundColor];

    theme.sectionTitleColor = [UIColor whiteColor];
    theme.sectionFooterColor = [UIColor whiteColor];

    theme.toolbarTranslucent = NO;

    return theme;
}

- (void)cell:(UITableViewCell *)cell willAppearForElement:(QElement *)element atIndexPath:(NSIndexPath *)path
{
    [super cell:cell willAppearForElement:element atIndexPath:path];

    if ([cell isKindOfClass:[QEntryTableViewCell class]]) {
        QEntryTableViewCell *entryCell = (QEntryTableViewCell *)cell;

        if ([entryCell.textField.placeholder length] > 0) {
            UIColor *attColor = [self.entryTextColorEnabled colorWithAlphaComponent:0.7f];

            NSAttributedString *attributedPlaceHolder = [[NSAttributedString alloc] initWithString:entryCell.textField.placeholder
                                                                                        attributes:@{
                                                                                             NSFontAttributeName : entryCell.textField.font,
                                                                                             NSForegroundColorAttributeName : attColor,
                                                                                             NSUnderlineStyleAttributeName : @1,
                                                                                             NSUnderlineColorAttributeName : attColor,
                                                                                        }];

            [entryCell.textField setAttributedPlaceholder:attributedPlaceHolder];
        }
    }
}

@end
