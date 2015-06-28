//
//  MREncodingTests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/26/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "MRTestHelpers.h"
#import "SSStringCoder.h"

@interface MREncodingTests : XCTestCase

@end

@implementation MREncodingTests
{
    SSStringCoder *sut;
    SSStringEncoding *asciiCoding;
    NSString *testStr;
    NSData *testData;
}

- (void)setUp {
    [super setUp];
    sut = [SSStringCoder new];
    asciiCoding = [sut encodingFromLocalizedEncodingName:@"ASCII"];
    testStr = @"Hello World";
    testData = [testStr dataUsingEncoding:NSASCIIStringEncoding];
}

- (void)tearDown {
    [super tearDown];
    sut = nil;
}

- (void)testHasDefaultEncodings {
    expect(sut.encodings.count).to.beGreaterThan(0);
    expect(asciiCoding).toNot.beNil();
}

- (void)testDefaultsToASCII {
    expect(sut.currentStringEncoding).to.equal(asciiCoding);
}

- (void)testDecodesASCIIString {
    expect([sut stringByDecodingDataWithCurrentEncoding:testData]).to.equal(testStr);
}

- (void)testEncodesASCIIString {
    expect([sut dataByEncodingStringWithCurrentEncoding:testStr]).to.equal(testData);
}

- (void)testUserCommandData {
    NSData *data = [@"Hello\r\nHi\r\n" dataUsingEncoding:NSASCIIStringEncoding];
    expect([sut dataForUserCommands:@[ @"Hello", @"Hi" ]]).to.equal(data);
}

@end
