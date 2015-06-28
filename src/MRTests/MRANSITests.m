//
//  MRANSITests.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/7/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

#import "MRTestHelpers.h"

/* Achaea

 Rapture Runtime Environment v2.3.7 -- (c) 2014 -- Iron Realms Entertainment

 Multi-User License: 100-0000-000



 \033[0;37m           \e[34m******************************************\e[37m

 [32mAchaea, Dreams of Divine Lands[37m

 [36m"Your fate and fame shall be
 an echo and a light unto eternity."

 [34m******************************************[37m

 Achaea's IP address is 69.65.42.198
 For general questions e-mail support@achaea.com.
 162 adventurers are currently in the realms.

 [32m1.[37m Enter the game.
 [32m2.[37m Create a new character.
 [32m3.[37m Quit.

 Enter an option or enter your character's name.

 */

/*
 [30;40m [0m
 [30;40m [0m
 [47m                                   [0m[40m [0m
 [47m [0m[7;1;30;40m          (8BIT MUSH)            [0m[47m [0m[40m [0m
 [47m [0m[7;1;30m   [0m[1;37;40m| [0m[7;1;30m                  [0m[47m    [0m[7;1;30m [0m[47m    [0m[7;1;30m [0m[47m [0m[40m [0m
 [47m [0m[7;1;30m [0m[1;37;40m|_   _[0m[7;1;30;47m  select start  [0m[47m [0m[7;1;31m  [0m[47m [0m[7;1;30m [0m[47m [0m[7;1;31m  [0m[47m [0m[7;1;30m [0m[47m [0m[40m [0m
 [47m [0m[7;1;30m   [0m[1;37;40m| [0m[7;1;30;40m    [0m[7;1;30;47m  ==    ==    [0m[47m    [0m[7;1;30m [0m[47m    [0m[7;1;30m [0m[47m [0m[40m [0m
 [47m [0m[7;1;30;41m                          B    A [0m[37;47m [0m[30;40m [0m
 [1;30;47m           A Social MUSH           [0m

 > Type '[32mcreate[0m' to create a new character.
 > Type '[32mconnect[0m' to connect to an existing character.

 */

@interface MRANSITests : XCTestCase

@end

@implementation MRANSITests
{
    SSANSIEngine *engine;
    SSAttributedLineGroup *lineGroup;
    NSString *testString;
}

- (void)setUp {
    [super setUp];

    engine = [SSANSIEngine new];
    engine.defaultTextColor = kDefaultColor;
    engine.defaultFont = kDefaultFont;
}

- (void)testSimpleString {
    testString = @"Hello World";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(1);
    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Hello World")));
}

- (void)testCollapsesNewlines {
    testString = @"Hello\n\rWorld";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(2);
    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Hello\n")));
    EXP_expect([lineGroup.lines lastObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"World")));

    testString = @"Hello\r\nWorld";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(2);
    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Hello\n")));
    EXP_expect([lineGroup.lines lastObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"World")));

    testString = @"Hello\r\n\r\nWorld";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(3);
    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Hello\n")));
    EXP_expect(lineGroup.lines[1]).to.equal([SSAttributedLineGroupItem itemWithBlankLine]);
    EXP_expect([lineGroup.lines lastObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"World")));

    testString = @"Hello\n\r\n\rWorld";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(3);
    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Hello\n")));
    EXP_expect(lineGroup.lines[1]).to.equal([SSAttributedLineGroupItem itemWithBlankLine]);
    EXP_expect([lineGroup.lines lastObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"World")));
}

