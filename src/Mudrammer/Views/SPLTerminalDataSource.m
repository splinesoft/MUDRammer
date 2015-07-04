//
//  SPLTerminalDataSource.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/11/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

#import "SPLTerminalDataSource.h"
#import "SSTextTableView.h"
#import "NSAttributedString+SPLAdditions.h"
#import <NSOperationQueue+SSAdditions.h>
#import "NSData+SPLDataParsing.h"
#import "NSMutableIndexSet+SPLAdditions.h"
@import CoreText;

CG_INLINE NSString * SPLStringWithSpaces(NSUInteger numSpaces) {
    NSMutableString *str = [NSMutableString string];

    for (NSUInteger i = 0; i < numSpaces; i++) {
        [str appendString:@" "];
    }

    return [NSString stringWithString:str];
};

typedef NS_ENUM(NSUInteger, SPLScrollPosition) {
    SPLScrollPositionNone,
    SPLScrollPositionBottom,
    SPLScrollPositionTop,
    SPLScrollPositionTopOfCurrentScreen
};

NSUInteger const kMaxLineHistory = 2000;
NSUInteger const kLineDeleteAmount = (kMaxLineHistory / 5);

@interface SPLTerminalDataSource ()

@property (nonatomic, strong) NSOperationQueue *operationQueue;
@property (nonatomic, strong) SSAttributedLineGroup *lineQueue;
@property (nonatomic, strong) FBKVOController *kvoController;
@property (nonatomic, strong) NSMutableDictionary *changeDictionary;

- (void) flushLineQueue;

- (void) restartOperationQueue;
- (void) suspendOperationQueue;

@end

@implementation SPLTerminalDataSource

