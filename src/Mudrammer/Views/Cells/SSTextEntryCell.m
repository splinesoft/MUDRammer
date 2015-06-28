//
//  SSTextEntryCell.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/27/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SSTextEntryCell.h"
#import <Masonry.h>
#import <FBKVOController.h>

@interface SSTextEntryCell ()

@property (nonatomic, strong) FBKVOController *kvoController;

@end

@implementation SSTextEntryCell

- (void)configureCell {
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    _textFieldShouldReturn = NO;

    _textField = [[UITextField alloc] initWithFrame:self.contentView.bounds];
    self.textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.textField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textField.textColor = [SSThemes valueForThemeKey:kThemeFontColor];
    self.textField.delegate = self;
    self.textField.clearButtonMode = UITextFieldViewModeNever;
    self.textField.returnKeyType = UIReturnKeyDone;
    self.textField.backgroundColor = [UIColor clearColor];

    [self.contentView addSubview:self.textField];
    [self.textField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.contentView);
        make.bottom.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset(16);
        make.right.equalTo(self.contentView).offset(-16);
    }];

    _kvoController = [FBKVOController controllerWithObserver:self];

    [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                        keyPath:kThemeFontColor
                        options:NSKeyValueObservingOptionNew
                          block:^(SSTextEntryCell *cell, id object, NSDictionary *change) {
                              UIColor *newColor = change[NSKeyValueChangeNewKey];
                              if (!newColor) newColor = [UIColor whiteColor];
                              [cell.textField setTextColor:newColor];
                          }];

    [SSThemes configureCell:self];
}

- (void)dealloc {
    _changeHandler = nil;
    _kvoController = nil;
    self.textField.delegate = nil;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldEndEditing:(UITextField *)textField {
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {

    if (self.changeHandler) {
        self.changeHandler(textField);
    }

    if (self.textFieldShouldReturn) {
        [textField resignFirstResponder];
    }

    return self.textFieldShouldReturn;
}

@end
