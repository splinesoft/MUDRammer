//
//  SSPortElement.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/20/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSPortElement.h"
#import "SSPortCell.h"

@implementation SSPortElement

- (instancetype)initWithTitle:(NSString *)title value:(NSNumber *)value {
    if ((self = [super initWithTitle:title Value:value.stringValue Placeholder:nil])) {
        self.keyboardType = UIKeyboardTypeNumberPad;
        self.maxLength = 5;
    }
    return self;
}

- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {
    SSPortCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SSPortElement"];
    if (!cell) {
        cell = [[SSPortCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"SSPortElement"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        [cell createSubviews];
    }
    [cell prepareForElement:self inTableView:tableView];
    cell.textField.userInteractionEnabled = self.enabled;
    return cell;
}

- (void)fetchValueIntoObject:(id)object {
    NSNumberFormatter *formatter = [NSNumberFormatter new];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator = NO;
    [object setValue:[formatter numberFromString:self.textValue ?: @""] forKey:self.key];
}

@end
