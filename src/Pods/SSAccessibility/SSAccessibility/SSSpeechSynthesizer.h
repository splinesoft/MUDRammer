//
//  SSSpeechSynthesizer.h
//  SSAccessibility
//
//  Created by Jonathan Hersh on 9/24/13.
//  Copyright (c) 2013 Splinesoft. All rights reserved.
//

/**
 * SSSpeechSynthesizer manages a queue of lines of text, speaking one at a time
 * with VoiceOver, then speaking the next line when speaking finishes.
 *
 * The user can interrupt speech by tapping any element on screen that is announced by VoiceOver.
 *
 * Why not use iOS 7's AVSpeechSynthesizer?
 * You should if you can. AVSpeechSynthesizer is good for speaking long blobs of text.
 * But there are reasons to prefer VoiceOver:
 * `AVSpeechSynthesizer` requires iOS 7
 * `AVSpeechSynthesizer` doesn't always pause or stop speaking when asked
 * The user can set her preferred VoiceOver speaking rate in Settings.app, but there is no programmatic API access to that default speech rate -- say, for use in your `AVSpeechSynthesizer`
 * `AVSpeechSynthesizer` doesn't stop speaking (only ducks) when VoiceOver starts, so two voices will be speaking at once
 * The user can immediately (and intentionally or unintentionally) interrupt VoiceOver by tapping any element on screen
 */

@import Foundation;

@protocol SSSpeechSynthesizerDelegate;

@interface SSSpeechSynthesizer : NSObject

/**
 * Returns a best guess as to whether the synthesizer is currently speaking something with VoiceOver.
 * There is no guaranteed programmatic access to VoiceOver's speaking status.
 * THIS MAY BE INACCURATE.
 */
@property (nonatomic, assign, readonly) BOOL mayBeSpeaking;

/**
 * Optional - the synthesizer will time out this number of seconds after it starts speaking
 * a line of text with voiceover. The timer is reset after each successfully-spoken line
 * and when the synthesizer stops speaking.
 * A timeout will cause the synthesizer to wipe its text queue, then start
 * speaking again once a new line is enqueued.
 * To disable this behavior, ignore this property or set it to 0.
 */
@property (nonatomic, assign) NSTimeInterval timeoutDelay;

/**
 * The delegate is notified about synthesizer events.
 */
@property (nonatomic, weak) id <SSSpeechSynthesizerDelegate> delegate;

/**
 * Stops speaking at the end of the current announcement and clears the text queue.
 */
- (void) stopSpeaking;

/**
 * Resumes speaking.
 * Useful if speaking was interrupted, perhaps when the user touched a VoiceOver element.
 */
- (void) continueSpeaking;

/**
 * Add a new line to the end of the speaking queue.
 * Will not interrupt speaking.
 * Starts speaking if the synthesizer believes itself to not currently be speaking.
 */
- (void) enqueueLineForSpeaking:(NSString *)line;

@end

@protocol SSSpeechSynthesizerDelegate <NSObject>

@optional

/**
 * Optionally implement this method to specify a number of seconds 
 * to wait before speaking a line of text.
 */
- (NSTimeInterval) synthesizer:(SSSpeechSynthesizer *)synthesizer
   secondsToWaitBeforeSpeaking:(NSString *)line;

/**
 * Sent to the delegate AFTER waiting the amount of time specified in 
 * `secondsToWaitBeforeSpeaking` and just BEFORE the synthesizer begins speaking.
 */
- (void) synthesizer:(SSSpeechSynthesizer *)synthesizer willBeginSpeakingLine:(NSString *)line;

/**
 * The synthesizer has successfully finished speaking a line of text.
 */
- (void) synthesizer:(SSSpeechSynthesizer *)synthesizer
        didSpeakLine:(NSString *)line;

/**
 * The synthesizer believes it has reached the end of its speaking queue.
 */
- (void) synthesizerDidFinishQueue:(SSSpeechSynthesizer *)synthesizer;

@end
