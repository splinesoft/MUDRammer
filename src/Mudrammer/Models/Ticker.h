//
//  Ticker.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import Foundation;
@import CoreData;
#import <SSMagicManagedObject.h>

@class World;

@interface Ticker : SSMagicManagedObject

@property (nonatomic, strong) NSNumber * isEnabled;
@property (nonatomic, strong) NSNumber * interval;
@property (nonatomic, copy) NSString * commands;
@property (nonatomic, copy) NSString * soundFileName;
@property (nonatomic, strong) World *world;

+ (NSPredicate *) predicateForTickersWithWorld:(World *)world;

@end
