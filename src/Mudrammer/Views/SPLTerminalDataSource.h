//
//  SPLTerminalDataSource.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/11/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

#import <SSDataSources.h>
#import "SSAttributedLineGroup.h"

// Maximum number of lines in the table before enqueuing a partial clear.
UIKIT_EXTERN NSUInteger const kMaxLineHistory;

// Number of lines cleared when the maximum line limit is hit.
UIKIT_EXTERN NSUInteger const kLineDeleteAmount;

@interface SPLTerminalDataSource : SSArrayDataSource

#pragma mark - Adding items

/**
 *  Add more items to the data source. Process any commands and update the table.
 *
 *  @param group lines to parse
 */
- (void) appendAttributedLineGroup:(SSAttributedLineGroup *)group;

/**
 *  Append some text directly to the table.
 *
 *  @param text        text to append
 *  @param isUserInput whether it should be styled as user input
 */
- (void) appendText:(NSString *)text isUserInput:(BOOL)isUserInput;

#pragma mark - Cursor Position

/**
 *  Current cursor position of the terminal.
 */
@property (readonly, assign, nonatomic) UIOffset cursorPosition;

/**
 *  Given the number of rows currently displayed, normalizes a cursor position row
 *  such that it is inset from the bottom of the screen.
 *
 *  @param position position to normalize
 *
 *  @return normalized position
 */
- (UIOffset)cursorPositionByNormalizingPosition:(UIOffset)position;

@end
