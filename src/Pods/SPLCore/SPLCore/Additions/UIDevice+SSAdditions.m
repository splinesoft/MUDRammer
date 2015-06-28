//
//  UIDevice+SSAdditions.m
//  SPLCore
//
//  Created by Jonathan Hersh on 10/22/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "UIDevice+SSAdditions.h"
#import <UIKit/UIKit.h>
#import <AudioToolbox/AudioToolbox.h>

@implementation UIDevice (SSAdditions)

- (BOOL) isIPad {
    return [self userInterfaceIdiom] == UIUserInterfaceIdiomPad;
}

+ (BOOL)isLandscape {
    return UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]);
}

+ (void)vibrateWithBeepFallback:(BOOL)beep {
    if( beep )
        AudioServicesPlayAlertSound(kSystemSoundID_Vibrate);
    else
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
}

@end
