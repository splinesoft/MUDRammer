//
//  SSWorldEditViewController.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import "SSQuickDialogController.h"

typedef void (^SSWorldSaveCompletionBlock) (BOOL);

@interface SSWorldEditViewController : SSQuickDialogController <NSFetchedResultsControllerDelegate>

@property (nonatomic, copy) SSWorldSaveCompletionBlock saveCompletionBlock;

// Edit world
+ (instancetype) editorForWorld:(NSManagedObjectID *)world;

// New actions
- (void) editRecord:(NSManagedObjectID *)TGARecordId;
- (void) newTrigger;
- (void) newAlias;
- (void) newGag;
- (void) newTicker;
- (void) deepClone;

@end
