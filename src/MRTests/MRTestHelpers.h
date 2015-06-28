//
//  MRTestHelpers.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/8/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

#pragma once

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import <Expecta.h>
#import <OCMock.h>
#import "SSANSIEngine.h"
#import "SSAttributedLineGroup.h"
#import <TTTAttributedLabel.h>
#import "NSData+SPLDataParsing.h"
#import "World.h"
#import "Ticker.h"
#import "Trigger.h"
#import "Gag.h"
#import "Alias.h"
#import <SPLCore.h>
#import <MagicalRecord.h>
@import CoreText;

#define kDefaultColor [UIColor whiteColor]
#define kDefaultFont  [UIFont fontWithName:@"Menlo" size:13]

CG_INLINE NSAttributedString * SPLTestStringWithStringAndColorAndFont(NSString *string, UIColor *color, UIFont *font) {
    return [[NSAttributedString alloc] initWithString:string
                                           attributes:@{
                                                        (id)kCTForegroundColorAttributeName : (id)color.CGColor,
                                                        NSFontAttributeName : font,
                                                        NSKernAttributeName : [NSNull null]
                                                        }];
};

CG_INLINE NSAttributedString * SPLTestStringWithStringAndColor(NSString *string, UIColor *color) {
    return SPLTestStringWithStringAndColorAndFont(string, color, kDefaultFont);
};

CG_INLINE NSAttributedString * SPLTestStringWithString(NSString *string) {
    return SPLTestStringWithStringAndColor(string, kDefaultColor);
};

CG_INLINE SSAttributedLineGroupItem * SPLItemWithString(NSAttributedString *string) {
    return [SSAttributedLineGroupItem itemWithAttributedString:string];
};

CG_INLINE SSAttributedLineGroup * SPLLineGroupWithString(NSString *string) {
    return [SSAttributedLineGroup lineGroupWithAttributedString:SPLTestStringWithString(string)];
}

CG_INLINE SSAttributedLineGroup * SPLLineGroupWithCommand(SSLineGroupCommandType command, NSUInteger a, NSUInteger b) {
    return [SSAttributedLineGroup lineGroupWithItems:
            @[
                [SSAttributedLineGroupItem itemWithCommand:
                 [[SSLineGroupCommand alloc] initWithCommand:command number1:a number2:b]]
            ]];
}

CG_INLINE NSArray * SPLTestLines(NSString *testString, NSUInteger numberOfLines) {
    NSMutableArray *items = [NSMutableArray array];

    for (NSUInteger i = 0; i < numberOfLines; i++) {
        [items addObject:SPLItemWithString(SPLTestStringWithString(testString))];
    }

    return items;
};

CG_INLINE void SPLArtificialTestDelay(NSTimeInterval delay, dispatch_block_t completion) {
    __block BOOL testFinished = NO;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (completion) {
            completion();
        }

        testFinished = YES;
    });

    while(testFinished == NO) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode
                                 beforeDate:[NSDate distantFuture]];
    }
};