- (void)testLineItemsDetectTrailingNewlines {
    testString = @"Hello";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(1);
    EXP_expect(((SSAttributedLineGroupItem *)lineGroup.lines[0]).endsInNewLine).to.beFalsy();

    testString = @"Hello\nHi";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(2);
    EXP_expect(((SSAttributedLineGroupItem *)lineGroup.lines[0]).endsInNewLine).to.beTruthy();
    EXP_expect([lineGroup.lines lastObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Hi")));
    EXP_expect(((SSAttributedLineGroupItem *)lineGroup.lines[1]).endsInNewLine).to.beFalsy();
}

- (void)testAddsBlankLines {
    testString = @"Hello\n\nWorld";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(3);
    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Hello\n")));
    EXP_expect(lineGroup.lines[1]).to.equal([SSAttributedLineGroupItem itemWithBlankLine]);
    EXP_expect([lineGroup.lines lastObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"World")));

    testString = @"Hello\n\n\n";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(3);
    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Hello\n")));
    EXP_expect(lineGroup.lines[1]).to.equal([SSAttributedLineGroupItem itemWithBlankLine]);
    EXP_expect(lineGroup.lines[2]).to.equal([SSAttributedLineGroupItem itemWithBlankLine]);
}

- (void)testSimpleReset {
    testString = @"\033[31mHe\033[mllo";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(1);

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:SPLTestStringWithString(@"Hello")];
    [string addAttributes:@{
                            (id)kCTForegroundColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeFgRed defaultColor:kDefaultColor].CGColor
    } range:NSMakeRange(0, 2)];

    EXP_expect(SPLItemWithString(string)).to.equal(lineGroup.lines.firstObject);
}

- (void)testStandardReset {
    testString = @"\033[31mHe\033[0mllo";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(1);

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:SPLTestStringWithString(@"Hello")];
    [string addAttributes:@{
                            (id)kCTForegroundColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeFgRed defaultColor:kDefaultColor].CGColor
                            } range:NSMakeRange(0, 2)];

    EXP_expect(SPLItemWithString(string)).to.equal(lineGroup.lines.firstObject);
}

- (void)testRespectsTrailingNewLine {
    testString = @"Hello\n";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(1);
    EXP_expect(((SSAttributedLineGroupItem *)lineGroup.lines[0]).endsInNewLine).to.beTruthy();

    testString = @"Hello";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(1);
    EXP_expect(((SSAttributedLineGroupItem *)lineGroup.lines[0]).endsInNewLine).to.beFalsy();
}

- (void)testMaintainsSpacing {
    testString = @"    Hello World\n\n   Hello";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(3);
    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(SPLTestStringWithString(@"    Hello World\n")));
    EXP_expect(lineGroup.lines[1]).to.equal(SPLItemWithString(SPLTestStringWithString(@"\n")));
    EXP_expect(lineGroup.lines[2]).to.equal(SPLItemWithString(SPLTestStringWithString(@"   Hello")));
}

- (void)testSimpleColoredString {
    testString = @"\033[0;36mHello World\033[mhi";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(1);
    EXP_expect(((SSAttributedLineGroupItem *)[lineGroup.lines firstObject]).line.string).to.equal(@"Hello Worldhi");

    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:SPLTestStringWithStringAndColor(@"Hello Worldhi", [UIColor colorForSGRCode:SPLSGRCodeFgCyan
                                                                                                                                                               defaultColor:nil])];
    [str addAttributes:@{
         (id)kCTForegroundColorAttributeName : (id)kDefaultColor.CGColor
                         } range:NSMakeRange(11, 2)];

    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(str));
}

- (void)testMultiLineColoredString {
    testString = @"\033[0;36mHello\nWorld\nAnd All\033[m\nDe";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(4);
    EXP_expect(((SSAttributedLineGroupItem *)lineGroup.lines[0]).line.string).to.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)lineGroup.lines[1]).line.string).to.equal(@"World");
    EXP_expect(((SSAttributedLineGroupItem *)lineGroup.lines[2]).line.string).to.equal(@"And All");
    EXP_expect(((SSAttributedLineGroupItem *)lineGroup.lines[3]).line.string).to.equal(@"De");

    EXP_expect(lineGroup.lines[0]).to.equal(SPLItemWithString(SPLTestStringWithStringAndColor(@"Hello\n", [UIColor colorForSGRCode:SPLSGRCodeFgCyan
                                                                                                                               defaultColor:nil])));
    EXP_expect(lineGroup.lines[1]).to.equal(SPLItemWithString(SPLTestStringWithStringAndColor(@"World\n", [UIColor colorForSGRCode:SPLSGRCodeFgCyan
                                                                                                                              defaultColor:nil])));
    EXP_expect(lineGroup.lines[2]).to.equal(SPLItemWithString(SPLTestStringWithStringAndColor(@"And All\n", [UIColor colorForSGRCode:SPLSGRCodeFgCyan
                                                                                                                    defaultColor:nil])));
    EXP_expect(lineGroup.lines[3]).to.equal(SPLItemWithString(SPLTestStringWithStringAndColor(@"De", kDefaultColor)));
}

