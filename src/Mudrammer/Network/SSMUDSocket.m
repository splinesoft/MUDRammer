//
//  SSMUDSocket.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 1/15/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSMUDSocket.h"
#import "SSAdvSettingsController.h"
#import "SSANSIEngine.h"
#import "SPLTelnetLib.h"
#import "NSAttributedString+SPLAdditions.h"
#import "NSCharacterSet+SPLAdditions.h"
#import "SSStringCoder.h"

#define SPLSOCKET_BRIDGE_STRING __bridge NSString *
#define SPLSOCKET_BRIDGE_NUMBER __bridge NSNumber *

@interface GCDAsyncSocket (SPLAdditions)

- (void) readFromSocket;

@end

@interface SSMUDSocket () <SPLTelnetLibDelegate>

- (void) informDelegateWithSelector:(SEL)selector object:(id)object;

// Perform append from cache and split on broken ANSI sequences
- (NSString *) stringBySplittingAndCachingString:(NSString *)string;

@property (nonatomic, strong) GCDAsyncSocket *socket;
@property (nonatomic, strong) NSMutableString *dataCache;
@property (nonatomic, strong) SSANSIEngine *ansiEngine;
@property (nonatomic, strong) SPLTelnetLib *telnetLib;

// Ensure that text is processed one at a time and FIFO
@property (nonatomic, strong) NSOperationQueue *parsingQueue;

@end

@implementation GCDAsyncSocket (SPLAdditions)

- (void)readFromSocket {
    [self readDataWithTimeout:-1 tag:0];
}

@end

@implementation SSMUDSocket

#pragma mark - init

- (instancetype)initWithSocket:(GCDAsyncSocket *)socket
                      delegate:(id <SSMUDSocketDelegate>)delegate {

    if ((self = [super init])) {
        _dataCache = [NSMutableString string];
        _parsingQueue = [NSOperationQueue ss_serialOperationQueue];
        _ansiEngine = [SSANSIEngine new];

        _socket = socket;
        self.socket.delegate = self;
        self.socket.delegateQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        _SSdelegate = delegate;
    }

    return self;
}

- (void)dealloc {
    [self.parsingQueue cancelAllOperations];
    self.socket.delegate = nil;
    _SSdelegate = nil;
    [self.socket disconnect];
}

#pragma mark - Connection Lifecycle

- (void)resetSocket {
    [self.socket setDelegate:nil delegateQueue:NULL];
}

- (BOOL)connectToHostname:(NSString *)hostname
                   onPort:(NSUInteger)port
                    error:(NSError *__autoreleasing *)error {
    
    return [self.socket connectToHost:hostname
                               onPort:(uint16_t)port
                          withTimeout:30
                                error:error];
}

- (BOOL)isDisconnected {
    return [self.socket isDisconnected];
}

- (void)disconnect {
    [self.socket disconnect];
}

#pragma mark - informing delegate

- (void)informDelegateWithSelector:(SEL)selector object:(id)object {
    if ([self.SSdelegate respondsToSelector:selector]) {
        dispatch_async( dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *sel = NSStringFromSelector(selector);

            if( [sel isEqualToString:NSStringFromSelector(@selector(mudsocketDidConnectToHost:))] )
                [self.SSdelegate mudsocketDidConnectToHost:self];
            else if( [sel isEqualToString:NSStringFromSelector(@selector(mudsocket:didDisconnectWithError:))] )
                [self.SSdelegate mudsocket:self didDisconnectWithError:object];
        });
    }
}

#pragma mark - socket options states

- (BOOL)shouldEchoText {
    return self.telnetLib.shouldEchoText;
}

- (NSString *)stringBySplittingAndCachingString:(NSString *)string {

    NSMutableString *fullStr = [NSMutableString new];

    // Append from cache
    if ([self.dataCache length] > 0) {
        DLog(@"append from %@", self.dataCache);

        [fullStr appendString:self.dataCache];

        [self.dataCache deleteCharactersInRange:NSMakeRange(0, [self.dataCache length])];
    }

    [fullStr appendString:string];

    if ([fullStr length] == 0) {
        return @"";
    }

    // Find the last CSI in this sequence, if any
    NSString *searchStr = [kANSIEscapeCSI substringToIndex:1];

    NSRange CSIRange = [fullStr rangeOfString:searchStr
                                      options:NSBackwardsSearch | NSLiteralSearch];

    if (CSIRange.location == NSNotFound) {
        return fullStr;
    }

    // We've found the start of an ANSI CSI sequence. Was it terminated properly?
    NSRange CSITerminationRange = [fullStr rangeOfCharacterFromSet:[NSCharacterSet CSITerminationCharacterSet]
                                                           options:NSLiteralSearch
                                                             range:NSMakeRange(CSIRange.location, [fullStr length] - CSIRange.location)];

    if (CSITerminationRange.location == NSNotFound) {
        // We have an ANSI CSI that was started but not terminated.
        // Split the string here and cache it for next time.

        NSRange cacheRange = NSMakeRange(CSIRange.location, [fullStr length] - CSIRange.location);

        [self.dataCache appendString:[fullStr substringWithRange:cacheRange]];

        [fullStr deleteCharactersInRange:cacheRange];

        DLog(@"caching %@", self.dataCache);
    }

    return fullStr;
}

#pragma mark - Read/write

- (void)sendUserCommands:(NSArray *)commands {
    if (![self.socket isConnected]) {
        return;
    }

    self.ansiEngine.defaultTextColor = [[SSThemes sharedThemer] valueForThemeKey:kThemeFontColor];

    [self.telnetLib sendUserCommands:commands];
}