- (instancetype)initWithItems:(NSArray *)items {
    if ((self = [super initWithItems:items])) {
        _cursorPosition = UIOffsetMake(1, 1);
        _operationQueue = [NSOperationQueue ss_serialOperationQueueNamed:@"Terminal Flush Queue"];
        _lineQueue = [SSAttributedLineGroup lineGroup];
        _kvoController = [FBKVOController controllerWithObserver:self];
        _changeDictionary = [NSMutableDictionary dictionary];

        @weakify(self);
        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeFontColor
                            options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                              block:^(id table, id object, NSDictionary *change)
         {
             UIColor *oldColor = change[NSKeyValueChangeOldKey];
             UIColor *newColor = change[NSKeyValueChangeNewKey];

             @strongify(self);
             [self.operationQueue ss_addBlockOperationWithBlock:^(SSBlockOperation *operation) {
                 if ([operation isCancelled]) {
                     return;
                 }

                 [[self allItems] enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                   usingBlock:^(SSAttributedLineGroupItem *line,
                                                                NSUInteger index,
                                                                BOOL *stop)
                  {
                      if ([operation isCancelled]) {
                          *stop = YES;
                          return;
                      }

                      if ([line.line length] == 0) {
                          return;
                      }

                      [line.line enumerateAttribute:(id)kCTForegroundColorAttributeName
                                            inRange:NSMakeRange(0, [line.line length])
                                            options:NSAttributedStringEnumerationReverse
                                         usingBlock:^(id value, NSRange range, BOOL *colorStop) {
                                             if ([operation isCancelled]) {
                                                 *colorStop = YES;
                                                 return;
                                             }

                                             if ([[UIColor colorWithCGColor:(CGColorRef)value] isEqual:oldColor]) {
                                                 [line.line addAttribute:(id)kCTForegroundColorAttributeName
                                                                   value:(id)newColor.CGColor
                                                                   range:range];
                                             }
                                         }];
                  }];

                 dispatch_sync(dispatch_get_main_queue(), ^{
                     UITableView *tableView = self.tableView;
                     NSArray *visibleRows = [tableView indexPathsForVisibleRows];
                     
                     if ([visibleRows count] > 0) {
                         [tableView reloadRowsAtIndexPaths:visibleRows
                                          withRowAnimation:UITableViewRowAnimationFade];
                     }
                 });
             }];
         }];

        void (^FontChangeBlock)(id) = ^(id newValue) {
            @strongify(self);
            UIFont *newFont = [SSThemes sharedThemer].currentFont;

            [self.operationQueue ss_addBlockOperationWithBlock:^(SSBlockOperation *operation) {
                if ([operation isCancelled]) {
                    return;
                }

                [[self allItems] enumerateObjectsWithOptions:NSEnumerationConcurrent
                                                  usingBlock:^(SSAttributedLineGroupItem *line,
                                                               NSUInteger index,
                                                               BOOL *stop)
                 {
                     if ([operation isCancelled]) {
                         *stop = YES;
                         return;
                     }

                     if ([line.line length] == 0) {
                         return;
                     }


                     [line.line addAttribute:NSFontAttributeName
                                       value:newFont
                                       range:NSMakeRange(0, [line.line length])];
                 }];

                dispatch_sync(dispatch_get_main_queue(), ^{
                    UITableView *tableView = self.tableView;
                    NSArray *visibleRows = [tableView indexPathsForVisibleRows];
                    
                    if ([visibleRows count] > 0) {
                        [tableView reloadRowsAtIndexPaths:visibleRows
                                         withRowAnimation:UITableViewRowAnimationFade];
                    }
                });
            }];
        };

        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeFontName
                            options:NSKeyValueObservingOptionNew
                              block:^(id table, id object, NSDictionary *change) {
                                  FontChangeBlock(change[NSKeyValueChangeNewKey]);
                              }];

        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeFontSize
                            options:NSKeyValueObservingOptionNew
                              block:^(id table, id object, NSDictionary *change) {
                                  FontChangeBlock(change[NSKeyValueChangeNewKey]);
                              }];

        // start and stop operation queue
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(suspendOperationQueue)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(restartOperationQueue)
                                                     name:UIApplicationDidBecomeActiveNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc {
    _kvoController = nil;
    [self.operationQueue cancelAllOperations];
    [self.lineQueue cleanAllLines];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setTableView:(UITableView *)tableView {
    [self.operationQueue cancelAllOperations];
    [self.lineQueue cleanAllLines];
    [super setTableView:tableView];
}

- (void)suspendOperationQueue {
    [self.operationQueue setSuspended:YES];
}

- (void)restartOperationQueue {
    [self.operationQueue setSuspended:NO];
}

#pragma mark - Appending

- (void)appendAttributedLineGroup:(SSAttributedLineGroup *)group {
    @weakify(self);
    [self.operationQueue ss_addBlockOperationWithBlock:^(SSBlockOperation *op) {
        @strongify(self);

        if ([op isCancelled]) {
            return;
        }

        [self.lineQueue appendAttributedLineGroup:group];
        [self flushLineQueue];
    }];
}

- (void)appendText:(NSString *)text isUserInput:(BOOL)isUserInput {
    NSAttributedString *attr = nil;

    if ([text length] == 0) {
        attr = [NSAttributedString userInputStringForString:@""];
    } else if (isUserInput) {
        attr = [NSAttributedString userInputStringForString:[text stringByAppendingString:@"\n"]];
    } else {
        attr = [NSAttributedString worldStringForString:text];
    }

    SSAttributedLineGroup *group = [SSAttributedLineGroup lineGroupWithAttributedString:attr];
    group.containsUserInput = isUserInput;

    [self appendAttributedLineGroup:group];
}

#pragma mark - Clearing

- (void)clearItems {
    [self.operationQueue cancelAllOperations];
    [self.lineQueue cleanAllLines];
    [self.changeDictionary removeAllObjects];
    [super clearItems];
    _cursorPosition = UIOffsetMake(1, 1);
}

#pragma mark - Flush changes

- (void) flushLineQueue {
    @weakify(self);

    [self.operationQueue ss_addBlockOperationWithBlock:^(SSBlockOperation *operation) {
        @strongify(self);

        if ([operation isCancelled] || [self.lineQueue.lines count] == 0) {
            DLog(@"No text to flush.");
            return;
        }

        DLog(@"initiating %@-item flush", @(self.lineQueue.lines.count));

        [self.changeDictionary removeAllObjects];

        // Block the operation from completing until UI is updated.
        dispatch_sync(dispatch_get_main_queue(), ^{
            if ([operation isCancelled]) {
                return;
            }

            SSTextTableView *tableView = (SSTextTableView *)self.tableView;

            SPLScrollPosition scrollPosition = SPLScrollPositionNone;

            if ([tableView isNearBottom] || self.lineQueue.containsUserInput) {
                scrollPosition = SPLScrollPositionBottom;
            }

            if ([operation isCancelled]) {
                return;
            }

            [tableView beginUpdates];

            if ([self numberOfItems] > kMaxLineHistory) {
                [self removeItemsInRange:NSMakeRange(0, kLineDeleteAmount)];

                if (self.cursorPosition.vertical >= kLineDeleteAmount) {
                    _cursorPosition = UIOffsetMake(self.cursorPosition.horizontal,
                                                   self.cursorPosition.vertical - kLineDeleteAmount);
                }
            }

            if ([operation isCancelled]) {
                return;
            }

            for (SSAttributedLineGroupItem *item in self.lineQueue.lines) {
                if ([operation isCancelled]) {
                    return;
                }

                // Special handling for screen clears.
                if (item.command && item.command.command == SSLineGroupCommandDisplayClear) {
                    [self processScreenClearItem:item.command];
                } else if (item.command) {
                    [self processCommand:item.command];
                } else {
                    [self processLineItem:item];
                }
            }

            if ([operation isCancelled]) {
                return;
            }

            NSArray *sortedRows = [[self.changeDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
            NSUInteger initialRowCount = [self numberOfItems];

            NSMutableArray *replaceItems = [NSMutableArray array];
            NSMutableArray *blankItems = [NSMutableArray array];
            NSMutableArray *insertItems = [NSMutableArray array];

            NSMutableIndexSet *replaceIndexes = [NSMutableIndexSet indexSet];
            NSMutableIndexSet *blankIndexes = [NSMutableIndexSet indexSet];
            NSMutableIndexSet *insertIndexes = [NSMutableIndexSet indexSet];
            NSMutableIndexSet *deleteIndexes = [NSMutableIndexSet indexSet];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
            for (NSNumber *row in sortedRows) {
                NSUInteger index = [row unsignedIntegerValue];

                if ([self.changeDictionary[row] isKindOfClass:[NSNull class]]) {
                    if (index < initialRowCount) {
                        [deleteIndexes addIndex:index];
                    }
                } else if (index < initialRowCount) {
                    [replaceIndexes addIndex:index];
                    [replaceItems addObject:self.changeDictionary[row]];
                } else {
                    for (NSUInteger i = initialRowCount + [blankIndexes count] + [insertIndexes count]; i < index; i++) {
                        [blankIndexes addIndex:i];
                        [blankItems addObject:[SSAttributedLineGroupItem itemWithBlankLine]];
                    }

                    [insertIndexes addIndex:index];
                    [insertItems addObject:self.changeDictionary[row]];
                }
            }
#pragma clang diagnostic pop

//            DLog(@"%@\n%@ %@\n%@ %@\n%@ %@",
//                 deleteIndexes,
//                 replaceIndexes, replaceItems,
//                 blankIndexes, blankItems,
//                 insertIndexes, insertItems);

            if ([deleteIndexes count] > 0) {
                [self removeItemsAtIndexes:deleteIndexes];

                [blankIndexes spl_shiftIndexesWithDeletedIndexes:deleteIndexes];
                [insertIndexes spl_shiftIndexesWithDeletedIndexes:deleteIndexes];
                [replaceIndexes spl_shiftIndexesWithDeletedIndexes:deleteIndexes];
            }

            if ([blankIndexes count] > 0) {
                [self insertItems:blankItems atIndexes:blankIndexes];
            }

            if ([insertIndexes count] > 0) {
                [self insertItems:insertItems atIndexes:insertIndexes];
            }

            if ([replaceIndexes count] > 0) {
                [self replaceItemsAtIndexes:replaceIndexes withItemsFromArray:replaceItems];
            }

            [tableView endUpdates];

            if ([operation isCancelled]) {
                return;
            }

            [self.lineQueue cleanAllLines];

            if ([operation isCancelled]) {
                return;
            }

            DLog(@"Scroll position: %@", @(scrollPosition));

            switch (scrollPosition) {
                case SPLScrollPositionBottom:
                    [tableView scrollToBottom];
                    break;
                case SPLScrollPositionTop:
                    [tableView setContentOffset:CGPointZero animated:NO];
                    break;
                default:
                    break;
            }
        });
    }];
}

#pragma mark - Line items

- (void)processScreenClearItem:(SSLineGroupCommand *)command {

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefSimpleTelnetMode]) {
        return;
    }

    DLog(@"Screen clear %@", command);

    SSTextTableView *tableView = (SSTextTableView *)self.tableView;

    if (command.number1 == 2) {
        // Full screen clear

        UIOffset topOffset = [self cursorPositionByNormalizingPosition:UIOffsetMake(1, 1)];

        UIOffset bottomOffset = [self cursorPositionByNormalizingPosition:
                                 UIOffsetMake(1, [tableView charSize].height)];

        for (NSUInteger i = (NSUInteger)topOffset.vertical - 1; i < (NSUInteger)bottomOffset.vertical; i++) {
            self.changeDictionary[@(i)] = [NSNull null];
        }

        _cursorPosition = UIOffsetMake(1, topOffset.vertical);
    } else if (command.number1 == 1) {
        // Clear from cursor to start of screen
        UIOffset topOffset = [self cursorPositionByNormalizingPosition:UIOffsetMake(1, 1)];

        // Clear to the start of the current line
        [self processCommand:[[SSLineGroupCommand alloc] initWithCommand:SSLineGroupCommandLineClear
                                                                 number1:1
                                                                 number2:0]];

        if (topOffset.vertical < self.cursorPosition.vertical) {
            for (NSUInteger clearRow = (NSUInteger)topOffset.vertical - 1; clearRow < (NSUInteger)self.cursorPosition.vertical - 1; clearRow++) {
                self.changeDictionary[@(clearRow)] = [SSAttributedLineGroupItem itemWithBlankLine];
            }
        }
    } else if (command.number1 == 0) {
        // Clear from cursor to end of screen
        UIOffset bottomOffset = [self cursorPositionByNormalizingPosition:
                                 UIOffsetMake(1, [tableView charSize].height)];

        // Clear to the end of the current line
        [self processCommand:[[SSLineGroupCommand alloc] initWithCommand:SSLineGroupCommandLineClear
                                                                 number1:0
                                                                 number2:0]];

        if (bottomOffset.vertical > self.cursorPosition.vertical) {
            for (NSUInteger clearRow = (NSUInteger)self.cursorPosition.vertical; clearRow < (NSUInteger)bottomOffset.vertical; clearRow++) {
                self.changeDictionary[@(clearRow)] = [NSNull null];
            }
        }
    }
}

- (void)processCommand:(SSLineGroupCommand *)command {

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefSimpleTelnetMode]) {
        return;
    }

    // Position values are 1-indexed
    NSUInteger columnIndex = (NSUInteger)self.cursorPosition.horizontal - 1;
    NSUInteger rowIndex = (NSUInteger)self.cursorPosition.vertical - 1;

    // Any existing item at the current row.
    SSAttributedLineGroupItem *existingItem = self.changeDictionary[@(rowIndex)];
    //        DLog(@"item %@", existingItem);

    if ([existingItem isKindOfClass:[NSNull class]]) {
        existingItem = [SSAttributedLineGroupItem itemWithBlankLine];
    }

    if (!existingItem && rowIndex < [self numberOfItems]) {
        existingItem = [self itemAtIndexPath:
                        [NSIndexPath indexPathForRow:(NSInteger)rowIndex inSection:0]];
        //            DLog(@"Existing table row %@ %@", @(rowIndex), existingItem);
    }

    if (!existingItem) {
        existingItem = [SSAttributedLineGroupItem itemWithBlankLine];
    }

    switch (command.command) {

        case SSLineGroupCommandLineClear: {
            // If n is zero (or missing), clear from cursor to the end of the line.
            // If n is one, clear from cursor to beginning of the line.
            // If n is two, clear entire line.
            // Cursor position does not change.

            if (command.number1 == 2) {
                [existingItem.line deleteCharactersInRange:NSMakeRange(0, existingItem.line.length)];
            } else if (command.number1 == 1) {

                if (existingItem.line.length <= columnIndex) {
                    [existingItem.line replaceCharactersInRange:NSMakeRange(0, existingItem.line.length)
                                           withAttributedString:[NSAttributedString worldStringForString:SPLStringWithSpaces(existingItem.line.length)]];
                } else {
                    [existingItem.line replaceCharactersInRange:NSMakeRange(0, 1 + columnIndex)
                                           withAttributedString:[NSAttributedString worldStringForString:SPLStringWithSpaces(1 + columnIndex)]];
                }

            } else if (existingItem.line.length > columnIndex) {
                [existingItem.line deleteCharactersInRange:NSMakeRange(columnIndex, existingItem.line.length - columnIndex)];
            }

            self.changeDictionary[@(rowIndex)] = existingItem;

            break;
        }

        case SSLineGroupCommandCursorPosition: {
            UIOffset newPoint = [self cursorPositionByNormalizingPosition:
                                 UIOffsetMake(command.number1, command.number2)];

            columnIndex = (NSUInteger)newPoint.horizontal - 1;
            rowIndex = (NSUInteger)newPoint.vertical - 1;

            DLog(@"Set cursor to %@ %@", @(columnIndex), @(rowIndex));

            break;
        }

        case SSLineGroupCommandCursorRight: {
            [self adjustCursorPositionByOffset:UIOffsetMake(command.number1, 0)];

            DLog(@"Right cursor to %@", @(columnIndex));

            return;
        }

        case SSLineGroupCommandCursorLeft: {
            [self adjustCursorPositionByOffset:UIOffsetMake(-(CGFloat)(command.number1), 0)];

            DLog(@"Left cursor to %@", @(columnIndex));

            return;
        }

        case SSLineGroupCommandCursorDown: {
            [self adjustCursorPositionByOffset:UIOffsetMake(0, command.number1)];

            DLog(@"Down cursor to %@", @(rowIndex));

            return;
        }

        case SSLineGroupCommandCursorUp: {
            [self adjustCursorPositionByOffset:UIOffsetMake(0, -(CGFloat)(command.number1))];

            DLog(@"Up cursor to %@", @(rowIndex));

            return;
        }

        case SSLineGroupCommandCursorPreviousLine: {
            [self adjustCursorPositionByOffset:UIOffsetMake(-(CGFloat)columnIndex, -(CGFloat)command.number1)];

            DLog(@"Previous line cursor to %@", @(rowIndex));

            return;
        }

        case SSLineGroupCommandCursorNextLine: {
            [self adjustCursorPositionByOffset:UIOffsetMake(-(CGFloat)columnIndex, command.number1)];

            DLog(@"Next line cursor to %@", @(rowIndex));

            return;
        }

        case SSLineGroupCommandCursorHorizontalAbsolute: {
            UIOffset newPoint = [self cursorPositionByNormalizingPosition:
                                 UIOffsetMake(command.number1, 0)];

            columnIndex = (NSUInteger)newPoint.horizontal - 1;

            DLog(@"Horizontal cursor to %@", @(columnIndex));

            break;
        }

        default:
            DLog(@"Unimplemented command: %@", command);
            break;
    }

    _cursorPosition = UIOffsetMake(columnIndex + 1, rowIndex + 1);
    //    DLog(@"Cursor now at: %@ %@", @(columnIndex), @(rowIndex));
    //    DLog(@"Rows: %@", @([self.MUDDataSource numberOfItems]));
    //    DLog(@"Updates: %@", rowUpdates);
}

