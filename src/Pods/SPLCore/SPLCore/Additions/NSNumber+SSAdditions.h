//
//  NSNumber+SSAdditions.h
//  SPLCore
//
//  Created by Jonathan Hersh on 10/2/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNumber (SSAdditions)

/*
 * Many analytics services (*cough* Localytics *cough) do not bucket your values for you,
 * so your reported numeric data can be awfully difficult to read.
 * These bucketing functions will read in a number and output a bucketed range as a string.
 *
 * Example: A value of 47, with bucket size 25, will return the string "25-49".
 * A value of 10, with bucket size 15, will return the string "< 15".
 */
- (NSString *) bucketStringWithBucketSize:(NSUInteger)bucketSize;

- (NSString *) bucketStringWithBucketSize:(NSUInteger)bucketSize
                               maxBuckets:(NSUInteger)maxBuckets;

@end
