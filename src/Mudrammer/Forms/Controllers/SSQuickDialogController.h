//
//  SSQuickDialogController.h
//  MUDRammer
//
//  Created by Jonathan Hersh on 4/16/13.
//  Copyright (c) 2013 Zumper. All rights reserved.
//

#import <QuickDialog.h>

@interface SSQuickDialogController : QuickDialogController <QuickDialogEntryElementDelegate>

// If YES, after the form loads it'll place focus in its first text field.
// Default NO.
@property (nonatomic, assign) BOOL focusesFirstTextFieldOnLoad;

@end
