//
//  UIApplication+Additions.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 1/22/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "UIApplication+Additions.h"
#import <UIApplication+SSAdditions.h>

@implementation UIApplication (Additions)

+ (NSString *)applicationCopyright {
    return NSLocalizedString(@"COPYRIGHT", @"MMXIII splinesoft.net");
}

+ (NSString *)applicationExtras {
    return NSLocalizedString(@"MADE_IN", @"Made in San Francisco");
}

+ (NSString *)applicationFullAbout {
    static NSArray *extras;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        extras = @[
            @"> invoke iOS incantation",
            @"MUDRammer is crafted in one person's spare time. Please consider leaving a review - it really helps. Thanks!",
            @"Thanks for mudding with MUDRammer!",
            @"> perform dance of cellular connectivity",
            @"> use MUDRammer\nIt's super effective!",
        ];
    });

    return [NSString stringWithFormat:@"%@\n"
            @"%@\n"
            @"%@\n\n"
            @"%@",
            [UIApplication applicationNameVersionBuild],
            [self applicationCopyright],
            [self applicationExtras],
            extras[arc4random_uniform((uint32_t)[extras count])]];
}

@end
