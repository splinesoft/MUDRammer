//
//  SSConnectButton.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/3/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@protocol SSConnectButtonDelegate;

@interface SSConnectButton : UIButton

@property (nonatomic, weak) id <SSConnectButtonDelegate> connectDelegate;

// Change state by assigning here
@property (nonatomic, assign, getter = isConnected) BOOL connected;

// Hackish means of setting action sheet presentation
@property (nonatomic, weak) UIBarButtonItem *targetBarButton;

- (instancetype) init;

@end

@protocol SSConnectButtonDelegate <NSObject>

// called when the user taps the button.
- (void) connectButton:(SSConnectButton *)button didChangeState:(BOOL)connected;

@end
