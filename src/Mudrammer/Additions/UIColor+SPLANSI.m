//
//  UIColor+SPLANSI.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/1/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

#import "UIColor+SPLANSI.h"

CGFloat const kBrightColorBrightness = 1.0f;
CGFloat const kBrightColorSaturation = 0.4f;
CGFloat const kBrightColorAlpha = 1.0f;

NSString * const kANSIEscapeCSI = @"\033[";
NSString * const kANSIEscapeSGREnd = @"m";

@implementation UIColor (SPLANSI)

+ (instancetype) colorForSGRCode:(SPLSGRCode)code
                    defaultColor:(UIColor *)defaultColor {

    switch (code) {
        case SPLSGRCodeFgBlack:
            return ([[SSThemes sharedThemer] isUsingDarkTheme] ? defaultColor : [UIColor blackColor]);
        case SPLSGRCodeFgRed:
            return kDefaultANSIColorFgRed;
        case SPLSGRCodeFgGreen:
            return kDefaultANSIColorFgGreen;
        case SPLSGRCodeFgYellow:
            return kDefaultANSIColorFgYellow;
        case SPLSGRCodeFgBlue:
            return kDefaultANSIColorFgBlue;
        case SPLSGRCodeFgMagenta:
            return kDefaultANSIColorFgMagenta;
        case SPLSGRCodeFgCyan:
            return kDefaultANSIColorFgCyan;
        case SPLSGRCodeFgWhite:
            return defaultColor;
        case SPLSGRCodeFgBrightBlack:
            return kDefaultANSIColorFgBrightBlack;
        case SPLSGRCodeFgBrightRed:
            return kDefaultANSIColorFgBrightRed;
        case SPLSGRCodeFgBrightGreen:
            return kDefaultANSIColorFgBrightGreen;
        case SPLSGRCodeFgBrightYellow:
            return kDefaultANSIColorFgBrightYellow;
        case SPLSGRCodeFgBrightBlue:
            return kDefaultANSIColorFgBrightBlue;
        case SPLSGRCodeFgBrightMagenta:
            return kDefaultANSIColorFgBrightMagenta;
        case SPLSGRCodeFgBrightCyan:
            return kDefaultANSIColorFgBrightCyan;
        case SPLSGRCodeFgBrightWhite:
            return kDefaultANSIColorFgBrightWhite;
        case SPLSGRCodeBgBlack:
            return kDefaultANSIColorBgBlack;
        case SPLSGRCodeBgRed:
            return kDefaultANSIColorBgRed;
        case SPLSGRCodeBgGreen:
            return kDefaultANSIColorBgGreen;
        case SPLSGRCodeBgYellow:
            return kDefaultANSIColorBgYellow;
        case SPLSGRCodeBgBlue:
            return kDefaultANSIColorBgBlue;
        case SPLSGRCodeBgMagenta:
            return kDefaultANSIColorBgMagenta;
        case SPLSGRCodeBgCyan:
            return kDefaultANSIColorBgCyan;
        case SPLSGRCodeBgWhite:
            return ([[SSThemes sharedThemer] isUsingDarkTheme] ? [UIColor whiteColor] : [UIColor blackColor]);
        case SPLSGRCodeBgBrightBlack:
            return kDefaultANSIColorBgBrightBlack;
        case SPLSGRCodeBgBrightRed:
            return kDefaultANSIColorBgBrightRed;
        case SPLSGRCodeBgBrightGreen:
            return kDefaultANSIColorBgBrightGreen;
        case SPLSGRCodeBgBrightYellow:
            return kDefaultANSIColorBgBrightYellow;
        case SPLSGRCodeBgBrightBlue:
            return kDefaultANSIColorBgBrightBlue;
        case SPLSGRCodeBgBrightMagenta:
            return kDefaultANSIColorBgBrightMagenta;
        case SPLSGRCodeBgBrightCyan:
            return kDefaultANSIColorBgBrightCyan;
        case SPLSGRCodeBgBrightWhite:
            return ([[SSThemes sharedThemer] isUsingDarkTheme] ? [UIColor whiteColor] : [UIColor blackColor]);

        default:
            DLog(@"unknown sgr %@", @(code));
            break;
    }

    return defaultColor;
}

@end
