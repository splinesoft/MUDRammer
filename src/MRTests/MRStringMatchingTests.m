//
//  MRStringMatchingTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 6/29/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "MRTestHelpers.h"
#import "NSString+SPLMatching.h"

@interface MRStringMatchingTests : XCTestCase

@end

@implementation MRStringMatchingTests

- (void)testParsesRandomNumbersInStrings {
    NSString *randString = @"#4#;#10#";

    NSArray *stringCommands = [randString spl_commandsFromUserInput];

    expect(stringCommands.count).to.equal(2);

    NSInteger firstNumber = ((NSNumber *)stringCommands.firstObject).integerValue;
    NSInteger secondNumber = ((NSNumber *)stringCommands.lastObject).integerValue;

    expect(firstNumber).to.beGreaterThanOrEqualTo(1);
    expect(firstNumber).to.beLessThanOrEqualTo(4);
    expect(secondNumber).to.beGreaterThanOrEqualTo(1);
    expect(secondNumber).to.beLessThanOrEqualTo(10);
}

- (void)testSkipsEmptyCommandsInStrings {
    NSString *commandString = @"Hello;;Hi";

    NSArray *stringCommands = [commandString spl_commandsFromUserInput];

    expect(stringCommands.count).to.equal(2);
    expect(stringCommands.firstObject).to.equal(@"Hello");
    expect(stringCommands.lastObject).to.equal(@"Hi");
}

- (void)testLocatesCommandPatternsInStrings {
    NSString *commandString = @"There once was a $1 and $2";

    NSDictionary *commandLocations = [commandString spl_commandLocationsForPattern];

    expect(commandLocations.count).to.equal(2);
    expect(commandLocations[@4]).to.equal(1);
    expect(commandLocations[@6]).to.equal(2);
}

- (void)testMatchesStringsToCommandPatterns {
    NSString *patternString = @"$1 and $2 are here";

    NSString *passingString = @"Bob and Sally are here";
    NSString *failingString = @"Charlie is here";

    expect([passingString spl_matchesPattern:patternString]).to.beTruthy();
    expect([failingString spl_matchesPattern:patternString]).to.beFalsy();
}

- (void)testGeneratesCommandsForStringsMatchingPatterns {
    NSString *patternString = @"$1 and $2 are here";
    NSString *commandString = @"greet $1 and $2";
    NSString *inputString = @"Bob and Sue are here";

    NSString *command = [patternString spl_commandForUserCommand:commandString
                                                       inputLine:inputString];

    expect(command).to.equal(@"greet Bob and Sue");
}

@end
