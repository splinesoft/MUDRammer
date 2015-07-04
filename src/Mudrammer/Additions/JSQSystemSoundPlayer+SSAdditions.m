//
//  JSQSystemSoundPlayer+SSAdditions.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 12/7/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "JSQSystemSoundPlayer+SSAdditions.h"

@interface SSSound ()

@property (nonatomic, copy) NSString * fileName;
@property (nonatomic, copy) NSString * soundName;

@end

@implementation SSSound

- (instancetype)initWithFileName:(NSString *)fileName soundName:(NSString *)soundName {
    if ((self = [super init])) {
        _fileName = fileName;
        _soundName = soundName;
    }

    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[SSSound alloc] initWithFileName:self.fileName
                                   soundName:self.soundName];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ filename %@ Localized %@",
            [super description],
            self.fileName,
            self.soundName];
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[SSSound class]]
        && [((SSSound *)object).soundName isEqualToString:self.soundName]
        && [((SSSound *)object).fileName isEqualToString:self.fileName];
}

- (NSUInteger)hash {
    NSUInteger result = 1, prime = 31;

    result = prime * result + [self.fileName hash];
    result = prime * result + [self.soundName hash];

    return result;
}

+ (NSComparator)soundNameComparator {
    return ^NSComparisonResult(SSSound *one, SSSound *two) {
        return [one.soundName compare:two.soundName
                              options:NSCaseInsensitiveSearch];
    };
}

@end

@implementation JSQSystemSoundPlayer (SSAdditions)

+ (SSSound *)soundForFileName:(NSString *)fileName {
    if ([fileName length] == 0)
        return nil;

    NSArray *sounds = [self allSounds];

    NSUInteger index = [sounds indexOfObjectPassingTest:^BOOL(SSSound *sound,
                                                              NSUInteger i,
                                                              BOOL *stop) {
        return [sound.fileName isEqualToString:fileName];
    }];

    if (index == NSNotFound)
        return nil;

    return sounds[index];
}

+ (NSArray *)allSounds {
    static NSArray *sounds;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSArray * soundFiles = [NSBundle URLsForResourcesWithExtension:@"wav"
                                                          subdirectory:nil
                                                       inBundleWithURL:[[NSBundle mainBundle] bundleURL]];

        NSMutableArray *tmpSounds = [NSMutableArray array];

        [soundFiles bk_each:^(NSURL *soundURL) {
            if ([soundURL isFileURL]) {
                NSArray *bits = [[soundURL lastPathComponent] componentsSeparatedByString:@"."];

                if ([bits count] != 2)
                    return;

                NSString *soundName = [NSString stringWithFormat:@"SOUND_%@",
                                       [bits[0] uppercaseString]];

                if ([NSLocalizedString(soundName, nil) isEqualToString:soundName])
                    return;

                [tmpSounds addObject:[[SSSound alloc] initWithFileName:[soundURL lastPathComponent]
                                                             soundName:NSLocalizedString(soundName, nil)]];
            }
        }];

        [tmpSounds sortUsingComparator:[SSSound soundNameComparator]];
        sounds = [NSArray arrayWithArray:tmpSounds];
    });

    return sounds;
}

+ (void)playSound:(SSSound *)sound completion:(JSQSystemSoundPlayerCompletionBlock)completion {

    if (!sound)
        return;

    NSArray *bits = [sound.fileName componentsSeparatedByString:@"."];

    if ([bits count] != 2)
        return;

    [[self sharedPlayer] playSoundWithFilename:bits[0]
                                 fileExtension:bits[1]
                                    completion:completion];
}

@end
