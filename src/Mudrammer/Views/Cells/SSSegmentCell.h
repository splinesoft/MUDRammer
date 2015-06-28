//
//  SSSegmentCell.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/15/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SSBaseTableCell.h"

typedef void (^SSSegmentChangeHandler) (NSInteger);

@interface SSSegmentCell : SSBaseTableCell

- (void) configureWithLabel:(NSString *)label
                   segments:(NSArray *)segments
              selectedIndex:(NSInteger)selectedIndex
              changeHandler:(SSSegmentChangeHandler)changeHandler;

@end
