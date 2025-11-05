//
//  Trigger.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/10/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;
@import Foundation;
@import CoreData;
#import <SSMagicManagedObject.h>

@class World;

typedef NS_ENUM( NSInteger, SSTriggerType ) {
    TriggerTypeStartOfLine = 0,
    TriggerTypeLineContains,
    TriggerNumTypes
};

@interface Trigger : SSMagicManagedObject

@property (nonatomic, strong) NSNumber * isEnabled;
@property (nonatomic, copy) NSString * trigger;
@property (nonatomic, copy) NSString * commands;
@property (nonatomic, copy) NSString * soundFileName;
@property (nonatomic, strong) NSNumber * triggerType;
@property (nonatomic, strong) UIColor * highlightColor;
@property (nonatomic, strong) NSNumber * vibrate;
@property (nonatomic, strong) World *world;

+ (NSArray *) triggerTypeLabelArray;

+ (NSPredicate *) predicateForTriggersWithWorld:(World *)world active:(BOOL)active;

// Is this trigger fired by this line?
- (BOOL) matchesLine:(NSString *)line;

// Commands to send when fired against a given line of text.
- (NSArray *) triggerCommandsForLine:(NSString *)line;

@end