- (void)testMultiLineMultiColoredString {
    testString = @"\033[0;36mHello\nWor\033[35mld\033[m";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(2);
    EXP_expect(((SSAttributedLineGroupItem *)[lineGroup.lines firstObject]).line.string).to.equal(@"Hello");
    EXP_expect(((SSAttributedLineGroupItem *)[lineGroup.lines lastObject]).line.string).to.equal(@"World");

    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(SPLTestStringWithStringAndColor(@"Hello\n", [UIColor colorForSGRCode:SPLSGRCodeFgCyan
                                                                                                                               defaultColor:nil])));

    NSMutableAttributedString *secondLine = [[NSMutableAttributedString alloc] initWithAttributedString:
                                             SPLTestStringWithStringAndColor(@"World", [UIColor colorForSGRCode:SPLSGRCodeFgCyan
                                                                                                   defaultColor:nil])];

    [secondLine addAttributes:@{
                                (id)kCTForegroundColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeFgMagenta
                                                                                      defaultColor:nil].CGColor,
                        }
                        range:NSMakeRange(3, 2)];

    EXP_expect([lineGroup.lines lastObject]).to.equal(SPLItemWithString(secondLine));
}

- (void)testSimpleBackgroundColor {
    testString = @"\033[41mTest \033[36mBackground\033[m";

    lineGroup = [engine parseANSIString:testString];

    SSAttributedLineGroupItem *item = [lineGroup.lines firstObject];

    EXP_expect([lineGroup.lines count]).to.equal(1);
    EXP_expect(item.line.string).to.equal(@"Test Background");

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:SPLTestStringWithString(@"Test Background")];
    [string addAttributes:@{
                            kTTTBackgroundFillColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeBgRed
                                                                               defaultColor:nil].CGColor,
                            kTTTBackgroundStrokeColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeBgRed
                                                                                 defaultColor:nil].CGColor
                            }
                    range:NSMakeRange(0, string.length)];
    [string addAttributes:@{
                            (id)kCTForegroundColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeFgCyan defaultColor:nil].CGColor,
                            } range:NSMakeRange(5, 10)];

    EXP_expect(item).to.equal(SPLItemWithString(string));
}

- (void)testMultilineBackgroundColor {
    testString = @"\033[41mTest \033[36mBack\nground\033[m";

    lineGroup = [engine parseANSIString:testString];

    SSAttributedLineGroupItem *item1 = [lineGroup.lines firstObject];
    SSAttributedLineGroupItem *item2 = [lineGroup.lines lastObject];

    EXP_expect([lineGroup.lines count]).to.equal(2);
    EXP_expect(item1.line.string).to.equal(@"Test Back");
    EXP_expect(item2.line.string).to.equal(@"ground");

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:SPLTestStringWithString(@"Test Back\n")];
    [string addAttributes:@{
                            kTTTBackgroundFillColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeBgRed
                                                                                   defaultColor:nil].CGColor,
                            kTTTBackgroundStrokeColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeBgRed
                                                                                     defaultColor:nil].CGColor
                            }
                    range:NSMakeRange(0, string.length)];
    [string addAttributes:@{
                            (id)kCTForegroundColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeFgCyan defaultColor:nil].CGColor,
                            } range:NSMakeRange(5, 4)];

    EXP_expect(item1).to.equal(SPLItemWithString(string));

    NSAttributedString *string2 = [[NSAttributedString alloc] initWithString:@"ground"
                                                                  attributes:@{
                                                                               (id)kCTForegroundColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeFgCyan defaultColor:nil].CGColor,
                                                                               NSFontAttributeName : kDefaultFont,
                                                                               NSKernAttributeName : [NSNull null],
                                                                               kTTTBackgroundFillColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeBgRed
                                                                                                                                      defaultColor:nil].CGColor,
                                                                               kTTTBackgroundStrokeColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeBgRed
                                                                                                                                        defaultColor:nil].CGColor
                                                                }];

    EXP_expect(item2).to.equal(SPLItemWithString(string2));
}

