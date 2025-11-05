//
//  NSMutableIndexSet+SPLAdditions.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/8/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

@import Foundation;

@interface NSMutableIndexSet (SPLAdditions)

/**
 *  Adjusts the indexes in the receiver given the indexes in another index set.
 *
 *  e.g. an index set of [4, 5, 6] and deleted indexes [1, 2, 8],
 *  at return time the receiver's indexes will be shifted down to [2, 3, 4].
 *
 *  @param deletedIndexes indexes being marked as deleted
 */
- (void) spl_shiftIndexesWithDeletedIndexes:(NSIndexSet *)deletedIndexes;

@end
