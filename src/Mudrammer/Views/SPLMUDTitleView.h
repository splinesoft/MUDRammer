//
//  SPLMUDTitleView.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/28/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

/**
 *  Nav bar title view for the current MUD.
 *  Can receive MSSP data to indicate MSSP is available to view.
 */

@import UIKit;

@interface SPLMUDTitleView : UIView

- (instancetype) initWithFrame:(CGRect)frame;

/**
 *  Set or update the MSSP data available.
 *  Shows an MSSP button if not previously visible.
 */
@property (nonatomic, copy) NSDictionary *MSSPData;

/**
 *  Set or update the title displayed in the title view.
 *
 *  @param title title to set or update
 */
- (void) setTitle:(NSString *)title;

/**
 *  Block called when there is MSSP data available and the button has been tapped.
 */
@property (nonatomic, copy) void (^MSSPButtonBlock) (void);

@end