- (void)testStrikethroughText {
    testString = @"\033[45;9mTest Strike\033[m";

    lineGroup = [engine parseANSIString:testString];

    SSAttributedLineGroupItem *item = [lineGroup.lines firstObject];

    EXP_expect(@"Test Strike").to.equal(item.line.string);

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:SPLTestStringWithStringAndColor(@"Test Strike", kDefaultColor)];
    [string addAttributes:@{
                            kTTTStrikeOutAttributeName : @1,
                            kTTTBackgroundFillColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeBgMagenta
                                                                                   defaultColor:nil].CGColor,
                            kTTTBackgroundStrokeColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeBgMagenta
                                                                                     defaultColor:nil].CGColor
    } range:NSMakeRange(0, string.length)];

    EXP_expect(item).to.equal(SPLItemWithString(string));
}

- (void)testUnderlinedText {
    testString = @"\033[45;4mTest Under\033[m";

    lineGroup = [engine parseANSIString:testString];

    SSAttributedLineGroupItem *item = [lineGroup.lines firstObject];

    EXP_expect(@"Test Under").to.equal(item.line.string);

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:SPLTestStringWithStringAndColor(@"Test Under", kDefaultColor)];
    [string addAttributes:@{
                            NSUnderlineStyleAttributeName : @1,
                            kTTTBackgroundFillColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeBgMagenta
                                                                                   defaultColor:nil].CGColor,
                            kTTTBackgroundStrokeColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeBgMagenta
                                                                                     defaultColor:nil].CGColor
                            } range:NSMakeRange(0, string.length)];

    EXP_expect(SPLItemWithString(string)).to.equal(item);
}

- (void)testReverseText {
    testString = @"\033[7;1;30;40m (8BIT MUSH) \033[0m";

    lineGroup = [engine parseANSIString:testString];

    SSAttributedLineGroupItem *item = [lineGroup.lines firstObject];

    EXP_expect(@" (8BIT MUSH) ").to.equal(item.line.string);

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:SPLTestStringWithString(@" (8BIT MUSH) ")];
    [string addAttributes:@{
                            kTTTBackgroundFillColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeFgBrightBlack defaultColor:kDefaultColor].CGColor,
                            kTTTBackgroundStrokeColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeFgBrightBlack defaultColor:kDefaultColor].CGColor
    } range:NSMakeRange(0, string.length)];

    EXP_expect(SPLItemWithString(string)).to.equal(item);
}

- (void)testDarkensForegroundWhenIdentical {
    testString = @"\033[31m\033[7;31m (8BIT MUSH) \033[0m";

    lineGroup = [engine parseANSIString:testString];

    SSAttributedLineGroupItem *item = [lineGroup.lines firstObject];

    EXP_expect(@" (8BIT MUSH) ").to.equal(item.line.string);

    NSMutableAttributedString *string = [[NSMutableAttributedString alloc] initWithAttributedString:SPLTestStringWithString(@" (8BIT MUSH) ")];
    [string addAttributes:@{
                            (id)kCTForegroundColorAttributeName : (id)[[UIColor colorForSGRCode:SPLSGRCodeFgRed defaultColor:kDefaultColor] colorByDarkeningColor].CGColor,
                            (id)kTTTBackgroundFillColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeFgRed defaultColor:kDefaultColor].CGColor,
                            (id)kTTTBackgroundStrokeColorAttributeName : (id)[UIColor colorForSGRCode:SPLSGRCodeFgRed defaultColor:kDefaultColor].CGColor,
                            } range:NSMakeRange(0, string.length)];

    EXP_expect(SPLItemWithString(string)).to.equal(item);
}

