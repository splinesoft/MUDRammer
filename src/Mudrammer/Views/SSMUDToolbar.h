//
//  SSMUDToolbar.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/1/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import UIKit;

#import "SSStashButton.h"
#import "SSMudHistoryControl.h"
#import "SSGrowingTextView.h"

@protocol SSMUDToolbarDelegate;

extern UIEdgeInsets const kToolbarInsets;

@interface SSMUDToolbar : UIView <SSGrowingTextViewDelegate>

// Enable/disable text field and buttons
- (void) setInputBarEnabled:(BOOL)enabled;

@property (nonatomic, strong) SSStashButton *stashButton;
@property (nonatomic, strong) SSGrowingTextView *textView;
@property (nonatomic, strong) SSMudHistoryControl *historyControl;

@property (nonatomic, weak) id <SSMUDToolbarDelegate> toolbarDelegate;

- (instancetype) initWithFrame:(CGRect)frame;

@end

@protocol SSMUDToolbarDelegate <NSObject>

@optional

- (void) mudToolbar:(SSMUDToolbar *)toolbar willChangeToHeight:(CGFloat)height;

- (void) mudToolbar:(SSMUDToolbar *)toolbar didSendInput:(NSString *)input;

@end
