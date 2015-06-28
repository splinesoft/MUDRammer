//
//  NSData+SPLDataParsing.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 4/27/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "NSData+SPLDataParsing.h"

@implementation NSData (SPLDataParsing)

- (unsigned char)characterAtIndex:(NSUInteger)index {
    unsigned char byte;

    [self getBytes:&byte range:NSMakeRange(index, 1)];

    return byte;
}

- (NSString *)charCodeString {
    NSMutableString *output = [NSMutableString stringWithCapacity:[self length] * 3];

    for (NSUInteger i = 0; i < [self length]; i++) {
        [output appendFormat:@"%i ",
         [self characterAtIndex:i]];
    }

    return output;
}

@end
