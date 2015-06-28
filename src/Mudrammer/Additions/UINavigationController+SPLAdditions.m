//
//  UINavigationController+SPLAdditions.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/22/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "UINavigationController+SPLAdditions.h"

@implementation UINavigationController (SPLAdditions)

- (BOOL)SPLNavigationIsAtRoot {
    return [self viewControllers].count > 0
        && [[self visibleViewController] isEqual:[self viewControllers].firstObject];
}

@end
