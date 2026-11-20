//
//  SSPortCell.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/20/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSPortCell.h"
#import "QEntryElement.h"

@implementation SSPortCell

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)replacement {
    NSUInteger newLength = textField.text.length - range.length + replacement.length;
    if (newLength > _entryElement.maxLength ||
        [replacement rangeOfCharacterFromSet:NSCharacterSet.decimalDigitCharacterSet.invertedSet].location != NSNotFound) {
        return NO;
    }
    return [super textField:textField shouldChangeCharactersInRange:range replacementString:replacement];
}

@end
