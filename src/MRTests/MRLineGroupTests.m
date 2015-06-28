//
//  MRLineGroupTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/12/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SSAttributedLineGroup.h"
#import "SSANSIEngine.h"

@interface MRLineGroupTests : XCTestCase

@end

@implementation MRLineGroupTests
{
    NSString *testString;
    SSAttributedLineGroup *lineGroup;
    SSANSIEngine *engine;
}

- (void)setUp {
    [super setUp];

    engine = [SSANSIEngine new];
    engine.defaultTextColor = kDefaultColor;
    engine.defaultFont = kDefaultFont;
}

- (void)testAppendingGroupPreservesUserInput {
    SSAttributedLineGroup *group = [SSAttributedLineGroup lineGroupWithAttributedString:SPLTestStringWithString(@"Hello World")];

    SSAttributedLineGroup *userGroup = [SSAttributedLineGroup lineGroupWithAttributedString:SPLTestStringWithString(@"Yarr\n")];
    userGroup.containsUserInput = YES;

    EXP_expect(group.containsUserInput).to.beFalsy();

    [group appendAttributedLineGroup:userGroup];

    EXP_expect(group.lines.count).to.equal(1);
    EXP_expect(group.containsUserInput).to.beTruthy();
}

- (void)testLineGroupAppendsLines {
    SSAttributedLineGroup *group = [SSAttributedLineGroup lineGroupWithAttributedString:SPLTestStringWithString(@"Hello World\n")];

    EXP_expect(group.lines.count).to.equal(1);

    [group appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithAttributedString:SPLTestStringWithString(@"Ahoy-hoy")]];

    EXP_expect(group.lines.count).to.equal(2);

    [group appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithAttributedString:SPLTestStringWithString(@"Yarr\n")]];

    EXP_expect(group.lines.count).to.equal(2);

    [group appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithAttributedString:SPLTestStringWithString(@"Brr")]];

    EXP_expect(group.lines.count).to.equal(3);
    EXP_expect(group.lines[0]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Hello World\n")));
    EXP_expect(group.lines[1]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Ahoy-hoyYarr\n")));
    EXP_expect(group.lines[2]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Brr")));
}

- (void)testLineGroupAppendJoinsLines {
    SSAttributedLineGroup *group = [SSAttributedLineGroup lineGroupWithAttributedString:SPLTestStringWithString(@"Hello World")];
    [group appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithAttributedString:SPLTestStringWithString(@"Ahoy-hoy")]];

    EXP_expect(group.lines.count).to.equal(1);
    EXP_expect(group.lines[0]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Hello WorldAhoy-hoy")));
}

- (void)testCleanTextLines {
    testString = @"\033[H\033[31m\033[7;31m (8BIT\nMUSH) \033[0m\nhey";

    lineGroup = [engine parseANSIString:testString];

    NSArray *cleanLines = [lineGroup cleanTextLinesWithCommands:NO];

    EXP_expect(cleanLines.count).to.equal(3);
    EXP_expect(cleanLines[0]).to.equal(@"(8BIT");
    EXP_expect(cleanLines[1]).to.equal(@"MUSH)");
    EXP_expect(cleanLines[2]).to.equal(@"hey");

    testString = @"\033[H\033[7;31m (8BIT\nMUSH) \033[0m\nhey";

    lineGroup = [engine parseANSIString:testString];

    cleanLines = [lineGroup cleanTextLinesWithCommands:YES];

    EXP_expect(cleanLines.count).to.equal(4);
    EXP_expect(cleanLines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:nil endCode:@"H"]]);
    EXP_expect(cleanLines[1]).to.equal(@"(8BIT");
    EXP_expect(cleanLines[2]).to.equal(@"MUSH)");
    EXP_expect(cleanLines[3]).to.equal(@"hey");
}

- (void)testRemovingFirstLine {
    lineGroup = [SSAttributedLineGroup lineGroupWithAttributedString:SPLTestStringWithString(@"Hell\no\nWorld")];

    EXP_expect(lineGroup.lines.count).to.equal(3);

    [lineGroup removeFirstLine];

    EXP_expect(lineGroup.lines.count).to.equal(2);
    EXP_expect(lineGroup.lines.firstObject).to.equal(SPLItemWithString(SPLTestStringWithString(@"o\n")));

    [lineGroup removeFirstLine];

    EXP_expect(lineGroup.lines.count).to.equal(1);
    EXP_expect(lineGroup.lines.firstObject).to.equal(SPLItemWithString(SPLTestStringWithString(@"World")));

    [lineGroup removeFirstLine];

    EXP_expect(lineGroup.lines.count).to.equal(0);

    [lineGroup removeFirstLine];

    EXP_expect(lineGroup.lines.count).to.equal(0);
}

- (void)testRemovingFirstLines {
    lineGroup = [SSAttributedLineGroup lineGroupWithAttributedString:SPLTestStringWithString(@"Hell\no\nWorld")];

    EXP_expect(lineGroup.lines.count).to.equal(3);

    [lineGroup removeFirstLines:0];

    EXP_expect(lineGroup.lines.count).to.equal(3);

    [lineGroup removeFirstLines:2];

    EXP_expect(lineGroup.lines.count).to.equal(1);
    EXP_expect(lineGroup.lines[0]).to.equal(SPLItemWithString(SPLTestStringWithString(@"World")));

    [lineGroup removeFirstLines:1];

    EXP_expect(lineGroup.lines.count).to.equal(0);
}

- (void)testIgnoresUnknownCommands {
    testString = @"\033[6n\033[31m\033[s";

    lineGroup = [engine parseANSIString:testString];

    expect(lineGroup.lines.count).to.equal(1);
    expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithBlankLine]);
}

@end
