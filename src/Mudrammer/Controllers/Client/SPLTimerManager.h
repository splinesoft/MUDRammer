//
//  SPLTimerManager.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import Foundation;

typedef void (^SPLTimerBlock) (void);

@interface SPLTimerManager : NSObject

#pragma mark - Setting timers

/**
 *  Schedule a repeating timer.
 *
 *  @param name     an object by which to identify this timer
 *  @param interval time interval for this timer
 *  @param block    block to fire when the timer fires
 */
- (void) scheduleRepeatingTimerWithName:(id)name
                               interval:(NSTimeInterval)interval
                                  block:(SPLTimerBlock)block;

/**
 *  Access the interval for a timer with the given identifier.
 *
 *  @param name identifier for a timer
 *
 *  @return interval for the timer, or 0 if there is no timer with this name
 */
- (NSTimeInterval) intervalForTimerWithName:(id)name;

/**
 *  Return YES if a ticker with the specified identifier is active.
 *
 *  @param name identifier
 *
 *  @return YES if the ticker is actively firing
 */
- (BOOL) isTickerEnabledWithIdentifier:(id)name;

/**
 *  Cancel a repeating timer.
 *
 *  @param name timer to cancel.
 */
- (void) cancelRepeatingTimerWithName:(id)name;

@end
