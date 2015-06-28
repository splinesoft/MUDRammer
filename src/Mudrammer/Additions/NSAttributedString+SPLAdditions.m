//
//  NSAttributedString+SPLAdditions.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/1/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

#import "NSAttributedString+SPLAdditions.h"
#import "UIColor+SPLANSI.h"
@import CoreText;

@implementation NSAttributedString (SPLAdditions)

+ (instancetype)userInputStringForString:(NSString *)string {
    return [[NSAttributedString alloc] initWithString:string
                                           attributes:@{
                                                    (id)kCTForegroundColorAttributeName : (id)kDefaultANSIColorFgBrightMagenta.CGColor,
                                                    NSForegroundColorAttributeName : kDefaultANSIColorFgBrightMagenta,
                                                    NSFontAttributeName : [SSThemes currentFont],
                                                    NSKernAttributeName : [NSNull null],
                                            }];
}

+ (instancetype)worldStringForString:(NSString *)string {
    return [[NSAttributedString alloc] initWithString:string
                                           attributes:@{
                                                    NSFontAttributeName : [SSThemes currentFont],
                                                    NSForegroundColorAttributeName : [SSThemes valueForThemeKey:kThemeFontColor],
                                                    (id)kCTForegroundColorAttributeName : (id)((UIColor *)[SSThemes valueForThemeKey:kThemeFontColor]).CGColor,
                                                    NSKernAttributeName : [NSNull null],
                                            }];
}

@end
