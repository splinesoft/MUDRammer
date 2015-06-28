//
//  NSString+SSAdditions.h
//  SPLCore
//
//  Created by Jonathan Hersh on 3/19/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSString (SSAdditions)

// Performs a literal search for the specified pattern.
- (BOOL) stringContainsString:(NSString *)matcher;

@end
