//
//  SSAppDelegate.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/21/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import <SSApplication.h>
#import "SPLNotificationManager.h"

@interface SSAppDelegate : SSApplication

@property (nonatomic, strong) SPLNotificationManager *notificationObserver;

@end
