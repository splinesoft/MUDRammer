//
//  SSAttributedLineGroup.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 1/25/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSAttributedLineGroup.h"
#import "SSANSIEngine.h"
#import "NSScanner+SPLAdditions.h"

@implementation SSLineGroupCommand

- (instancetype)initWithCommand:(SSLineGroupCommandType)command number1:(NSUInteger)number1 number2:(NSUInteger)number2 {
    if ((self = [super init])) {
        _command = command;
        _number1 = number1;
        _number2 = number2;
    }

    return self;
}

+ (instancetype)commandWithBody:(NSString *)commandBody endCode:(NSString *)endCode {

    // https://en.wikipedia.org/wiki/ANSI_escape_code#CSI_codes
    SSLineGroupCommandType commandType;

    if ([endCode isEqualToString:@"A"]) {
        commandType = SSLineGroupCommandCursorUp;
    } else if ([endCode isEqualToString:@"B"]) {
        commandType = SSLineGroupCommandCursorDown;
    } else if ([endCode isEqualToString:@"C"]) {
        commandType = SSLineGroupCommandCursorRight;
    } else if ([endCode isEqualToString:@"D"]) {
        commandType = SSLineGroupCommandCursorLeft;
    } else if ([endCode isEqualToString:@"E"]) {
        commandType = SSLineGroupCommandCursorNextLine;
    } else if ([endCode isEqualToString:@"F"]) {
        commandType = SSLineGroupCommandCursorPreviousLine;
    } else if ([endCode isEqualToString:@"G"]) {
        commandType = SSLineGroupCommandCursorHorizontalAbsolute;
    } else if ([endCode isEqualToString:@"J"]) {
        commandType = SSLineGroupCommandDisplayClear;
    } else if ([endCode isEqualToString:@"H"] || [endCode isEqualToString:@"f"]) {
        commandType = SSLineGroupCommandCursorPosition;
    } else if ([endCode isEqualToString:@"K"]) {
        commandType = SSLineGroupCommandLineClear;
    } else {
        DLog(@"Unsupported command type %@ %@", commandBody, endCode);
        return nil;
    }

    NSUInteger n1 = 0, n2 = 0;

    NSArray *bits = [commandBody componentsSeparatedByString:@";"];

    if ([commandBody hasPrefix:@";"]) {
        n2 = (NSUInteger)[bits[1] integerValue];
    } else {
        if ([bits count] > 0) {
            n1 = (NSUInteger)[bits[0] integerValue];
        }

        if ([bits count] > 1) {
            n2 = (NSUInteger)[bits[1] integerValue];
        }
    }

    return [[self alloc] initWithCommand:commandType
                                 number1:n1
                                 number2:n2];
}

- (BOOL)isClearingCommand {
    switch (self.command) {
        case SSLineGroupCommandDisplayClear:
        case SSLineGroupCommandLineClear:
            return YES;
        case SSLineGroupCommandCursorDown:
        case SSLineGroupCommandCursorHorizontalAbsolute:
        case SSLineGroupCommandCursorLeft:
        case SSLineGroupCommandCursorNextLine:
        case SSLineGroupCommandCursorPosition:
        case SSLineGroupCommandCursorPreviousLine:
        case SSLineGroupCommandCursorRight:
        case SSLineGroupCommandCursorUp:
            return NO;
    }
}

- (NSUInteger)hash {
    return NSUINTROTATE(self.command, NSUINT_BIT / 2) ^ NSUINTROTATE(self.number1, NSUINT_BIT / 4) ^ NSUINTROTATE(self.number2, NSUINT_BIT / 6);
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:self.class]
        && ((SSLineGroupCommand *)object).command == self.command
        && ((SSLineGroupCommand *)object).number1 == self.number1
        && ((SSLineGroupCommand *)object).number2 == self.number2;
}

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@"comm %@ num1 %@ num2 %@",
            @(self.command),
            @(self.number1),
            @(self.number2)];
}

@end

@implementation SSAttributedLineGroupItem

+ (instancetype)itemWithAttributedString:(NSAttributedString *)string {
    NSParameterAssert(string);

    SSAttributedLineGroupItem *groupLine = [SSAttributedLineGroupItem new];
    groupLine.line = [string mutableCopy];

    BOOL endsInNewLine = [[NSCharacterSet newlineCharacterSet] characterIsMember:
                          [[string string] characterAtIndex:([[string string] length] - 1)]];

    if (endsInNewLine) {
        [groupLine.line deleteCharactersInRange:NSMakeRange(groupLine.line.length - 1, 1)];
        groupLine.endsInNewLine = YES;
    }

    return groupLine;
}