#pragma mark - NAWS

- (void)sendNAWSWithSize:(CGSize)size {
    [self.telnetLib sendNAWSWithSize:size];
}

#pragma mark - GCDAsyncSocketDelegate

- (void)socketDidSecure:(GCDAsyncSocket *)sock {
    dispatch_async(dispatch_get_main_queue(), ^{
        SSAttributedLineGroup *secureLine = [SSAttributedLineGroup lineGroupWithAttributedString:
                                             [NSAttributedString worldStringForString:NSLocalizedString(@"SSL_SUCCESS", nil)]];

        [self.SSdelegate mudsocket:self
     didReceiveAttributedLineGroup:secureLine];
    });
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    // try to background it
    [sock performBlock:^{
        [sock enableBackgroundingOnSocket];
    }];

    // reset telnet lib
    _telnetLib = [[SPLTelnetLib alloc] initWithDelegate:self
                                            stringCoder:[SSStringCoder new]];

    // Reset default string color
    self.ansiEngine.defaultTextColor = [[SSThemes sharedThemer] valueForThemeKey:kThemeFontColor];

    // try to enable SSL
    if ([self.SSdelegate respondsToSelector:@selector(mudsocketShouldAttemptSSL:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([self.SSdelegate mudsocketShouldAttemptSSL:self]) {
                DLog(@"ATTEMPTING SSL");
                [sock startTLS:@{
                     (SPLSOCKET_BRIDGE_STRING)kCFStreamSSLLevel                     : (SPLSOCKET_BRIDGE_STRING)kCFStreamSocketSecurityLevelNegotiatedSSL,
        #pragma clang diagnostic push
        #pragma clang diagnostic ignored "-Wdeprecated-declarations"
                     (SPLSOCKET_BRIDGE_STRING)kCFStreamSSLAllowsExpiredCertificates : (SPLSOCKET_BRIDGE_NUMBER)kCFBooleanFalse,
                     (SPLSOCKET_BRIDGE_STRING)kCFStreamSSLAllowsExpiredRoots        : (SPLSOCKET_BRIDGE_NUMBER)kCFBooleanFalse,
                     (SPLSOCKET_BRIDGE_STRING)kCFStreamSSLAllowsAnyRoot             : (SPLSOCKET_BRIDGE_NUMBER)kCFBooleanTrue,
        #pragma clang diagnostic pop
                     (SPLSOCKET_BRIDGE_STRING)kCFStreamSSLValidatesCertificateChain : (SPLSOCKET_BRIDGE_NUMBER)kCFBooleanTrue,
                }];
            }
        });
    }

    // Clear saved options
    self.dataCache = [NSMutableString new];

    [self.telnetLib socketDidConnect];

    // inform delegate
    [self informDelegateWithSelector:@selector(mudsocketDidConnectToHost:)
                              object:nil];

    // Start reading!
    [sock readFromSocket];
}

- (void)socketDidDisconnect:(SSMUDSocket *)sock withError:(NSError *)err {
    @weakify(self);
    [self.parsingQueue ss_addBlockOperationWithBlock:^(SSBlockOperation *operation) {
        @strongify(self);
        self.telnetLib = nil;
        [self informDelegateWithSelector:@selector(mudsocket:didDisconnectWithError:)
                                  object:err];
    }];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    @weakify(self);

    [self.parsingQueue ss_addBlockOperationWithBlock:^(SSBlockOperation *operation) {
        @strongify(self);
        if ([operation isCancelled]) {
            return;
        }

        // Initiate telnet library processing
        DLog(@"RCV %@ bytes", @([data length]));
        [self.telnetLib receivedSocketData:data];
    }];

    // Continue reading
    [sock readFromSocket];
}

- (void)socket:(SSMUDSocket *)sock didWriteDataWithTag:(long)tag {
    // anything to do here?
}

#pragma mark - SPLTelnetLibDelegate

- (void)telnetLibrary:(SPLTelnetLib *)library receivedMSSPData:(NSDictionary *)MSSPData {
    if ([self.SSdelegate respondsToSelector:@selector(mudsocket:receivedMSSPData:)]) {
        [self.SSdelegate mudsocket:self receivedMSSPData:MSSPData];
    }
}

- (void)telnetLibrary:(SPLTelnetLib *)library encounteredFatalError:(NSString *)error {
    DLog(@"Fatal telnet error: %@", error);
    // TODO: surface this error to the user
    [self.socket disconnect];
}

- (void)telnetLibrary:(SPLTelnetLib *)library mustSendData:(NSData *)data {
    DLog(@"Sending data %@", data.charCodeString);
    [self.socket writeData:data withTimeout:-1 tag:0];
}

- (void)telnetLibrary:(SPLTelnetLib *)library shouldPrintString:(NSString *)string {
    [self.parsingQueue ss_addBlockOperationWithBlock:^(SSBlockOperation *operation) {
        if ([string length] == 0 || [operation isCancelled]) {
            return;
        }

        // Split and cache
        NSString *fullStr = [self stringBySplittingAndCachingString:string];

        if ([fullStr length] == 0 || [operation isCancelled]) {
            return;
        }

        // Parse ANSI into an attributed line group
        SSAttributedLineGroup *group = [self.ansiEngine parseANSIString:fullStr];

        if ([operation isCancelled]) {
            return;
        }

        if ([self.SSdelegate respondsToSelector:@selector(mudsocket:didReceiveAttributedLineGroup:)]) {
            dispatch_async( dispatch_get_main_queue(), ^{
                [self.SSdelegate mudsocket:self didReceiveAttributedLineGroup:group];
            });
        }
    }];
}

@end
