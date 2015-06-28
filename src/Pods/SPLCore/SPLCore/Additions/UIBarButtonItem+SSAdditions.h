//
//  UIBarButtonItem+SSAdditions.h
//  SPLCore
//
//  Created by Jonathan Hersh on 11/3/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIBarButtonItem (SSAdditions)

+ (instancetype) barButtonItemWithImage:(UIImage *)img target:(id)target selector:(SEL)selector;

+ (instancetype) flexibleSpaceBarButtonItem;

+ (instancetype) fixedWidthBarButtonItemWithWidth:(CGFloat)width;

@end