- (void)testContinuesForegroundColor {
    testString = @"\033[0;36mHello World";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(1);
    EXP_expect(((SSAttributedLineGroupItem *)[lineGroup.lines firstObject]).line.string).to.equal(@"Hello World");

    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:SPLTestStringWithStringAndColor(@"Hello World", [UIColor colorForSGRCode:SPLSGRCodeFgCyan
                                                                                                                                                               defaultColor:nil])];

    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(str));

    testString = @"Yo Dawg";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(1);
    EXP_expect(((SSAttributedLineGroupItem *)[lineGroup.lines firstObject]).line.string).to.equal(@"Yo Dawg");

    str = [[NSMutableAttributedString alloc] initWithAttributedString:SPLTestStringWithStringAndColor(@"Yo Dawg", [UIColor colorForSGRCode:SPLSGRCodeFgCyan
                                                                                                                                                               defaultColor:nil])];

    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(str));
}

- (void)testContinuesBackgroundColor {
    testString = @"\033[0;46mHello World";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(1);
    EXP_expect(((SSAttributedLineGroupItem *)[lineGroup.lines firstObject]).line.string).to.equal(@"Hello World");

    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithAttributedString:SPLTestStringWithString(@"Hello World")];

    [str addAttributes:@{
                         kTTTBackgroundFillColorAttributeName : (id)((UIColor *)[UIColor colorForSGRCode:SPLSGRCodeBgCyan defaultColor:nil]).CGColor,
                         kTTTBackgroundStrokeColorAttributeName : (id)((UIColor *)[UIColor colorForSGRCode:SPLSGRCodeBgCyan defaultColor:nil]).CGColor
    } range:NSMakeRange(0, str.length)];

    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(str));

    testString = @"Yo Dawg";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect([lineGroup.lines count]).to.equal(1);
    EXP_expect(((SSAttributedLineGroupItem *)[lineGroup.lines firstObject]).line.string).to.equal(@"Yo Dawg");

    str = [[NSMutableAttributedString alloc] initWithAttributedString:SPLTestStringWithString(@"Yo Dawg")];

    [str addAttributes:@{
                         kTTTBackgroundFillColorAttributeName : (id)((UIColor *)[UIColor colorForSGRCode:SPLSGRCodeBgCyan defaultColor:nil]).CGColor,
                         kTTTBackgroundStrokeColorAttributeName : (id)((UIColor *)[UIColor colorForSGRCode:SPLSGRCodeBgCyan defaultColor:nil]).CGColor
    } range:NSMakeRange(0, str.length)];

    EXP_expect([lineGroup.lines firstObject]).to.equal(SPLItemWithString(str));
}

#pragma mark - ANSI commands

- (void)testCreatesCommands {
    SSLineGroupCommand *command = [SSLineGroupCommand commandWithBody:@"1;2" endCode:@"K"];

    EXP_expect(command).toNot.beNil();
    EXP_expect(command.number1).to.equal(1);
    EXP_expect(command.number2).to.equal(2);
    EXP_expect(command.command).to.equal(SSLineGroupCommandLineClear);

    command = [SSLineGroupCommand commandWithBody:nil endCode:@"Z"];

    EXP_expect(command).to.beNil();
}

- (void)testUnrecognizedCommand {
    SSLineGroupCommand *command = [SSLineGroupCommand commandWithBody:@"1;2" endCode:@"ZZ"];

    EXP_expect(command).to.beNil();

    testString = @"\033[Z\033[H";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(1);
    EXP_expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:nil endCode:@"H"]]);
}

- (void)testParsesBlankCommandValues {
    testString = @"\033[H";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(1);
    EXP_expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:nil endCode:@"H"]]);
}

