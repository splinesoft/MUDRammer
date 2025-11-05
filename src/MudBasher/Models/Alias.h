//
//  Alias.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/10/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import Foundation;
@import CoreData;
#import <SSMagicManagedObject.h>

@class World;

@interface Alias : SSMagicManagedObject

@property (nonatomic, strong) NSNumber * isEnabled;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, copy) NSString * commands;
@property (nonatomic, strong) World *world;

+ (NSPredicate *) predicateForAliasesWithWorld:(World *)world active:(BOOL)active;

// Given a user-inputted string, we calculate an array of command(s) to be sent to the server
- (NSArray *) aliasCommandsForInput:(NSString *)input;

@end
