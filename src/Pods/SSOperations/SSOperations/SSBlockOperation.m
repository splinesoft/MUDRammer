//
//  SSBlockOperation.m
//  SSOperationsExample
//
//  Created by Jonathan Hersh on 8/30/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import "SSOperations.h"

@implementation SSBlockOperation

+ (instancetype)operationWithBlock:(SSBlockOperationBlock)block {
    NSParameterAssert(block);
    
    SSBlockOperation *operation = [SSBlockOperation new];
    
    __weak typeof (operation) weakOperation = operation;
    
    [operation addExecutionBlock:^{
        block( weakOperation );
    }];
    
    return operation;
}

@end
