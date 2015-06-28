//
//  SPLNotificationManager.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@interface SPLNotificationManager : NSObject

// Uses the iOS 8+ system
@property (nonatomic, readonly) BOOL usesNewNotificationSystem;

// Has already asked for permissions
@property (nonatomic, readonly) BOOL askedForLocalNotifications;

// Settings granted by the current user
@property (nonatomic, strong, readonly) UIUserNotificationSettings *userNotificationSettings;

// Call when we receive a response for the user's notification preferences.
- (void) didRegisterUserNotificationSettings:(UIUserNotificationSettings *)settings;

// Handle a local notification action
- (void) handleActionWithIdentifier:(NSString *)identifier
               forLocalNotification:(UILocalNotification *)notification
                         completion:(void (^)())completion;

// Ask for local notification permissions (iOS 8+)
- (void) registerForLocalNotifications;

// Schedule a socket timeout warning local notification after 8 minutes.
- (void) scheduleTimeoutNotification;

@end
