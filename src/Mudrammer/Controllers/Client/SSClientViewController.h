//
//  SSClientViewController.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/22/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@protocol SSClientDelegate;
@class SSMudView, SSMUDSocket;

@interface SSClientViewController : UIViewController <UINavigationControllerDelegate,
                                                      NSFetchedResultsControllerDelegate>

@property (nonatomic, copy) NSString *hostname;
@property (nonatomic, copy) NSNumber *port;

@property (nonatomic, weak) id <SSClientDelegate> delegate;

/**
 *  Multiconn world status button. Updated by SSWorldDisplayController.
 */
@property (nonatomic, strong) UIButton *worldSelectButton;

/**
 *  The mudview managed by this view controller.
 */
@property (nonatomic, strong, readonly) SSMudView *mudView;

/**
 *  The socket managed by this view controller.
 */
@property (nonatomic, strong, readonly) SSMUDSocket *socket;

// create an empty client.
+ (instancetype) client;

// Create a client for a particular world.
+ (instancetype) clientWithWorld:(NSManagedObjectID *)world;

// Connect, assuming we have both a hostname and a port.
- (void) connect;

// Connected?
@property (nonatomic, getter=isConnected, readonly) BOOL connected;

// Disconnect the socket
- (void) disconnect;

// Clear text
- (void) clearText;

// Force resign first-responder
- (void) hideKeyboard;

- (void) updateCurrentWorld:(NSManagedObjectID *)newWorld connectAfterUpdate:(BOOL)connectAfterUpdate;

// Description for current world
@property (nonatomic, readonly, copy) NSString *currentWorldDescription;

// show or hide the nav bar
- (void) setNavVisible:(BOOL)visible;

@end

@protocol SSClientDelegate <NSObject>

@optional

- (void) clientDidConnect:(SSClientViewController *)client;
- (void) clientDidDisconnect:(SSClientViewController *)client;
- (void) clientDidReceiveText:(SSClientViewController *)client;

@end
