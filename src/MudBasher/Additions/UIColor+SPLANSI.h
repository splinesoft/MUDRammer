//
//  UIColor+SPLANSI.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/1/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import <UIColor+SSAdditions.h>

@interface UIColor (SPLANSI)

FOUNDATION_EXTERN NSString * const kANSIEscapeCSI;

// the end byte of an SGR (Select Graphic Rendition)
// ANSI Escape Sequence
FOUNDATION_EXTERN NSString * const kANSIEscapeSGREnd;

// color definition helper macros
FOUNDATION_EXTERN CGFloat const kBrightColorBrightness;
FOUNDATION_EXTERN CGFloat const kBrightColorSaturation;
FOUNDATION_EXTERN CGFloat const kBrightColorAlpha;
#define kBrightColorWithHue(h)  [UIColor colorWithHue:(h) saturation:kBrightColorSaturation brightness:kBrightColorBrightness alpha:kBrightColorAlpha]

/**
 *  16-color SGR codes, including xterm-256 markers.
 */
typedef NS_ENUM(NSInteger, SPLSGRCode) {
    SPLSGRCodeNoneOrInvalid =      -1,

    SPLSGRCodeAllReset =           0,

    SPLSGRCodeIntensityBold =      1,
    SPLSGRCodeIntensityFaint =     2,
    SPLSGRCodeIntensityNormal =    22,

    SPLSGRCodeItalicOn =           3,

    SPLSGRCodeUnderlineSingle =    4,

    SPLSGRCodeXTermMarker2 =       5,  // xterm-256

    SPLSGRCodeReverse =            7,
    SPLSGRCodeHidden =             8,
    SPLSGRCodeStrikeOut =          9,

    SPLSGRCodeUnderlineDouble =    21,
    SPLSGRCodeUnderlineNone =      24,
    SPLSGRCodeUndoReverse =        27,
    SPLSGRCodeUndoStrikeOut =      29,

    SPLSGRCodeFgBlack =            30,
    SPLSGRCodeFgRed =              31,
    SPLSGRCodeFgGreen =            32,
    SPLSGRCodeFgYellow =           33,
    SPLSGRCodeFgBlue =             34,
    SPLSGRCodeFgMagenta =          35,
    SPLSGRCodeFgCyan =             36,
    SPLSGRCodeFgWhite =            37,
    SPLSGRCodeXTermForeground =    38, // xterm-256
    SPLSGRCodeFgReset =            39,

    SPLSGRCodeBgBlack =            40,
    SPLSGRCodeBgRed =              41,
    SPLSGRCodeBgGreen =            42,
    SPLSGRCodeBgYellow =           43,
    SPLSGRCodeBgBlue =             44,
    SPLSGRCodeBgMagenta =          45,
    SPLSGRCodeBgCyan =             46,
    SPLSGRCodeBgWhite =            47,
    SPLSGRCodeXTermBackground =    48, // xterm-256
    SPLSGRCodeBgReset =            49,

    SPLSGRCodeFgBrightBlack =      90,
    SPLSGRCodeFgBrightRed =        91,
    SPLSGRCodeFgBrightGreen =      92,
    SPLSGRCodeFgBrightYellow =     93,
    SPLSGRCodeFgBrightBlue =       94,
    SPLSGRCodeFgBrightMagenta =    95,
    SPLSGRCodeFgBrightCyan =       96,
    SPLSGRCodeFgBrightWhite =      97,

    SPLSGRCodeBgBrightBlack =      100,
    SPLSGRCodeBgBrightRed =        101,
    SPLSGRCodeBgBrightGreen =      102,
    SPLSGRCodeBgBrightYellow =     103,
    SPLSGRCodeBgBrightBlue =       104,
    SPLSGRCodeBgBrightMagenta =    105,
    SPLSGRCodeBgBrightCyan =       106,
    SPLSGRCodeBgBrightWhite =      107
};

#define SPLBackgroundColorForColor(color) ([color colorByDarkeningColor])
#define SPLLightenedColorForColor(color)  ([color colorByLighteningColor])

#define kDefaultANSIColorFgBlack	([[SSThemes sharedThemer] isUsingDarkTheme] ? self.defaultTextColor : [UIColor blackColor])
#define kDefaultANSIColorFgRed		[UIColor redColor]
#define kDefaultANSIColorFgGreen	[UIColor greenColor]
#define kDefaultANSIColorFgYellow	[UIColor yellowColor]
#define kDefaultANSIColorFgBlue		[UIColor blueColor]
#define kDefaultANSIColorFgMagenta	[UIColor magentaColor]
#define kDefaultANSIColorFgCyan		[UIColor cyanColor]

#define kDefaultANSIColorFgBrightBlack		[UIColor colorWithWhite:0.337f alpha:1.0f]
#define kDefaultANSIColorFgBrightRed		kBrightColorWithHue(1.0f)
#define kDefaultANSIColorFgBrightGreen		kBrightColorWithHue(1.0f/3.0f)
#define kDefaultANSIColorFgBrightYellow		kBrightColorWithHue(1.0f/6.0f)
#define kDefaultANSIColorFgBrightBlue		kBrightColorWithHue(2.0f/3.0f)
#define kDefaultANSIColorFgBrightMagenta	kBrightColorWithHue(5.0f/6.0f)
#define kDefaultANSIColorFgBrightCyan		kBrightColorWithHue(0.5f)
#define kDefaultANSIColorFgBrightWhite		[UIColor lightGrayColor]

#define kDefaultANSIColorBgBlack	[UIColor clearColor]
#define kDefaultANSIColorBgRed		SPLBackgroundColorForColor(kDefaultANSIColorFgRed)
#define kDefaultANSIColorBgGreen	SPLBackgroundColorForColor(kDefaultANSIColorFgGreen)
#define kDefaultANSIColorBgYellow	SPLBackgroundColorForColor(kDefaultANSIColorFgYellow)
#define kDefaultANSIColorBgBlue		SPLBackgroundColorForColor(kDefaultANSIColorFgBlue)
#define kDefaultANSIColorBgMagenta	SPLBackgroundColorForColor(kDefaultANSIColorFgMagenta)
#define kDefaultANSIColorBgCyan		SPLBackgroundColorForColor(kDefaultANSIColorFgCyan)

#define kDefaultANSIColorBgBrightBlack		[UIColor clearColor]
#define kDefaultANSIColorBgBrightRed		SPLBackgroundColorForColor(kDefaultANSIColorFgBrightRed)
#define kDefaultANSIColorBgBrightGreen		SPLBackgroundColorForColor(kDefaultANSIColorFgBrightGreen)
#define kDefaultANSIColorBgBrightYellow		SPLBackgroundColorForColor(kDefaultANSIColorFgBrightYellow)
#define kDefaultANSIColorBgBrightBlue		SPLBackgroundColorForColor(kDefaultANSIColorFgBrightBlue)
#define kDefaultANSIColorBgBrightMagenta 	SPLBackgroundColorForColor(kDefaultANSIColorFgBrightMagenta)
#define kDefaultANSIColorBgBrightCyan		SPLBackgroundColorForColor(kDefaultANSIColorFgBrightCyan)

/**
 *  Return a suitable color for this SGR code.
 *
 *  @param code         code to use
 *  @param defaultColor default color if not found or for white/black text
 *
 *  @return a suitable color
 */
+ (instancetype) colorForSGRCode:(SPLSGRCode)code
                    defaultColor:(UIColor *)defaultColor;

@end
