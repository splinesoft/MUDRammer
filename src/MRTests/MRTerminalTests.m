//
//  MRTerminalTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/8/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SSTextTableView.h"
#import "SPLTerminalDataSource.h"
#import "NSAttributedString+SPLAdditions.h"
#import "SSMRConstants.h"

@interface MRTerminalTests : XCTestCase

@end

@implementation MRTerminalTests
{
    SSTextTableView *tableView;
    SSAttributedLineGroup *lineGroup;
    SPLTerminalDataSource *dataSource;
    CGSize charSize;
}

- (void)setUp {
    [super setUp];

    tableView = [[SSTextTableView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    dataSource = [[SPLTerminalDataSource alloc] initWithItems:nil];
    dataSource.tableView = tableView;
    charSize = [tableView charSize];

    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPrefSimpleTelnetMode];
}

- (void)tearDown {
    [super tearDown];

    dataSource.tableView = nil;
    dataSource = nil;
    tableView = nil;
}

- (void)testAppendingToEmptyTable {
    [dataSource appendText:@"Yarr Ahoy" isUserInput:YES];

    EXP_expect(dataSource.numberOfItems).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 2));
}

- (void)testAppendingSameLineToEmptyTable {
    [dataSource appendText:@"Yarr Ahoy" isUserInput:NO];

    EXP_expect(dataSource.numberOfItems).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(10, 1));
}

- (void)testAppendingSameLineToLineEdge {
    [dataSource appendText:@"Yarr Ahoy" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(10, 1));

    [dataSource appendText:@"Yarr Ahoy" isUserInput:NO];

    EXP_expect(dataSource.numberOfItems).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(19, 1));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).line.string).will.equal(@"Yarr AhoyYarr Ahoy");
}

- (void)testInsertingSameLineMovesCursor {
    [dataSource appendText:@"Hello" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(6, 1));

    [dataSource appendText:@"Ahoy" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(10, 1));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).line.string).will.equal(@"HelloAhoy");
}

- (void)testInsertingNewLine {
    [dataSource appendText:@"Hi" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 1));

    [dataSource appendText:@"Ahoy\n" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 2));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).line.string).will.equal(@"HiAhoy");
}

- (void)testInsertingNewLineAndSameLine {
    [dataSource appendText:@"Ahoy\n" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 2));

    [dataSource appendText:@"Ahoy" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(2);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(5, 2));
}

- (void)testOverwritesFirstLine {
    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:SPLTestLines(@"Yarr\n", 10)]];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(10);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 11));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 1, 1)];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(10);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 1));

    [dataSource appendText:@"Ahoy-hoy" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(10);
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).line.string).will.equal(@"Ahoy-hoy");
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(9, 1));
}

- (void)testOverwritingThroughLine {
    [dataSource appendText:@"Hello" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(6, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 3, 1)];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 1));

    [dataSource appendText:@"Ahoy-hoy" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).line.string).will.equal(@"HeAhoy-hoy");
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(11, 1));
}

- (void)testOverwritingWithNewLine {
    [dataSource appendText:@"Hello" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(6, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 3, 1)];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 1));

    [dataSource appendText:@"Ahoy-hoy" isUserInput:YES];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).line.string).will.equal(@"HeAhoy-hoy");
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 2));
}

- (void)testOverwritingWithinLine {
    [dataSource appendText:@"Hello-ho" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(9, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 3, 1)];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 1));

    [dataSource appendText:@"AS" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).line.string).will.equal(@"HeASo-ho");
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(5, 1));
}

- (void)testOverwritingWithinLineWithNewLine {
    [dataSource appendText:@"Hello-ho" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(9, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 3, 1)];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 1));

    [dataSource appendText:@"AS" isUserInput:YES];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).line.string).will.equal(@"HeASo-ho");
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 2));

    [dataSource appendText:@"Hey" isUserInput:YES];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(2);
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]]).line.string).will.equal(@"Hey");
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 3));
}

- (void)testInsertingNewLineMovesCursor {
    [dataSource appendText:@"Hello\n" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 2));

    [dataSource appendText:@"Hello\n" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(2);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 3));
}

- (void)testWritingNewLineClearsToEndOfLine {
    [dataSource appendText:@"Hello" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(6, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 3, 1)];
    [dataSource appendText:@"\n" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 2));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]).line.string).to.equal(@"He");
}

- (void)testWritingNewLineClearsFromStartOfLine {
    [dataSource appendText:@"Hello" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(6, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 1, 1)];
    [dataSource appendText:@"\n" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 2));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]).line.string).to.equal(@"");
}

- (void)testAppendingLineMovesCursor {
    [dataSource appendText:@"Hello\n" isUserInput:NO];
    [dataSource appendText:@"Hi" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(2);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 2));
}

#pragma mark - Cursor Position

- (void)testDefaultCursorPositioning {
    EXP_expect(dataSource.cursorPosition).to.equal(UIOffsetMake(1, 1));
}

- (void)testBlankCursorPosition {
    EXP_expect(dataSource.cursorPosition).to.equal(UIOffsetMake(1, 1));

    [dataSource appendText:@"Hello" isUserInput:NO];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(6, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 0, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 1));
}

