//
//  NSScanner+SPLAdditions.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/8/15.
//  Copyright (c) 2015 Jonathan Hersh. All rights reserved.
//

@import Foundation;

@interface NSScanner (SPLAdditions)

/**
 *  Scan a single character from the provided set.
 *
 *  @param set    character set to scan
 *  @param result the character scanned
 *
 *  @return YES if any characters were scanned
 */
- (BOOL) SPLScanCharacterFromSet:(NSCharacterSet *)set
                      intoString:(NSString *__autoreleasing *)result;

@end
