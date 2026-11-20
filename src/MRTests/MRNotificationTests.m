//
//  MRNotificationTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/24/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SPLNotificationManager.h"
#import <UserNotifications/UserNotifications.h>

@interface MRNotificationTests : XCTestCase

@end

@implementation MRNotificationTests
{
    SPLNotificationManager *manager;
    id center;
    XCTestExpectation *authorizationRequested;
}

- (void)setUp {
    [super setUp];

    manager = [SPLNotificationManager new];
    center = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([center currentNotificationCenter]).andReturn(center);
    OCMStub([center requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionSound
                                completionHandler:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        void (^ __unsafe_unretained completion)(BOOL, NSError *);
        [invocation getArgument:&completion atIndex:3];
        completion(YES, nil);
        [authorizationRequested fulfill];
    });
}

- (void)tearDown {
    [center stopMocking];
    center = nil;
    manager = nil;
    [super tearDown];
}

- (void)testRegisteringForNotifications {
    authorizationRequested = [self expectationWithDescription:@"Request authorization only once"];
    authorizationRequested.assertForOverFulfill = YES;

    XCTAssertFalse(manager.askedForLocalNotifications, @"Should initially not notify");
    [manager registerForLocalNotifications];
    XCTAssertTrue(manager.askedForLocalNotifications, @"Should have asked");
    [manager registerForLocalNotifications];
    [self waitForExpectationsWithTimeout:2 handler:nil];
}

- (void)testTimeoutUsesOneReplaceableRequest {
    NSMutableArray *requests = [NSMutableArray array];
    XCTestExpectation *scheduled = [self expectationWithDescription:@"Schedule both timeout requests"];
    scheduled.expectedFulfillmentCount = 2;
    OCMStub([center addNotificationRequest:[OCMArg any] withCompletionHandler:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained UNNotificationRequest *request;
        [invocation getArgument:&request atIndex:2];
        [requests addObject:request];
        [scheduled fulfill];
    });
    [manager scheduleTimeoutNotification];
    [manager scheduleTimeoutNotification];
    [self waitForExpectationsWithTimeout:2 handler:nil];
    XCTAssertEqual(requests.count, (NSUInteger)2);
    if (requests.count != 2) return;
    UNNotificationRequest *first = requests[0];
    UNNotificationRequest *second = requests[1];
    XCTAssertEqualObjects(first.identifier, second.identifier, @"Backgrounding twice must replace the existing reminder");
    UNTimeIntervalNotificationTrigger *trigger = (UNTimeIntervalNotificationTrigger *)first.trigger;
    XCTAssertEqualWithAccuracy(trigger.timeInterval, 8 * 60, 0.01);
    XCTAssertFalse(trigger.repeats);
    XCTAssertGreaterThan(first.content.body.length, (NSUInteger)0);
    XCTAssertNotNil(first.content.sound);
}

- (void)testReturningToAppClearsOnlyTimeoutReminder {
    OCMExpect([center removePendingNotificationRequestsWithIdentifiers:@[@"session-timeout"]]);
    OCMExpect([center removeDeliveredNotificationsWithIdentifiers:@[@"session-timeout"]]);
    [[center reject] removeAllPendingNotificationRequests];
    [[center reject] removeAllDeliveredNotifications];
    [manager cancelTimeoutNotification];
    [center verifyWithDelay:2];
}

@end
