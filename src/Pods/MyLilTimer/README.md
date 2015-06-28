# MyLilTimer

## Know your clocks

`MyLilTimer` is a Cocoa timer class for iOS and Mac OS X. Its only dependency is the Foundation framework. `MyLilTimer` has an interface similar to `NSTimer`, while also providing a choice of three behaviors (three different clocks).

Read the accompanying article on dev etc: [Timers, Clocks, and Cocoa](http://devetc.org/code/2014/01/21/timers-clocks-and-cocoa.html).

## Behaviors

The three behaviors are visualized in [this YouTube video](http://www.youtube.com/watch?v=ZRM8mq-ZSO0).

### MyLilTimerBehaviorHourglass (MyLilTimerClockBoottime)

The timer fires after an interval has elapsed, regardless of system clock changes and system sleep. This is the behavior people often expect from `NSTimer`, and it appears to have this behavior **when running under Xcode** (and when an iOS device is plugged in to power).

### MyLilTimerBehaviorPauseOnSystemSleep (MyLilTimerClockMonotonic)

The timer fires after the system has run for some duration; this is paused while the operating system was asleep. This is the **actual** behavior of `NSTimer` — an iOS device will sleep when unplugged from power, the screen is locked, and no apps are keeping it awake.

This behavior is appropriate for measuring the speed of long-running operations, such as “3 of 7 items processed, 30 seconds remaining”.

### MyLilTimerBehaviorObeySystemClockChanges (MyLilTimerClockRealtime)

The timer fires when the time on the system clock passes the fire date. This behavior is appropriate for an alarm that fires when the clock shows a particular time.


## Usage

The most common way to set a timer is with the class convenience method:

    +[MyLilTimer scheduledTimerWithBehavior:(MyLilTimerBehavior)behavior
                               timeInterval:(NSTimeInterval)intervalSinceNow
                                     target:(id)target
                                   selector:(SEL)action
                                   userInfo:(id)userInfo]

The `TimerTest` iPhone / iPad app demonstrates the use of `MyLilTimer`, along with all three behaviors.


## Requirements

`MyLilTimer` uses automatic reference counting and the `dispatch_once` GCD function, which are available on Mac OS X 10.6+ and iOS 4+.

If you so wanted, it would be easy to remove both these dependencies for compatibility to much earlier systems.


## Installation

Simply add `MyLilTimer.h` and `MyLilTimer.m` to your project file.

Or, with [CocoaPods](http://cocoapods.org), add to your Podfile:

    pod 'MyLilTimer'

(Note: I have never used CocoaPods and don't otherwise endorse it,)


## NSTimer features not (yet) supported

- Repeating timers
- Changing the fire date
- Use on run loops other than the main run loop (including background threads)


## License

MyLilTimer is available under the MIT license. See the LICENSE file for full text.
