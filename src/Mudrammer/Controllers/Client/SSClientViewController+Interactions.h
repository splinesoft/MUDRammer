//
//  SSClientViewController+Interactions.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 12/20/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SSClientViewController.h"
#import <JTSImageViewController.h>
#import <TTTAttributedLabel.h>
#import "SSConnectButton.h"

@interface SSClientViewController (Interactions) <
JTSImageViewControllerInteractionsDelegate,
JTSImageViewControllerOptionsDelegate,
SSConnectButtonDelegate,
TTTAttributedLabelDelegate
>

#pragma mark - UIKeyCommand

/**
 *  Switch to the next available connected session.
 */
- (void) keyCommandCycleActiveConnections:(UIKeyCommand *)sender;

/**
 *  Switch to the session specified by this key command (1-4)
 */
- (void) keyCommandSwitchToActiveConnection:(UIKeyCommand *)sender;

@end
