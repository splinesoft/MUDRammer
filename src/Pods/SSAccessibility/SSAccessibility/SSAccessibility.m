//
//  SSAccessibility.m
//  SSAccessibility
//
//  Created by Jonathan Hersh on 3/31/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import "SSAccessibility.h"

@implementation SSAccessibility

+ (void) speakWithVoiceOver:(NSString *)string {
    if ([string length] == 0) {
        return;
    }
    
    if (!UIAccessibilityIsVoiceOverRunning()) {
        return;
    }
    
    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, string);
}

@end
