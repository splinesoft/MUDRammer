//
//  Gag.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/10/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "Gag.h"

@implementation Gag

@dynamic isEnabled;
@dynamic gag;
@dynamic world;
@dynamic gagType;

+ (NSString *)defaultSortField {
    return @"gag";
}

+ (BOOL)defaultSortAscending {
    return YES;
}

+ (instancetype)createObjectInContext:(NSManagedObjectContext *)context {
    Gag *gag = [super createObjectInContext:context];

    gag.isEnabled = @(YES);
    gag.gagType = @(GagTypeLineContains);

    return gag;
}

- (void)saveObject {
    self.isHidden = @(NO);
    [super saveObject];
}

- (BOOL)canSave {
    return YES;
}

+ (NSArray *)gagTypeLabelArray {
    return @[
        NSLocalizedString(@"START_OF_LINE", @"Start of Line"),
        NSLocalizedString(@"LINE_CONTAINS", @"Line contains"),
        NSLocalizedString(@"LINE_EQUALS", @"Line equals")
    ];
}

+ (NSPredicate *)predicateForGagsWithWorld:(World *)world active:(BOOL)active {
    return [NSPredicate predicateWithFormat:@"isHidden == NO "
            "AND isEnabled == %i "
            "AND world == %@",
            active,
            world];
}

- (BOOL)matchesLine:(NSString *)line {
    NSString *toMatch = [self.gag stringByTrimmingCharactersInSet:
                         [NSCharacterSet whitespaceCharacterSet]];

    if ([toMatch length] == 0) {
        return [line length] == 0;
    } else if ([line length] == 0) {
        return NO;
    }

    if ([self.gagType integerValue] == GagTypeStartOfLine && [line hasPrefix:toMatch]) {
        return YES;
    }

    if ([self.gagType integerValue] == GagTypeLineContains && [line stringContainsString:toMatch]) {
        return YES;
    }

    if ([self.gagType integerValue] == GagTypeLineEquals && [line isEqualToString:toMatch]) {
        return YES;
    }

    return NO;
}

@end
