//
//  SSMudHistoryDelegate.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/25/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import Foundation;

@class SSMudHistoryControl;

@protocol SSMudHistoryDelegate <NSObject>

@optional

- (void) mudHistoryControl:(SSMudHistoryControl *)control willChangeToCommand:(NSString *)command;

@end
