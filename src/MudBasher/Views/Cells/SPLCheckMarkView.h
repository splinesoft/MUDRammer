//
//  SPLCheckMarkView.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/9/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@interface SPLCheckMarkView : UIControl

@property (nonatomic, copy) UIColor *accessoryColor;
@property (nonatomic, copy) UIColor *highlightedColor;

+ (instancetype)checkWithColor:(UIColor *)color;

@end