- (void)testRedundantCursorPositioning {
    EXP_expect(dataSource.cursorPosition).to.equal(UIOffsetMake(1, 1));

    [dataSource appendText:@"Hello" isUserInput:NO];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(6, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandDisplayClear, 2, 0)];
    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 0, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 1));
}

- (void)testCursorPositionCommandMovesCursor {
    [dataSource appendText:@"Hello" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(6, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 3, 1)];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 1));
}

- (void)testCursorPositionConfinedToScreenSize {
    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 999, 999)];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(0);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, charSize.width, charSize.height)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(charSize.width, charSize.height));
}

- (void)testCapsCursorPositionValuesAtRowCount {
    [dataSource appendText:@"Hello\nHi\nHey" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(3);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(4, 3));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 1, 60)];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(3);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(4, 3));
}

- (void)testCapsCursorPositionValuesAtColumnCount {
    [dataSource appendText:@"Hello\nYo" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(2);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 2));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 600, 1)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 2));
}

- (void)testCursorPositionZero {
    [dataSource appendText:@"Hi" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 0, 0)];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 1));
}

#pragma mark - Cursor Movement

- (void)testCursorForward {
    EXP_expect(dataSource.cursorPosition).to.equal(UIOffsetMake(1, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorRight, 4, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(5, 1));
}

- (void)testSimpleTelnetModeDisablesCursorMovement {
    EXP_expect(dataSource.cursorPosition).to.equal(UIOffsetMake(1, 1));

    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kPrefSimpleTelnetMode];

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorRight, 4, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 10, 10)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 1));
}

- (void)testCursorBack {
    EXP_expect(dataSource.cursorPosition).to.equal(UIOffsetMake(1, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorLeft, 4, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorRight, 4, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(5, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorLeft, 1, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(4, 1));
}

- (void)testCursorDown {
    EXP_expect(dataSource.cursorPosition).to.equal(UIOffsetMake(1, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorDown, 4, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 5));
}

- (void)testCursorUp {
    EXP_expect(dataSource.cursorPosition).to.equal(UIOffsetMake(1, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorUp, 4, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorDown, 4, 0)];
    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorUp, 1, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 4));
}

- (void)testCursorNextLine {
    EXP_expect(dataSource.cursorPosition).to.equal(UIOffsetMake(1, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorNextLine, 4, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 5));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 4, 4)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(4, 4));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorNextLine, 1, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 5));
}

- (void)testCursorPreviousLine {
    EXP_expect(dataSource.cursorPosition).to.equal(UIOffsetMake(1, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPreviousLine, 10, 1)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 10, 10)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(10, 10));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPreviousLine, 4, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 6));
}

- (void)testCursorHorizontalAbsolute {
    EXP_expect(dataSource.cursorPosition).to.equal(UIOffsetMake(1, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorHorizontalAbsolute, 10, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(10, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorHorizontalAbsolute, 200, 10)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(10, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorHorizontalAbsolute, 4, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(4, 1));
}

#pragma mark - Erase In Line

- (void)testClearToEndOfLine {
    [dataSource appendText:@"Hello World" isUserInput:NO];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(12, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 3, 1)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandLineClear, 0, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 1));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).line.string).will.equal(@"He");
}

- (void)testClearToStartOfLine {
    [dataSource appendText:@"Hello World" isUserInput:NO];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(12, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 3, 1)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandLineClear, 1, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 1));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).line.string).will.equal(@"   lo World");
}

- (void)testClearFullLine {
    [dataSource appendText:@"Hello World" isUserInput:NO];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(12, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 3, 1)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandLineClear, 2, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 1));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).line.string).will.equal(@"");
}

#pragma mark - Position Normalizing

- (void)testCursorPositionNormalizesToBottomOfScreen {
    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:SPLTestLines(@"Hello\n", 100)]];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(100);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 101));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorUp, 10, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 91));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 30, 10)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(30, 100 - (NSUInteger)charSize.height + 10));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorNextLine, 30, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 100 - (NSUInteger)charSize.height + 40));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorDown, 400, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 101));
}

#pragma mark - Arbitrary Positioning

- (void)testCursorPositionNotConfinedToText {
    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 20, 3)];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(0);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(20, 3));
}

- (void)testInsertsLinesToMeetCursorRow {
    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 1, 20)];
    [dataSource appendText:@"Yo" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(20);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 20));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:19 inSection:0]]).line.string).will.equal(@"Yo");
}

- (void)testInsertsSpacesToMeetCursorColumn {
    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 10, 1)];
    [dataSource appendText:@"Yo" isUserInput:NO];

    EXP_expect(dataSource.numberOfItems).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(12, 1));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]]).line.string).will.equal(@"         Yo");
}

- (void)testInsertsSpacesToMeetCursorRowAndColumn {
    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 10, 10)];
    [dataSource appendText:@"Yolo" isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(10);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(14, 10));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:9 inSection:0]]).line.string).will.equal(@"         Yolo");
}

#pragma mark - User Input

