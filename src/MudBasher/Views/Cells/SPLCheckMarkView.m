//
//  SPLCheckMarkView.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/9/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLCheckMarkView.h"

@implementation SPLCheckMarkView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];
    }

    return self;
}

+ (instancetype)checkWithColor:(UIColor *)color {
    SPLCheckMarkView *check = [[SPLCheckMarkView alloc] initWithFrame:CGRectMake(0, 0, 12, 15)];
    check.accessoryColor = color;
    check.highlightedColor = [UIColor whiteColor];
    return check;
}

- (void)setAccessoryColor:(UIColor *)accessoryColor {
    _accessoryColor = accessoryColor;
    [self setNeedsDisplay];
}

- (void)setHighlightedColor:(UIColor *)highlightedColor {
    _highlightedColor = highlightedColor;
    [self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGRect checkRect = CGRectInset(rect, 2, 2);

    CGContextMoveToPoint(context, 0, CGRectGetMidY(checkRect) + 1);
    CGContextAddLineToPoint(context, CGRectGetMidX(checkRect), CGRectGetMaxY(checkRect));
    CGContextAddLineToPoint(context, CGRectGetMaxX(checkRect), CGRectGetMinY(checkRect));

    CGContextSetLineCap(context, kCGLineCapSquare);
    CGContextSetLineJoin(context, kCGLineJoinRound);
    CGContextSetLineWidth(context, 3.f);

    if (self.highlighted) {
        [self.highlightedColor setStroke];
    } else {
        [self.accessoryColor setStroke];
    }

    CGContextStrokePath(context);
}

@end
