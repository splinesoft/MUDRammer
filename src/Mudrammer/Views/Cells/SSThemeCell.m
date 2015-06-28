//
//  SSThemeCell.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSThemeCell.h"
#import "CMUpDownControl.h"

#pragma mark - SSThemeCell

@implementation SSThemeCell

+ (UITableViewCellStyle)cellStyle {
    return UITableViewCellStyleValue1;
}

- (void)configureCell {
    self.selectionStyle = UITableViewCellSelectionStyleGray;
}

@end

#pragma mark - SSFontCell

@implementation SSFontCell

+ (UITableViewCellStyle)cellStyle {
    return UITableViewCellStyleValue1;
}

- (void)configureCell {
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    self.textLabel.text = NSLocalizedString(@"FONT", @"Font");

    [SSThemes configureCell:self];
}

@end

#pragma mark - SSFontSizeCell

@interface SSFontSizeCell ()
- (void) fontSizeChanged:(CMUpDownControl *)sender;

- (void) performFontSizeChange:(NSNumber *)newSize;
@end

@implementation SSFontSizeCell

+ (UITableViewCellStyle)cellStyle {
    return UITableViewCellStyleDefault;
}

- (void)configureCell {
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    self.textLabel.text = NSLocalizedString(@"FONT_SIZE", @"Font Size");

    CMUpDownControl *sizer = [[CMUpDownControl alloc] init];
    sizer.minimumAllowedValue = 8;
    sizer.maximumAllowedValue = 24;
    sizer.value = (NSInteger)[[SSThemes currentFont] pointSize];
    sizer.backgroundColor = [UIColor clearColor];
    [sizer addTarget:self
              action:@selector(fontSizeChanged:)
    forControlEvents:UIControlEventValueChanged];

    [sizer setFrame:CGRectMake(0, 0, 120, 60)];

    self.accessoryView = sizer;

    [SSThemes configureCell:self];
}

- (void)fontSizeChanged:(CMUpDownControl *)sender {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];

    [self performSelector:@selector(performFontSizeChange:)
               withObject:@(sender.value)
               afterDelay:0.4f];
}

- (void)performFontSizeChange:(NSNumber *)newSize {
    [[SSThemes sharedThemer] applyTheme:@{
                        kThemeFontSize : newSize
     }];
}

@end
