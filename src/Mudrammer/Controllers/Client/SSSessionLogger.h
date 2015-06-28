//
//  SSSessionLogger.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/10/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

@import Foundation;

@interface SSSessionLogger : NSObject

/**
 *  Generate the name of a logging filename to use.
 *  This uses a very simple scheme based on current time.
 *
 *  @param hostname of the world being logged
 *
 *  @return a name you might use, like "nanvaent.org - 3/15/15.html"
 */
+ (NSString *) logFileNameForHost:(NSString *)hostname;

/**
 *  Return the contents of a log with the given file name.
 *
 *  @param name the file name
 *
 *  @return the contents of the log file
 */
+ (NSString *) contentsOfLogWithFileName:(NSString *)name;

/**
 *  Log some stuff. Asynchronous, thread-safe
 *
 *  @param  text text to log
 *  @param  filename filename to log to
 */
- (void) appendText:(NSString *)text
     toFileWithName:(NSString *)filename;

/**
 *  Log some stuff with a completion block called on main thread
 *
 *  @param completion completion block, called with a BOOL indicating write success
 */
- (void)appendText:(NSString *)text
    toFileWithName:(NSString *)filename
        completion:(void (^)(BOOL))completion;

/**
 *  Stop logging to a particular filename. Closes the output stream and removes it from cache.
 *
 *  @param name file name
 */
- (void) closeStreamForFileName:(NSString *)name;

@end
