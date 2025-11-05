//
//  SSTextEntryCell.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/27/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SSBaseTableCell.h"

// Block called when the text field ends editing.
typedef void (^SSTextEntryCellChangeBlock) (UITextField *);

@interface SSTextEntryCell : SSBaseTableCell <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, copy) SSTextEntryCellChangeBlock changeHandler;

@property (nonatomic, assign) BOOL textFieldShouldReturn;

@end
