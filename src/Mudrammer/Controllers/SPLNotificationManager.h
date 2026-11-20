//
//  SPLNotificationManager.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@interface SPLNotificationManager : NSObject

// Has already asked for permissions
@property (nonatomic, readonly) BOOL askedForLocalNotifications;
// Ask for local notification permissions.
- (void) registerForLocalNotifications;

// Schedule a socket timeout warning local notification after 8 minutes.
- (void) scheduleTimeoutNotification;

- (void) cancelTimeoutNotification;

@end