- (void)testParsesCursorPositionValues {
    testString = @"\033[17;H";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(1);
    EXP_expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[[SSLineGroupCommand alloc] initWithCommand:SSLineGroupCommandCursorPosition number1:17 number2:0]]);

    testString = @"\033[17H";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(1);
    EXP_expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[[SSLineGroupCommand alloc] initWithCommand:SSLineGroupCommandCursorPosition number1:17 number2:0]]);

    testString = @"\033[;5H";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(1);
    EXP_expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[[SSLineGroupCommand alloc] initWithCommand:SSLineGroupCommandCursorPosition number1:0 number2:5]]);

    testString = @"\033[17;1H";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(1);
    EXP_expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[[SSLineGroupCommand alloc] initWithCommand:SSLineGroupCommandCursorPosition number1:17 number2:1]]);

    testString = @"\033[17;H";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(1);
    EXP_expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[[SSLineGroupCommand alloc] initWithCommand:SSLineGroupCommandCursorPosition number1:17 number2:0]]);

    testString = @"\033[2J\033[H";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(2);
    EXP_expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[[SSLineGroupCommand alloc] initWithCommand:SSLineGroupCommandDisplayClear number1:2 number2:0]]);
    EXP_expect(lineGroup.lines[1]).to.equal([SSAttributedLineGroupItem itemWithCommand:[[SSLineGroupCommand alloc] initWithCommand:SSLineGroupCommandCursorPosition number1:0 number2:0]]);
}

- (void)testStripsSimpleANSICommands {
    testString = @"hi\n\033[Hhi";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(3);
    EXP_expect(lineGroup.lines[0]).to.equal(SPLItemWithString(SPLTestStringWithString(@"hi\n")));
    EXP_expect(lineGroup.lines[1]).to.equal([SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:nil endCode:@"H"]]);
    EXP_expect(lineGroup.lines[2]).to.equal(SPLItemWithString(SPLTestStringWithString(@"hi")));
}

- (void)testCollapsesCommandNewLines {
    testString = @"\033[HHello Yo";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(2);
    EXP_expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:nil endCode:@"H"]]);
    EXP_expect(lineGroup.lines[1]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Hello Yo")));

    testString = @"\033[2J\033[H\n";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(2);
    EXP_expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:@"2" endCode:@"J"]]);
    EXP_expect(lineGroup.lines[1]).to.equal([SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:nil endCode:@"H"]]);

    testString = @"\033[H\nHello Yo";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(2);
    EXP_expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:nil endCode:@"H"]]);
    EXP_expect(lineGroup.lines[1]).to.equal(SPLItemWithString(SPLTestStringWithString(@"Hello Yo")));
}

- (void)testStripsSingleLineANSICommands {
    testString = @"\033[Hhi";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(2);
    EXP_expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:nil endCode:@"H"]]);
    EXP_expect(lineGroup.lines[1]).to.equal(SPLItemWithString(SPLTestStringWithString(@"hi")));
}

- (void)testStripsMultiLineSimpleANSICommands {
    testString = @"hi\n\033[Hhi\033[Hyo";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(5);
    EXP_expect(lineGroup.lines[0]).to.equal(SPLItemWithString(SPLTestStringWithString(@"hi\n")));
    EXP_expect(lineGroup.lines[1]).to.equal([SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:nil endCode:@"H"]]);
    EXP_expect(lineGroup.lines[2]).to.equal(SPLItemWithString(SPLTestStringWithString(@"hi")));
    EXP_expect(lineGroup.lines[3]).to.equal([SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:nil endCode:@"H"]]);
    EXP_expect(lineGroup.lines[4]).to.equal(SPLItemWithString(SPLTestStringWithString(@"yo")));
}

- (void)testStripsANSICommandsWithArguments {
    testString = @"\033[2Jyo";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(2);
    EXP_expect(lineGroup.lines[0]).to.equal([SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:@"2" endCode:@"J"]]);
    EXP_expect(lineGroup.lines[1]).to.equal(SPLItemWithString(SPLTestStringWithString(@"yo")));

    testString = @"sup\033[2;4J";

    lineGroup = [engine parseANSIString:testString];

    EXP_expect(lineGroup.lines.count).to.equal(2);
    EXP_expect(lineGroup.lines[0]).to.equal(SPLItemWithString(SPLTestStringWithString(@"sup")));
    EXP_expect(lineGroup.lines[1]).to.equal([SSAttributedLineGroupItem itemWithCommand:[SSLineGroupCommand commandWithBody:@"2;4" endCode:@"J"]]);
}

@end
