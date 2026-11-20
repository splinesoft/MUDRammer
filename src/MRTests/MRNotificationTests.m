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
    NSUInteger authorizationRequests;
}

- (void)setUp {
    [super setUp];

    manager = [SPLNotificationManager new];
    center = OCMClassMock([UNUserNotificationCenter class]);
    OCMStub([center currentNotificationCenter]).andReturn(center);
    authorizationRequests = 0;
    OCMStub([center requestAuthorizationWithOptions:UNAuthorizationOptionAlert | UNAuthorizationOptionSound
                                completionHandler:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        authorizationRequests++;
        void (^ __unsafe_unretained completion)(BOOL, NSError *);
        [invocation getArgument:&completion atIndex:3];
        completion(YES, nil);
    });
}

- (void)tearDown {
    [center stopMocking];
    center = nil;
    manager = nil;
    [super tearDown];
}

- (void)testRegisteringForNotifications {
    XCTAssertFalse(manager.askedForLocalNotifications, @"Should initially not notify");
    [manager registerForLocalNotifications];
    XCTAssertTrue(manager.askedForLocalNotifications, @"Should have asked");
    [manager registerForLocalNotifications];
    XCTAssertEqual(authorizationRequests, (NSUInteger)1, @"Do not repeatedly request authorization in one session");
}

- (void)testTimeoutUsesOneReplaceableRequest {
    NSMutableArray *requests = [NSMutableArray array];
    OCMStub([center addNotificationRequest:[OCMArg any] withCompletionHandler:[OCMArg any]])
    .andDo(^(NSInvocation *invocation) {
        __unsafe_unretained UNNotificationRequest *request;
        [invocation getArgument:&request atIndex:2];
        [requests addObject:request];
    });
    [manager scheduleTimeoutNotification];
    [manager scheduleTimeoutNotification];
    XCTAssertEqual(requests.count, (NSUInteger)2);
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
    OCMVerifyAll(center);
}

@end
