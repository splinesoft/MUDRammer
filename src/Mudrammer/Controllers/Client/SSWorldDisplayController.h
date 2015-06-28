//
//  SSWorldDisplayController.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/14/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

@import UIKit;

#import "SSClientContainer.h"
#import "SSClientViewController.h"

extern CGFloat const kWorldDisplayWidth;

@interface SSWorldDisplayController : UITableViewController <SSClientDelegate>

/**
 * Currently-selected view controller.
 */
@property (nonatomic, assign) NSInteger selectedIndex;

#pragma mark - Client Access

/**
 *  Switch to the next visible world, if more than one is connected.
 */
- (void) selectNextWorld;

/**
 * Add a new client with the specified world to the end of the viewcontroller list.
 */
- (void) addClientWithWorld:(NSManagedObjectID *)world;

/**
 * Remove the client at the specified index.
 */
- (void) removeClientAtIndex:(NSInteger)index;

/**
 * Number of clients currently connected.
 */
@property (nonatomic, readonly) NSInteger numberOfClients;

/**
 * Return the client VC at the specified index.
 */
- (SSClientViewController *) clientAtIndex:(NSInteger)index;

/**
 * Find the index of this client, or NSNotFound.
 */
- (NSInteger) indexOfClient:(SSClientViewController *)client;

/**
 * Viewcontroller at the current index. Probably a nav controller
 @see currentVisibleClient.
 */
@property (nonatomic, readonly, strong) UIViewController *selectedViewController;

// Image to use for the select world button, given how many worlds are currently open
@property (nonatomic, readonly, strong) UIImage *worldSelectButtonImage;

// Client access
@property (nonatomic, readonly, strong) SSClientViewController *currentVisibleClient;

@end
