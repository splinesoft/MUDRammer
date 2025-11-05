//
//  SPLFXWorldEditor.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/20/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLFXFormViewController.h"

@interface SPLFXWorldEditor : SPLFXFormViewController

+ (instancetype) editorForRecord:(NSManagedObjectID *)recordId
                         inWorld:(NSManagedObjectID *)worldId
                   parentContext:(NSManagedObjectContext *)context;

- (void) deleteCurrentRecord;

- (void) showSoundPicker;

@end
