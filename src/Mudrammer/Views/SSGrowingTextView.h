//
//  SSGrowingTextView.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/2/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@protocol SSGrowingTextViewDelegate;

@interface SSGrowingTextView : UITextView

@property (nonatomic, assign) CGFloat minHeight;
@property (nonatomic, assign) CGFloat maxHeight;

@property (nonatomic, weak) id <UITextViewDelegate, SSGrowingTextViewDelegate> textDelegate;

- (instancetype) initWithFrame:(CGRect)frame
                 textContainer:(NSTextContainer *)textContainer;

@property (nonatomic, readonly) CGSize currentContentSize;

@end

@protocol SSGrowingTextViewDelegate <NSObject, UITextViewDelegate>

- (void) growingTextViewPressedKeyCommand:(NSString *)keyCommand;

- (void) growingTextViewSentDirectionalCommand:(NSString *)direction;

@end
