//
//  NSScanner+SPLAdditions.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/8/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

#import "NSScanner+SPLAdditions.h"

@implementation NSScanner (SPLAdditions)

- (BOOL)SPLScanCharacterFromSet:(NSCharacterSet *)set
                     intoString:(NSString *__autoreleasing *)result {

    if ([self isAtEnd]) {
        return NO;
    }

    unichar character = [self.string characterAtIndex:self.scanLocation];

    if (![set characterIsMember:character]) {
        return NO;
    }

    if (result) {
        *result = [NSString stringWithCharacters:&character length:1];
    }

    self.scanLocation++;
    return YES;
}

@end
