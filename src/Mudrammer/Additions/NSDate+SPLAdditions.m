//
//  NSDate+SPLAdditions.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/29/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "NSDate+SPLAdditions.h"

@implementation NSDate (SPLAdditions)

- (NSString *)SPLShortDateTimeValue {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        formatter.timeStyle = NSDateFormatterShortStyle;
        formatter.dateStyle = NSDateFormatterShortStyle;
    });

    return [formatter stringFromDate:self];
}

- (NSString *)SPLTimeSinceValue {
    NSTimeInterval interval = [[NSDate date] timeIntervalSinceDate:self];

    if (interval < 0) {
        return @""; // wat
    }

    if (interval < 120) {
        return @"just now";
    } else if (interval < 60 * 60) {
        return [NSString stringWithFormat:@"%@ minutes", @(SPLFloat_round((CGFloat)interval / 60))];
    } else if (interval < 60 * 60 * 24) {
        return [NSString stringWithFormat:@"%@ hours", @(SPLFloat_round((CGFloat)interval / (60 * 60)))];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbad-function-cast"
        NSInteger days = (NSInteger)SPLFloat_floor((CGFloat)interval / (60 * 60 * 24));
        NSInteger hours = (NSInteger)SPLFloat_floor(((CGFloat)interval - (days * 60 * 60 * 24)) / (60 * 60));
#pragma clang diagnostic pop
        NSMutableString *str = [NSMutableString string];

        if (days > 0) {
            [str appendFormat:@"%@ day%@",
             @(days),
             (days != 1 ? @"s" : @"")];
        }

        if (hours > 0) {
            if (days > 0) {
                [str appendString:@", "];
            }

            [str appendFormat:@"%@ hour%@",
                @(hours),
                (hours != 1 ? @"s" : @"")];
        }

        return str;
    }
}

@end
