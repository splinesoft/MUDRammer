//
//  SSAppDelegate.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/21/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import "SPLNotificationManager.h"

@interface SSAppDelegate : UIResponder <UIApplicationDelegate>

+ (instancetype)sharedDelegate;
- (UIViewController *)makeRootViewController;

@property (nonatomic, weak, readonly) UIWindow *mainWindow;

@property (nonatomic, strong) SPLNotificationManager *notificationObserver;

@end
