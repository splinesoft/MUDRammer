//
//  UIApplication+SSAdditions.m
//  SPLCore
//
//  Created by Jonathan Hersh on 1/22/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "UIApplication+SSAdditions.h"

@implementation UIApplication (SSAdditions)

+ (NSString *)applicationName {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleNameKey];
}

+ (NSString *)applicationVersion {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

+ (NSString *)applicationBuild {
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString *)kCFBundleVersionKey];
}

+ (NSString *) applicationNameAndVersion {
    return [NSString stringWithFormat:@"%@ %@",
            [self applicationName],
            [self applicationVersion]];
}

+ (NSString *)applicationNameVersionBuild {
    return [[self applicationNameAndVersion] stringByAppendingFormat:@" (%@)",
            [self applicationBuild]];
}

+ (BOOL)isTestflightBeta
{
    return [[[[NSBundle mainBundle] appStoreReceiptURL] lastPathComponent] isEqualToString:@"sandboxReceipt"];
}

@end
