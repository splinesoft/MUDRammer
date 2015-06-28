//
//  MRModelTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/14/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

#import "MRTestHelpers.h"
#import <Gag.h>
#import <World.h>
#import <Trigger.h>
#import <MagicalRecord.h>

@interface MRModelTests : XCTestCase

@end

@implementation MRModelTests
{
    World *world;
    Gag *gag;
    Trigger *trigger;
}

- (void)setUp {
    [super setUp];

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *context) {
        World *w = [World createObjectInContext:context];
        w.name = @"Test";

        Gag *g = [Gag createObjectInContext:context];
        g.gag = @"Test";

        Trigger *t = [Trigger createObjectInContext:context];
        t.trigger = @"Test";
    }];

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *context) {
        World *w = [World MR_findFirstByAttribute:@"name" withValue:@"Test"];

        Gag *g = [Gag MR_findFirstByAttribute:@"gag" withValue:@"Test"];
        g.world = w;
    }];

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *context) {
        World *w = [World MR_findFirstByAttribute:@"name" withValue:@"Test"];

        Trigger *t = [Trigger MR_findFirstByAttribute:@"trigger" withValue:@"Test"];
        t.world = w;
    }];

    world = [World MR_findFirst];
    gag = [Gag MR_findFirst];
    trigger = [Trigger MR_findFirst];
}

- (void)tearDown {
    [super tearDown];

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *context) {
        [Gag MR_truncateAllInContext:context];
        [Trigger MR_truncateAllInContext:context];
        [World MR_truncateAllInContext:context];
    }];
}

#pragma mark - Base

- (void)testCreateObjectWithCompletion {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Create Entity"];

    [World createObjectWithCompletion:^(NSManagedObjectID *objectID) {
        expect(objectID).toNot.beNil();
        expect(objectID.isTemporaryID).to.beFalsy();
        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5 handler:nil];
}

#pragma mark - Worlds

- (void)testWorldFiltersGagLines {
    EXP_expect(world.gags.count).will.equal(1);

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *context) {
        Gag *g = [gag MR_inContext:context];
        g.gag = @"World";
        g.gagType = @(GagTypeStartOfLine);
    }];

    NSMutableArray *lines = [NSMutableArray array];

    for (NSUInteger i = 0; i < 10; i++) {
        [lines addObject:@"Hello"];
    }

    EXP_expect([world filteredIndexesByMatchingGagsInLines:lines]).to.equal([NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 10)]);

    [lines insertObject:@"World" atIndex:5];

    NSIndexSet *indexes = [world filteredIndexesByMatchingGagsInLines:lines];

    EXP_expect(indexes.count).will.equal(10);
    EXP_expect([indexes containsIndex:5]).will.beFalsy();

    SSAttributedLineGroupItem *item = [SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:nil endCode:@"H"]];
    [lines insertObject:item atIndex:6];

    indexes = [world filteredIndexesByMatchingGagsInLines:lines];

    EXP_expect(indexes.count).will.equal(11);
    EXP_expect([indexes containsIndex:5]).will.beFalsy();
}

- (void)testWorldRunsTriggers {
    NSArray *lines = @[
        @"Hello world",
        @"Testing here",
        @"One two three"
    ];

    NSString *soundFileName = @"sound.wav";

    [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *context) {
        World *w = [world MR_inContext:context];

        Trigger *t = [Trigger createObjectInContext:context];
        t.world = w;
        t.trigger = @"Hello";
        t.commands = @"yo";
        t.highlightColor = [UIColor redColor];
        t.soundFileName = soundFileName;

        Trigger *t2 = [Trigger createObjectInContext:context];
        t2.world = w;
        t2.trigger = @"three";
        t2.commands = @"hey";
        t2.highlightColor = [UIColor blueColor];
    }];

    NSArray *outCommands;
    NSDictionary *outColors;
    NSString *outSoundName;

    [world runTriggersForLines:lines
                   outCommands:&outCommands
                     outColors:&outColors
                  outSoundName:&outSoundName];

    expect(outCommands.count).to.equal(2);
    expect(outCommands[0]).to.equal(@"yo");
    expect(outCommands[1]).to.equal(@"hey");

    expect(outColors.count).to.equal(lines.count);
    expect(outColors[@0]).to.equal([UIColor redColor]);
    expect(outColors[@1]).to.equal([UIColor clearColor]);
    expect(outColors[@2]).to.equal([UIColor blueColor]);

    expect(outSoundName).to.equal(soundFileName);
}

#pragma mark - Gags

- (void)testGagMatchesLine {
    gag.gag = @"World";
    gag.gagType = @(GagTypeStartOfLine);

    EXP_expect([gag matchesLine:@"Hello World"]).to.beFalsy();

    gag.gagType = @(GagTypeLineContains);

    EXP_expect([gag matchesLine:@"Hello World"]).to.beTruthy();

    gag.gag = @"World";
    gag.gagType = @(GagTypeStartOfLine);

    EXP_expect([gag matchesLine:@"Hello World"]).to.beFalsy();
    EXP_expect([gag matchesLine:@"World"]).to.beTruthy();

    gag.gagType = @(GagTypeLineEquals);

    EXP_expect([gag matchesLine:@"World"]).to.beTruthy();
    EXP_expect([gag matchesLine:@"Hello World"]).to.beFalsy();
    EXP_expect([gag matchesLine:@"World World"]).to.beFalsy();
}

#pragma mark - Triggers

- (void)testTriggerMatchesLine {
    trigger.trigger = @"World";

    EXP_expect([trigger matchesLine:@"Hello World"]).to.beTruthy();

    trigger.trigger = @"World";

    EXP_expect([trigger matchesLine:@"Hello World"]).to.beTruthy();
    EXP_expect([trigger matchesLine:@"World"]).to.beTruthy();
}

@end
