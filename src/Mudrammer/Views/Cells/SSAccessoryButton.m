//
//  SSAccessoryButton.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/19/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSAccessoryButton.h"
#import <Masonry.h>
#import <TTTAttributedLabel.h>

#define kObservedProps @[ kThemeFontColor, kThemeFontName ]

@interface SSAccessoryButton ()

@property (nonatomic, strong) TTTAttributedLabel *label;
@property (nonatomic, strong) FBKVOController *kvoController;

@end

@implementation SSAccessoryButton

- (void)configureCell {
    _kvoController = [FBKVOController controllerWithObserver:self];

    [_kvoController observe:[SSThemes sharedThemer].currentTheme
                    keyPath:kThemeFontColor
                    options:NSKeyValueObservingOptionNew
                      block:^(SSAccessoryButton *button, id theme, NSDictionary *dict) {
                          UIColor *newColor = dict[NSKeyValueChangeNewKey];
                          if (!newColor) newColor = [UIColor whiteColor];
                          button.label.textColor = newColor;
                      }];

    [_kvoController observe:[SSThemes sharedThemer].currentTheme
                    keyPath:kThemeFontName
                    options:NSKeyValueObservingOptionNew
                      block:^(SSAccessoryButton *button, id theme, NSDictionary *dict) {
                          [button.label setFont:[UIFont fontWithName:[SSThemes currentFont].fontName
                                                                size:24.0f]];
                      }];

    _label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    self.label.font = [UIFont fontWithName:[SSThemes currentFont].fontName
                                      size:24.0f];
    self.label.textColor = [SSThemes valueForThemeKey:kThemeFontColor];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
    [self.contentView addSubview:self.label];
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];

    UIView *selectedView = [[UIView alloc] initWithFrame:self.contentView.frame];
    selectedView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    selectedView.backgroundColor = [UIColor colorWithWhite:0.4f alpha:0.3f];
    self.selectedBackgroundView = selectedView;
}

- (void)dealloc {
    _kvoController = nil;
}

- (void)configureWithText:(NSString *)text {
    self.label.text = text;
}

@end
