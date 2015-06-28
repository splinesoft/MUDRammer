//
//  NSNumber+SSAdditions.m
//  SPLCore
//
//  Created by Jonathan Hersh on 10/2/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import "NSNumber+SSAdditions.h"

@implementation NSNumber (SSAdditions)

- (NSString *) bucketStringWithBucketSize:(NSUInteger)bucketSize {
    return [self bucketStringWithBucketSize:bucketSize
                                 maxBuckets:10];
}

- (NSString *) bucketStringWithBucketSize:(NSUInteger)bucketSize
                               maxBuckets:(NSUInteger)maxBuckets {
    
    NSUInteger intVal = [self unsignedIntegerValue];
    
    if( intVal < bucketSize )
        return [NSString stringWithFormat:@"< %@", @(bucketSize)];
    
    NSUInteger multiple = intVal / bucketSize;
    
    if( multiple >= maxBuckets )
        return [NSString stringWithFormat:@">= %@", @( bucketSize * maxBuckets )];
    
    return [NSString stringWithFormat:@"%@ - %@",
            @( multiple * bucketSize ),
            @( ( ( multiple + 1 ) * bucketSize ) - 1)];
}

@end
