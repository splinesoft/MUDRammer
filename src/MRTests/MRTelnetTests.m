//
//  MRTelnetTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 6/5/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SPLTelnetLib.h"
#import "SSStringCoder.h"
#import "SSMRConstants.h"
#import "libtelnet.h"

@interface MRTelnetTests : XCTestCase

@end

@implementation MRTelnetTests
{
    SPLTelnetLib *sut;
    OCMockObject *stringCoderMock;
    OCMockObject *telnetDelegateMock;
}

- (void)setUp {
    [super setUp];

    stringCoderMock = OCMClassMock([SSStringCoder class]);
    telnetDelegateMock = OCMProtocolMock(@protocol(SPLTelnetLibDelegate));
    sut = [[SPLTelnetLib alloc] initWithDelegate:(id <SPLTelnetLibDelegate>)telnetDelegateMock
                                     stringCoder:(SSStringCoder *)stringCoderMock];

    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kPrefSimpleTelnetMode];
}

- (void)tearDown {
    sut.delegate = nil;
    sut = nil;

    [super tearDown];
}

- (void)testEchoesTextByDefault {
    expect(sut.shouldEchoText).to.beTruthy();
}

- (void)testConnectingSendsInitialOptions {
    for (NSUInteger i = 0; i < 3; i++) {
        [[telnetDelegateMock expect] telnetLibrary:sut mustSendData:OCMOCK_ANY];
    }

    [sut socketDidConnect];

    [telnetDelegateMock verifyWithDelay:1];
}

- (void)testReceivingDataParsesToString {
    NSString *testStr = @"Hello World";

    [[telnetDelegateMock expect] telnetLibrary:sut shouldPrintString:testStr];
    OCMStub([(SSStringCoder *)stringCoderMock stringByDecodingDataWithCurrentEncoding:OCMOCK_ANY]).andReturn(testStr);

    [sut receivedSocketData:[testStr dataUsingEncoding:NSUTF8StringEncoding]];

    [telnetDelegateMock verifyWithDelay:1];
}

- (void)testSendingCommandsForwardsDataToSocket {
    NSString *testStr = @"Yo Dawg";
    NSData *testData = [testStr dataUsingEncoding:NSASCIIStringEncoding];

    [[telnetDelegateMock expect] telnetLibrary:sut mustSendData:testData];
    OCMStub([(SSStringCoder *)stringCoderMock dataForUserCommands:OCMOCK_ANY]).andReturn(testData);

    [sut sendUserCommands:@[ testStr ]];

    [telnetDelegateMock verifyWithDelay:1];
}

- (void)testNAWSSendsSocketData {
    [[telnetDelegateMock expect] telnetLibrary:sut mustSendData:OCMOCK_ANY];

    [sut sendNAWSWithSize:CGSizeMake(80, 80)];

    [telnetDelegateMock verifyWithDelay:1];
}

- (void)testReceivingEchoCommandChangesEchoStatus {
    expect(sut.shouldEchoText).to.beTruthy();

    [[telnetDelegateMock reject] telnetLibrary:sut shouldPrintString:OCMOCK_ANY];

    unsigned char onBytes[] = { TELNET_IAC, TELNET_WILL, TELNET_TELOPT_ECHO };
    NSData *onData = [NSData dataWithBytes:onBytes length:3];

    [sut receivedSocketData:onData];

    expect(sut.shouldEchoText).to.beFalsy();

    unsigned char offBytes[] = { TELNET_IAC, TELNET_WONT, TELNET_TELOPT_ECHO };
    NSData *offData = [NSData dataWithBytes:offBytes length:3];

    [sut receivedSocketData:offData];

    expect(sut.shouldEchoText).to.beTruthy();
    [telnetDelegateMock verify];
}

- (void)testReceivingTTYPECommandSendsTTYPE {
    unsigned char ttBytes[] = { TELNET_IAC, TELNET_DO, TELNET_TELOPT_TTYPE };
    NSData *ttData = [NSData dataWithBytes:ttBytes length:3];

    [[telnetDelegateMock expect] telnetLibrary:sut mustSendData:OCMOCK_ANY];
    [[telnetDelegateMock reject] telnetLibrary:sut shouldPrintString:OCMOCK_ANY];

    [sut receivedSocketData:ttData];

    [telnetDelegateMock verifyWithDelay:1];
}

@end
