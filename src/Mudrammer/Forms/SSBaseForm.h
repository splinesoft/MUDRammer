//
//  SSBaseForm.h
//  MUDRammer
//
//  Created by Jonathan Hersh on 5/23/13.
//  Copyright (c) 2013 Zumper. All rights reserved.
//

#import "QuickDialog.h"

@interface SSBaseForm : QRootElement

// If YES, will attempt to focus the first text field upon form load.
// Defaults to NO.
@property (nonatomic, assign) BOOL shouldFocusFirstTextFieldOnLoad;

// Returns the first text field form element, if any, or nil if there are none in the form.
@property (nonatomic, readonly, strong) QEntryElement *firstTextField;

@end
