//
//  NSCharacterSet+SPLAdditions.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/8/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

@import Foundation;

@interface NSCharacterSet (SPLAdditions)

/**
 *  A character set containing the characters that terminate a valid
 *  CSI sequence. ASCII characters 64 to 126.
 *
 *  @return the terminating character set
 */
+ (instancetype) CSITerminationCharacterSet;

/**
 *  A character set containing the intermediate characters of a CSI
 *  sequence. Bytes 32-47 plus ;.
 *
 *  @return the intermediate character set
 */
+ (instancetype) CSIIntermediateCharacterSet;

@end
