//
//  SSStringCoder.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 12/8/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSStringCoder.h"

@implementation SSStringCoder

- (instancetype)init {
    if ((self = [super init])) {
        // Setup encodings
        NSMutableArray *arr = [NSMutableArray array];
        const NSStringEncoding *availableEncodings = [NSString availableStringEncodings];

        while (*availableEncodings) {
            NSStringEncoding encoding = *availableEncodings;
            NSString *name = [NSString localizedNameOfStringEncoding:encoding];

            if ([name length] == 0) {
                // DLog(@"unknown %u", encoding);
                availableEncodings++;
                continue;
            }

            [arr addObject:[[SSStringEncoding alloc] initWithName:name
                                                         encoding:encoding
                                                             type:kStringEncodingTypeNSStringEncoding]];

            availableEncodings++;
        }

        // Custom NSStringEncodings
        NSDictionary *NSEncodings = @{
             @"ASCII" : @(NSASCIIStringEncoding),
             @"CP1251 (Cyrillic)" : @(NSWindowsCP1251StringEncoding),
             @"ISO 2022 (Japanese)" : @(NSISO2022JPStringEncoding),
        };

        [NSEncodings enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSNumber *encoding, BOOL *stop) {
            [arr addObject:[[SSStringEncoding alloc] initWithName:name
                                                         encoding:[encoding unsignedIntegerValue]
                                                             type:kStringEncodingTypeNSStringEncoding]];
        }];

        // CFStringEncodings
        NSDictionary *CFEncodings = @{
             @"Big5 (Chinese)" : @(kCFStringEncodingBig5),
             @"KOI8 (Russian)" : @(kCFStringEncodingKOI8_R),
             @"EUCKR (Korean)" : @(kCFStringEncodingEUC_KR),
             @"EUC JP" : @(kCFStringEncodingEUC_JP),
             @"GB (Chinese)"   : @(kCFStringEncodingEUC_CN),
             @"HZ GB (Chinese)" : @(kCFStringEncodingHZ_GB_2312),
             @"Latin 1 (ISO-8859)" : @(kCFStringEncodingISOLatin1),

             // DOS
             @"DOS Latin (CP 437)" : @(kCFStringEncodingDOSLatinUS),
             @"DOS Korean (CP 949)" : @(kCFStringEncodingDOSKorean),
             @"DOS Japanese (CP 932)" : @(kCFStringEncodingDOSJapanese),
             @"DOS Chinese Simplified (CP 936)" : @(kCFStringEncodingDOSChineseSimplif),
             @"DOS Chinese Traditional (CP 950)" : @(kCFStringEncodingDOSChineseTrad),
             @"DOS Hebrew (CP 862)" : @(kCFStringEncodingDOSHebrew),
             @"DOS Greek (CP 737)" : @(kCFStringEncodingDOSGreek),
             @"DOS Russian (CP 866)" : @(kCFStringEncodingDOSRussian),
        };

        [CFEncodings enumerateKeysAndObjectsUsingBlock:^(NSString *name, NSNumber *encoding, BOOL *stop) {
            [arr addObject:[[SSStringEncoding alloc] initWithName:name
                                                         encoding:[encoding unsignedIntegerValue]
                                                             type:kStringEncodingTypeCFStringEncoding]];
        }];

        [arr sortUsingComparator:[SSStringEncoding encodingComparator]];

        _encodings = [arr copy];
    }

    return self;
}

#pragma mark - Encoding access

- (SSStringEncoding *)encodingFromLocalizedEncodingName:(NSString *)name {
    for (SSStringEncoding *encoding in _encodings) {
        if ([encoding.localizedName isEqualToString:name])
            return encoding;
    }

    if ([name isEqualToString:@"ASCII"]) {
        return nil;
    }

    return [self encodingFromLocalizedEncodingName:@"ASCII"];
}

- (SSStringEncoding *)currentStringEncoding {
    return [self encodingFromLocalizedEncodingName:
            [[NSUserDefaults standardUserDefaults]
             stringForKey:kPrefStringEncoding]];
}

#pragma mark - User commands

- (NSData *)dataForUserCommands:(NSArray *)commands {
    NSMutableData *data = [NSMutableData data];

    for (NSString *command in commands) {
        NSData *encodedUserInput;

        @try {
            encodedUserInput = [self dataByEncodingStringWithCurrentEncoding:command];
        } @catch (NSException *exc) {

        }

        if ([encodedUserInput length] > 0) {
            [data appendData:encodedUserInput];

            // CRLF
            [data appendData:[NSData dataWithBytes:"\x0D\x0A" length:2]];
        }
    }

    return [NSData dataWithData:data];
}

