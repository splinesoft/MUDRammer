//
//  SSTGAEditor.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 1/5/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import "SSQuickDialogController.h"

// Editor for gags, triggers, aliases

@interface SSTGAEditor : SSQuickDialogController

+ (instancetype) editorForRecord:(NSManagedObjectID *)record
                         inWorld:(NSManagedObjectID *)world
                   parentContext:(NSManagedObjectContext *)parentContext;

- (void) deleteCurrentRecord;

- (void) showSoundPicker;

@end
