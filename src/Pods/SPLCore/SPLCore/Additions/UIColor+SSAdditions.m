//
//  UIColor+SSAdditions.m
//  SPLCore
//
//  Created by Jonathan Hersh on 12/22/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

static CGFloat const kDarkFactor = 0.7f;
static CGFloat const kLightFactor = 1.5f;

#import "UIColor+SSAdditions.h"

@implementation UIColor (SSAdditions)

- (UIColor *)colorByApplyingMultiplier:(CGFloat)multiplier {
    CGFloat r,g,b,a;
    
    if (![self getRed:&r green:&g blue:&b alpha:&a]) {
        CGFloat white;
        
        if ([self getWhite:&white alpha:NULL]) {
            return [UIColor colorWithWhite:(white * multiplier) alpha:1.0f];
        }
        
        return nil;
    }
    
    r *= multiplier;
    g *= multiplier;
    b *= multiplier;
    
    UIColor *newColor = [UIColor colorWithRed:r green:g blue:b alpha:a];
    
    return newColor;
}

- (UIColor *)colorByLighteningColor {
    return [self colorByApplyingMultiplier:kLightFactor];
}

- (UIColor *)colorByDarkeningColor {
    return [self colorByApplyingMultiplier:kDarkFactor];
}

@end
