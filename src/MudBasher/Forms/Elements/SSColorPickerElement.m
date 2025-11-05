//
//  SSColorPickerElement.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/15/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSColorPickerElement.h"

@implementation SSColorPickerElement

- (void)setColor:(UIColor *)color {

    for( NSUInteger i = 0; i < [self.items count]; i++ ) {
        if ([color isEqual:(self.items[i])[1]]) {
            self.selected = (NSInteger)i;
            return;
        }
    }

    self.selected = 0;

    [self handleEditingChanged];
}

- (void)fetchValueIntoObject:(id)obj {
    // HAAAAAAACK
    [obj setValue:(self.items[(NSUInteger)self.selected])[1]
           forKey:self.key];
}

@end
