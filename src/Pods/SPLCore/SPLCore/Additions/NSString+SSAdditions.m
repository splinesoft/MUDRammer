//
//  NSString+SSAdditions.m
//  SPLCore
//
//  Created by Jonathan Hersh on 3/19/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "NSString+SSAdditions.h"

@implementation NSString (SSAdditions)

- (BOOL) stringContainsString:(NSString *)matcher {
    return [matcher length] > 0
        && [self length] > 0
        && [self rangeOfString:matcher
                   options:NSLiteralSearch].location != NSNotFound;
}

@end
