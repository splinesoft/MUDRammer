//
//  SSMagicManagedObject+Matching.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/24/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSMagicManagedObject+Matching.h"

NSString * const kPatternRandom = @"\\#(\\d{1,6})\\#";
NSString * const kPatternCommandIndex = @"\\$\\d{1,2}(\\$)?";
NSString * const kPatternWord = @"\\b(\\w)+(\\$)?\\b";

static NSRegularExpression *patternLocationMatcher;
static NSRegularExpression *randomRegex;
static NSCharacterSet *splitChars;
static NSCharacterSet *nonDecimalCharacterSet;

@interface SSMagicManagedObject (Matching_Private)

+ (NSRegularExpression *) regexForPattern:(NSString *)pattern;

@end

@implementation SSMagicManagedObject (Matching)

+ (NSArray *)commandsFromUserInput:(NSString *)input {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *charSet = [NSMutableCharacterSet characterSetWithCharactersInString:@";"];
        [charSet formUnionWithCharacterSet:[NSCharacterSet newlineCharacterSet]];

        splitChars = [charSet copy];

        randomRegex = [NSRegularExpression regularExpressionWithPattern:kPatternRandom
                                                                options:NSRegularExpressionUseUnixLineSeparators | NSRegularExpressionUseUnicodeWordBoundaries
                                                                  error:NULL];
    });

    if( [input length] == 0 )
        return nil;

    NSMutableString *matchString = [NSMutableString stringWithString:input];
    NSMutableArray *rangeMatches = [NSMutableArray array];

    [randomRegex enumerateMatchesInString:matchString
                                  options:NSMatchingReportProgress
                                    range:NSMakeRange(0, [matchString length])
                               usingBlock:^(NSTextCheckingResult *result,
                                            NSMatchingFlags flags,
                                            BOOL *stop) {

       if( !result || result.range.location == NSNotFound )
           return;

       [rangeMatches addObject:[NSValue valueWithRange:result.range]];
    }];

    [rangeMatches enumerateObjectsWithOptions:NSEnumerationReverse
                                   usingBlock:^(NSValue *result,
                                                NSUInteger index,
                                                BOOL *stop) {

       NSRange range = [result rangeValue];

       if( NSMaxRange(range) > [matchString length] )
           return;

       NSString *match = [matchString substringWithRange:range];

       match = [match stringByReplacingOccurrencesOfString:@"#"
                                                withString:@""];

       NSUInteger matchValue = (NSUInteger)[match integerValue];

       if( matchValue <= 0 || matchValue > 999999 )
           return;

       [matchString replaceCharactersInRange:range
                                  withString:[NSString stringWithFormat:@"%i",
                                              (1+arc4random_uniform((unsigned int)matchValue))]];
    }];

    return [[matchString componentsSeparatedByCharactersInSet:splitChars]
            bk_select:^BOOL(NSString *command) {
                return [command length] > 0;
            }];
}

+ (NSDictionary *)commandLocationsForPattern:(NSString *)pattern {
    static dispatch_once_t onceTriggerToken;
    dispatch_once(&onceTriggerToken, ^{
        patternLocationMatcher = [NSRegularExpression regularExpressionWithPattern:kPatternCommandIndex
                                                                           options:NSRegularExpressionUseUnixLineSeparators | NSRegularExpressionUseUnicodeWordBoundaries
                                                                             error:NULL];
        nonDecimalCharacterSet = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
    });

    if( [pattern length] == 0 )
        return nil;

    NSMutableDictionary *ret = [NSMutableDictionary dictionary];

    NSArray *words = [pattern componentsSeparatedByCharactersInSet:
                      [NSCharacterSet whitespaceAndNewlineCharacterSet]];

    [words enumerateObjectsUsingBlock:^(NSString *aWord,
                                        NSUInteger index,
                                        BOOL *stop) {

        NSUInteger matches = [patternLocationMatcher numberOfMatchesInString:aWord
                                                                     options:kNilOptions
                                                                       range:NSMakeRange(0, [aWord length])];

        if( matches > 0 ) {

            NSString *word = [[aWord componentsSeparatedByCharactersInSet:nonDecimalCharacterSet]
                              componentsJoinedByString:@""];

            NSInteger intVal = [word integerValue];

            if( intVal < 1 || intVal > 99 )
                return;

            ret[@(index)] = @(intVal);
        }
    }];

    return [ret copy];
}

