//
//  Ticker.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "Ticker.h"

@implementation Ticker

@dynamic isEnabled;
@dynamic interval;
@dynamic commands;
@dynamic world;
@dynamic soundFileName;

+ (instancetype)createObjectInContext:(NSManagedObjectContext *)context {
    Ticker *ticker = [super createObjectInContext:context];

    ticker.isEnabled = @YES;
    ticker.interval = @15;
    ticker.commands = @"";
    ticker.soundFileName = @"None";

    return ticker;
}

+ (NSPredicate *)predicateForTickersWithWorld:(World *)world {
    return [NSPredicate predicateWithFormat:@"isHidden == NO "
            "AND world == %@",
            world];
}

+ (NSString *)defaultSortField {
    return @"commands";
}

+ (BOOL)defaultSortAscending {
    return YES;
}

- (void)saveObject {
    self.isHidden = @(NO);
    [super saveObject];
}

- (BOOL)canSave {
    return [self.interval unsignedIntegerValue] > 0
        && ([self.commands length] > 0 || ([self.soundFileName length] > 0 && ![self.soundFileName isEqualToString:@"None"]));
}

@end
