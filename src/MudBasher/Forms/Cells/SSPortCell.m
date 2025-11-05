//
//  SSPortCell.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/20/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSPortCell.h"
#import "QDecimalTableViewCell.h"
#import "QuickDialog.h"

@implementation SSPortCell {
    NSNumberFormatter *_numberFormatter;
}

- (QDecimalTableViewCell *)init {
    self = [self initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"QuickformDecimalElement"];
    if (self!=nil){
        [self createSubviews];
		self.selectionStyle = UITableViewCellSelectionStyleNone;
        _numberFormatter = [[NSNumberFormatter alloc] init];
        [_numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
        [_numberFormatter setUsesGroupingSeparator:NO];
        [_numberFormatter setMinimum:@0];
        [_numberFormatter setMaximum:@999999];
    };
    return self;
}

- (void)createSubviews {
    _textField = [[QTextField alloc] init];
    //[_textField addTarget:self action:@selector(textFieldEditingChanged:) forControlEvents:UIControlEventEditingChanged];
    _textField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _textField.borderStyle = UITextBorderStyleNone;
    _textField.keyboardType = UIKeyboardTypeDecimalPad;
    _textField.delegate = self;
    _textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    _textField.autoresizingMask = ( UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight);
    [self.contentView addSubview:_textField];

    [self setNeedsLayout];
}

- (QDecimalElement *)decimalElement {
    return ((QDecimalElement *)_entryElement);
}

- (void)updateTextFieldFromElement {
    [_numberFormatter setMaximumFractionDigits:[self decimalElement].fractionDigits];
    [_numberFormatter setMinimumFractionDigits:[self decimalElement].fractionDigits];
    QDecimalElement *el = (QDecimalElement *)_entryElement;
    _textField.text = [_numberFormatter stringFromNumber:el.numberValue];
}

- (void)prepareForElement:(QEntryElement *)element inTableView:(QuickDialogTableView *)view {
    [super prepareForElement:element inTableView:view];
    _entryElement = element;
    [self updateTextFieldFromElement];
}

- (void)updateElementFromTextField:(NSString *)value {
    NSMutableString *result = [[NSMutableString alloc] init];
    for (NSUInteger i = 0; i< [value length]; i++){
        unichar c = [value characterAtIndex:i];
        NSString *charStr = [NSString stringWithCharacters:&c length:1];
        if ([[NSCharacterSet decimalDigitCharacterSet] characterIsMember:c]) {
            [result appendString:charStr];
        }
    }
    [_numberFormatter setMaximumFractionDigits:[self decimalElement].fractionDigits];
    [_numberFormatter setMinimumFractionDigits:[self decimalElement].fractionDigits];
    float parsedValue = [_numberFormatter numberFromString:result].floatValue;
    [self decimalElement].numberValue = @((CGFloat) (parsedValue / pow(10, [self decimalElement].fractionDigits)));
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacement {
    BOOL shouldChange = YES;

    if(_entryElement && _entryElement.delegate && [_entryElement.delegate respondsToSelector:@selector(QEntryShouldChangeCharactersInRange:withString:forElement:andCell:)])
        shouldChange = [_entryElement.delegate QEntryShouldChangeCharactersInRange:range withString:replacement forElement:_entryElement andCell:self];

    if( shouldChange ) {
        NSString *newValue = [_textField.text stringByReplacingCharactersInRange:range withString:replacement];
        [self updateElementFromTextField:newValue];
        [self updateTextFieldFromElement];
        [_entryElement handleEditingChanged:self];
    }
    return NO;
}

@end
