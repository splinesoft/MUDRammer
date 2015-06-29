//
//  NSString+SPLMatching.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/24/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

@import Foundation;

@interface NSString (SPLMatching)

/**
 * The user has entered some input.
 * We split the input by semicolons and newlines,
 * and perform random number insertion via the #N# syntax.
 */
- (NSArray *)spl_commandsFromUserInput;

/**
 Given a match pattern that has some command-indexes ($1, $2, etc),
 we return a dictionary.
 Keys are the indexes of the word in the line at which each pattern occurs.
 Values are an NSNumber representation of each index.
 */
- (NSDictionary *)spl_commandLocationsForPattern;

/**
 Given a match pattern that has some command-indexes ($1, $2, etc),
 determines if a given input string matches the pattern.
*/
- (BOOL)spl_matchesPattern:(NSString *)pattern;

/**
 * @param command - a user command that contains command-indexes
 * @param line - a received line of text
 *
 * This performs performs command replacements for Aliases and Triggers.
 *
 * Alias usage:
 * alias command: say eat my $1 and $2
 *
 * Trigger usage:
 * match pattern: you see $1 and $2
 * user command: say hello $1 and $2
 * input line: you see bob and thor
 *
 * Returns: 'say hello bob and thor'
 */
- (NSString *)spl_commandForUserCommand:(NSString *)command
                              inputLine:(NSString *)line;
@end
