//
//  SSANSIEngine.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/5/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SSANSIEngine.h"
#import <TTTAttributedLabel.h>
#import "SSAttributedLineGroup.h"
#import "NSCharacterSet+SPLAdditions.h"
#import "NSScanner+SPLAdditions.h"
#import "NSData+SPLDataParsing.h"

static NSString * const kANSIRegex = @"(?s)(?:\e\\[(?:(\\d+)?;?)*([A-Za-z])(.*?))(?=\e\\[|\\z)";

#pragma mark - Color helpers

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wswitch-enum"

CG_INLINE BOOL SPLCodesAreXTermSequence(NSInteger code1, NSInteger code2) {
    return (code2 == SPLSGRCodeXTermMarker2 && (code1 == SPLSGRCodeXTermForeground || code1 == SPLSGRCodeXTermBackground));
}

CG_INLINE SPLSGRCode SPLIntenseColorForColor(SPLSGRCode color) {
    switch (color) {
        case SPLSGRCodeFgBlack:
            return SPLSGRCodeFgBrightBlack;
        case SPLSGRCodeFgRed:
            return SPLSGRCodeFgBrightRed;
        case SPLSGRCodeFgGreen:
            return SPLSGRCodeFgBrightGreen;
        case SPLSGRCodeFgYellow:
            return SPLSGRCodeFgBrightYellow;
        case SPLSGRCodeFgBlue:
            return SPLSGRCodeFgBrightBlue;
        case SPLSGRCodeFgMagenta:
            return SPLSGRCodeFgBrightMagenta;
        case SPLSGRCodeFgCyan:
            return SPLSGRCodeFgBrightCyan;
        case SPLSGRCodeFgWhite:
            return SPLSGRCodeFgBrightWhite;
        case SPLSGRCodeBgBlack:
            return SPLSGRCodeBgBrightBlack;
        case SPLSGRCodeBgRed:
            return SPLSGRCodeBgBrightRed;
        case SPLSGRCodeBgGreen:
            return SPLSGRCodeBgBrightGreen;
        case SPLSGRCodeBgYellow:
            return SPLSGRCodeBgBrightYellow;
        case SPLSGRCodeBgBlue:
            return SPLSGRCodeBgBrightBlue;
        case SPLSGRCodeBgMagenta:
            return SPLSGRCodeBgBrightMagenta;
        case SPLSGRCodeBgCyan:
            return SPLSGRCodeBgBrightCyan;
        case SPLSGRCodeBgWhite:
            return SPLSGRCodeBgBrightWhite;
        default:
            DLog(@"unknown intense %@", @(color));
            return color;
    }
}

@interface SPLTextOptions : NSObject

/**
 *  Any command associated with the text.
 */
@property (nonatomic, strong) SSLineGroupCommand *command;

/**
 Set the text color.
 */
@property(nonatomic, strong) UIColor *color;

/**
 Set the replacement text.
 */
@property(nonatomic, copy)NSString *replaceText;

/**
 Set if the text is underlined.
 */
@property(nonatomic, assign)BOOL isUnderline;

/**
 Set if the text is strikethrough.
 */
@property(nonatomic, assign)BOOL isStrikeThrough;

/**
 Set the strikeThrough color.
 */
@property(nonatomic, strong)UIColor *strikeColor;

/**
 Set the highlight color.
 */
@property(nonatomic, strong)UIColor *highlightColor;

@property (nonatomic, assign) BOOL isReverse;

@end

@protocol SPLANSIEngine <NSObject>

@required

- (NSDictionary *)generateAttributes:(SPLTextOptions *)options;

- (void)parseColorForColorCodes:(NSArray *)codes options:(SPLTextOptions *)options;

- (SPLTextOptions *)optionsForANSIString:(NSString *)text;

@end

@interface SSANSIEngine () <SPLANSIEngine>

@property (nonatomic, copy) UIColor *lastColor;
@property (nonatomic, copy) UIColor *lastBGColor;
@property (nonatomic, strong) FBKVOController *kvoController;

- (void) parseSixteenColorForBits:(NSArray *)codes options:(SPLTextOptions *)options;
- (void) parseXtermColorForColor:(NSInteger)color isForeground:(BOOL)isForeground options:(SPLTextOptions *)options;

@end

@implementation SPLTextOptions

- (instancetype)init {
    if ((self = [super init])) {
        _replaceText = @"";
    }

    return self;
}

@end

@implementation SSANSIEngine

