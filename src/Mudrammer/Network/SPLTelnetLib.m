//
//  SPLTelnetLib.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/23/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLTelnetLib.h"
#import <libtelnet.h>
#import "SSStringCoder.h"
#import "NSData+SPLDataParsing.h"

typedef struct telnet_t * telnet_t_p;

@interface SPLTelnetLib ()

@property (nonatomic) telnet_t_p spl_telnet_t;

@property (nonatomic, assign, readwrite) BOOL shouldEchoText;

#pragma mark - TTYPE

@property (nonatomic, assign) NSUInteger ttypeIndex;

/**
 *  Iterate through our known terminal types and send the next one.
 */
- (void) sendTTYPE;

@end

static const telnet_telopt_t SPLTelOpts[] = {
    { TELNET_TELOPT_ECHO,      TELNET_WILL, TELNET_DO },
    { TELNET_TELOPT_SGA,       TELNET_WILL, TELNET_DO },
    { TELNET_TELOPT_TTYPE,     TELNET_WILL, TELNET_DO },
    { TELNET_TELOPT_COMPRESS,  TELNET_WONT, TELNET_DONT },
    { TELNET_TELOPT_COMPRESS2, TELNET_WILL, TELNET_DO },
    { TELNET_TELOPT_ZMP,       TELNET_WONT, TELNET_DONT },
    { TELNET_TELOPT_MSSP,      TELNET_WILL, TELNET_DO },
    { TELNET_TELOPT_BINARY,    TELNET_WONT, TELNET_DONT },
    { TELNET_TELOPT_NAWS,      TELNET_WILL, TELNET_DO },
    { -1, 0, 0 }
};

CG_INLINE void SPLTelnetEventHandler(telnet_t *telnet,
                                     telnet_event_t *ev,
                                     void *user_data) {

    SPLTelnetLib *lib = (__bridge SPLTelnetLib *)user_data;
    id <SPLTelnetLibDelegate> delegate = lib.delegate;

    switch (ev->type) {

        /* data received */
        case TELNET_EV_DATA:

            if ([delegate respondsToSelector:@selector(telnetLibrary:shouldPrintString:)]) {
                NSData *data = [NSData dataWithBytes:ev->data.buffer length:ev->data.size];
                NSString *string = [lib.stringCoder stringByDecodingDataWithCurrentEncoding:data];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate telnetLibrary:lib
                          shouldPrintString:string];
                });
            }

            break;

        /* data must be sent */
        case TELNET_EV_SEND:

            if ([delegate respondsToSelector:@selector(telnetLibrary:mustSendData:)]) {
                NSData *data = [NSData dataWithBytes:ev->data.buffer
                                              length:ev->data.size];

                dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate telnetLibrary:lib
                               mustSendData:data];
                });
            }

            break;

        case TELNET_EV_IAC:

            DLog(@"IAC %@", @(ev->iac.cmd));

            break;

        /* request to enable remote feature (or receipt) */
        case TELNET_EV_WILL: {

            unsigned char telopt = ev->neg.telopt;
            DLog(@"WILL %@", @(telopt));

            /* we'll agree to turn off our echo if server wants us to stop */
            if (telopt == TELNET_TELOPT_ECHO) {
                DLog(@"DISABLING ECHO");
                lib.shouldEchoText = NO;
            }

            break;
        }

        /* notification of disabling remote feature (or receipt) */
        case TELNET_EV_WONT: {

            unsigned char telopt = ev->neg.telopt;
            DLog(@"WONT %@", @(telopt));

            if (telopt == TELNET_TELOPT_ECHO) {
                DLog(@"ENABLING ECHO");
                lib.shouldEchoText = YES;
            }

            break;
        }
        /* request to enable local feature (or receipt) */
        case TELNET_EV_DO: {

            unsigned char telopt = ev->neg.telopt;
            DLog(@"DO %@", @(telopt));

            if (telopt == TELNET_TELOPT_TTYPE) {
                [lib sendTTYPE];
            }

            break;
        }

        /* demand to disable local feature (or receipt) */
        case TELNET_EV_DONT:

            DLog(@"DONT %@", @(ev->neg.telopt));

            break;

        /* respond to TTYPE commands */
        case TELNET_EV_TTYPE:

            /* respond with our terminal type, if requested */
            if (ev->ttype.cmd == TELNET_TTYPE_SEND) {
                [lib sendTTYPE];
            }

            break;

        /* respond to particular subnegotiations */
        case TELNET_EV_SUBNEGOTIATION:

            DLog(@"SUB %@", @(ev->sub.telopt));

            break;

        case TELNET_EV_COMPRESS:

            DLog(@"COMPRESS ENABLED");

            break;

            /* error */
        case TELNET_EV_ERROR:

            if ([delegate respondsToSelector:@selector(telnetLibrary:encounteredFatalError:)]) {
                NSString *errMsg = @(ev->error.msg);

                dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate telnetLibrary:lib
                      encounteredFatalError:errMsg];
                });
            }

            break;

        case TELNET_EV_ENVIRON:

            DLog(@"ENVIRON");

            break;

        case TELNET_EV_MSSP: {

            NSMutableDictionary *MSSPDict = [NSMutableDictionary dictionaryWithCapacity:ev->mssp.size];

            const struct telnet_environ_t *MSSPValues = ev->mssp.values;

            for (NSUInteger i = 0; i < ev->mssp.size; i++) {

                struct telnet_environ_t MSSPValue = *MSSPValues;

                if (MSSPValue.var == NULL || MSSPValue.value == NULL) {
                    continue;
                }

                NSString *key = @(MSSPValue.var);
                NSString *value = @(MSSPValue.value);

                if ([key length] > 0 && [value length] > 0) {
                    if ([MSSPDict[key] isKindOfClass:[NSArray class]]) {
                        MSSPDict[key] = [MSSPDict[key] arrayByAddingObject:value];
                    } else if ([MSSPDict[key] isKindOfClass:[NSString class]]) {
                        MSSPDict[key] = @[ MSSPDict[key], value ];
                    } else {
                        MSSPDict[key] = value;
                    }
                }

                MSSPValues++;
            }

            if ([delegate respondsToSelector:@selector(telnetLibrary:receivedMSSPData:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [delegate telnetLibrary:lib
                           receivedMSSPData:MSSPDict];
                });
            }

            break;
        }
        case TELNET_EV_WARNING:

            DLog(@"WARNING %@ file %@ func %@ line %@",
                 @(ev->error.msg),
                 @(ev->error.file),
                 @(ev->error.func),
                 @(ev->error.line));

            break;

        case TELNET_EV_ZMP:

            DLog(@"ZMP");

            break;
    }
}

