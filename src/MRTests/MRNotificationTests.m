//
//  MRNotificationTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/24/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SPLNotificationManager.h"

@interface MRNotificationTests : XCTestCase

@end

@implementation MRNotificationTests
{
    SPLNotificationManager *manager;
}

- (void)setUp {
    [super setUp];

    manager = [SPLNotificationManager new];
}

- (void)tearDown {
    [super tearDown];

    manager = nil;
}

- (void)testRegisteringForNotifications {
    XCTAssertFalse(manager.askedForLocalNotifications, @"Should initially not notify");
    XCTAssertNil(manager.userNotificationSettings, @"Should not have settings to start");
    [manager registerForLocalNotifications];
    XCTAssertTrue(manager.askedForLocalNotifications, @"Should have asked");
}

@end