+ (instancetype)itemWithCommand:(SSLineGroupCommand *)command {
    SSAttributedLineGroupItem *item = [SSAttributedLineGroupItem new];
    item.command = command;
    return item;
}

+ (instancetype)itemWithBlankLine {
    SSAttributedLineGroupItem *item = [self itemWithAttributedString:[NSAttributedString new]];
    item.endsInNewLine = YES;
    return item;
}

- (void)appendItem:(SSAttributedLineGroupItem *)newLine {
    if (![newLine hasText]) {
        return;
    }

    [self.line appendAttributedString:newLine.line];
    self.endsInNewLine = newLine.endsInNewLine;
}

- (BOOL)hasText {
    return self.line != nil;
}

- (BOOL)isNewLineItem {
    return self.endsInNewLine && [self.line length] == 0;
}

- (void)dealloc {
    _line = nil;
}

- (NSUInteger)hash {
    NSUInteger hash = [super hash];

    if ([self hasText]) {
        hash ^= [self.line hash];
        hash ^= NSUINTROTATE(self.endsInNewLine, NSUINT_BIT / 2);
    } else {
        hash ^= [self.command hash];
    }

    return hash;
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[SSAttributedLineGroupItem class]]
        && ([self hasText]
            ? ([self.line isEqualToAttributedString:((SSAttributedLineGroupItem *)object).line]
               && self.endsInNewLine == ((SSAttributedLineGroupItem *)object).endsInNewLine)
            : [self.command isEqual:((SSAttributedLineGroupItem *)object).command]);
}

- (NSString *)description {
    return [[super description] stringByAppendingFormat:@" %@",
            ([self hasText]
             ? [NSString stringWithFormat:@"Line: New %@ %@", @(self.endsInNewLine), self.line]
             : [NSString stringWithFormat:@"Command: %@", self.command])];
}

@end

#pragma mark -

@interface SSAttributedLineGroup ()

+ (NSArray *)attributedLinesFromAttributedString:(NSAttributedString *)string;

- (SSAttributedLineGroup *) initWithLines:(NSArray *)lines;

@end

@implementation SSAttributedLineGroup

- (SSAttributedLineGroup *) initWithLines:(NSArray *)lines {
    if ((self = [super init])) {
        _lines = (lines ? [NSArray arrayWithArray:lines] : @[]);
        _containsUserInput = NO;
    }

    return self;
}

+ (instancetype)lineGroup {
    return [[SSAttributedLineGroup alloc] initWithLines:nil];
}

+ (instancetype)lineGroupWithAttributedString:(NSAttributedString *)string {

    NSParameterAssert(string);

    return [self lineGroupWithAttributedString:string commandLocations:nil];
}

+ (instancetype)lineGroupWithAttributedString:(NSAttributedString *)string
                             commandLocations:(NSDictionary *)commandLocations {

    if ([commandLocations count] == 0) {
        return [self lineGroupWithItems:
                [self attributedLinesFromAttributedString:string]];
    }

    NSUInteger characterPosition = 0;
    NSArray *sortedLocations = [[commandLocations allKeys] sortedArrayUsingSelector:@selector(compare:)];
    NSMutableArray *lines = [NSMutableArray array];

    for (NSNumber *commandLocation in sortedLocations) {

        if ([commandLocation unsignedIntegerValue] - characterPosition > 0) {
            NSAttributedString *substring = [string attributedSubstringFromRange:
                                             NSMakeRange(characterPosition, [commandLocation unsignedIntegerValue] - characterPosition)];

            NSArray *attributedLines = [self attributedLinesFromAttributedString:substring];

            [lines addObjectsFromArray:attributedLines];

            characterPosition += [substring length];
        }

        id commands = commandLocations[commandLocation];

        if ([commands isKindOfClass:[NSArray class]]) {
            [(NSArray *)commands bk_each:^(SSLineGroupCommand *command) {
                [lines addObject:[SSAttributedLineGroupItem itemWithCommand:command]];
            }];
        } else {
            [lines addObject:[SSAttributedLineGroupItem itemWithCommand:commands]];
        }
    }

    // Capture text after the last command and before the end of the string
    if (characterPosition < [string length]) {
        NSAttributedString *remainderString = [string attributedSubstringFromRange:
                                               NSMakeRange(characterPosition, [string length] - characterPosition)];

        NSArray *attributedLines = [self attributedLinesFromAttributedString:remainderString];

        [lines addObjectsFromArray:attributedLines];
    }

//    DLog(@"%@", lines);

    // Collapse newlines that are between or bordering CSI commands.
    if ([lines count] > 1) {
        for (NSInteger i = (NSInteger)[lines count] - 1; i >= 0; i--) {
            SSAttributedLineGroupItem *item = lines[(NSUInteger)i];
            SSAttributedLineGroupItem *adjacent = (i > 0
                                                   ? lines[(NSUInteger)i - 1]
                                                   : lines[(NSUInteger)i + 1]);

            if ([item hasText] && [item.line length] == 0 && ![adjacent hasText]) {
                [lines removeObjectAtIndex:(NSUInteger)i];
                DLog(@"Remove %@", item);
            }
        }
    }

//    DLog(@"%@", lines);

    return [self lineGroupWithItems:lines];
}

