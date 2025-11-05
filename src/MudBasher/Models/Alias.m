//
//  Alias.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/10/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "Alias.h"
#import "NSString+SPLMatching.h"

@implementation Alias

@dynamic isEnabled;
@dynamic name;
@dynamic commands;
@dynamic world;

+ (NSString *)defaultSortField {
    return @"name";
}

+ (BOOL)defaultSortAscending {
    return YES;
}

+ (instancetype)createObjectInContext:(NSManagedObjectContext *)context {
    Alias *alias = [super createObjectInContext:context];

    alias.isEnabled = @YES;

    return alias;
}

- (void)saveObject {
    self.isHidden = @(NO);
    [super saveObject];
}

- (BOOL)canSave {
    return [self.name length] > 0 && [self.commands length] > 0;
}

+ (NSPredicate *)predicateForAliasesWithWorld:(World *)world active:(BOOL)active {
    return [NSPredicate predicateWithFormat:@"isHidden == NO "
            "AND isEnabled == %i "
            "AND world == %@",
            active,
            world];
}

- (NSArray *)aliasCommandsForInput:(NSString *)input {
    NSArray *commands = [self.commands spl_commandsFromUserInput];
    NSArray *inputWords = [input componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *targetInput = nil;

    inputWords = [inputWords bk_select:^BOOL(NSString *word) {
        return ![[word lowercaseString] isEqualToString:[self.name lowercaseString]];
    }];

    if( !inputWords || [inputWords count] < 1 )
        targetInput = @"";
    else
        targetInput = [inputWords componentsJoinedByString:@" "];


    // if string contains $1$ or $2$, we replace that with the nth word from the user input string.
    // if string contains $*$, it contains the remainder of the input string after the highest-n so far
    NSRegularExpression *commandIndexer = [NSRegularExpression regularExpressionWithPattern:@"\\$..?\\$"
                                                                                    options:NSRegularExpressionCaseInsensitive | NSRegularExpressionUseUnixLineSeparators
                                                                                      error:NULL];

    NSMutableArray *ret = [NSMutableArray array];

    [commands bk_each:^(NSString *command) {
        __block NSUInteger maxCommandIndex = 0;
        __block NSMutableString *outString = [NSMutableString stringWithString:command];
        __block BOOL didApplyMatching = NO;

        [commandIndexer enumerateMatchesInString:command
                                         options:kNilOptions
                                           range:NSMakeRange(0, [command length])
                                      usingBlock:^(NSTextCheckingResult *result, NSMatchingFlags flags, BOOL *stop) {
                                          NSString *marker = [command substringWithRange:result.range];
                                          // Read the index(es) at this match
                                          NSString *aIndex = [marker stringByReplacingOccurrencesOfString:@"$"
                                                                                               withString:@""];

                                          NSString *replaceWith = nil;

                                          if( [aIndex isEqualToString:@"*"] ) {
                                              // concat the remainder of the user input string from the highest index onwards

                                              // are we able to fill any?
                                              if( [inputWords count] > maxCommandIndex ) {
                                                  replaceWith = [[inputWords objectsAtIndexes:
                                                                 [NSIndexSet indexSetWithIndexesInRange:
                                                                  NSMakeRange(maxCommandIndex, [inputWords count] - maxCommandIndex)]]
                                                                 componentsJoinedByString:@" "];
                                              } else {
                                                  // clean fill marker from string
                                                  replaceWith = @"";
                                              }


                                          } else {
                                              NSUInteger intVal = (NSUInteger)[aIndex integerValue];

                                              // $1$ -> 0, etc
                                              intVal --;

                                              // Does our user input contain text at this index?
                                              if( [inputWords count] > intVal ) {
                                                  // we can fill a word
                                                  replaceWith = inputWords[intVal];

                                                  if( intVal >= maxCommandIndex )
                                                      maxCommandIndex++;
                                              } else {
                                                  // clean it from the string
                                                  replaceWith = @"";
                                              }
                                          }

                                          if( replaceWith ) {
                                              [outString replaceOccurrencesOfString:marker
                                                                         withString:replaceWith
                                                                            options:NSLiteralSearch
                                                                              range:NSMakeRange(0, [outString length])];
                                              didApplyMatching = YES;
                                          }
                                      }];

        if( !didApplyMatching )
            [outString appendFormat:@" %@",targetInput];

        [ret addObject:outString];
    }];

    return ( [ret count] > 0 ? ret : nil );
}

@end
