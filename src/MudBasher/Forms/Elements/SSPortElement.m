//
//  SSPortElement.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/20/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSPortElement.h"
#import "SSPortCell.h"
#import <QTextField.h>

@implementation SSPortElement

- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {

    SSPortCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SSPortElement"];
    if (cell==nil){
        cell = [[SSPortCell alloc] init];
    }
    [cell prepareForElement:self inTableView:tableView];
    cell.textField.userInteractionEnabled = self.enabled;

    return cell;
}

@end
