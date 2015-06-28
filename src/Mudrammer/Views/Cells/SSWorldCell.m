//
//  SSWorldCell.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/10/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSWorldCell.h"

@implementation SSWorldCell

+ (UITableViewCellStyle)cellStyle {
    return UITableViewCellStyleSubtitle;
}

- (void)configureCell {
    self.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;

    [SSThemes configureCell:self];
}

@end
