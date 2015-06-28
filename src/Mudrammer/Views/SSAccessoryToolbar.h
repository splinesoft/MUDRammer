//
//  SSAccessoryToolbar.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/19/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import <SSDataSources.h>

@protocol SSAccessoryToolbarDelegate;

@interface SSAccessoryToolbar : UIView <UICollectionViewDelegate, UICollectionViewDelegateFlowLayout>

@property (nonatomic, weak) id <SSAccessoryToolbarDelegate> accessoryDelegate;

@end

@protocol SSAccessoryToolbarDelegate <NSObject>

@optional

- (void) accessoryToolbarDidSendCommand:(NSString *)cmd;

@end
