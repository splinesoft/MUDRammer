//
//  UIScreen+SSAdditions.m
//  SPLCore
//
//  Created by Jonathan Hersh on 7/19/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import "UIScreen+SSAdditions.h"

@implementation UIScreen (SSAdditions)

- (BOOL)isRetina {
    return [self scale] > 1;
}

@end
