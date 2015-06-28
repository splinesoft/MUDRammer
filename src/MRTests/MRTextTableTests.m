//
//  MRTextTableTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/17/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

#import "MRTestHelpers.h"
#import <SPLTerminalDataSource.h>
#import <SSTextTableView.h>

@interface MRTextTableTests : XCTestCase

@end

@implementation MRTextTableTests
{
    SPLTerminalDataSource *dataSource;
    OCMockObject *tableMock;
}

- (void)setUp {
    [super setUp];

    dataSource = [[SPLTerminalDataSource alloc] initWithItems:nil];
    tableMock = [OCMockObject niceMockForClass:[SSTextTableView class]];
    dataSource.tableView = (UITableView *)tableMock;
}

- (void)testMultipleTextLinesAreSingleInsert {
    NSArray *lines = SPLTestLines(@"Hello world\n", 10);

    [[tableMock expect] insertRowsAtIndexPaths:[SPLTerminalDataSource indexPathArrayWithRange:NSMakeRange(0, 10) inSection:0]
                              withRowAnimation:dataSource.rowAnimation];

    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:lines]];

    [tableMock verifyWithDelay:0.5];
}

//- (void)testAppendIsInsertAndReload {
//    [[tableMock expect] insertRowsAtIndexPaths:[SPLTerminalDataSource indexPathArrayWithRange:NSMakeRange(0, 11) inSection:0]
//                              withRowAnimation:dataSource.rowAnimation];
//
//    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:SPLTestLines(@"Hello world\n", 10)]];
//    [dataSource appendAttributedLineGroup:SPLLineGroupWithString(@"Yo")];
//
//    [tableMock verifyWithDelay:3];
//
//    [[tableMock expect] reloadRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:10 inSection:0] ]
//                              withRowAnimation:dataSource.rowAnimation];
//
//    [dataSource appendAttributedLineGroup:SPLLineGroupWithString(@"Hello")];
//
//    [tableMock verifyWithDelay:3];
//}

- (void)testOverwriteIsSingleReload {

    [[tableMock expect] insertRowsAtIndexPaths:[SPLTerminalDataSource indexPathArrayWithRange:NSMakeRange(0, 10) inSection:0]
                              withRowAnimation:dataSource.rowAnimation];

    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:SPLTestLines(@"Hello World\n", 10)]];
    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandCursorPosition, 1, 1)];

    [tableMock verifyWithDelay:0.5];

    [[tableMock expect] reloadRowsAtIndexPaths:[SPLTerminalDataSource indexPathArrayWithRange:NSMakeRange(0, 10) inSection:0]
                              withRowAnimation:dataSource.rowAnimation];

    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:SPLTestLines(@"Hello world\n", 10)]];

    [tableMock verifyWithDelay:0.5];
}

- (void)testClearingTableDeletesRows {

    [[tableMock expect] insertRowsAtIndexPaths:[SPLTerminalDataSource indexPathArrayWithRange:NSMakeRange(0, 1) inSection:0]
                              withRowAnimation:dataSource.rowAnimation];

    [dataSource appendAttributedLineGroup:[SSAttributedLineGroup lineGroupWithItems:SPLTestLines(@"Hello World\n", 1)]];

    [tableMock verifyWithDelay:0.5];
    expect(dataSource.cursorPosition).to.equal(UIOffsetMake(1, 2));

    [[tableMock expect] deleteRowsAtIndexPaths:[SPLTerminalDataSource indexPathArrayWithRange:NSMakeRange(0, 1) inSection:0]
                              withRowAnimation:dataSource.rowAnimation];

    [dataSource appendAttributedLineGroup:SPLLineGroupWithCommand(SSLineGroupCommandDisplayClear, 2, 0)];

    [tableMock verifyWithDelay:0.5];
}

@end
