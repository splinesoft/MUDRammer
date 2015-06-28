//
//  UIBarButtonItem+SSAdditions.m
//  SPLCore
//
//  Created by Jonathan Hersh on 11/3/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "UIBarButtonItem+SSAdditions.h"
#import <QuartzCore/QuartzCore.h>

@implementation UIBarButtonItem (SSAdditions)

+ (UIBarButtonItem *)barButtonItemWithImage:(UIImage *)img target:(id)target selector:(SEL)selector {
  UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
  
  [btn setImage:img forState:UIControlStateNormal];
  [btn addTarget:target
          action:selector
forControlEvents:UIControlEventTouchUpInside];
  
  [btn setFrame:CGRectMake(0, 0, img.size.width, img.size.height)];
  
  return [[UIBarButtonItem alloc] initWithCustomView:btn];
}

+ (UIBarButtonItem *)flexibleSpaceBarButtonItem {
  return [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace
                                                       target:nil
                                                       action:nil];
}

+ (UIBarButtonItem *)fixedWidthBarButtonItemWithWidth:(CGFloat)width {
  UIBarButtonItem *item = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                                                        target:nil
                                                                        action:nil];
  item.width = width;
  
  return item;
}

@end
