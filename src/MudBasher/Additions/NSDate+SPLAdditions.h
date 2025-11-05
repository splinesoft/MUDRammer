//
//  NSDate+SPLAdditions.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/29/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@interface NSDate (SPLAdditions)

/**
 *  Return a formatted string for this date using the short date and time styles.
 *
 *  @return a string for this date
 */
@property (nonatomic, readonly, copy) NSString *SPLShortDateTimeValue;

/**
 *  Assuming a date in the past, return a relative duration string like "3 days".
 *
 *  @return a string describing this date relatively
 */
@property (nonatomic, readonly, copy) NSString *SPLTimeSinceValue;

@end