- (instancetype)init {
    if ((self = [super init])) {
        _defaultTextColor = [[SSThemes sharedThemer] valueForThemeKey:kThemeFontColor];
        _defaultFont = [SSThemes sharedThemer].currentFont;
        _lastColor = self.defaultTextColor;
        _lastBGColor = [UIColor clearColor];

        // Observe theme changes
        _kvoController = [FBKVOController controllerWithObserver:self];

        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeFontColor
                            options:NSKeyValueObservingOptionNew
                              block:^(SSANSIEngine *engine, id object, NSDictionary *change) {
                                  UIColor *newColor = change[NSKeyValueChangeNewKey];
                                  if (!newColor) newColor = [UIColor whiteColor];
                                  engine.defaultTextColor = newColor;
                                  engine.lastColor = newColor;
                              }];

        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeFontSize
                            options:NSKeyValueObservingOptionNew
                              block:^(SSANSIEngine *engine, id object, NSDictionary *change) {
                                  engine.defaultFont = [SSThemes sharedThemer].currentFont;
                              }];

        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeFontName
                            options:NSKeyValueObservingOptionNew
                              block:^(SSANSIEngine *engine, id object, NSDictionary *change) {
                                  engine.defaultFont = [SSThemes sharedThemer].currentFont;
                              }];
    }

    return self;
}

#pragma mark - SPLANSIEngine

- (NSDictionary *)generateAttributes:(SPLTextOptions *)options {
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 (id)self.lastColor.CGColor, (id)kCTForegroundColorAttributeName,
                                 self.defaultFont, NSFontAttributeName,
                                 [NSNull null], NSKernAttributeName,
                                 nil];

    if (self.lastBGColor && ![self.lastBGColor isEqual:[UIColor clearColor]]) {
        options.highlightColor = self.lastBGColor;
    }

    if (options.isUnderline) {
        dict[NSUnderlineStyleAttributeName] = @1;
    }

    if (options.highlightColor && ![options.highlightColor isEqual:[UIColor clearColor]]) {
        dict[kTTTBackgroundFillColorAttributeName] = (id)options.highlightColor.CGColor;
        dict[kTTTBackgroundStrokeColorAttributeName] = (id)options.highlightColor.CGColor;
    }

    if (options.isStrikeThrough) {
        dict[kTTTStrikeOutAttributeName] = @YES;
    }

    if (options.color && options.highlightColor && [options.color isEqual:options.highlightColor]) {
//        DLog(@"same %@", options.color);
        options.color = [options.color colorByDarkeningColor] ?: self.lastColor ?: self.defaultTextColor;
    }

    if (options.color) {
        dict[(id)kCTForegroundColorAttributeName] = (id)options.color.CGColor;
    }

    // Reverse can cause a clear color to show for the foreground
    if (!options.color || [options.color isEqual:[UIColor clearColor]]) {
        dict[(id)kCTForegroundColorAttributeName] = (id)self.defaultTextColor.CGColor;
    }

    return dict;
}

- (void)parseColorForColorCodes:(NSArray *)codes options:(SPLTextOptions *)options {
    if ([codes count] == 0) {
        DLog(@"no codes?");
        options.color = self.defaultTextColor;
        return;
    }

    BOOL didColor = NO;

    if ([codes count] > 2) {
        for (NSUInteger index = 0; index < [codes count]; index += 3) {
            if (index + 2 >= [codes count]) {
                break;
            }

            NSInteger code1 = [codes[index] integerValue];
            NSInteger code2 = [codes[index + 1] integerValue];
            NSInteger code3 = [codes[index + 2] integerValue];

            if (SPLCodesAreXTermSequence(code1, code2)) {
                [self parseXtermColorForColor:code3
                                 isForeground:(code1 == SPLSGRCodeXTermForeground)
                                      options:options];
                didColor = YES;
            }
        }
    }

    if (!didColor) {
        [self parseSixteenColorForBits:codes options:options];
    }

    options.color = self.lastColor;
    options.highlightColor = self.lastBGColor;
}

