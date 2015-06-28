//
//  UITableView+SSAdditions.m
//  SPLCore
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SPLCore.h"

@implementation UITableView (SSAdditions)

- (UIView *) centeredViewWithImage:(UIImage *)image alpha:(CGFloat)alpha {
    UIImageView *iv = [[UIImageView alloc] initWithImage:image];
    iv.alpha = alpha;
    iv.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    
    [iv setFrame:CGRectMake(SPLFloat_round((CGRectGetWidth(self.frame) - image.size.width ) / 2.0f ),
                            10, image.size.width, image.size.height)];
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.frame), image.size.height * 1.5f )];
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [view addSubview:iv];
    
    return view;
}

- (void)addCenteredHeaderWithImage:(UIImage *)image alpha:(CGFloat)alpha {
    self.tableHeaderView = [self centeredViewWithImage:image alpha:alpha];
}

- (void)addCenteredFooterWithImage:(UIImage *)image alpha:(CGFloat)alpha {
    self.tableFooterView = [self centeredViewWithImage:image alpha:alpha];
}

- (CGSize)popoverContentSize {
    CGSize size = [self sizeThatFits:CGSizeMake(320.0f, CGFLOAT_MAX)];
    size.height += self.rowHeight;
    
    return size;
}

@end