- (void)processLineItem:(SSAttributedLineGroupItem *)item {

    // Position values are 1-indexed
    NSUInteger columnIndex = (NSUInteger)self.cursorPosition.horizontal - 1;
    NSUInteger rowIndex = (NSUInteger)self.cursorPosition.vertical - 1;

    // Any existing item at the current row.
    SSAttributedLineGroupItem *existingItem = self.changeDictionary[@(rowIndex)];
    //        DLog(@"item %@", existingItem);

    if ([existingItem isKindOfClass:[NSNull class]]) {
        existingItem = [SSAttributedLineGroupItem itemWithBlankLine];
    }

    if (!existingItem && rowIndex < [self numberOfItems]) {
        existingItem = [self itemAtIndexPath:
                        [NSIndexPath indexPathForRow:(NSInteger)rowIndex inSection:0]];
        //            DLog(@"Existing table row %@ %@", @(rowIndex), existingItem);
    }

    if (!existingItem) {
        existingItem = [SSAttributedLineGroupItem itemWithBlankLine];
    }

//    DLog(@"Insert item %@ at %@ %@",
//         item.line.string,
//         @(columnIndex),
//         @(rowIndex));

    // Insert some text at the current line position.

    if (existingItem.line.length < columnIndex) {
        // Insert some spaces to match the column index
        [existingItem appendItem:
         [SSAttributedLineGroupItem itemWithAttributedString:
          [NSAttributedString worldStringForString:
           SPLStringWithSpaces(columnIndex - existingItem.line.length)]]];
    }

    // If we are writing a newline, clear to the end of the line
    if (item.line.length == 0 && item.endsInNewLine) {
        [existingItem.line deleteCharactersInRange:NSMakeRange(columnIndex, existingItem.line.length - columnIndex)];
        existingItem.endsInNewLine = YES;
    } else if (existingItem.line.length == columnIndex) {
        // Now equal, perhaps after having just added spaces
        [existingItem appendItem:item];
    } else {
        // Replace some characters on this line
        NSRange replaceRange = NSMakeRange(columnIndex, 0);

        if (columnIndex + [item.line length] > [existingItem.line length]) {
            replaceRange.length = existingItem.line.length - columnIndex;
        } else {
            replaceRange.length = item.line.length;
        }

        [existingItem.line replaceCharactersInRange:replaceRange
                               withAttributedString:item.line];
    }

    self.changeDictionary[@(rowIndex)] = existingItem;

    if (item.endsInNewLine) {
        rowIndex++;
        columnIndex = 0;
    } else {
        columnIndex += [item.line length];
    }

    _cursorPosition = UIOffsetMake(columnIndex + 1, rowIndex + 1);
    //    DLog(@"Cursor now at: %@ %@", @(columnIndex), @(rowIndex));
    //    DLog(@"Rows: %@", @([self.MUDDataSource numberOfItems]));
    //    DLog(@"Updates: %@", rowUpdates);
}