- (SPLTextOptions *)optionsForANSIString:(NSString *)text {
    SPLTextOptions *options = [SPLTextOptions new];

//    DLog(@"opt for %@ %@ %@", text, @(text.length), [[text dataUsingEncoding:NSUTF8StringEncoding] charCodeString]);

    if ([text length] < [kANSIEscapeCSI length]) {
        options.color = self.lastColor;
        options.replaceText = text;
        return options;
    }

    NSScanner *scanner = [NSScanner scannerWithString:text];
    [scanner setCharactersToBeSkipped:nil];

    NSMutableString *output = [NSMutableString new];

    do {
        NSString *tmp;

        if ([scanner scanUpToString:kANSIEscapeCSI intoString:&tmp]) {
            // There is text at the start of the string, before the ANSI color code.
            // Or something insane has happened and there is no CSI in this string.

//            DLog(@"text %@ %@", tmp, @(tmp.length));
            [output appendString:tmp];
        }

        if ([scanner isAtEnd]) {
            break;
        }

        [scanner scanString:kANSIEscapeCSI intoString:NULL];

        if ([scanner isAtEnd]) {
            break;
        }

        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet CSITerminationCharacterSet]
                                    intoString:&tmp]) {

            // We have scanned one or more characters between the CSI initiator
            // and a termination character.

//            DLog(@"value %@", tmp);

            if (![scanner isAtEnd]) {
                NSString *endCode;

                if ([scanner scanString:kANSIEscapeSGREnd intoString:&endCode]) {

                    // Scanned an SGR color code
                    //                    DLog(@"%@", tmp);

                    NSArray *bits = [tmp componentsSeparatedByString:@";"];
                    [self parseColorForColorCodes:bits options:options];

                } else if ([scanner SPLScanCharacterFromSet:[NSCharacterSet CSITerminationCharacterSet]
                                                 intoString:&endCode]) {

                    // Capture something like ESC[;17H
                    // or ESC[17;H

                    // Scanned some other type of SGR end code
                    options.command = [SSLineGroupCommand commandWithBody:tmp endCode:endCode];
                } else {
                    DLog(@"NOT ANSI? %@", tmp);
                    [output appendString:tmp];
                }
            }

        } else {

            // There were no characters between the CSI initiator and a
            // termination character.

            NSString *endCode;

            if ([scanner scanString:kANSIEscapeSGREnd intoString:NULL]) {

                // something like ESC[m
                // should be treated as a reset

                [self parseColorForColorCodes:@[@"0"] options:options];

            } else if ([scanner SPLScanCharacterFromSet:[NSCharacterSet CSITerminationCharacterSet]
                                             intoString:&endCode]) {

                // Scanned some other type of SGR end code
                options.command = [SSLineGroupCommand commandWithBody:nil endCode:endCode];

            } else {
                DLog(@"NOT ANSI? %@", tmp);
                [output appendString:tmp];
            }
        }
    } while (![scanner isAtEnd]);

    options.replaceText = output;

    return options;
}

#pragma mark  - Parsing

- (SSAttributedLineGroup *)parseANSIString:(NSString *)string {
//    DLog(@"Parse %@", string);
    NSMutableString *ansiString = [NSMutableString stringWithString:string];

    // Collapse extra newlines
    [ansiString replaceOccurrencesOfString:@"\r\n"
                                withString:@"\n"
                                   options:NSLiteralSearch
                                     range:NSMakeRange(0, [ansiString length])];

    [ansiString replaceOccurrencesOfString:@"\n\r"
                                withString:@"\n"
                                   options:NSLiteralSearch
                                     range:NSMakeRange(0, [ansiString length])];

    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:ansiString
                                                                                         attributes:@{
                                                                                    NSFontAttributeName : self.defaultFont,
                                                                                    (id)kCTForegroundColorAttributeName : (id)self.lastColor.CGColor,
                                                                                    NSKernAttributeName : [NSNull null],
                                                                                }];

    if (self.lastBGColor && ![self.lastBGColor isEqual:[UIColor clearColor]]) {
        [attributedString addAttributes:@{
              kTTTBackgroundFillColorAttributeName : (id)self.lastBGColor.CGColor,
              kTTTBackgroundStrokeColorAttributeName : (id)self.lastBGColor.CGColor
        } range:NSMakeRange(0, attributedString.length)];
    }

    NSUInteger offset = 0;
    NSRange range;
    NSMutableDictionary *commandLocations = [NSMutableDictionary dictionary];

    do {
        NSString *text = attributedString.string;
        NSUInteger end = text.length - offset;

        range = [text rangeOfString:kANSIRegex
                            options:NSRegularExpressionSearch
                              range:NSMakeRange(offset, end)];

        if (range.location != NSNotFound) {
            offset = NSMaxRange(range);
        } else {
            break;
        }

        NSString *subText = [text substringWithRange:range];

        SPLTextOptions *opts = [self optionsForANSIString:subText];

        NSString *replaceText = opts.replaceText;

        if (!replaceText) {
            replaceText = subText;
        }

        offset += replaceText.length - subText.length;

        if (opts.command) {
            NSNumber *location = @(range.location);
            id bits = commandLocations[location];

            if (!bits) {
                commandLocations[location] = opts.command;
            } else if ([bits isKindOfClass:opts.command.class]) {
                commandLocations[location] = @[ bits, opts.command ];
            } else {
                commandLocations[location] = [commandLocations[location] arrayByAddingObject:opts.command];
            }
        }

        NSAttributedString *replaceStr = [[NSAttributedString alloc] initWithString:replaceText
                                                                         attributes:[self generateAttributes:opts]];
        [attributedString replaceCharactersInRange:range
                              withAttributedString:replaceStr];

    } while (range.location != NSNotFound && offset < attributedString.length);

    SSAttributedLineGroup *group = [SSAttributedLineGroup lineGroupWithAttributedString:attributedString
                                                                       commandLocations:commandLocations];

