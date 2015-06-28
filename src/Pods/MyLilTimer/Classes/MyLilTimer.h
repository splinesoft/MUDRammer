//
//  MyLilTimer.h
//  TimerTest
//
//  Created by Jonathon Mah on 2014-01-01.
//  Copyright (c) 2014 Jonathon Mah.
//  Use is subject to the MIT License, full text in the LICENSE file.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSInteger, MyLilTimerClock) {
    MyLilTimerClockRealtime = 0,
    MyLilTimerClockMonotonic,
    MyLilTimerClockBoottime,
};

NSString *NSStringFromMyLilTimerClock(MyLilTimerClock clock);


typedef NS_ENUM(NSInteger, MyLilTimerBehavior) {
    /// The timer fires after an interval has elapsed, regardless of system clock changes and system sleep.
    MyLilTimerBehaviorHourglass = MyLilTimerClockBoottime,

    /// The timer fires after the system has run for some duration; this is paused while the operating system was asleep.
    /// This behavior is appropriate for measuring the speed of long-running operations, such as "3 of 7 items processed, 30 seconds remaining".
    ///
    /// This is the behavior of \p NSTimer and \p NSRunLoop / \p CFRunLoop.
    MyLilTimerBehaviorPauseOnSystemSleep = MyLilTimerClockMonotonic,

    /// The timer fires when the time on the system clock passes the fire date.
    /// This behavior is appropriate for an alarm that fires when the clock shows a particular time.
    MyLilTimerBehaviorObeySystemClockChanges = MyLilTimerClockRealtime,
};

NSString *NSStringFromMyLilTimerBehavior(MyLilTimerBehavior behavior);


MyLilTimerBehavior MyLilTimerBehaviorFromClock(MyLilTimerClock clock);
MyLilTimerClock MyLilTimerClockFromBehavior(MyLilTimerBehavior behavior);


@interface MyLilTimer : NSObject

/**
 * Returns the current value of a clock.
 * A single value is arbitrary; use the difference between two invocations of this method.
 */
+ (NSTimeInterval)nowValueForClock:(MyLilTimerClock)clock;

- (instancetype)init NS_UNAVAILABLE;

/**
 * Creates a new timer and schedules it on the main run loop in NSRunLoopCommonModes.
 *
 * \param behavior determines how time is measured.
 *
 * \param intervalSinceNow the number of seconds before the timer fires.
 *     Like NSTimer, this is measured from now, regardless when the timer is scheduled with a run loop.
 *     The minimum value is 0.0001 for consistency with NSTimer.
 *
 * \param target the object to which to send the message specified by \p action when the timer fires.
 *     The timer maintains a strong reference to target until the timer is invalidated.
 *
 * \param action the message to send to \p target when the timer fires.
 *     This method should have the signature:
 *     \p - (void)timerFired:(MyLilTimer *)timer
 *
 * \param userInfo an arbitrary object associated with the timer.
 *     The timer releases this object when it's invalidated (after the action has been sent to the target).
 */
+ (instancetype)scheduledTimerWithBehavior:(MyLilTimerBehavior)behavior timeInterval:(NSTimeInterval)intervalSinceNow target:(id)target selector:(SEL)action userInfo:(id)userInfo;

/**
 * Creates a new timer, without scheduling it on a run loop.
 * \em (Designated initializer.)
 *
 * \param behavior determines how time is measured.
 *
 * \param intervalSinceNow the number of seconds before the timer fires.
 *     Like NSTimer, this is measured from now, regardless when the timer is scheduled with a run loop.
 *     The minimum value is 0.0001 for consistency with NSTimer.
 *
 * \param target the object to which to send the message specified by \p action when the timer fires.
 *     The timer maintains a strong reference to target until the timer is invalidated.
 *
 * \param action the message to send to \p target when the timer fires.
 *     This method should have the signature:
 *     \p - (void)timerFired:(MyLilTimer *)timer
 *
 * \param userInfo an arbitrary object associated with the timer.
 *     The timer releases this object when it's invalidated (after the action has been sent to the target).
 */
- (instancetype)initWithBehavior:(MyLilTimerBehavior)behavior timeInterval:(NSTimeInterval)intervalSinceNow target:(id)target selector:(SEL)action userInfo:(id)userInfo;

/**
 * Currently only timers on the main thread (using the main loop) are supported.
 */
- (void)scheduleOnMainRunLoopForModes:(NSSet *)modes;

/**
 * Fires the timer immediately, sending the action to the target, then invalidates.
 * Does nothing if the timer has been invalidated.
 */
- (void)fire;

@property (nonatomic, readonly) MyLilTimerBehavior behavior;

/**
 * An arbitrary object associated with the timer.
 *
 * \returns the argument for the \p userInfo parameter of an init method,
 *     or nil if the timer has been invalidated.
 */
@property (nonatomic, readonly) id userInfo;

/**
 * Returns the date at which the timer is currently scheduled to fire.
 * This value can change depending on the timer behavior, system clock changes, and system sleep.
 */
- (NSDate *)fireDate;

/**
 * Returns the duration that has elapsed since the timer's fire date.
 * If the timer has not yet fired, the return value will be negative indicating a time in the future.
 */
- (NSTimeInterval)timeSinceFireDate;

/**
 * A larger value allows the timer to fire later, in sync with other system activity to reduce power use.
 * Has no effect if \p NSTimer does not support setting tolerance (prior to Mac OS X 10.9 and iOS 7.0).
 * \see -[NSTimer tolerance]
 */
@property (nonatomic) NSTimeInterval tolerance;

- (void)invalidate;
@property (nonatomic, readonly, getter = isValid) BOOL valid;

@end
