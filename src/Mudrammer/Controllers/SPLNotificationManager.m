//
//  SPLNotificationManager.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLNotificationManager.h"
#import <UserNotifications/UserNotifications.h>

static NSString * const SPLTimeoutNotificationIdentifier = @"session-timeout";

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

    _askedForLocalNotifications = YES;
    [[UNUserNotificationCenter currentNotificationCenter]
     requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionSound
     completionHandler:^(BOOL granted, NSError *error) {
         if (error) DLog(@"Notification authorization failed: %@", error);
     }];
}

- (void)scheduleTimeoutNotification {
    if (!self.askedForLocalNotifications) {
        [self registerForLocalNotifications];
    }

    UNMutableNotificationContent *content = [UNMutableNotificationContent new];
    content.body = NSLocalizedString(@"SESSION_TIMEOUT", @"Your session will timeout in two minutes.");
    content.sound = [UNNotificationSound defaultSound];
    UNTimeIntervalNotificationTrigger *trigger = [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:8 * 60 repeats:NO];
    UNNotificationRequest *request = [UNNotificationRequest requestWithIdentifier:SPLTimeoutNotificationIdentifier
                                                                        content:content trigger:trigger];
    [[UNUserNotificationCenter currentNotificationCenter] addNotificationRequest:request
                                                         withCompletionHandler:^(NSError *error) {
        if (error) DLog(@"Could not schedule session notification: %@", error);
    }];
}

- (void)cancelTimeoutNotification {
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center removePendingNotificationRequestsWithIdentifiers:@[SPLTimeoutNotificationIdentifier]];
    [center removeDeliveredNotificationsWithIdentifiers:@[SPLTimeoutNotificationIdentifier]];
}

@end
