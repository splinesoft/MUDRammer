//
//  SSTriggerForm.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/15/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSBaseForm.h"

extern NSString * const kSoundElement;

@interface SSTriggerForm : SSBaseForm

+ (instancetype) formForTrigger:(Trigger *)trigger;

@end
