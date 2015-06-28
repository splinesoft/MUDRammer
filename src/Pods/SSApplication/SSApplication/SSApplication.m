//
//  SSApplication.m
//  SSApplication
//
//  Created by Jonathan Hersh on 8/31/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import "SSApplication.h"

@interface SSApplication ()
- (void) _setupDefaultUserDefaults;
@end

@implementation SSApplication

+ (instancetype)sharedApplication {
    return (SSApplication *)[[UIApplication sharedApplication] delegate];
}

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // NSUserDefaults is thread-safe.
        [self _setupDefaultUserDefaults];
        
        [self ss_willLaunchBackgroundSetup];
    });
    
    [self ss_willFinishLaunchingWithOptions:launchOptions];
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor blackColor];
    self.window.rootViewController = [self ss_appRootViewController];
    [self.window makeKeyAndVisible];

    return YES;
}

#pragma mark - Setup

- (UIViewController *) ss_appRootViewController {
    // override me!
    // Not providing a default view controller will raise an exception.
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void) ss_willFinishLaunchingWithOptions:(NSDictionary *)options {
    // override me!
}

- (void) ss_willLaunchBackgroundSetup {
    // override me!
}

#pragma mark - Default NSUserDefaults

- (NSDictionary *) ss_defaultUserDefaults {
    // override me!
    return @{};
}

- (void) _setupDefaultUserDefaults {
    NSDictionary *defaultUserDefaults = [self ss_defaultUserDefaults];
    
    if ([defaultUserDefaults count] == 0) {
        return;
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSArray *prefKeys = [[defaults dictionaryRepresentation] allKeys];
    
    // Set default preferences, but don't overwrite any existing values.
    [defaultUserDefaults enumerateKeysAndObjectsUsingBlock:^(NSString *pref,
                                                             id defaultValue,
                                                             BOOL *stop) {
        if (![prefKeys containsObject:pref]) {
            [defaults setObject:defaultValue
                         forKey:pref];
        }
    }];
}

#pragma mark - App Events

- (void) ss_receivedApplicationEvent:(SSApplicationEvent)eventType {
    // override me!
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [self ss_receivedApplicationEvent:SSApplicationEventWillEnterForeground];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self ss_receivedApplicationEvent:SSApplicationEventWillTerminate];
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    [self ss_receivedApplicationEvent:SSApplicationEventDidBecomeActive];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    [self ss_receivedApplicationEvent:SSApplicationEventWillResignActive];
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self ss_receivedApplicationEvent:SSApplicationEventDidEnterBackground];
}

- (void)applicationDidReceiveMemoryWarning:(UIApplication *)application {
    [self ss_receivedApplicationEvent:SSApplicationEventDidReceiveMemoryWarning];
}

@end
