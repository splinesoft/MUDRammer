//
//  NSCharacterSet+SPLAdditions.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/8/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

#import "NSCharacterSet+SPLAdditions.h"
#import "UIColor+SPLANSI.h"

@implementation NSCharacterSet (SPLAdditions)

+ (instancetype)CSITerminationCharacterSet {
    static NSCharacterSet *termSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *startSet = [NSMutableCharacterSet characterSetWithRange:NSMakeRange(64, 62)];
        [startSet removeCharactersInString:[kANSIEscapeCSI substringFromIndex:1]];
        termSet = [startSet copy];
    });

    return termSet;
}

+ (instancetype)CSIIntermediateCharacterSet {
    static NSCharacterSet *interSet;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *startSet = [NSMutableCharacterSet characterSetWithRange:NSMakeRange(32, 16)];
        [startSet addCharactersInString:@";"];
        interSet = [startSet copy];
    });

    return interSet;
}

@end
