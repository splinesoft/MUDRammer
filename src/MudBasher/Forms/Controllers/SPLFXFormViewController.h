//
//  SPLFXFormViewController.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import <FXForms.h>

@interface SPLFXFormViewController : FXFormViewController <FXFormControllerDelegate>

+ (instancetype) formViewControllerWithForm:(id <FXForm>)form;

/**
 *  Enumerate all fields on this form and fill values into the target object.
 *
 *  @param object object to fill
 */
- (void) bindToObject:(id)object;

@end
