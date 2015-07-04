//
//  SPLNotificationManager.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLNotificationManager.h"

@implementation SPLNotificationManager

- (instancetype) init {
    if ((self = [super init])) {
        _askedForLocalNotifications = NO;
    }

    return self;
}

- (void)registerForLocalNotifications {
    if (self.askedForLocalNotifications) {
        DLog(@"*** Already asked for perms");
        return;
    }

    UIUserNotificationSettings *settings = [UIUserNotificationSettings settingsForTypes:UIUserNotificationTypeAlert | UIUserNotificationTypeSound
                                                                             categories:nil];

    [[UIApplication sharedApplication] registerUserNotificationSettings:settings];

    _askedForLocalNotifications = YES;
}

- (void)scheduleTimeoutNotification {
    if (!self.askedForLocalNotifications) {
        [self registerForLocalNotifications];
    }

    // Timeout alert after 8 minutes
    UILocalNotification *alert = [UILocalNotification new];

    alert.timeZone = [NSTimeZone defaultTimeZone];
    alert.fireDate = [NSDate dateWithTimeIntervalSinceNow:( 8 * 60 )];

    alert.soundName = UILocalNotificationDefaultSoundName;

    alert.alertAction = NSLocalizedString(@"OPEN_WORLD", @"Open World");
    alert.alertBody = NSLocalizedString(@"SESSION_TIMEOUT", @"Your session will timeout in two minutes.");

    [[UIApplication sharedApplication] scheduleLocalNotification:alert];
}

#pragma mark - UIApplication

- (void)didRegisterUserNotificationSettings:(UIUserNotificationSettings *)settings {
    DLog(@"Registered %@", settings);
    _userNotificationSettings = settings;
}

- (void)handleActionWithIdentifier:(NSString *)identifier
              forLocalNotification:(UILocalNotification *)notification
                        completion:(void (^)())completion {

    DLog(@"Received action with ID %@", identifier);

    if (completion) {
        completion();
    }
}

@end
