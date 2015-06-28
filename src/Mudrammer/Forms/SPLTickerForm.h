//
//  SPLTickerForm.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import Foundation;
#import <FXForms.h>

@class Ticker;

@interface SPLTickerForm : NSObject <FXForm>

+ (instancetype) formForTicker:(Ticker *)ticker;

@property (nonatomic, copy) NSString *commands;
@property (nonatomic, copy) NSNumber *interval;
@property (nonatomic, copy) NSString *soundFileName;
@property (nonatomic, assign) BOOL isEnabled;

// Non-form
@property (nonatomic, strong) Ticker *ticker;

@end
