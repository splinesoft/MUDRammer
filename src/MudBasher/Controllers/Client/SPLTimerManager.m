//
//  SPLTimerManager.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLTimerManager.h"
#import <MyLilTimer.h>
#import <OSCache.h>

@interface SPLTimerManager () <OSCacheDelegate>

@property (nonatomic, strong) OSCache *cache;

@end

@implementation SPLTimerManager

- (instancetype)init {
    if ((self = [super init])) {
        _cache = [OSCache new];
        [self.cache setName:@"SPLTimerManager Cache"];
        self.cache.delegate = self;
    }

    return self;
}

- (void)dealloc {
    self.cache.delegate = nil;
    [self.cache removeAllObjects];
}

#pragma mark - Timer management

- (void)scheduleRepeatingTimerWithName:(id)name
                              interval:(NSTimeInterval)interval
                                 block:(SPLTimerBlock)block {

    if (!name || !block || interval <= 0) {
        DLog(@"Invalid timer.");
        return;
    }

    if ([self.cache objectForKey:name]) {
        [self cancelRepeatingTimerWithName:name];
    }

    DLog(@"Scheduling %@ at %@", name, @(interval));

    MyLilTimer *timer = [MyLilTimer scheduledTimerWithBehavior:MyLilTimerBehaviorHourglass
                                                  timeInterval:interval
                                                        target:self
                                                      selector:@selector(timerFire:)
                                                      userInfo:@[ name, @(interval), [block copy] ]];

    timer.tolerance = 1;

    [self.cache setObject:timer forKey:name];
}

- (NSTimeInterval)intervalForTimerWithName:(id)name {
    MyLilTimer *timer = [self.cache objectForKey:name];

    if (!timer) {
        return 0;
    }

    NSArray *info = timer.userInfo;
    return [info[1] doubleValue];
}

- (BOOL)isTickerEnabledWithIdentifier:(id)name {
    MyLilTimer *timer = [self.cache objectForKey:name];

    return (timer && [timer isValid]);
}

- (void)cancelRepeatingTimerWithName:(id)name {
    MyLilTimer *timer = [self.cache objectForKey:name];

    if (timer) {
        DLog(@"Canceling timer %@", name);
        [timer invalidate];
        [self.cache removeObjectForKey:name];
    }
}

- (void) timerFire:(MyLilTimer *)timer {
    DLog(@"%@ fired", timer);

    NSArray *userInfo = timer.userInfo;

    NSString *name = userInfo[0];
    NSTimeInterval interval = [userInfo[1] doubleValue];
    SPLTimerBlock timerBlock = userInfo[2];

    if (timerBlock) {
        timerBlock();
    }

    [self scheduleRepeatingTimerWithName:name
                                interval:interval
                                   block:timerBlock];
}

#pragma mark - OSCacheDelegate

- (BOOL)cache:(OSCache *)cache shouldEvictObject:(id)entry {
    if ([entry isKindOfClass:[MyLilTimer class]]) {
        return ![(MyLilTimer *)entry isValid];
    }

    return YES;
}

- (void)cache:(OSCache *)cache willEvictObject:(id)entry {
    if ([entry isKindOfClass:[MyLilTimer class]]) {
        [(MyLilTimer *)entry invalidate];
    }
}

@end
