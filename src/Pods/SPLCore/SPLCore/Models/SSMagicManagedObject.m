//
//  SSMagicManagedObject.m
//  SPLCore
//
//  Created by Jonathan Hersh on 11/11/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSMagicManagedObject.h"
#import <MagicalRecord.h>

@implementation SSMagicManagedObject

@dynamic isHidden, lastModified;

#pragma mark - fetch

+ (instancetype)existingObjectWithId:(NSManagedObjectID *)objectId {
    return [self existingObjectWithId:objectId
                            inContext:[NSManagedObjectContext MR_defaultContext]];
}

+ (instancetype)existingObjectWithId:(NSManagedObjectID *)objectId inContext:(NSManagedObjectContext *)context {
    return (SSMagicManagedObject *)[context existingObjectWithID:objectId error:nil];
}

#pragma mark - create

+ (instancetype)createObject {
    return [self createObjectInContext:[NSManagedObjectContext MR_defaultContext]];
}

+ (instancetype)createObjectInContext:(NSManagedObjectContext *)context {
    SSMagicManagedObject *object = [self MR_createEntityInContext:context];

    object.isHidden = @(YES);
    object.lastModified = [NSDate date];

    return object;
}

+ (void)createObjectWithCompletion:(CreateCompletionBlock)completion {
    __block SSMagicManagedObject *object;
    
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *context) {
        object = [self createObjectInContext:context];
    } completion:^(BOOL didSave, NSError *error) {
        NSManagedObjectID *objectId = [object objectID];
        
        if (completion) {
            dispatch_async( dispatch_get_main_queue(), ^{
                completion( objectId );
            });
        }
    }];
}

#pragma mark - refresh

- (void)refreshObject {
    [self.managedObjectContext refreshObject:self mergeChanges:YES];
}

#pragma mark - saving

- (void)prepareForSave {
    [self setValue:[NSDate date] forKey:@"lastModified"];
}

- (void)saveObject {
    [self saveObjectWithCompletion:nil fail:nil];
}

- (void)saveObjectWithCompletion:(SaveCompletionBlock)completion fail:(SaveErrorBlock)fail {
    [self prepareForSave];

    [self.managedObjectContext MR_saveToPersistentStoreWithCompletion:^(BOOL success, NSError *err) {
        if( err && fail )
            fail( err );
        else if( !err && completion )
            completion();
    }];
}

- (void)saveObjectAndWait {
    [self prepareForSave];
    [self.managedObjectContext MR_saveToPersistentStoreAndWait];
}

- (BOOL)canSave {
    // override me!
    return YES;
}

#pragma mark - deleting

- (void)deleteObject {    
    [self MR_deleteEntityInContext:[self managedObjectContext]];
}

#pragma mark - predicates

+ (NSPredicate *)predicateForRecordsWithHidden:(BOOL)showHidden {
    if( showHidden )
        return nil;

    return [NSPredicate predicateWithFormat:@"isHidden == NO"];
}

+ (NSString *)defaultSortField {
    // override me!
    return @"lastModified";
}

+ (BOOL)defaultSortAscending {
    // override me!
    return NO;
}

@end
