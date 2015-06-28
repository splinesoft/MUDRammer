//
//  MRLoggingTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/21/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#include "MRTestHelpers.h"
#import "SSSessionLogger.h"

@interface MRLoggingTests : XCTestCase

@end

@implementation MRLoggingTests
{
    NSString *logFileName;
    SSSessionLogger *logger;
}

- (void)setUp {
    [super setUp];

    logFileName = [SSSessionLogger logFileNameForHost:
                   [NSString stringWithFormat:@"test.com-%@",
                    @([NSDate timeIntervalSinceReferenceDate])]];

    logger = [SSSessionLogger new];
}

- (void)tearDown {
    [super tearDown];

    [logger closeStreamForFileName:logFileName];
}

- (void)testLogsSimpleText {
    [logger appendText:@"Hello world" toFileWithName:logFileName];

    expect([SSSessionLogger contentsOfLogWithFileName:logFileName]).will.equal(@"Hello world");
}

- (void)testLogsSpecialCharacters {
    [logger appendText:@"<Hello> world\nHi" toFileWithName:logFileName];

    expect([SSSessionLogger contentsOfLogWithFileName:logFileName]).will.equal(@"<Hello> world\nHi");
}

- (void)testLogsSpecialCharactersExtended {
    [logger appendText:@"<<Hello>> world\nHi\nHey>> Test" toFileWithName:logFileName];

    expect([SSSessionLogger contentsOfLogWithFileName:logFileName]).will
    .equal(@"<<Hello>> world\nHi\nHey>> Test");
}

- (void)testLogsSeveralLines {
    [logger appendText:@"Hello world" toFileWithName:logFileName];
    [logger appendText:@"Hello world" toFileWithName:logFileName];
    [logger appendText:@"\nHello world" toFileWithName:logFileName];

    expect([SSSessionLogger contentsOfLogWithFileName:logFileName]).will.equal(@"Hello worldHello world\nHello world");
    expect([SSSessionLogger contentsOfLogWithFileName:logFileName]).will.equal(@"Hello worldHello world\nHello world");
}

@end
