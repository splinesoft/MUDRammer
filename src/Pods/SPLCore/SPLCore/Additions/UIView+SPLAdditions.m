//
//  UIView+SPLAdditions.m
//  SPLCore
//
//  Created by Jonathan Hersh on 3/12/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "UIView+SPLAdditions.h"
#import <objc/runtime.h>

@implementation UIView (SPLAdditions)

#pragma mark - SPL

- (UIBarButtonItem *)wrappedBarButtonItem {
    return [[UIBarButtonItem alloc] initWithCustomView:self];
}

#pragma mark - motion

- (void)addCenteredInterpolatingMotionEffectWithBounds:(NSUInteger)bounds {
    [self addInterpolatingMotionEffectWithKeyPath:@"center.x"
                                            bound:bounds
                                             type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    [self addInterpolatingMotionEffectWithKeyPath:@"center.y"
                                            bound:bounds
                                             type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
}

- (void)addInterpolatingMotionEffectWithKeyPath:(NSString *)keyPath bound:(NSUInteger)bound type:(UIInterpolatingMotionEffectType)type {
    UIInterpolatingMotionEffect *effect = [[UIInterpolatingMotionEffect alloc]
                                           initWithKeyPath:keyPath
                                           type:type];
    effect.minimumRelativeValue = @(-(NSInteger)bound);
    effect.maximumRelativeValue = @(bound);
    [self addMotionEffect:effect];
}

- (void)removeAllMotionEffects {
    [[self motionEffects] enumerateObjectsUsingBlock:^(UIMotionEffect *effect,
                                                       NSUInteger index,
                                                       BOOL *stop) {
        [self removeMotionEffect:effect];
    }];
}

@end