//    DLog(@"Parsed to %@", group);

    return group;
}

#pragma mark - ANSI-16

- (void)parseSixteenColorForBits:(NSArray *)codes options:(SPLTextOptions *)options {

    // go through all the found escape sequence codes and for each one, create
    // the string formatting attribute name and value, find the next escape
    // sequence that specifies the end of the formatting run started by
    // the currently handled code, and generate a range from the difference
    // in those codes' locations within the clean aString.

    BOOL isBolded = NO;

    for (NSUInteger iCode = 0; iCode < [codes count]; iCode++) {
        NSNumber *code = codes[iCode];
        SPLSGRCode thisCode = (SPLSGRCode)[code integerValue];

        // the attributed string attribute name for the formatting run introduced
        // by this code
        NSString *thisAttributeName = nil;

        // the attributed string attribute value for this formatting run introduced
        // by this code
        NSObject *thisAttributeValue = nil;

        // set attribute name
        switch(thisCode)
        {
            case SPLSGRCodeFgBlack:
            case SPLSGRCodeFgRed:
            case SPLSGRCodeFgGreen:
            case SPLSGRCodeFgYellow:
            case SPLSGRCodeFgBlue:
            case SPLSGRCodeFgMagenta:
            case SPLSGRCodeFgCyan:
            case SPLSGRCodeFgWhite:
            case SPLSGRCodeFgBrightBlack:
            case SPLSGRCodeFgBrightRed:
            case SPLSGRCodeFgBrightGreen:
            case SPLSGRCodeFgBrightYellow:
            case SPLSGRCodeFgBrightBlue:
            case SPLSGRCodeFgBrightMagenta:
            case SPLSGRCodeFgBrightCyan:
            case SPLSGRCodeFgBrightWhite:
                thisAttributeName = (options.isReverse ? NSBackgroundColorAttributeName : NSForegroundColorAttributeName);
                break;
            case SPLSGRCodeBgBlack:
            case SPLSGRCodeBgRed:
            case SPLSGRCodeBgGreen:
            case SPLSGRCodeBgYellow:
            case SPLSGRCodeBgBlue:
            case SPLSGRCodeBgMagenta:
            case SPLSGRCodeBgCyan:
            case SPLSGRCodeBgWhite:
            case SPLSGRCodeBgBrightBlack:
            case SPLSGRCodeBgBrightRed:
            case SPLSGRCodeBgBrightGreen:
            case SPLSGRCodeBgBrightYellow:
            case SPLSGRCodeBgBrightBlue:
            case SPLSGRCodeBgBrightMagenta:
            case SPLSGRCodeBgBrightCyan:
            case SPLSGRCodeBgBrightWhite:
                thisAttributeName = (options.isReverse ? NSForegroundColorAttributeName : NSBackgroundColorAttributeName);
                break;
            case SPLSGRCodeIntensityBold:
                isBolded = YES;
                continue;
            case SPLSGRCodeIntensityNormal:
            case SPLSGRCodeIntensityFaint:
                isBolded = NO;
                continue;
            case SPLSGRCodeUnderlineSingle:
            case SPLSGRCodeUnderlineDouble:
            case SPLSGRCodeUnderlineNone:
                thisAttributeName = NSUnderlineStyleAttributeName;
                break;
            case SPLSGRCodeFgReset:
                isBolded = NO;
                self.lastColor = self.defaultTextColor;
                options.isStrikeThrough = NO;
                continue;
            case SPLSGRCodeBgReset:
                self.lastBGColor = [UIColor clearColor];
                continue;
            case SPLSGRCodeAllReset:
                isBolded = NO;
                self.lastColor = self.defaultTextColor;
                self.lastBGColor = [UIColor clearColor];
                options.isStrikeThrough = NO;
                options.isUnderline = NO;
                options.isReverse = NO;
                continue;
            case SPLSGRCodeStrikeOut:
                options.strikeColor = self.lastColor;
                options.isStrikeThrough = YES;
                continue;
            case SPLSGRCodeUndoStrikeOut:
                options.isStrikeThrough = NO;
                continue;
            case SPLSGRCodeReverse:
                //DLog(@"reverse");
                options.isReverse = YES;
                continue;
            case SPLSGRCodeUndoReverse:
                options.isReverse = NO;
                continue;
            default:
                DLog(@"unknown code %@", @(thisCode));
                continue;
        }

        // set attribute value
        switch(thisCode)
        {
            case SPLSGRCodeBgBlack:
            case SPLSGRCodeFgBlack:
            case SPLSGRCodeBgRed:
            case SPLSGRCodeFgRed:
            case SPLSGRCodeBgGreen:
            case SPLSGRCodeFgGreen:
            case SPLSGRCodeBgYellow:
            case SPLSGRCodeFgYellow:
            case SPLSGRCodeBgBlue:
            case SPLSGRCodeFgBlue:
            case SPLSGRCodeBgMagenta:
            case SPLSGRCodeFgMagenta:
            case SPLSGRCodeBgCyan:
            case SPLSGRCodeFgCyan:
            case SPLSGRCodeBgWhite:
            case SPLSGRCodeFgWhite:
            case SPLSGRCodeBgBrightBlack:
            case SPLSGRCodeFgBrightBlack:
            case SPLSGRCodeBgBrightRed:
            case SPLSGRCodeFgBrightRed:
            case SPLSGRCodeBgBrightGreen:
            case SPLSGRCodeFgBrightGreen:
            case SPLSGRCodeBgBrightYellow:
            case SPLSGRCodeFgBrightYellow:
            case SPLSGRCodeBgBrightBlue:
            case SPLSGRCodeFgBrightBlue:
            case SPLSGRCodeBgBrightMagenta:
            case SPLSGRCodeFgBrightMagenta:
            case SPLSGRCodeBgBrightCyan:
            case SPLSGRCodeFgBrightCyan:
            case SPLSGRCodeBgBrightWhite:
            case SPLSGRCodeFgBrightWhite: {

                SPLSGRCode aCode = (isBolded
                                    ? SPLIntenseColorForColor(thisCode)
                                    : thisCode);

                //                DLog(@"code for %i %i", thisCode, aCode);
                thisAttributeValue = [UIColor colorForSGRCode:aCode
                                                 defaultColor:self.defaultTextColor];

                break;
            }
            case SPLSGRCodeIntensityBold:
            case SPLSGRCodeIntensityNormal:
            case SPLSGRCodeIntensityFaint:
                continue;
            case SPLSGRCodeUnderlineSingle:
                thisAttributeValue = @(NSUnderlineStyleSingle);
                break;
            case SPLSGRCodeUnderlineDouble:
                thisAttributeValue = @(NSUnderlineStyleDouble);
                break;
            case SPLSGRCodeUnderlineNone:
                thisAttributeValue = @(NSUnderlineStyleNone);
                break;
            default:
                //thisAttributeValue = self.color;
                continue;
        }

        if (!thisAttributeValue || !thisAttributeName) {
            DLog(@"skip");
            continue;
        }

        if ([thisAttributeName isEqualToString:NSForegroundColorAttributeName]) {
            self.lastColor = (UIColor *)thisAttributeValue;
        } else if ([thisAttributeName isEqualToString:NSBackgroundColorAttributeName]) {
            self.lastBGColor = (UIColor *)thisAttributeValue;
        } else if ([thisAttributeName isEqualToString:NSUnderlineStyleAttributeName]) {
            options.isUnderline = !((NSUnderlineStyle)[(NSNumber *)thisAttributeValue integerValue] == NSUnderlineStyleNone);
        }
    }
}

