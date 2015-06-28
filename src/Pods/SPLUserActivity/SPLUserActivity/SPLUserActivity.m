//
//  SPLUserActivity.m
//  SPLUserActivity
//
//  Created by Jonathan Hersh on 3/1/15.
//  Copyright (c) 2015 Splinesoft. All rights reserved.
//

#import "SPLUserActivity.h"

@interface SPLUserActivity ()

@end

@implementation SPLUserActivity

- (instancetype)initWithType:(NSString *)type {
    if ((self = [super init])) {
        _userActivity = [[NSUserActivity alloc] initWithActivityType:type];
        self.userActivity.delegate = self;
    }
    
    return self;
}

- (void)dealloc {
    _activityContinuedBlock = nil;
    _userActivity.delegate = nil;
    [self invalidate];
}

#pragma mark - Lifecycle

- (void)invalidate {
    [self.userActivity invalidate];
}

- (void)setNeedsUpdate {
    self.userActivity.needsSave = YES;
}

#pragma mark - NSUserActivityDelegate

- (void)userActivityWillSave:(NSUserActivity *)userActivity {
    
}

- (void)userActivityWasContinued:(NSUserActivity *)userActivity {
    if (self.activityContinuedBlock) {
        self.activityContinuedBlock();
    }
}

@end
