//
//  UIView+SPLAdditions.h
//  SPLCore
//
//  Created by Jonathan Hersh on 3/12/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@interface UIView (SPLAdditions)

// wrap this view in a barbuttonitem.
- (UIBarButtonItem *) wrappedBarButtonItem;

/**
 * UIInterpolatingMotionEffect for the 'center' property, both X and Y.
 */
- (void) addCenteredInterpolatingMotionEffectWithBounds:(NSUInteger)bounds;

/**
 * UIInterpolatingMotionEffect for either horizontal or vertical with the given max and (negative) min.
 */
- (void) addInterpolatingMotionEffectWithKeyPath:(NSString *)keyPath
                                           bound:(NSUInteger)bound
                                            type:(UIInterpolatingMotionEffectType)type;

/**
 * Remove all motion effects.
 */
- (void) removeAllMotionEffects;

@end
