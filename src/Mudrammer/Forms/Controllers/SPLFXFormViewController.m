//
//  SPLFXFormViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLFXFormViewController.h"

@interface SPLFXFormViewController ()

@end

@implementation SPLFXFormViewController

+ (instancetype)formViewControllerWithForm:(id<FXForm>)form {
    SPLFXFormViewController *vc = [self new];
    vc.formController.form = form;
    return vc;
}

- (void)bindToObject:(id)object {
    [self.formController enumerateFieldsWithBlock:^(FXFormField *field, NSIndexPath *indexPath) {
        if ([field.key length] == 0) {
            return;
        }

        DLog(@"Filling %@ => %@", field.key, field.value);

        [object setValue:field.value
                  forKey:field.key];
    }];
}

@end
