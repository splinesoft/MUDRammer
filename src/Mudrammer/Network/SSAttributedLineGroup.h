//
//  SSAttributedLineGroup.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 1/25/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

@import Foundation;

// A command associated with this line
typedef NS_ENUM(NSUInteger, SSLineGroupCommandType) {

    // Clearing
    SSLineGroupCommandLineClear,
    SSLineGroupCommandDisplayClear,

    // Absolute cursor position
    SSLineGroupCommandCursorPosition,

    // Cursor movement
    SSLineGroupCommandCursorUp,
    SSLineGroupCommandCursorDown,
    SSLineGroupCommandCursorLeft,
    SSLineGroupCommandCursorRight,
    SSLineGroupCommandCursorHorizontalAbsolute,

    // Line movement
    SSLineGroupCommandCursorNextLine,
    SSLineGroupCommandCursorPreviousLine,
};

@interface SSLineGroupCommand : NSObject

@property (readonly, nonatomic, assign) SSLineGroupCommandType command;

@property (readonly, nonatomic, assign) NSUInteger number1;
@property (readonly, nonatomic, assign) NSUInteger number2;

- (instancetype) initWithCommand:(SSLineGroupCommandType)command
                         number1:(NSUInteger)number1
                         number2:(NSUInteger)number2;

+ (instancetype) commandWithBody:(NSString *)commandBody
                         endCode:(NSString *)endCode;

/**
 *  Return YES if this is a command that involves erasing one or more lines.
 *
 *  @return whether this is a clearing command
 */
@property (nonatomic, getter=isClearingCommand, readonly) BOOL clearingCommand;

@end

// Encapsulates a single line within a group of attributed lines.
@interface SSAttributedLineGroupItem : NSObject

@property (nonatomic, strong) NSMutableAttributedString *line;
@property (nonatomic, strong) SSLineGroupCommand *command;
@property (nonatomic, assign) BOOL endsInNewLine;

/**
 *  Create a line group item that is an empty string to serve as a blank line.
 *
 *  @return an initialized item
 */
+ (instancetype) itemWithBlankLine;

/**
 *  Create a line group item with an attributed string.
 *
 *  @param string attributed string for this item
 *
 *  @return an initialized item
 */
+ (instancetype) itemWithAttributedString:(NSAttributedString *)string;

/**
 *  Create a line group item with a line command.
 *
 *  @param command command
 *
 *  @return an initialized item
 */
+ (instancetype) itemWithCommand:(SSLineGroupCommand *)command;

/**
 *  YES if this item contains printable text, including blank lines.
 *  NO if e.g. it contains only a line command.
 *
 *  @return whether this item is printable
 */
@property (nonatomic, readonly) BOOL hasText;

/**
 *  YES if this item is a newline - it has an empty string && endsInNewLine.
 *
 *  @return whether this item is a newline
 */
@property (nonatomic, getter=isNewLineItem, readonly) BOOL newLineItem;

// Append another item to this one.
- (void) appendItem:(SSAttributedLineGroupItem *)newLine;

@end

// Encapsulates a group of attributed strings, split by line.
// Append another group to merge them into one.

@interface SSAttributedLineGroup : NSObject

@property (nonatomic, copy, readonly) NSArray *lines;
@property (nonatomic, assign) BOOL containsUserInput;

+ (instancetype) lineGroup;
+ (instancetype) lineGroupWithAttributedString:(NSAttributedString *)string;

/**
 *  Create a line group with an array of line objects. Each item should be
 *  an SSAttributedLineGroupItem.
 *
 *  @param array an array of items
 *
 *  @return an initialized line group
 */
+ (instancetype) lineGroupWithItems:(NSArray *)array;

/**
 *  Create a line group with an attributed string and a dictionary of command locations.
 *
 *  @param string           attributed string
 *  @param commandLocations dictionary of command locations
 *
 *  @return an initialized line group
 */
+ (instancetype) lineGroupWithAttributedString:(NSAttributedString *)string
                              commandLocations:(NSDictionary *)commandLocations;

// Append a new line group onto this one
- (void) appendAttributedLineGroup:(SSAttributedLineGroup *)toAppend;

// Wipes lines and resets
- (void) cleanAllLines;

/**
 *  Remove the first line.
 */
- (void) removeFirstLine;

/**
 *  Remove the first N lines.
 */
- (void) removeFirstLines:(NSUInteger)lines;

/**
 *  Return an array of lines in this group that actually contain printable text.
 *  Includes blank lines.
 *
 *  @see hasText in SSAttributedLineGroupItem
 *  @return lines with text
 */
@property (nonatomic, readonly, copy) NSArray *textLines;

/**
 *  Return an array of our lines as regular strings.
 *
 *  @param withCommands whether commands should be included in the array
 *
 *  @return an array of clean text lines, optionally with commands
 */
- (NSArray *) cleanTextLinesWithCommands:(BOOL)withCommands;

@end
