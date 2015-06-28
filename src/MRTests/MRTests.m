//
//  MRTests.m
//  MRTests
//
//  Created by Jonathan Hersh on 6/1/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "MRTestHelpers.h"
#import "Mudrammer-Prefix.pch"
#import "JSQSystemSoundPlayer+SSAdditions.h"
#import "SPLImagesCatalog.h"
#import "NSScanner+SPLAdditions.h"
#import "NSMutableIndexSet+SPLAdditions.h"

@interface MRTests : XCTestCase

@end

@implementation MRTests

- (void)setUp
{
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown
{
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testSoundFetch
{
    NSArray *sounds = [JSQSystemSoundPlayer allSounds];

    XCTAssertNotNil(sounds, @"Should have some sounds");
    XCTAssertTrue([sounds count] > 0, @"Should have some sounds");
}

- (void)testImageCatalog
{
    XCTAssertNotNil([SPLImagesCatalog settingsImage], @"Should have catalog images");
}

- (void)testApplicationExtras
{
    XCTAssertNotNil([UIApplication applicationCopyright], @"Should have copyright");
    XCTAssertNotNil([UIApplication applicationExtras], @"Should have extras");
    XCTAssertNotNil([UIApplication applicationFullAbout], @"Should have full about");
}

#pragma mark - NSMutableIndexSet

- (void)testIndexSetNonShift {
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 10)];
    NSIndexSet *deletedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(12, 3)];

    [indexes spl_shiftIndexesWithDeletedIndexes:deletedIndexes];

    expect(indexes.count).to.equal(10);
    expect(indexes.firstIndex).to.equal(0);
    expect(indexes.lastIndex).to.equal(9);
}

- (void)testIndexSetSingleShift {
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(3, 10)];
    NSIndexSet *deletedIndexes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];

    [indexes spl_shiftIndexesWithDeletedIndexes:deletedIndexes];

    expect(indexes.count).to.equal(10);
    expect(indexes.firstIndex).to.equal(1);
    expect(indexes.lastIndex).to.equal(10);
}

- (void)testIndexSetPartialShift {
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(3, 10)];
    NSMutableIndexSet *deletedIndexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)];
    [deletedIndexes addIndex:7];
    [deletedIndexes addIndex:12];

    [indexes spl_shiftIndexesWithDeletedIndexes:deletedIndexes];

    expect(indexes.count).to.equal(10);
    expect(indexes.firstIndex).to.equal(1);
    expect(indexes.lastIndex).to.equal(10);
}

#pragma mark - NSScanner

- (void) testScannerScansNULLCharacter {
    NSScanner *scanner = [NSScanner scannerWithString:@"Hello"];
    BOOL scanned = [scanner SPLScanCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]
                                         intoString:NULL];

    expect(scanned).to.beTruthy();
    expect(scanner.scanLocation).to.equal(1);
}

- (void) testScannerScansSingleCharacter {
    NSScanner *scanner = [NSScanner scannerWithString:@"Hello"];
    NSString *character;
    BOOL scanned = [scanner SPLScanCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]
                                         intoString:&character];

    expect(scanned).to.beTruthy();
    expect(scanner.scanLocation).to.equal(1);
    expect(character).to.equal(@"H");
}

- (void) testScannerScansNotFoundCharacter {
    NSScanner *scanner = [NSScanner scannerWithString:@"Hello"];
    NSString *character;
    BOOL scanned = [scanner SPLScanCharacterFromSet:[NSCharacterSet whitespaceCharacterSet]
                                         intoString:&character];

    expect(scanned).to.beFalsy();
    expect(scanner.scanLocation).to.equal(0);
    expect(character).to.beNil();
}

@end
