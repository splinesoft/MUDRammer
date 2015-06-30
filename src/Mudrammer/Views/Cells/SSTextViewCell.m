//
//  SSTextViewCell.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/19/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSTextViewCell.h"
#import "SSMudView.h"
#import <Masonry.h>
#import <TTTAttributedLabel.h>

UIEdgeInsets const kTextInsets = (UIEdgeInsets) { 0, 2, 0, 5 };

@implementation SSTextViewCell

+ (UITableViewCellStyle)cellStyle {
    return UITableViewCellStyleDefault;
}

- (void)configureCell {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    self.backgroundColor = [UIColor clearColor];
    self.clipsToBounds = YES;

    _textView = [[SPLAttributedLabel alloc] initWithFrame:CGRectZero];
    self.textView.backgroundColor = [UIColor clearColor];
    self.textView.font = [SSThemes sharedThemer].currentFont;
    self.textView.lineBreakMode = NSLineBreakByWordWrapping;
    self.textView.numberOfLines = 0;
    self.textView.textInsets = UIEdgeInsetsZero;
    self.textView.kern = 0.0f;
    self.textView.adjustsFontSizeToFitWidth = NO;
    self.textView.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    self.textView.linkAttributes = @{
        (id)kCTForegroundColorAttributeName : (id)((UIColor *)[[SSThemes sharedThemer] valueForThemeKey:kThemeLinkColor]).CGColor
    };
    self.textView.activeLinkAttributes = @{
        (id)kCTForegroundColorAttributeName : (id)[UIColor whiteColor].CGColor,
    };
    self.textView.accessibilityTraits = self.textView.accessibilityTraits | UIAccessibilityTraitStaticText;
    self.textView.enabledTextCheckingTypes = NSTextCheckingTypeLink;

    [self.contentView addSubview:self.textView];
    [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView).insets(kTextInsets);
    }];
}

- (void)dealloc {
    _textView.delegate = nil;
}

#pragma mark - UIAccessibilityContainer

- (BOOL)isAccessibilityElement {
    return NO;
}

- (NSInteger)accessibilityElementCount {
    return 1;
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    if (index == 0) {
        return self.textView;
    }

    return nil;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    if (element == self.textView) {
        return 0;
    }

    return NSNotFound;
}

@end

@implementation SPLAttributedLabel

- (BOOL)isAccessibilityElement {
    return YES;
}

@end