+ (instancetype)lineGroupWithItems:(NSArray *)array {
    NSParameterAssert(array);

    return [[SSAttributedLineGroup alloc] initWithLines:array];
}

#pragma mark - group operations

- (void)appendAttributedLineGroup:(SSAttributedLineGroup *)toAppend {

    if ([toAppend.lines count] == 0) {
        DLog(@"No lines to append; skipping");
        return;
    }

    NSMutableIndexSet *linesToAppend = [NSMutableIndexSet indexSetWithIndexesInRange:
                                        NSMakeRange(0, [toAppend.lines count])];

    if ([self.lines count] > 0) {
        SSAttributedLineGroupItem *lastLine = [self.lines lastObject];

        if ([lastLine hasText] && !lastLine.endsInNewLine) {
            [linesToAppend removeIndex:linesToAppend.firstIndex];

            SSAttributedLineGroupItem *firstLine = toAppend.lines.firstObject;
            [lastLine appendItem:firstLine];
            lastLine.endsInNewLine = firstLine.endsInNewLine;
        }
    }

    if ([linesToAppend count] == 0) {
        DLog(@"No more lines");
    } else {
        NSArray *lines = [self.lines arrayByAddingObjectsFromArray:
                          [toAppend.lines objectsAtIndexes:linesToAppend]];
        _lines = lines;
    }

    if (toAppend.containsUserInput) {
        self.containsUserInput = YES;
    }
}

- (void)cleanAllLines {
    _lines = @[];
    self.containsUserInput = NO;
}

- (void)removeFirstLine {
    [self removeFirstLines:1];
}

- (void)removeFirstLines:(NSUInteger)lines {
    if (lines == 0) {
        return;
    }

    if (lines <= [self.lines count]) {
        _lines = [self.lines objectsAtIndexes:
                  [NSIndexSet indexSetWithIndexesInRange:
                   NSMakeRange(lines, [self.lines count] - lines)]];
    } else {
        _lines = @[];
    }
}

- (NSArray *)textLines {
    return [self.lines bk_select:^BOOL(SSAttributedLineGroupItem *item) {
        return [item hasText];
    }];
}

- (NSArray *)cleanTextLinesWithCommands:(BOOL)withCommands {
    return [(withCommands ? self.lines : [self textLines]) bk_map:^id(SSAttributedLineGroupItem *line) {

        if (line.command) {
            return line;
        }

        NSString *str = [line.line string];

        if ([str length] == 0) {
            return @"";
        }

        str = [str stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

        if ([str length] == 0) {
            return @"";
        }

        return str;
    }];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"Line Group: %@ lines, %i hasUI. Lines: %@",
            @([self.lines count]),
            self.containsUserInput,
            self.lines];
}

#pragma mark - attributed string parsing

+ (NSArray *)attributedLinesFromAttributedString:(NSAttributedString *)string {

    NSScanner *scanner = [NSScanner scannerWithString:[string string]];
    [scanner setCharactersToBeSkipped:nil];
    NSMutableArray *attributedLines = [NSMutableArray array];

    do {

        // Find the next newline, if any
        NSString *str;
        NSUInteger startPosition = scanner.scanLocation;

        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet newlineCharacterSet]
                                    intoString:&str]) {

            // Found a newline or the end of the string.
            // Create a line for any characters in the buffer.
            SSAttributedLineGroupItem *item = [SSAttributedLineGroupItem itemWithAttributedString:
                                               [string attributedSubstringFromRange:
                                                NSMakeRange(startPosition, [str length])]];

            item.endsInNewLine = ![scanner isAtEnd];
            [attributedLines addObject:item];

            [scanner SPLScanCharacterFromSet:[NSCharacterSet newlineCharacterSet]
                                  intoString:NULL];

        } else {

            [attributedLines addObject:[SSAttributedLineGroupItem itemWithBlankLine]];

            [scanner SPLScanCharacterFromSet:[NSCharacterSet newlineCharacterSet]
                                  intoString:NULL];

        }


    } while (![scanner isAtEnd]);

    return attributedLines;
}

@end
