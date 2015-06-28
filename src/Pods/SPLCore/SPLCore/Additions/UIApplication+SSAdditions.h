//
//  UIApplication+SSAdditions.h
//  SPLCore
//
//  Created by Jonathan Hersh on 1/22/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIApplication (SSAdditions)

+ (NSString *) applicationName;
+ (NSString *) applicationVersion;
+ (NSString *) applicationBuild;
+ (NSString *) applicationNameAndVersion;
+ (NSString *) applicationNameVersionBuild;

/**
 *  Attempt to detect whether the app is running as an Apple Testflight distribution.
 *
 *  @return YES if we are a Testflight app, NO otherwise
 */
+ (BOOL) isTestflightBeta;

@end
