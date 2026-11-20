//
//  SPLTestAppDelegate.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/20/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "SPLTestAppDelegate.h"

@implementation SPLTestAppDelegate

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelAll];
    [MagicalRecord setupCoreDataStackWithInMemoryStore];
    return YES;
}

- (UIViewController *)makeRootViewController {
    return [UIViewController new];
}

@end
