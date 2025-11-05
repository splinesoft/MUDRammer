//
//  SSBooleanCell.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/16/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import <SSDataSources.h>

typedef void (^SSBooleanChangeHandler) (BOOL);

@interface SSBooleanCell : SSBaseTableCell

- (void) configureWithLabel:(NSString *)label
                   selected:(BOOL)selected
              changeHandler:(SSBooleanChangeHandler)changeHandler;

@end