#pragma mark - Encode/decode

- (NSString *)stringByDecodingDataWithCurrentEncoding:(NSData *)data {
    return [self stringByDecodingData:data
                         withEncoding:[self currentStringEncoding]];
}

- (NSString *)stringByDecodingData:(NSData *)data withEncoding:(SSStringEncoding *)encoding {
    if( [data length] == 0 )
        return @"";

    DLog(@"Decode %@ with %@", @([data length]), encoding);

    NSString *ret;

    switch (encoding.encodingType) {
        case kStringEncodingTypeNSStringEncoding:

            ret = [[NSString alloc] initWithData:data
                                        encoding:(NSStringEncoding)encoding.encoding];

            break;

        case kStringEncodingTypeCFStringEncoding: {

            CFStringRef cString = CFStringCreateFromExternalRepresentation(NULL,
                                                                           (__bridge CFDataRef)data,
                                                                           (CFStringEncoding)encoding.encoding
                                                                           );

            if (cString) {
                ret = CFBridgingRelease(cString);
            }

            break;
        }
    }

    if ([ret length] == 0) {
        // We couldn't decode data using the user's preferred encoding.
        // Try once again with ASCII.
        DLog(@"retry with ascii");
        ret = [[NSString alloc] initWithData:data
                                    encoding:NSASCIIStringEncoding];
    }


    return ret;
}


- (NSData *)dataByEncodingStringWithCurrentEncoding:(NSString *)str {
    return [self dataByEncodingString:str
                         withEncoding:[self currentStringEncoding]];
}

- (NSData *)dataByEncodingString:(NSString *)str withEncoding:(SSStringEncoding *)encoding {

    NSData *ret;

    DLog(@"Encode %@ with %@", @([str length]), encoding);

    switch (encoding.encodingType) {
        case kStringEncodingTypeNSStringEncoding:

            ret = [str dataUsingEncoding:(NSStringEncoding)encoding.encoding
                    allowLossyConversion:NO];

            break;

        case kStringEncodingTypeCFStringEncoding: {

            CFDataRef dataRef = CFStringCreateExternalRepresentation(NULL,
                                                                     (__bridge CFStringRef)str,
                                                                     (CFStringEncoding)encoding.encoding,
                                                                     0
                                                                     );

            if (dataRef) {
                ret = CFBridgingRelease(dataRef);
            }

            break;
        }
    }

    if (!ret) {
        ret = [str dataUsingEncoding:NSASCIIStringEncoding
                allowLossyConversion:YES];
    }

    return ret;
}

@end

@interface SSStringEncoding ()

@property (nonatomic, copy) NSString * localizedName;
@property (nonatomic, assign) NSUInteger encoding;
@property (nonatomic, assign) kStringEncodingType encodingType;

@end

@implementation SSStringEncoding

- (instancetype)initWithName:(NSString *)name encoding:(NSUInteger)encoding type:(kStringEncodingType)type {
    if ((self = [self init])) {
        _localizedName = name;
        _encoding = encoding;
        _encodingType = type;
    }

    return self;
}

+ (NSComparator) encodingComparator {
    return ^NSComparisonResult(SSStringEncoding *one, SSStringEncoding *two) {
        return [one.localizedName compare:two.localizedName
                                  options:NSCaseInsensitiveSearch];
    };
}

- (BOOL)isEqual:(id)object {
    return [object isKindOfClass:[SSStringEncoding class]]
    && [((SSStringEncoding *)object).localizedName isEqualToString:self.localizedName]
    && ((SSStringEncoding *)object).encoding == self.encoding
    && ((SSStringEncoding *)object).encodingType == self.encodingType;
}

- (NSUInteger)hash {
    NSUInteger result = 1, prime = 31;

    result = prime * result + [self.localizedName hash];

    return result;
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ %@ (%@ %@)",
            [super description],
            self.localizedName,
            @(self.encoding),
            @(self.encodingType)];
}

- (id)copyWithZone:(NSZone *)zone {
    return [[SSStringEncoding alloc] initWithName:self.localizedName
                                         encoding:self.encoding
                                             type:self.encodingType];
}

@end
