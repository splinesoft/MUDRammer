//
//  SSMudHistoryControl.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/25/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import "SSMudHistoryDelegate.h"

@interface SSMudHistoryControl : UISegmentedControl

@property (nonatomic, weak) id <SSMudHistoryDelegate> delegate;

typedef NS_ENUM( NSUInteger, HistoryDirection ) {
    HistoryDirectionBackwards,
    HistoryDirectionForwards,
    HistoryNumSegments
};

@property (nonatomic, getter=isAtStart, readonly) BOOL atStart;
@property (nonatomic, getter=isAtEnd, readonly) BOOL atEnd;

// Navigate history
- (void) moveHistory:(HistoryDirection)direction;

// add a command to history
- (void) addCommand:(NSString *)command;

// purge history
- (void) purgeCommandHistory;

- (void) enableSegments;

@end
