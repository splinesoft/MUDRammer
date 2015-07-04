//
//  JSQSystemSoundPlayer+SSAdditions.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 12/7/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

@import Foundation;
@import UIKit;

@class SSSound;

#import <JSQSystemSoundPlayer.h>

@interface JSQSystemSoundPlayer (SSAdditions)

#pragma mark - Sound Access

/**
 * Returns an array of all discovered .wav files as SSSound objects.
 */
+ (NSArray *) allSounds;

/**
 * Return the SSSound object for a sound with the given filename.
 */
+ (SSSound *) soundForFileName:(NSString *)fileName;

#pragma mark - Playing

/**
 * Play a sound with optional completion.
 */
+ (void) playSound:(SSSound *)sound
        completion:(JSQSystemSoundPlayerCompletionBlock)completion;

@end

@interface SSSound : NSObject <NSCopying>

@property (nonatomic, copy, readonly) NSString * fileName;
@property (nonatomic, copy, readonly) NSString * soundName;

- (instancetype) initWithFileName:(NSString *)fileName
                        soundName:(NSString *)soundName;

+ (NSComparator) soundNameComparator;

@end
