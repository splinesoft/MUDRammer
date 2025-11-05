//
//  SSWorldForm.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/15/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSBaseForm.h"
#import "SSWorldEditViewController.h"

UIKIT_EXTERN NSUInteger const kFormMaxInputLength;

@interface SSWorldForm : SSBaseForm

+ (instancetype) formForWorld:(World *)world;

- (void) refreshWorldFormForController:(SSWorldEditViewController *)controller;

@end
