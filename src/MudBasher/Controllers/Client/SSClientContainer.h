//
//  SSClientContainer.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 4/20/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import <JASidePanelController.h>

@class SSWorldDisplayController, SSClientViewController;

/*
 * Container for multiple active clients.
 */

@interface SSClientContainer : JASidePanelController

/**
 * Assumed to be the app window's rootViewController.
 */
+ (instancetype) sharedClientContainer;

/**
 * Access the shared side drawer - world picker list.
 */
+ (SSWorldDisplayController *) worldDisplayDrawer;

/**
 * Close pane drawer if open.
 */
- (void)closeDrawerAnimated:(BOOL)animated;

@end
