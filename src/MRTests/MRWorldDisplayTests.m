//
//  MRWorldDisplayTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/25/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SSWorldDisplayController.h"
#import "SSClientContainer.h"

@interface MRWorldDisplayTests : XCTestCase

@end

@implementation MRWorldDisplayTests
{
    SSWorldDisplayController *worldController;
    World *world;
}

- (void)setUp {
    [super setUp];
    worldController = [SSWorldDisplayController new];

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *context) {
        World *w = [World createObjectInContext:context];
        w.isHidden = @NO;
        w.hostname = @"nanvaent.org";
        w.port = @23;
    }];

    world = [World MR_findFirst];
}

- (void)tearDown {
    [super tearDown];

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *context) {
        [World MR_truncateAllInContext:context];
    }];

    worldController = nil;
}

- (void)testAddsSingleWorld {
    expect(worldController.numberOfClients).to.equal(0);

    [worldController addClientWithWorld:[world objectID]];

    expect(worldController.numberOfClients).to.equal(1);
    expect(worldController.selectedIndex).to.equal(0);

    [worldController selectNextWorld];

    expect(worldController.selectedIndex).to.equal(0);
}

- (void)testRemovesSingleWorld {
    [worldController addClientWithWorld:[world objectID]];

    expect(worldController.numberOfClients).to.equal(1);
    expect(worldController.selectedIndex).to.equal(0);

    [worldController removeClientAtIndex:0];

    expect(worldController.selectedIndex).to.equal(0);
    expect(worldController.numberOfClients).to.equal(0);
}

- (void)testClientIndexAccess {
    [worldController addClientWithWorld:[world objectID]];

    SSClientViewController *client = worldController.currentVisibleClient;

    expect([client isKindOfClass:[SSClientViewController class]]).to.beTruthy();
    expect([worldController clientAtIndex:0]).to.equal(client);
    expect([worldController indexOfClient:client]).to.equal(0);
}

@end
