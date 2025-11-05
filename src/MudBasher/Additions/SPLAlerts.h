//
//  SPLAlerts.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/2/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import Foundation;
@import UIKit;

@interface UIViewController (SPLAlerts)

/**
 *  Loop until we find the frontmost VC presented by this view controller.
 *
 *  @return a frontmost VC, or self
 */
- (instancetype) SPLFrontViewController;

@end

@interface SPLAlerts : NSObject

/**
 *  Show a modal alertview with up to two buttons.
 *
 *  @param title       title of the alert
 *  @param message     message for the alert
 *  @param cancelTitle cancel button
 *  @param cancelBlock cancel block
 *  @param okTitle     ok button
 *  @param okBlock     ok block
 */
+ (void) SPLShowAlertViewWithTitle:(NSString *)title
                           message:(NSString *)message
                       cancelTitle:(NSString *)cancelTitle
                       cancelBlock:(void (^)(void))cancelBlock
                           okTitle:(NSString *)okTitle
                           okBlock:(void (^)(void))okBlock;

/**
 *  Show an action sheet with a cancel and destructive button.
 *
 *  @param title            action sheet title
 *  @param cancelTitle      cancel title
 *  @param cancelBlock      cancel block
 *  @param destructiveTitle destructive title
 *  @param destructiveBlock destructive block
 *  @param barButtonItem    target bar button, or...
 *  @param sourceView       ...target view, with
 *  @param sourceRect       source Rect
 */
+ (void) SPLShowActionViewWithTitle:(NSString *)title
                        cancelTitle:(NSString *)cancelTitle
                        cancelBlock:(void (^)(void))cancelBlock
                   destructiveTitle:(NSString *)destructiveTitle
                   destructiveBlock:(void (^)(void))destructiveBlock
                      barButtonItem:(UIBarButtonItem *)barButtonItem
                         sourceView:(UIView *)sourceView
                         sourceRect:(CGRect)sourceRect;

@end
