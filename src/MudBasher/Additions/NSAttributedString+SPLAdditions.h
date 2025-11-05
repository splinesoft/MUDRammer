//
//  NSAttributedString+SPLAdditions.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/1/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@interface NSAttributedString (SPLAdditions)

/**
 *  Defines the look of user-inputted strings
 *
 *  @param string User input
 *
 *  @return An attributed string for user text.
 */
+ (instancetype)userInputStringForString:(NSString *)string;

// Defines the look of default text received from a World.
+ (instancetype)worldStringForString:(NSString *)string;

@end
