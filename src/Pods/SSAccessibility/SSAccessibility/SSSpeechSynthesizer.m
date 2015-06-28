//
//  SSSpeechSynthesizer.m
//  SSAccessibility
//
//  Created by Jonathan Hersh on 9/24/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

#import "SSAccessibility.h"
#import "SSSpeechSynthesizer.h"

@interface SSSpeechSynthesizer ()

@property (nonatomic, strong) NSTimer *speakResetTimer;
@property (nonatomic, strong) NSMutableArray *speechQueue;
@property (nonatomic, copy) NSString *lastSpokenText;

- (void) voiceOverStatusChanged;
- (void) voiceOverDidFinishAnnouncing:(NSNotification *)note;
- (void) voiceOverMayHaveTimedOut;

- (void) _maybeDequeueLine;

@end

@implementation SSSpeechSynthesizer

- (instancetype)init {
    if ((self = [super init])) {
        _speechQueue = [NSMutableArray new];
        _mayBeSpeaking = NO;
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(voiceOverStatusChanged)
                                                     name:UIAccessibilityVoiceOverStatusChanged
                                                   object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(voiceOverDidFinishAnnouncing:)
                                                     name:UIAccessibilityAnnouncementDidFinishNotification
                                                   object:nil];
    }
    
    return self;
}

- (void)dealloc {
    _delegate = nil;
    [_speakResetTimer invalidate];
    _speakResetTimer = nil;
    [_speechQueue removeAllObjects];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - speech control

- (void)voiceOverStatusChanged {
    if (UIAccessibilityIsVoiceOverRunning()) {
        [self continueSpeaking];
    } else {
        [self stopSpeaking];
    }
}

- (void)stopSpeaking {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.speakResetTimer invalidate];
        [self.speechQueue removeAllObjects];
        _mayBeSpeaking = NO;
    });
}

- (void)continueSpeaking {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self _maybeDequeueLine];
    });
}

#pragma mark - Speaking

- (void)enqueueLineForSpeaking:(NSString *)line {
    if ([line length] == 0) {
        return;
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.speakResetTimer) {
            [self.speakResetTimer invalidate];
            _speakResetTimer = nil;
        }
        
        [self.speechQueue addObject:line];
        [self _maybeDequeueLine];
    });
}

- (void)_maybeDequeueLine {
    if (!UIAccessibilityIsVoiceOverRunning()) {
        return;
    }
    
    if ([self.speechQueue count] == 0) {
        if ([self.delegate respondsToSelector:@selector(synthesizerDidFinishQueue:)]) {
            [self.delegate synthesizerDidFinishQueue:self];
        }
        
        return;
    }
    
    if (self.mayBeSpeaking) {
        return;
    }
    
    _mayBeSpeaking = YES;
    
    if (self.speakResetTimer) {
        [self.speakResetTimer invalidate];
        _speakResetTimer = nil;
    }
    
    self.lastSpokenText = [self.speechQueue firstObject];
    [self.speechQueue removeObjectAtIndex:0];
    
    if (self.timeoutDelay > 0) {
        self.speakResetTimer = [NSTimer scheduledTimerWithTimeInterval:self.timeoutDelay
                                                                target:self
                                                              selector:@selector(voiceOverMayHaveTimedOut)
                                                              userInfo:nil
                                                               repeats:NO];
    }
    
    void (^speechAction)(void) = ^{
        if ([self.delegate respondsToSelector:@selector(synthesizer:willBeginSpeakingLine:)]) {
            [self.delegate synthesizer:self
                 willBeginSpeakingLine:self.lastSpokenText];
        }
        
        [SSAccessibility speakWithVoiceOver:self.lastSpokenText];
    };
    
    NSTimeInterval delay = 0;
    
    if ([self.delegate respondsToSelector:@selector(synthesizer:secondsToWaitBeforeSpeaking:)]) {
        delay = [self.delegate synthesizer:self
               secondsToWaitBeforeSpeaking:self.lastSpokenText];
    }
    
    if (delay > 0) {
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), speechAction);
    } else {
        speechAction();
    }
}

#pragma mark - VoiceOver events

- (void)voiceOverDidFinishAnnouncing:(NSNotification *)note {
    _mayBeSpeaking = NO;
    
    if (self.speakResetTimer) {
        [self.speakResetTimer invalidate];
        _speakResetTimer = nil;
    }
    
    NSDictionary *userInfo = [note userInfo];
    
    // This observer can also be fired by certain system audio events,
    // like toggling the mute switch.
    // We speak the next line only if VoiceOver successfully spoke our last line.
    if (userInfo
        && [self.lastSpokenText length] > 0
        && [userInfo[UIAccessibilityAnnouncementKeyStringValue] isEqualToString:self.lastSpokenText]) {
        
        if ([userInfo[UIAccessibilityAnnouncementKeyWasSuccessful] boolValue]) {
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if ([self.delegate respondsToSelector:@selector(synthesizer:didSpeakLine:)]) {
                    [self.delegate synthesizer:self
                                  didSpeakLine:self.lastSpokenText];
                }
                
                [self _maybeDequeueLine];
            });
        } else {
            // the system does not always call this observer with
            // UIAccessibilityAnnouncementKeyWasSuccessful == NO :(
            self.lastSpokenText = nil;
        }
    }
}

- (void)voiceOverMayHaveTimedOut {
    [self stopSpeaking];
}

@end
