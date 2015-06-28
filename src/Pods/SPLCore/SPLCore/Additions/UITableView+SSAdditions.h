//
//  UITableView+SSAdditions.h
//  SPLCore
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UITableView (SSAdditions)

- (void) addCenteredHeaderWithImage:(UIImage *)image alpha:(CGFloat)alpha;
- (void) addCenteredFooterWithImage:(UIImage *)image alpha:(CGFloat)alpha;

// Calculate the preferred content size for display in an iPad popover.
// Automatically adds an extra row to the height - seems to work around an iOS 7 issue?
- (CGSize) popoverContentSize;

@end
