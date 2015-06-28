//
//  SSMudHistoryControl.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/25/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSMudHistoryControl.h"

@interface SSMudHistoryControl ()

- (void) segmentControlPressed:(id)sender;

- (instancetype) init;

@end

@implementation SSMudHistoryControl
{
    NSMutableArray *commandHistory;
    NSInteger currentIndex;
    NSString *stashedText;
}

#pragma mark - init

- (instancetype) init {
    if ((self = [super init])) {
        self.momentary = YES;
        self.contentMode = UIViewContentModeCenter;

        [self insertSegmentWithImage:[SPLImagesCatalog historyUpImage]
                             atIndex:HistoryDirectionBackwards
                            animated:NO];
        [self insertSegmentWithImage:[SPLImagesCatalog historyDownImage]
                             atIndex:HistoryDirectionForwards
                            animated:NO];

        commandHistory = [NSMutableArray array];
        currentIndex = -1;

        [self addTarget:self
                 action:@selector(segmentControlPressed:)
       forControlEvents:UIControlEventValueChanged];

        [self sizeToFit];
        [self enableSegments];
    }

    // Set up accessibility for button segments
    UIView *segment = self.subviews[0];
    segment.accessibilityLabel = NSLocalizedString(@"HISTORY_BACK", nil);
    segment.accessibilityHint = @"Moves one step back in command history.";

    segment = self.subviews[1];
    segment.accessibilityLabel = NSLocalizedString(@"HISTORY_FORWARD", nil);
    segment.accessibilityHint = @"Moves one step forward in command history.";

    return self;
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];

    self.alpha = ( enabled ? 1.0f : 0.15f );
}

- (void)dealloc {
    [commandHistory removeAllObjects];

    _delegate = nil;
}

#pragma mark - history

- (BOOL)isAtStart {
    return currentIndex <= 0;
}

- (BOOL)isAtEnd {
    return currentIndex == -1 || currentIndex >= (NSInteger)[commandHistory count];
}

- (void)purgeCommandHistory {
    [commandHistory removeAllObjects];
    currentIndex = -1;
    [self enableSegments];
}

- (void)addCommand:(NSString *)command {
    if( [command length] == 0 )
        return;

    if( ![[commandHistory lastObject] isEqualToString:command] )
        [commandHistory addObject:command];

    currentIndex = (NSInteger)[commandHistory count];

    [self enableSegments];
}

- (void)enableSegments {
    [self setEnabled:( currentIndex > 0 )
   forSegmentAtIndex:HistoryDirectionBackwards];

    [self setEnabled:( [commandHistory count] > 0 && currentIndex < (NSInteger)[commandHistory count] )
   forSegmentAtIndex:HistoryDirectionForwards];
}

#pragma mark - actions

- (void)moveHistory:(HistoryDirection)direction {
    [self setSelectedSegmentIndex:direction];
    [self segmentControlPressed:nil];
}

- (void)segmentControlPressed:(id)sender {
    switch( [self selectedSegmentIndex] ) {
        case HistoryDirectionBackwards:
            currentIndex--;
            break;
        case HistoryDirectionForwards:
            currentIndex++;
            break;
    }

    NSString *cmd = nil;
    id del = self.delegate;

    if( currentIndex < 0 )
        currentIndex = 0;

    if (currentIndex >= (NSInteger)[commandHistory count]) {
        currentIndex = (NSInteger)[commandHistory count];
        cmd = @"";
    } else {
        cmd = commandHistory[(NSUInteger)currentIndex];
    }

    if ([del respondsToSelector:@selector(mudHistoryControl:willChangeToCommand:)]) {
        [del mudHistoryControl:self willChangeToCommand:cmd];
    }

    [self enableSegments];
}

@end