+ (NSRegularExpression *)regexForPattern:(NSString *)pattern {
    NSMutableString *toMatch = [[pattern stringByTrimmingCharactersInSet:
                                 [NSCharacterSet whitespaceCharacterSet]] mutableCopy];

    if( [toMatch length] == 0 )
        return nil;

    // Replace all instances of the match pattern ($1, $2, etc)
    // with the word pattern (/w)
    NSDictionary *commandLocations = [self commandLocationsForPattern:toMatch];
    NSMutableArray *words = [NSMutableArray arrayWithArray:
                             [toMatch componentsSeparatedByCharactersInSet:
                              [NSCharacterSet whitespaceAndNewlineCharacterSet]]];

    [commandLocations enumerateKeysAndObjectsUsingBlock:^(NSNumber *wordIndex,
                                                          NSNumber *commandIndex,
                                                          BOOL *stop) {
        words[[wordIndex unsignedIntegerValue]] = kPatternWord;
    }];

    // Create a new regular expression matching the substituted version of this line.
    // TODO: literal quote string? or expose regex?

    //DLog(@"match %@ %@", words, [NSRegularExpression escapedPatternForString:toMatch]);

    return [NSRegularExpression regularExpressionWithPattern:[words componentsJoinedByString:@" "]
                                                     options:NSRegularExpressionUseUnixLineSeparators | NSRegularExpressionUseUnicodeWordBoundaries
                                                       error:NULL];
}

+ (BOOL) matchPattern:(NSString *)pattern matchesLine:(NSString *)line {
    // Replace all instances of the match pattern ($1, $2, etc)
    // with the word pattern (\w+)
    NSDictionary *commandLocations = [self commandLocationsForPattern:pattern];

    // In the simple case, the pattern contains no match indexes.
    // If so, we do a simple literal string comparison.
    if( [commandLocations count] == 0 )
        return [line stringContainsString:pattern];

    NSRegularExpression *lineMatcher = [self regexForPattern:pattern];

    if( !lineMatcher )
        return NO;

    NSUInteger matchCount = [lineMatcher numberOfMatchesInString:line
                                                         options:kNilOptions
                                                           range:NSMakeRange(0, [line length])];

    return (BOOL)(matchCount > 0);
}

+ (NSString *)commandForMatchPattern:(NSString *)pattern userCommand:(NSString *)command inputLine:(NSString *)line {

    NSDictionary *patternLocations = [self commandLocationsForPattern:pattern];

    if( [patternLocations count] == 0 ) {
        // Simple case - no pattern matches in this line
        return command;
    }

    NSDictionary *commandLocations = [self commandLocationsForPattern:command];

    NSRegularExpression *lineMatcher = [self regexForPattern:pattern];

    if( !lineMatcher )
        return nil;

    NSArray *matches = [lineMatcher matchesInString:line
                                            options:kNilOptions
                                              range:NSMakeRange(0, [line length])];

    NSMutableArray *commandWords = [NSMutableArray arrayWithArray:
                                    [command componentsSeparatedByCharactersInSet:
                                     [NSCharacterSet whitespaceAndNewlineCharacterSet]]];

    [matches enumerateObjectsWithOptions:NSEnumerationReverse
                              usingBlock:^(NSTextCheckingResult *result,
                                            NSMatchingFlags flags,
                                            BOOL *stop) {

       NSRange range = result.range;
       NSString *substr = [line substringWithRange:range];

       // We know the xth word in this match is equal to the yth word in the pattern

       NSArray *matchWords = [substr componentsSeparatedByCharactersInSet:
                              [NSCharacterSet whitespaceAndNewlineCharacterSet]];

       [patternLocations enumerateKeysAndObjectsUsingBlock:^(NSNumber *wordIndex, NSNumber *cmdIndex, BOOL *stop2) {
           [commandLocations enumerateKeysAndObjectsUsingBlock:^(NSNumber *wordCmdIndex, NSNumber *cmdCmdIndex, BOOL *stop3) {
               if( ![cmdIndex isEqualToNumber:cmdCmdIndex] )
                   return;

               // Find the range within this word to replace
               NSString *commandWord = commandWords[[wordCmdIndex unsignedIntegerValue]];

               if( [commandWord length] == 0 )
                   return;

               NSTextCheckingResult *firstMatch = [patternLocationMatcher firstMatchInString:commandWord
                                                                                     options:kNilOptions
                                                                                       range:NSMakeRange(0, [commandWord length])];

               if( !firstMatch || firstMatch.range.location == NSNotFound )
                   return;

               NSString *newCommand = [commandWord stringByReplacingCharactersInRange:firstMatch.range
                                                                           withString:matchWords[[wordIndex unsignedIntegerValue]]];

               if( [newCommand length] == 0 )
                   return;

               // Replace the match range
               commandWords[[wordCmdIndex unsignedIntegerValue]] = newCommand;
           }];
       }];
    }];

    return [commandWords componentsJoinedByString:@" "];
}

@end
