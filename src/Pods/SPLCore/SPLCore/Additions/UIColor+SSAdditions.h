//
//  UIColor+SSAdditions.h
//  SPLCore
//
//  Created by Jonathan Hersh on 12/22/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import <UIKit/UIKit.h>

#define RGB(r, g, b) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:1]
#define RGBA(r, g, b, a) [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
#define UIColorFromRGB(rgbValue) [UIColor colorWithRed:((CGFloat)((rgbValue & 0xFF0000) >> 16))/255.0f green:((CGFloat)((rgbValue & 0xFF00) >> 8))/255.0f blue:((CGFloat)(rgbValue & 0xFF))/255.0f alpha:1.0]

@interface UIColor (SSAdditions)

- (UIColor *)colorByDarkeningColor;
- (UIColor *)colorByLighteningColor;

- (UIColor *)colorByApplyingMultiplier:(CGFloat)multiplier;

@end
