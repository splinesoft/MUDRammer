//
//  SSBlockOperation.h
//  SSOperationsExample
//
//  Created by Jonathan Hersh on 8/30/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

@import Foundation;

/**
 * A block operation that is passed itself as an input when executed.
 * The primary benefit is that you can inspect, at run-time, whether the operation
 * has been canceled and if so, clean up and exit appropriately.
 */

@interface SSBlockOperation : NSBlockOperation

typedef void (^SSBlockOperationBlock) (SSBlockOperation *);

/**
 * Construct an `SSBlockOperation` with the specified operation block.
 */
+ (instancetype) operationWithBlock:(SSBlockOperationBlock)block;

@end
