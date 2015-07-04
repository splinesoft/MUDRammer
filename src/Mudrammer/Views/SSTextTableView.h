//
//  SSTextTableView.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/22/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@interface SSTextTableView : UITableView <UIScrollViewAccessibilityDelegate>

// Specify a frame.
- (instancetype) initWithFrame:(CGRect)frame;

// Scrolling to bottom
- (void) scrollToBottom;
@property (nonatomic, getter=isNearBottom, readonly) BOOL nearBottom;

// Approx char size
@property (nonatomic, readonly) CGSize charSize;

@end