@implementation SPLTelnetLib

- (instancetype)initWithDelegate:(id<SPLTelnetLibDelegate>)delegate stringCoder:(SSStringCoder *)stringCoder {
    if ((self = [super init])) {
        _shouldEchoText = YES;
        _ttypeIndex = 0;
        _spl_telnet_t = telnet_init(SPLTelOpts, SPLTelnetEventHandler, 0, (__bridge void *)self);
        _delegate = delegate;
        _stringCoder = stringCoder;
    }

    return self;
}

- (void)dealloc {
    telnet_free(_spl_telnet_t);
}

#pragma mark - Telnet Options

- (BOOL)isSimpleTelnetMode {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kPrefSimpleTelnetMode];
}

- (void)sendTTYPE {
    if ([self isSimpleTelnetMode]) {
        DLog(@"NO TTYPE - Simple");
        return;
    }

    // IAC SB TERMINAL-TYPE IS IBM-3278-2 IAC SE
    static NSArray *ttypes;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ttypes = @[
           @"MUDRAMMER",
           @"XTERM",
           @"ANSI",
        ];
    });

    // When we send the last TTYPE in our list, we should send the last item once more.
    // Any subsequent requests for TTYPE should go back to the first item in the list.
    NSString *type;

    if (self.ttypeIndex < [ttypes count]) {
        type = ttypes[self.ttypeIndex];
        self.ttypeIndex++;
    } else if(self.ttypeIndex == [ttypes count]) {
        type = [ttypes lastObject];
        self.ttypeIndex++;
    } else {
        type = [ttypes firstObject];
        self.ttypeIndex = 1;
    }

    DLog(@"SENDING TTYPE %@", type);

    telnet_ttype_is(self.spl_telnet_t, [type cStringUsingEncoding:NSASCIIStringEncoding]);
}

- (void)sendNAWSWithSize:(CGSize)size {
    if ([self isSimpleTelnetMode]) {
        DLog(@"NO NAWS - Simple");
        return;
    }

    DLog(@"SEND NAWS %@", NSStringFromCGSize(size));

    // IAC SB NAWS 0 80 0 24 IAC SE
    NSUInteger width = (NSUInteger)size.width;

    if (width >= UINT8_MAX) {
        width = UINT8_MAX - 1;
    }

    NSUInteger height = (NSUInteger)size.height;

    if (height >= UINT8_MAX) {
        height = UINT8_MAX - 1;
    }

    char message[4] = { 0, (char) width, 0, (char) height };

    telnet_subnegotiation(self.spl_telnet_t, TELNET_TELOPT_NAWS, message, 4);
}

#pragma mark - Telnet Events

- (void)socketDidConnect {
    if ([self isSimpleTelnetMode]) {
        DLog(@"NO CONNECT OPTS - SIMPLE TELNET");
        return;
    }

    DLog(@"SENDING CONNECT OPTS");

    telnet_negotiate(self.spl_telnet_t, TELNET_WILL, TELNET_TELOPT_TTYPE);
    telnet_negotiate(self.spl_telnet_t, TELNET_DO, TELNET_TELOPT_SGA);
    telnet_negotiate(self.spl_telnet_t, TELNET_WILL, TELNET_TELOPT_NAWS);
}

- (void)receivedSocketData:(NSData *)data {
    telnet_recv(self.spl_telnet_t, [data bytes], [data length]);
}

- (void)sendUserCommands:(NSArray *)commands {
    NSData *commandData = [self.stringCoder dataForUserCommands:commands];
    telnet_send(self.spl_telnet_t, [commandData bytes], [commandData length]);
}

@end
