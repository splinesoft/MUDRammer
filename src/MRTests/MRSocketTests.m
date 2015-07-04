//
//  MRSocketTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 6/6/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SSMUDSocket.h"

@interface MRSocketTests : XCTestCase

@end

@implementation MRSocketTests
{
    SSMUDSocket *sut;
    GCDAsyncSocket *socket;
    OCMockObject *mockSocketDelegate;
}

- (void)setUp {
    [super setUp];

    socket = [GCDAsyncSocket new];
    mockSocketDelegate = OCMProtocolMock(@protocol(SSMUDSocketDelegate));
    sut = [[SSMUDSocket alloc] initWithSocket:socket];
    sut.delegate = (id <SSMUDSocketDelegate>)mockSocketDelegate;
}

- (void)tearDown {
    sut.delegate = nil;
    socket.delegate = nil;
    [socket disconnect];
    sut = nil;

    socket = nil;
    mockSocketDelegate = nil;

    [super tearDown];
}

- (void)testSocketInitialSetup {
    expect(socket.delegate).to.equal(sut);
    expect(sut.delegate).to.equal(mockSocketDelegate);
}

- (void)testSocketConnectSendsConnectAndSSLCheck {
    [[mockSocketDelegate expect] mudsocketDidConnectToHost:sut];
    [[mockSocketDelegate expect] mudsocketShouldAttemptSSL:sut];
    
    [sut socket:socket didConnectToHost:@"nanvaent.org" port:23];
    [sut socket:socket didReadData:[@"Hello" dataUsingEncoding:NSUTF8StringEncoding] withTag:0];

    [mockSocketDelegate verifyWithDelay:3];
}

- (void)testSocketDisconnectSendsDisconnect {
    [[mockSocketDelegate expect] mudsocket:sut didDisconnectWithError:OCMOCK_ANY];

    [sut socketDidDisconnect:socket withError:[NSError errorWithDomain:@"test" code:12 userInfo:nil]];

    [mockSocketDelegate verifyWithDelay:3];
}

- (void)testSocketParsesAttributedLines {
    [[mockSocketDelegate expect] mudsocket:sut
             didReceiveAttributedLineGroup:[OCMArg checkWithBlock:^BOOL(id object) {

        return [object isKindOfClass:[SSAttributedLineGroup class]]
            && [((SSAttributedLineGroup *)object).textLines count] > 0;
    }]];

    [sut socket:socket didConnectToHost:@"world" port:23];
    [sut socket:socket didReadData:[@"Hello world" dataUsingEncoding:NSASCIIStringEncoding] withTag:0];

    [mockSocketDelegate verifyWithDelay:3];
}

@end
