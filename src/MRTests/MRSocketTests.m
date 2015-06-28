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
    sut = [[SSMUDSocket alloc] initWithSocket:socket
                                     delegate:(id <SSMUDSocketDelegate>)mockSocketDelegate];
}

- (void)tearDown {
    sut.SSdelegate = nil;
    sut.socket.delegate = nil;
    [sut.socket disconnect];
    sut = nil;

    socket = nil;
    mockSocketDelegate = nil;

    [super tearDown];
}

- (void)testSocketInitialSetup {
    expect(sut.socket.delegate).to.equal(sut);
    expect(sut.SSdelegate).to.equal(mockSocketDelegate);
}

- (void)testSocketConnectSendsConnectAndSSLCheck {
    NSError *err;

    [[mockSocketDelegate expect] mudsocketDidConnectToHost:sut];
    [[mockSocketDelegate expect] mudsocketShouldAttemptSSL:sut];

    BOOL connected = [sut.socket connectToHost:@"discworld.starturtle.net"
                                        onPort:23
                                   withTimeout:30
                                         error:&err];

    expect(connected).to.beTruthy();
    expect(err).to.beNil();

    [mockSocketDelegate verifyWithDelay:3];
}

- (void)testSocketDisconnectSendsDisconnect {
    NSError *err;

    [[mockSocketDelegate expect] mudsocket:sut didDisconnectWithError:OCMOCK_ANY];

    BOOL connected = [sut.socket connectToHost:@"discworld.starturtle.net"
                                        onPort:23
                                   withTimeout:30
                                         error:&err];

    expect(connected).to.beTruthy();
    expect(err).to.beNil();

    [sut.socket disconnect];

    [mockSocketDelegate verifyWithDelay:3];
}

- (void)testSocketParsesAttributedLines {
    NSError *err;

    [[mockSocketDelegate expect] mudsocket:sut
             didReceiveAttributedLineGroup:[OCMArg checkWithBlock:^BOOL(id object) {

        return [object isKindOfClass:[SSAttributedLineGroup class]]
            && [((SSAttributedLineGroup *)object).textLines count] > 0;
    }]];

    BOOL connected = [sut.socket connectToHost:@"discworld.starturtle.net"
                                        onPort:23
                                   withTimeout:30
                                         error:&err];

    expect(connected).to.beTruthy();
    expect(err).to.beNil();

    [mockSocketDelegate verifyWithDelay:3];
}

- (void)testSocketParsesMSSPResponse {
    NSError *err;

    [[mockSocketDelegate expect] mudsocket:sut
                          receivedMSSPData:[OCMArg checkWithBlock:^BOOL(id object) {

        return [object isKindOfClass:[NSDictionary class]]
            && [(NSDictionary *)object count] > 0;
    }]];

    BOOL connected = [sut.socket connectToHost:@"discworld.starturtle.net"
                                        onPort:23
                                   withTimeout:30
                                         error:&err];

    expect(connected).to.beTruthy();
    expect(err).to.beNil();

    [mockSocketDelegate verifyWithDelay:3];
}

@end
