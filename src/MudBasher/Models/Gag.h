//
//  Gag.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/10/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import Foundation;
@import CoreData;
#import <SSMagicManagedObject.h>

@class World;

typedef NS_ENUM( NSInteger, SSGagType ) {
    GagTypeStartOfLine = 0,
    GagTypeLineContains,
    GagTypeLineEquals,
    GagNumTypes
};

@interface Gag : SSMagicManagedObject

@property (nonatomic, strong) NSNumber * isEnabled;
@property (nonatomic, strong) NSNumber * gagType;
@property (nonatomic, copy) NSString * gag;
@property (nonatomic, strong) World *world;

+ (NSArray *) gagTypeLabelArray;

+ (NSPredicate *) predicateForGagsWithWorld:(World *)world active:(BOOL)active;

/**
 * Return YES if this gag matches the given line.
 */
- (BOOL) matchesLine:(NSString *)line;

@end
