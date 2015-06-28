//
//  MRTimerTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/23/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SPLTimerManager.h"
#import "SPLWorldTickerManager.h"

@interface MRTimerTests : XCTestCase

@end

@implementation MRTimerTests
{
    SPLWorldTickerManager *tickerManager;
    SPLTimerManager *timerManager;
    NSString *timerName;
}

- (void)setUp {
    [super setUp];

    timerManager = [SPLTimerManager new];
    timerName = @"TimerTest";
    tickerManager = [[SPLWorldTickerManager alloc] initWithTimerManager:timerManager];

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *context) {
        [Ticker MR_truncateAllInContext:context];
        [World MR_truncateAllInContext:context];

        World *world = [World createObjectInContext:context];
        world.isHidden = @NO;

        Ticker *ticker = [Ticker createObjectInContext:context];
        ticker.world = world;
        ticker.isHidden = @NO;
        ticker.interval = @1;
        ticker.isEnabled = @YES;
        ticker.commands = @"hi";
    }];
}

- (void)tearDown {
    [super tearDown];
    [timerManager cancelRepeatingTimerWithName:timerName];
    timerManager = nil;
    tickerManager = nil;
}

#pragma mark - Timers

- (void)testSchedulesTimer {
    XCTestExpectation *timerExp = [self expectationWithDescription:@"Timer"];
    __block NSUInteger count = 0;

    [timerManager scheduleRepeatingTimerWithName:timerName interval:1 block:^{
        count++;
    }];

    expect([timerManager intervalForTimerWithName:timerName]).to.equal(1);
    expect([timerManager isTickerEnabledWithIdentifier:timerName]).to.beTruthy();

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        expect(count).to.beGreaterThanOrEqualTo(3);
        [timerExp fulfill];
    });

    [self waitForExpectationsWithTimeout:5 handler:nil];

    [timerManager cancelRepeatingTimerWithName:timerName];
}

- (void)testCancelsTimer {
    XCTestExpectation *cancelExp = [self expectationWithDescription:@"CancelTimer"];

    [timerManager scheduleRepeatingTimerWithName:timerName
                                        interval:1
                                           block:^{
                                               XCTFail(@"Timer called!");
                                           }];

    expect([timerManager isTickerEnabledWithIdentifier:timerName]).to.beTruthy();

    [timerManager cancelRepeatingTimerWithName:timerName];

    expect([timerManager isTickerEnabledWithIdentifier:timerName]).to.beFalsy();

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [cancelExp fulfill];
    });

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark - Tickers

- (void)testEnablingTickerSchedulesTimer {
    XCTestExpectation *tickerExp = [self expectationWithDescription:@"TickerFire"];

    World *world = [World MR_findFirst];

    expect([world orderedTickers].count).to.beGreaterThan(0);

    NSUInteger identifier = [tickerManager enableAndObserveTickersForWorld:world
     tickerBlock:^(NSManagedObjectID *tickerID) {
         [tickerExp fulfill];
     }];

    expect(identifier).to.beGreaterThan(0);

    [self waitForExpectationsWithTimeout:2 handler:nil];

    [tickerManager disableTickersForIdentifier:identifier];
}

- (void)testCreatingTickerCreatesTimer {
    XCTestExpectation *tickerExp = [self expectationWithDescription:@"TickerFire"];

    World *world = [World MR_findFirst];
    expect([world orderedTickers].count).to.beGreaterThan(0);

    __block NSUInteger count = 0;

    NSUInteger identifier = [tickerManager enableAndObserveTickersForWorld:world
                                                               tickerBlock:^(NSManagedObjectID *tickerID) {
                                                                   count++;
                                                               }];

    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *context) {
        Ticker *t = [Ticker createObjectInContext:context];
        t.world = [world MR_inContext:context];
        t.interval = @1;
        t.isHidden = @NO;
        t.isEnabled = @YES;
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        expect(count).to.beGreaterThanOrEqualTo(10);
        [tickerExp fulfill];
    });

    [self waitForExpectationsWithTimeout:7 handler:nil];

    [tickerManager disableTickersForIdentifier:identifier];
}

- (void)testUpdatingTickerUpdatesTimer {
    XCTestExpectation *tickerExp = [self expectationWithDescription:@"TickerFire"];

    World *world = [World MR_findFirst];
    expect([world orderedTickers].count).to.beGreaterThan(0);

    __block NSUInteger count = 0;

    NSUInteger identifier = [tickerManager enableAndObserveTickersForWorld:world
                                                               tickerBlock:^(NSManagedObjectID *tickerID) {
                                                                   count++;
                                                               }];

    expect(identifier).to.beGreaterThan(0);

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *context) {
        Ticker *ticker = [Ticker MR_findFirstInContext:context];
        ticker.interval = @5;
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(6 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        expect(count).to.equal(1);
        [tickerExp fulfill];
    });

    [self waitForExpectationsWithTimeout:7 handler:nil];

    [tickerManager disableTickersForIdentifier:identifier];
}

- (void)testDisablingTickerDisablesTimer {
    XCTestExpectation *tickerExp = [self expectationWithDescription:@"TickerFire"];

    World *world = [World MR_findFirst];
    expect([world orderedTickers].count).to.beGreaterThan(0);

    __block NSUInteger count = 0;

    NSUInteger identifier = [tickerManager enableAndObserveTickersForWorld:world
                                                               tickerBlock:^(NSManagedObjectID *tickerID) {
                                                                   count++;
                                                               }];

    expect(identifier).to.beGreaterThan(0);

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *context) {
        Ticker *ticker = [Ticker MR_findFirstInContext:context];
        ticker.isEnabled = @NO;
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        expect(count).to.equal(0);
        [tickerExp fulfill];
    });

    [self waitForExpectationsWithTimeout:3 handler:nil];

    [tickerManager disableTickersForIdentifier:identifier];
}

- (void)testDisablingTickersDoesNotCallTimer {
    XCTestExpectation *tickerExp = [self expectationWithDescription:@"TickerNotFire"];

    World *world = [World MR_findFirst];

    expect([world orderedTickers].count).to.beGreaterThan(0);

    NSUInteger identifier = [tickerManager enableAndObserveTickersForWorld:world
                                                               tickerBlock:^(NSManagedObjectID *tickerID) {
                                                                   XCTFail(@"Called ticker!");
                                                               }];

    expect(identifier).to.beGreaterThan(0);

    [tickerManager disableTickersForIdentifier:identifier];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [tickerExp fulfill];
    });

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

@end
