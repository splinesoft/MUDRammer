//
//  MyLilTimer.m
//  TimerTest
//
//  Created by Jonathon Mah on 2014-01-01.
//  Copyright (c) 2014 Jonathon Mah.
//  Use is subject to the MIT License, full text in the LICENSE file.
//

#import "MyLilTimer.h"

#import <objc/message.h>
#import <mach/mach.h>
#import <sys/sysctl.h>


#if ! __has_feature(objc_arc)
#error This file needs Automatic Reference Counting (ARC). Use -fobjc-arc flag (or convert project to ARC).
#endif


NSString *NSStringFromMyLilTimerClock(MyLilTimerClock clock)
{
    switch (clock) {
#define CASE_RETURN(x)  case x: return @#x
            CASE_RETURN(MyLilTimerClockRealtime);
            CASE_RETURN(MyLilTimerClockMonotonic);
            CASE_RETURN(MyLilTimerClockBoottime);
#undef CASE_RETURN
    }
    return nil;
}

NSString *NSStringFromMyLilTimerBehavior(MyLilTimerBehavior behavior)
{
    switch (behavior) {
#define CASE_RETURN(x)  case x: return @#x
            CASE_RETURN(MyLilTimerBehaviorHourglass);
            CASE_RETURN(MyLilTimerBehaviorPauseOnSystemSleep);
            CASE_RETURN(MyLilTimerBehaviorObeySystemClockChanges);
#undef CASE_RETURN
    }
    return nil;
}

static BOOL __unused isValidClock(MyLilTimerClock b)
{
    return (NSStringFromMyLilTimerClock(b) != nil);
}

static BOOL __unused isValidBehavior(MyLilTimerBehavior b)
{
    return (NSStringFromMyLilTimerBehavior(b) != nil);
}

static NSTimeInterval timeIntervalSinceBoot(void)
{
    // TODO: Potentially a race condition if the system clock changes between reading `bootTime` and `now`
    int status;

    struct timeval bootTime;
    status = sysctl((int[]){CTL_KERN, KERN_BOOTTIME}, 2,
                    &bootTime, &(size_t){sizeof(bootTime)},
                    NULL, 0);
    NSCAssert(status == 0, nil);

    struct timeval now;
    status = gettimeofday(&now, NULL);
    NSCAssert(status == 0, nil);

    struct timeval difference;
    timersub(&now, &bootTime, &difference);

    return (difference.tv_sec + difference.tv_usec * 1.e-6);
}

static void assertMainThread(void)
{
    NSCAssert([NSThread isMainThread], @"MyLilTimer does not currently support background threads.");
}


static NSString *const MyLilTimerHostCalendarChangedNotification = @"MyLilTimerHostCalendarChanged";


MyLilTimerBehavior MyLilTimerBehaviorFromClock(MyLilTimerClock clock)
{ return (MyLilTimerBehavior)clock; }

MyLilTimerClock MyLilTimerClockFromBehavior(MyLilTimerBehavior behavior)
{ return (MyLilTimerClock)behavior; }


@interface MyLilTimer ()
@property (nonatomic, readwrite, getter = isValid) BOOL valid;
@end


@implementation MyLilTimer {
    id _target;
    SEL _action;

    NSTimeInterval _fireClockValue;
    NSSet *_runLoopModes;
    NSTimer *_nextCheckTimer;
}


#pragma mark NSObject

- (instancetype)init
{
    NSAssert(NO, @"Bad initializer, use %s", sel_getName(@selector(initWithBehavior:timeInterval:target:selector:userInfo:)));
    return nil;
}

- (void)dealloc
{
    [self invalidate];
}

- (NSString *)description
{
    NSString *fireInfo = self.isValid ? @"scheduled" : @"fired";
    NSTimeInterval timeSinceFireDate = self.timeSinceFireDate;
    NSString *ago = (timeSinceFireDate < 0) ? @"from now" : @"ago";
    return [NSString stringWithFormat:@"<%@ %p %@ %fs %@>", [self class], self, fireInfo, ABS(timeSinceFireDate), ago];
}


#pragma mark MyLilTimer: API

+ (NSTimeInterval)nowValueForClock:(MyLilTimerClock)clock
{
    NSParameterAssert(isValidClock(clock));
    switch (clock) {
        case MyLilTimerClockRealtime:
            return [NSDate timeIntervalSinceReferenceDate];
        case MyLilTimerClockMonotonic:
            // a.k.a. CACurrentMediaTime()
            // a.k.a. [NSProcessInfo processInfo].systemUptime
            // a.k.a. _CFGetSystemUptime()
            // a.k.a. mach_absolute_time() (in different units)
            return [NSProcessInfo processInfo].systemUptime;
        case MyLilTimerClockBoottime:
            return timeIntervalSinceBoot();
    }
    return NAN; // assertions disabled
}

+ (instancetype)scheduledTimerWithBehavior:(MyLilTimerBehavior)behavior timeInterval:(NSTimeInterval)intervalSinceNow target:(id)target selector:(SEL)action userInfo:(id)userInfo
{
    assertMainThread();
    MyLilTimer *timer = [[self alloc] initWithBehavior:behavior timeInterval:intervalSinceNow target:target selector:action userInfo:userInfo];
    [timer scheduleOnMainRunLoopForModes:[NSSet setWithObject:NSRunLoopCommonModes]];
    return timer;
}

