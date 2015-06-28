//
//  SPLTelnetLib.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/23/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import Foundation;

@protocol SPLTelnetLibDelegate;
@class SSStringCoder;

@interface SPLTelnetLib : NSObject

// Start here!
- (instancetype) initWithDelegate:(id <SPLTelnetLibDelegate>)delegate
                      stringCoder:(SSStringCoder *)stringCoder;

@property (nonatomic, weak) id <SPLTelnetLibDelegate> delegate;

@property (nonatomic, strong, readonly) SSStringCoder *stringCoder;

/**
 *  Whether the client should echo text. YES by default.
 */
@property (nonatomic, assign, readonly) BOOL shouldEchoText;

/**
 *  The socket successfully connected. We should send some commands
 *  that indicate our capabilities (NAWS, TTYPE, etc).
 */
- (void) socketDidConnect;

/**
 *  When the socket receives data, it must pass that data to the telnet lib
 *  before performing any other processing. The telnet lib will call delegate
 *  methods as appropriate.
 *
 *  @param data data received
 */
- (void) receivedSocketData:(NSData *)data;

/**
 * Convert some user commands to data and then send them.
 */
- (void) sendUserCommands:(NSArray *)commands;

/**
 *  The socket should send a NAWS message with the specified size.
 *
 *  @param size size to send
 */
- (void) sendNAWSWithSize:(CGSize)size;

@end

/**
 *  All delegate methods are called on the main thread.
 */
@protocol SPLTelnetLibDelegate <NSObject>

@required
/**
 *  The telnet library has created some data that must be sent over the socket.
 *
 *  @param library the telnet library
 *  @param data    data to send
 */
- (void) telnetLibrary:(SPLTelnetLib *)library mustSendData:(NSData *)data;

@optional
/**
 *  The telnet library has received some data and parsed it into a string that should be printed to the user.
 *
 *  @param library the telnet library
 *  @param string  string to print
 */
- (void) telnetLibrary:(SPLTelnetLib *)library shouldPrintString:(NSString *)string;

/**
 *  The telnet library has encountered an unrecoverable error. The socket must disconnect immediately.
 *
 *  @param library the telnet library
 *  @param error   a string describing the fatal error
 */
- (void) telnetLibrary:(SPLTelnetLib *)library encounteredFatalError:(NSString *)error;

/**
 *  The telnet library has received some MSSP data and parsed it into a dictionary.
 *
 *  @param library  the telnet library
 *  @param MSSPData dictionary of MSSP data
 */
- (void) telnetLibrary:(SPLTelnetLib *)library receivedMSSPData:(NSDictionary *)MSSPData;

@end
