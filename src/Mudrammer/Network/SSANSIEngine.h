//
//  SSANSIEngine.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/5/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import Foundation;
#import "UIColor+SPLANSI.h"

@class SSAttributedLineGroup;

@interface SSANSIEngine : NSObject

@property (nonatomic, strong) UIColor *defaultTextColor;
@property (nonatomic, strong) UIFont *defaultFont;

/**
 *  Parse some ANSI text into a group of attributed lines.
 *
 *  @param string text containing ANSI SGR codes
 *
 *  @return a parsed attributed line group
 */
- (SSAttributedLineGroup *)parseANSIString:(NSString *)string;

@end
