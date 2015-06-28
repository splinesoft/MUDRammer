//
//  Trigger.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/10/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "Trigger.h"
#import "SSMagicManagedObject+Matching.h"

@implementation Trigger

@dynamic isEnabled;
@dynamic trigger;
@dynamic commands;
@dynamic world;
@dynamic highlightColor;
@dynamic soundFileName;
@dynamic vibrate;
@dynamic triggerType;

static NSRegularExpression *triggerSubMatcher;

+ (instancetype)createObjectInContext:(NSManagedObjectContext *)context {
    Trigger *t = [super createObjectInContext:context];

    t.isEnabled = @(YES);
    t.triggerType = @(TriggerTypeLineContains);
    t.vibrate = @(NO);
    t.highlightColor = [UIColor clearColor];
    t.soundFileName = @"None";

    return t;
}

+ (NSString *)defaultSortField {
    return @"trigger";
}

+ (BOOL)defaultSortAscending {
    return YES;
}

- (void)saveObject {
    self.isHidden = @(NO);
    [super saveObject];
}

- (BOOL)canSave {
    return [self.trigger length] > 0;
}

+ (NSArray *)triggerTypeLabelArray {
    return @[
        NSLocalizedString(@"START_OF_LINE", @"Start of Line"),
        NSLocalizedString(@"LINE_CONTAINS", @"Line contains")
    ];
}

+ (NSPredicate *)predicateForTriggersWithWorld:(World *)world active:(BOOL)active {
    return [NSPredicate predicateWithFormat:@"isHidden == NO "
            "AND isEnabled == %i "
            "AND world == %@",
            active,
            world];
}

- (BOOL)matchesLine:(NSString *)line {
    if( [self.trigger length] == 0 )
        return NO;

    return [Trigger matchPattern:self.trigger
                     matchesLine:line];
}

- (NSArray *)triggerCommandsForLine:(NSString *)line {
    // Splits our command lines by semicolon, handles &N syntax, etc
    NSArray *userCommands = [World commandsFromUserInput:self.commands];

    NSMutableArray *outputCommands = [NSMutableArray array];

    [userCommands bk_each:^(NSString *userCommand) {
        if( [userCommand length] == 0 )
            return;

        NSString *cmd = [Trigger commandForMatchPattern:self.trigger
                                            userCommand:userCommand
                                              inputLine:line];

        if( [cmd length] > 0 )
            [outputCommands addObject:cmd];
    }];

    return outputCommands;
}

@end
