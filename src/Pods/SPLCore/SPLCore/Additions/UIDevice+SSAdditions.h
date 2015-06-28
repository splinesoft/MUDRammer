//
//  UIDevice+SSAdditions.h
//  SPLCore
//
//  Created by Jonathan Hersh on 10/22/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIDevice (SSAdditions)

- (BOOL) isIPad;

+ (BOOL) isLandscape;

// Vibrate the device.
// If the device cannot vibrate, YES will play a beep.
// NO will not beep.
+ (void) vibrateWithBeepFallback:(BOOL)beep;

@end