#pragma mark - Text Rendering

- (UIOffset)cursorPositionByNormalizingPosition:(UIOffset)position {
    if (position.horizontal < 1) {
        position.horizontal = 1;
    }

    if (position.vertical < 1) {
        position.vertical = 1;
    }

    CGSize tableSize = [(SSTextTableView *)self.tableView charSize];

    if (CGSizeEqualToSize(tableSize, CGSizeZero)) {
        return UIOffsetMake(1, 1);
    }

    if (position.horizontal > tableSize.width) {
        position.horizontal = tableSize.width;
    }

    // offset from the top of the screen, not the start of the scroll history
    NSUInteger rowOffset = (NSUInteger)position.vertical;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbad-function-cast"
    NSUInteger screenRows = (NSUInteger)SPLFloat_floor(tableSize.height);
#pragma clang diagnostic pop

    if (rowOffset > screenRows) {
        rowOffset = screenRows;
    }

    if ([self numberOfItems] > screenRows) {
        position.vertical = [self numberOfItems] - screenRows + rowOffset;
    } else {
        position.vertical = rowOffset;
    }

    return position;
}

- (void)adjustCursorPositionByOffset:(UIOffset)offset {
    CGSize screenSize = [(SSTextTableView *)self.tableView charSize];
    CGFloat columnIndex = MAX(1, SPLFloat_floor(self.cursorPosition.horizontal + offset.horizontal));

    if (columnIndex > screenSize.width) {
        columnIndex = (NSUInteger)screenSize.width;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbad-function-cast"
    NSUInteger screenRows = (NSUInteger)SPLFloat_floor(screenSize.height);
#pragma clang diagnostic pop
    
    NSUInteger minimumRow;

    if ([self numberOfItems] > screenRows) {
        minimumRow = [self numberOfItems] - screenRows;
    } else {
        minimumRow = 1;
    }

    CGFloat rowIndex = MAX(1, SPLFloat_floor(self.cursorPosition.vertical + offset.vertical));

    if (rowIndex < minimumRow) {
        rowIndex = minimumRow;
    } else if (rowIndex > minimumRow + screenRows) {
        rowIndex = 1 + minimumRow + screenRows;
    }

//    DLog(@"Adjust %@ by %@ to %@",
//         NSStringFromUIOffset(self.cursorPosition),
//         NSStringFromUIOffset(offset),
//         NSStringFromUIOffset(UIOffsetMake(columnIndex, rowIndex)));

    _cursorPosition = UIOffsetMake(columnIndex, rowIndex);
}

@end
