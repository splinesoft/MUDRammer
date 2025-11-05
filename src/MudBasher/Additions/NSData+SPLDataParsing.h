//
//  NSData+SPLDataParsing.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 4/27/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import Foundation;

@interface NSData (SPLDataParsing)

/**
 *  Return the byte at the specified index.
 *
 *  @param index index of data
 *
 *  @return the byte at this index
 */
- (unsigned char) characterAtIndex:(NSUInteger)index;

/**
 *  Return a space-delimited string of the bytes in this data object.
 *
 *  @return a string of bytes
 */
@property (nonatomic, readonly, copy) NSString *charCodeString;

@end