- (void)testUserInputAlwaysAppendsNewLine {
    [dataSource appendText:@"Hello World " isUserInput:NO];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(13, 1));

    [dataSource appendText:@"Yarr" isUserInput:YES];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 2));

    EXP_expect(((SSAttributedLineGroupItem *)[dataSource itemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]]).line.string).to.equal(@"Hello World Yarr");
}

#pragma mark - Clearing Lines

- (void)testClearingToStartOfScreen {
    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:SPLTestLines(@"Hello\n", 10)]];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(10);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 11));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 4, 4)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(4, 4));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandDisplayClear, 1, 0)];

    EXP_expect(dataSource.numberOfItems).will.equal(10);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(4, 4));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][0]).line.string).will.equal(@"");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][1]).line.string).will.equal(@"");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][2]).line.string).will.equal(@"");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][3]).line.string).will.equal(@"    o");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][4]).line.string).will.equal(@"Hello");
}

- (void)testClearingToStartOfScreenFromFirstLine {
    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:SPLTestLines(@"Hello\n", 10)]];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(10);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 11));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 4, 1)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(4, 1));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandDisplayClear, 1, 0)];

    EXP_expect(dataSource.numberOfItems).will.equal(10);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(4, 1));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][0]).line.string).will.equal(@"    o");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][1]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][2]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][3]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][4]).line.string).will.equal(@"Hello");
}

- (void)testClearingToStartOfScreenFromOffset {
    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:SPLTestLines(@"Hello\n", 100)]];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(100);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 101));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorUp, 4, 0)];
    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorRight, 2, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 97));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandDisplayClear, 1, 0)];

    EXP_expect(dataSource.numberOfItems).will.equal(100);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 97));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][99]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][98]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][97]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][96]).line.string).will.equal(@"   lo");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][95]).line.string).will.equal(@"");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][94]).line.string).will.equal(@"");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][93]).line.string).will.equal(@"");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][92]).line.string).will.equal(@"");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][7]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][8]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][9]).line.string).will.equal(@"Hello");
}

- (void)testClearingToEndOfScreen {
    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:SPLTestLines(@"Hello\n", 10)]];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(10);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 11));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 4, 4)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(4, 4));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandDisplayClear, 0, 0)];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(4);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(4, 4));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][3]).line.string).will.equal(@"Hel");
}

- (void)testClearingToEndOfScreenFromOffset {
    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:SPLTestLines(@"Hello\n", 100)]];

    EXP_expect(dataSource.numberOfItems).will.equal(100);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 101));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorUp, 4, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 97));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorRight, 2, 0)];

    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 97));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandDisplayClear, 0, 0)];

    EXP_expect(dataSource.numberOfItems).will.equal(97);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(3, 97));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][96]).line.string).will.equal(@"He");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][95]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][94]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][93]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][92]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][91]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][90]).line.string).will.equal(@"Hello");
}

- (void)testClearingFullScreen {
    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:SPLTestLines(@"Hello\n", 10)]];

    EXP_expect(dataSource.numberOfItems).will.equal(10);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 11));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandDisplayClear, 2, 0)];

    EXP_expect(dataSource.numberOfItems).will.equal(0);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 1));
}

- (void)testClearingFullScreenFromOffset {
    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:SPLTestLines(@"Hello\n", 100)]];

    EXP_expect(dataSource.numberOfItems).will.equal(100);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 101));

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandDisplayClear, 2, 0)];

    EXP_expect(dataSource.numberOfItems).will.equal(100 - charSize.height);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 101 - charSize.height));
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][99 - (NSUInteger)charSize.height]).line.string).will.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[dataSource allItems][99 - (NSUInteger)charSize.height - 1]).line.string).will.equal(@"Hello");
}


- (void)testClearingLinesAfterLimit {
    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:
                                          SPLTestLines(@"Hello world\n", 1 + kMaxLineHistory)]];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(1 + kMaxLineHistory);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, 2 + kMaxLineHistory));

    [dataSource appendText:@"New line!" isUserInput:YES];

    EXP_expect([tableView numberOfRowsInSection:0]).will.equal(kMaxLineHistory - kLineDeleteAmount + 2);
    EXP_expect(dataSource.cursorPosition).will.equal(UIOffsetMake(1, kMaxLineHistory - kLineDeleteAmount + 3));
    EXP_expect(((SSAttributedLineGroupItem *)[[dataSource allItems] lastObject]).line.string).to.equal(@"New line!");
}

#pragma mark - Screen size

- (void)testZeroScreenSize {
    [tableView setFrame:CGRectZero];

    EXP_expect([tableView charSize]).to.equal(UIOffsetZero);
}

- (void)testNominalScreenSize {
    [tableView setFrame:CGRectMake(0, 0, 100, 20)];

    CGSize size = [tableView charSize];

    EXP_expect(size.width).to.beGreaterThanOrEqualTo(10);
    EXP_expect(size.width).to.beLessThanOrEqualTo(25);
    EXP_expect(size.height).to.beGreaterThanOrEqualTo(1);
    EXP_expect(size.height).to.beLessThanOrEqualTo(2);
}

@end
