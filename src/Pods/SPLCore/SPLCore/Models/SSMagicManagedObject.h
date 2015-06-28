//
//  SSMagicManagedObject.h
//  SPLCore
//
//  Created by Jonathan Hersh on 11/11/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import <CoreData/CoreData.h>

@interface SSMagicManagedObject : NSManagedObject

@property (nonatomic, retain) NSNumber * isHidden;
@property (nonatomic, retain) NSDate * lastModified;

typedef void (^SaveCompletionBlock) (void);
typedef void (^SaveErrorBlock)      (NSError *);
typedef void (^CreateCompletionBlock) (NSManagedObjectID *);

// Fetching
+ (instancetype) existingObjectWithId:(NSManagedObjectID *)objectId;
+ (instancetype) existingObjectWithId:(NSManagedObjectID *)objectId
                            inContext:(NSManagedObjectContext *)context;

// Creating
+ (instancetype) createObject;
+ (instancetype) createObjectInContext:(NSManagedObjectContext *)context;
+ (void) createObjectWithCompletion:(CreateCompletionBlock)completion;

// Saving
// Returns YES if all required fields are filled
- (BOOL) canSave;

- (void) prepareForSave;

// ASYNC
- (void) saveObject;
- (void) saveObjectWithCompletion:(SaveCompletionBlock)completion fail:(SaveErrorBlock)fail;

// SYNC
- (void) saveObjectAndWait;

// Refresh. Merges changes
- (void) refreshObject;

// Deleting
- (void) deleteObject;

// Predicates
+ (NSPredicate *) predicateForRecordsWithHidden:(BOOL)showHidden;
+ (NSString *) defaultSortField;
+ (BOOL) defaultSortAscending;

@end
