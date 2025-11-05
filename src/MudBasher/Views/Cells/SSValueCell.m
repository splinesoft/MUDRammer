//
//  SSValueCell.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 4/25/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSValueCell.h"

@implementation SSValueCell

+ (UITableViewCellStyle)cellStyle {
    return UITableViewCellStyleValue1;
}

- (void)configureCell {
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

@end
