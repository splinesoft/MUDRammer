//
//  SSAccessibility.h
//  SSAccessibility
//
//  Created by Jonathan Hersh on 3/31/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

@import Foundation;

@interface SSAccessibility : NSObject

/**
 * Speak some text with VoiceOver.
 * This is a shortcut for UIAccessibilityPostNotification.
 */
+ (void) speakWithVoiceOver:(NSString *)string;

@end
