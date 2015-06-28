//
//  NSMutableIndexSet+SPLAdditions.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/8/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "NSMutableIndexSet+SPLAdditions.h"

@implementation NSMutableIndexSet (SPLAdditions)

- (void)spl_shiftIndexesWithDeletedIndexes:(NSIndexSet *)deletedIndexes {

    NSIndexSet *advanceRangeIndexes = [deletedIndexes indexesPassingTest:^BOOL(NSUInteger index, BOOL *stop) {
        return index <= self.firstIndex;
    }];

    NSUInteger shiftCount = advanceRangeIndexes.count;

    [self shiftIndexesStartingAtIndex:advanceRangeIndexes.firstIndex by:-(NSInteger)shiftCount];
}

@end