- (instancetype)initWithBehavior:(MyLilTimerBehavior)behavior timeInterval:(NSTimeInterval)intervalSinceNow target:(id)target selector:(SEL)action userInfo:(id)userInfo
{
    if (!(self = [super init])) {
        return nil;
    }

    assertMainThread();
    NSParameterAssert(isValidBehavior(behavior));
    NSParameterAssert(target != nil);
    NSParameterAssert(action != NULL);
    if (!isValidBehavior(behavior) || !target || !action) { // assertions diabled
        return nil;
    }

    // NSTimer behavior
    intervalSinceNow = MAX(0.1e-3, intervalSinceNow);

    _behavior = behavior;
    _target = target;
    _action = action;
    _userInfo = userInfo;

    _fireClockValue = [[self class] nowValueForClock:MyLilTimerClockFromBehavior(self.behavior)] + intervalSinceNow;

    self.valid = YES;

    return self;
}

- (void)scheduleOnMainRunLoopForModes:(NSSet *)modes
{
    assertMainThread();
    if (_runLoopModes) {
        [NSException raise:NSInvalidArgumentException format:@"Timer can only be scheduled once"];
    }
    NSParameterAssert(modes.count > 0);
    _runLoopModes = [modes copy];

    registerForHostCalendarChangedNotification();
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(checkExpirationAndRescheduleIfNeeded:) name:MyLilTimerHostCalendarChangedNotification object:nil];

    [self checkExpirationAndRescheduleIfNeeded:self];
}

- (void)fire
{
    assertMainThread();
    if (!self.valid) {
        return;
    }

    ((void(*)(id, SEL, id))objc_msgSend)(_target, _action, self);
    //[_target performSelector:_action withObject:self];

    [self invalidate];
}

- (NSDate *)fireDate
{ return [NSDate dateWithTimeIntervalSinceNow:-self.timeSinceFireDate]; }

- (NSTimeInterval)timeSinceFireDate
{
    assertMainThread();
    return [[self class] nowValueForClock:MyLilTimerClockFromBehavior(self.behavior)] - _fireClockValue;
}

- (void)setTolerance:(NSTimeInterval)tolerance
{
    _tolerance = tolerance;
    [self checkExpirationAndRescheduleIfNeeded:self];
}

- (void)invalidate
{
    assertMainThread();
    if (!self.valid) {
        return;
    }

    self.valid = NO;
    _target = nil;
    _userInfo = nil;

    if (!_runLoopModes) {
        return; // never scheduled
    }

    [_nextCheckTimer invalidate];
    _nextCheckTimer = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self name:MyLilTimerHostCalendarChangedNotification object:nil];
}


#pragma mark MyLilTimer: Private

/// Sender is notification, timer, or self
- (void)checkExpirationAndRescheduleIfNeeded:(id)sender
{
    assertMainThread();
    if (!self.valid || !_runLoopModes.count) {
        return;
    }

    // _nextCheckTimer may have the only strong reference to us; keep ourselves alive while it's invalidated
    __typeof(self) __attribute__((objc_precise_lifetime, unused)) strongSelf = self;

    [_nextCheckTimer invalidate];
    _nextCheckTimer = nil;

    NSDate *fireDate = self.fireDate;
    if (fireDate.timeIntervalSinceNow <= 0) {
        // Need to fire; do so in its own run loop pass so callback is run in a consistent execution environment, and run loop is in an expected mode.
        // No need to keep track of "waiting to fire" state; multiple calls to -fire are harmless.
        [self performSelector:@selector(fire) withObject:nil afterDelay:0 inModes:_runLoopModes.allObjects];
        return;
    }

    _nextCheckTimer = [[NSTimer alloc] initWithFireDate:fireDate interval:0 target:self selector:_cmd userInfo:nil repeats:NO];
    if ([_nextCheckTimer respondsToSelector:@selector(setTolerance:)]) { // OS X 10.9, iOS 7.0
        _nextCheckTimer.tolerance = self.tolerance;
    }

    NSAssert([NSRunLoop currentRunLoop] == [NSRunLoop mainRunLoop], @"MyLilTimer only supports the main run loop");
    NSRunLoop *runLoop = [NSRunLoop mainRunLoop];
    for (NSString *mode in _runLoopModes) {
        [runLoop addTimer:_nextCheckTimer forMode:mode];
    }
}


static void registerForHostCalendarChangedNotification(void)
{
    // Implementation inspired by <http://opensource.apple.com/source/PowerManagement/PowerManagement-420.1.20/pmconfigd/pmconfigd.c>
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        CFMachPortRef cfMachPort = CFMachPortCreate(kCFAllocatorDefault, handleHostCalendarChangeMessage, NULL, NULL);
        NSCAssert(cfMachPort, nil);

        registerForHostCalendarChangeNotificationOnMachPort(CFMachPortGetPort(cfMachPort));

        CFRunLoopSourceRef cfRunLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, cfMachPort, 0);
        NSCAssert(cfRunLoopSource, nil);
        CFRunLoopAddSource(CFRunLoopGetCurrent(), cfRunLoopSource, kCFRunLoopDefaultMode);

        CFRelease(cfRunLoopSource);
        CFRelease(cfMachPort);
    });
}

static void registerForHostCalendarChangeNotificationOnMachPort(mach_port_t port)
{
    kern_return_t __unused result = host_request_notification(mach_host_self(), HOST_NOTIFY_CALENDAR_CHANGE, port);
    NSCAssert(result == KERN_SUCCESS, @"host_request_notification error");
}

static void handleHostCalendarChangeMessage(CFMachPortRef port, void *msg, CFIndex size, void *info)
{
    const mach_msg_header_t *header = msg;
    if (!header || header->msgh_id != HOST_CALENDAR_CHANGED_REPLYID) {
        return;
    }

    // Register again
    registerForHostCalendarChangeNotificationOnMachPort(header->msgh_local_port);

    [[NSNotificationCenter defaultCenter] postNotificationName:MyLilTimerHostCalendarChangedNotification object:nil];
}


@end
