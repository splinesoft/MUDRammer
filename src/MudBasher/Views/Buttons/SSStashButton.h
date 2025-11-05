//
//  SSStashButton.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/21/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@protocol SSStashDelegate;

@interface SSStashButton : UIButton

@property (nonatomic, weak) id <SSStashDelegate> delegate;

+ (instancetype) stashButton;

@property (nonatomic, readonly) BOOL stashContainsText;

@end

@protocol SSStashDelegate <NSObject>

@required

// User has tapped the stash button. Should swap input field with the stash text.
// Return a string to create a stash, or nil to clear the stash
- (NSString *) stashButton:(SSStashButton *)button didTapStash:(NSString *)stash;

@end