#pragma mark - XTERM-256

- (void)parseXtermColorForColor:(NSInteger)color isForeground:(BOOL)isForeground options:(SPLTextOptions *)options {
    static NSDictionary *codes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        codes = @{
              @(0):kDefaultANSIColorFgBlack,
              @(1):kDefaultANSIColorFgRed,
              @(2):kDefaultANSIColorFgGreen,
              @(3):kDefaultANSIColorFgYellow,
              @(4):kDefaultANSIColorFgBlue,
              @(5):kDefaultANSIColorFgMagenta,
              @(6):kDefaultANSIColorFgCyan,
              @(7):self.defaultTextColor,
              @(8):kDefaultANSIColorFgBrightBlack,
              @(9):kDefaultANSIColorFgBrightRed,
              @(10):kDefaultANSIColorFgBrightGreen,
              @(11):kDefaultANSIColorFgBrightYellow,
              @(12):kDefaultANSIColorFgBrightBlue,
              @(13):kDefaultANSIColorFgBrightMagenta,
              @(14):kDefaultANSIColorFgBrightCyan,
              @(15):kDefaultANSIColorFgBrightWhite,
              @(16):UIColorFromRGB(0x000000),
              @(17):UIColorFromRGB(0x00005F),
              @(18):UIColorFromRGB(0x000087),
              @(19):UIColorFromRGB(0x0000AF),
              @(20):UIColorFromRGB(0x0000D7),
              @(21):UIColorFromRGB(0x0000FF),
              @(22):UIColorFromRGB(0x005F00),
              @(23):UIColorFromRGB(0x005F5F),
              @(24):UIColorFromRGB(0x005F87),
              @(25):UIColorFromRGB(0x005FAF),
              @(26):UIColorFromRGB(0x005FD7),
              @(27):UIColorFromRGB(0x005FFF),
              @(28):UIColorFromRGB(0x008700),
              @(29):UIColorFromRGB(0x00875F),
              @(30):UIColorFromRGB(0x008787),
              @(31):UIColorFromRGB(0x0087AF),
              @(32):UIColorFromRGB(0x0087D7),
              @(33):UIColorFromRGB(0x0087FF),
              @(34):UIColorFromRGB(0x00AF00),
              @(35):UIColorFromRGB(0x00AF5F),
              @(36):UIColorFromRGB(0x00AF87),
              @(37):UIColorFromRGB(0x00AFAF),
              @(38):UIColorFromRGB(0x00AFD7),
              @(39):UIColorFromRGB(0x00AFFF),
              @(40):UIColorFromRGB(0x00D700),
              @(41):UIColorFromRGB(0x00D75F),
              @(42):UIColorFromRGB(0x00D787),
              @(43):UIColorFromRGB(0x00D7AF),
              @(44):UIColorFromRGB(0x00D7D7),
              @(45):UIColorFromRGB(0x00D7FF),
              @(46):UIColorFromRGB(0x00FF00),
              @(47):UIColorFromRGB(0x00FF5F),
              @(48):UIColorFromRGB(0x00FF87),
              @(49):UIColorFromRGB(0x00FFAF),
              @(50):UIColorFromRGB(0x00FFD7),
              @(51):UIColorFromRGB(0x00FFFF),
              @(52):UIColorFromRGB(0x5F0000),
              @(53):UIColorFromRGB(0x5F005F),
              @(54):UIColorFromRGB(0x5F0087),
              @(55):UIColorFromRGB(0x5F00AF),
              @(56):UIColorFromRGB(0x5F00D7),
              @(57):UIColorFromRGB(0x5F00FF),
              @(58):UIColorFromRGB(0x5F5F00),
              @(59):UIColorFromRGB(0x5F5F5F),
              @(60):UIColorFromRGB(0x5F5F87),
              @(61):UIColorFromRGB(0x5F5FAF),
              @(62):UIColorFromRGB(0x5F5FD7),
              @(63):UIColorFromRGB(0x5F5FFF),
              @(64):UIColorFromRGB(0x5F8700),
              @(65):UIColorFromRGB(0x5F875F),
              @(66):UIColorFromRGB(0x5F8787),
              @(67):UIColorFromRGB(0x5F87AF),
              @(68):UIColorFromRGB(0x5F87D7),
              @(69):UIColorFromRGB(0x5F87FF),
              @(70):UIColorFromRGB(0x5FAF00),
              @(71):UIColorFromRGB(0x5FAF5F),
              @(72):UIColorFromRGB(0x5FAF87),
              @(73):UIColorFromRGB(0x5FAFAF),
              @(74):UIColorFromRGB(0x5FAFD7),
              @(75):UIColorFromRGB(0x5FAFFF),
              @(76):UIColorFromRGB(0x5FD700),
              @(77):UIColorFromRGB(0x5FD75F),
              @(78):UIColorFromRGB(0x5FD787),
              @(79):UIColorFromRGB(0x5FD7AF),
              @(80):UIColorFromRGB(0x5FD7D7),
              @(81):UIColorFromRGB(0x5FD7FF),
              @(82):UIColorFromRGB(0x5FFF00),
              @(83):UIColorFromRGB(0x5FFF5F),
              @(84):UIColorFromRGB(0x5FFF87),
              @(85):UIColorFromRGB(0x5FFFAF),
              @(86):UIColorFromRGB(0x5FFFD7),
              @(87):UIColorFromRGB(0x5FFFFF),
              @(88):UIColorFromRGB(0x870000),
              @(89):UIColorFromRGB(0x87005F),
              @(90):UIColorFromRGB(0x870087),
              @(91):UIColorFromRGB(0x8700AF),
              @(92):UIColorFromRGB(0x8700D7),
              @(93):UIColorFromRGB(0x8700FF),
              @(94):UIColorFromRGB(0x875F00),
              @(95):UIColorFromRGB(0x875F5F),
              @(96):UIColorFromRGB(0x875F87),
              @(97):UIColorFromRGB(0x875FAF),
              @(98):UIColorFromRGB(0x875FD7),
              @(99):UIColorFromRGB(0x875FFF),
              @(100):UIColorFromRGB(0x878700),
              @(101):UIColorFromRGB(0x87875F),
              @(102):UIColorFromRGB(0x878787),
              @(103):UIColorFromRGB(0x8787AF),
              @(104):UIColorFromRGB(0x8787D7),
              @(105):UIColorFromRGB(0x8787FF),
              @(106):UIColorFromRGB(0x87AF00),
              @(107):UIColorFromRGB(0x87AF5F),
              @(108):UIColorFromRGB(0x87AF87),
              @(109):UIColorFromRGB(0x87AFAF),
              @(110):UIColorFromRGB(0x87AFD7),
              @(111):UIColorFromRGB(0x87AFFF),
              @(112):UIColorFromRGB(0x87D700),
              @(113):UIColorFromRGB(0x87D75F),
              @(114):UIColorFromRGB(0x87D787),
              @(115):UIColorFromRGB(0x87D7AF),
              @(116):UIColorFromRGB(0x87D7D7),
              @(117):UIColorFromRGB(0x87D7FF),
              @(118):UIColorFromRGB(0x87FF00),
              @(119):UIColorFromRGB(0x87FF5F),
              @(120):UIColorFromRGB(0x87FF87),
              @(121):UIColorFromRGB(0x87FFAF),
              @(122):UIColorFromRGB(0x87FFD7),
              @(123):UIColorFromRGB(0x87FFFF),
              @(124):UIColorFromRGB(0xAF0000),
              @(125):UIColorFromRGB(0xAF005F),
              @(126):UIColorFromRGB(0xAF0087),
              @(127):UIColorFromRGB(0xAF00AF),
              @(128):UIColorFromRGB(0xAF00D7),
              @(129):UIColorFromRGB(0xAF00FF),
              @(130):UIColorFromRGB(0xAF5F00),
              @(131):UIColorFromRGB(0xAF5F5F),
              @(132):UIColorFromRGB(0xAF5F87),
              @(133):UIColorFromRGB(0xAF5FAF),
              @(134):UIColorFromRGB(0xAF5FD7),
              @(135):UIColorFromRGB(0xAF5FFF),
              @(136):UIColorFromRGB(0xAF8700),
              @(137):UIColorFromRGB(0xAF875F),
              @(138):UIColorFromRGB(0xAF8787),
              @(139):UIColorFromRGB(0xAF87AF),
              @(140):UIColorFromRGB(0xAF87D7),
              @(141):UIColorFromRGB(0xAF87FF),
              @(142):UIColorFromRGB(0xAFAF00),
              @(143):UIColorFromRGB(0xAFAF5F),
              @(144):UIColorFromRGB(0xAFAF87),
              @(145):UIColorFromRGB(0xAFAFAF),
              @(146):UIColorFromRGB(0xAFAFD7),
              @(147):UIColorFromRGB(0xAFAFFF),
              @(148):UIColorFromRGB(0xAFD700),
              @(149):UIColorFromRGB(0xAFD75F),
              @(150):UIColorFromRGB(0xAFD787),
              @(151):UIColorFromRGB(0xAFD7AF),
              @(152):UIColorFromRGB(0xAFD7D7),
              @(153):UIColorFromRGB(0xAFD7FF),
              @(154):UIColorFromRGB(0xAFFF00),
              @(155):UIColorFromRGB(0xAFFF5F),
              @(156):UIColorFromRGB(0xAFFF87),
              @(157):UIColorFromRGB(0xAFFFAF),
              @(158):UIColorFromRGB(0xAFFFD7),
              @(159):UIColorFromRGB(0xAFFFFF),
              @(160):UIColorFromRGB(0xD70000),
              @(161):UIColorFromRGB(0xD7005F),
              @(162):UIColorFromRGB(0xD70087),
              @(163):UIColorFromRGB(0xD700AF),
              @(164):UIColorFromRGB(0xD700D7),
              @(165):UIColorFromRGB(0xD700FF),
              @(166):UIColorFromRGB(0xD75F00),
              @(167):UIColorFromRGB(0xD75F5F),
              @(168):UIColorFromRGB(0xD75F87),
              @(169):UIColorFromRGB(0xD75FAF),
              @(170):UIColorFromRGB(0xD75FD7),
              @(171):UIColorFromRGB(0xD75FFF),
              @(172):UIColorFromRGB(0xD78700),
              @(173):UIColorFromRGB(0xD7875F),
              @(174):UIColorFromRGB(0xD78787),
              @(175):UIColorFromRGB(0xD787AF),
              @(176):UIColorFromRGB(0xD787D7),
              @(177):UIColorFromRGB(0xD787FF),
              @(178):UIColorFromRGB(0xD7AF00),
              @(179):UIColorFromRGB(0xD7AF5F),
              @(180):UIColorFromRGB(0xD7AF87),
              @(181):UIColorFromRGB(0xD7AFAF),
              @(182):UIColorFromRGB(0xD7AFD7),
              @(183):UIColorFromRGB(0xD7AFFF),
              @(184):UIColorFromRGB(0xD7D700),
              @(185):UIColorFromRGB(0xD7D75F),
              @(186):UIColorFromRGB(0xD7D787),
              @(187):UIColorFromRGB(0xD7D7AF),
              @(188):UIColorFromRGB(0xD7D7D7),
              @(189):UIColorFromRGB(0xD7D7FF),
              @(190):UIColorFromRGB(0xD7FF00),
              @(191):UIColorFromRGB(0xD7FF5F),
              @(192):UIColorFromRGB(0xD7FF87),
              @(193):UIColorFromRGB(0xD7FFAF),
              @(194):UIColorFromRGB(0xD7FFD7),
              @(195):UIColorFromRGB(0xD7FFFF),
              @(196):UIColorFromRGB(0xFF0000),
              @(197):UIColorFromRGB(0xFF005F),
              @(198):UIColorFromRGB(0xFF0087),
              @(199):UIColorFromRGB(0xFF00AF),
              @(200):UIColorFromRGB(0xFF00D7),
              @(201):UIColorFromRGB(0xFF00FF),
              @(202):UIColorFromRGB(0xFF5F00),
              @(203):UIColorFromRGB(0xFF5F5F),
              @(204):UIColorFromRGB(0xFF5F87),
              @(205):UIColorFromRGB(0xFF5FAF),
              @(206):UIColorFromRGB(0xFF5FD7),
              @(207):UIColorFromRGB(0xFF5FFF),
              @(208):UIColorFromRGB(0xFF8700),
              @(209):UIColorFromRGB(0xFF875F),
              @(210):UIColorFromRGB(0xFF8787),
              @(211):UIColorFromRGB(0xFF87AF),
              @(212):UIColorFromRGB(0xFF87D7),
              @(213):UIColorFromRGB(0xFF87FF),
              @(214):UIColorFromRGB(0xFFAF00),
              @(215):UIColorFromRGB(0xFFAF5F),
              @(216):UIColorFromRGB(0xFFAF87),
              @(217):UIColorFromRGB(0xFFAFAF),
              @(218):UIColorFromRGB(0xFFAFD7),
              @(219):UIColorFromRGB(0xFFAFFF),
              @(220):UIColorFromRGB(0xFFD700),
              @(221):UIColorFromRGB(0xFFD75F),
              @(222):UIColorFromRGB(0xFFD787),
              @(223):UIColorFromRGB(0xFFD7AF),
              @(224):UIColorFromRGB(0xFFD7D7),
              @(225):UIColorFromRGB(0xFFD7FF),
              @(226):UIColorFromRGB(0xFFFF00),
              @(227):UIColorFromRGB(0xFFFF5F),
              @(228):UIColorFromRGB(0xFFFF87),
              @(229):UIColorFromRGB(0xFFFFAF),
              @(230):UIColorFromRGB(0xFFFFD7),
              @(231):UIColorFromRGB(0xFFFFFF),
              @(232):UIColorFromRGB(0x000000),
              @(233):UIColorFromRGB(0x121212),
              @(234):UIColorFromRGB(0x1C1C1C),
              @(235):UIColorFromRGB(0x262626),
              @(236):UIColorFromRGB(0x303030),
              @(237):UIColorFromRGB(0x3A3A3A),
              @(238):UIColorFromRGB(0x444444),
              @(239):UIColorFromRGB(0x4E4E4E),
              @(240):UIColorFromRGB(0x585858),
              @(241):UIColorFromRGB(0x626262),
              @(242):UIColorFromRGB(0x6C6C6C),
              @(243):UIColorFromRGB(0x767676),
              @(244):UIColorFromRGB(0x808080),
              @(245):UIColorFromRGB(0x8A8A8A),
              @(246):UIColorFromRGB(0x949494),
              @(247):UIColorFromRGB(0x9E9E9E),
              @(248):UIColorFromRGB(0xA8A8A8),
              @(249):UIColorFromRGB(0xB2B2B2),
              @(250):UIColorFromRGB(0xBCBCBC),
              @(251):UIColorFromRGB(0xC6C6C6),
              @(252):UIColorFromRGB(0xD0D0D0),
              @(253):UIColorFromRGB(0xDADADA),
              @(254):UIColorFromRGB(0xE4E4E4),
              @(255):UIColorFromRGB(0xEEEEEE),
          };
    });

    UIColor *aColor = codes[@(color)];

    if (options.isReverse) {
        isForeground = !isForeground;
    }

    if (aColor) {
        if (isForeground) {
            self.lastColor = aColor;
        } else {
            self.lastBGColor = aColor;
        }
    } else {
        DLog(@"no xterm color?");
    }
}

#pragma clang diagnostic pop

@end
