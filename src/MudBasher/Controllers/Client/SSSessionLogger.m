//
//  SSSessionLogger.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/10/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSSessionLogger.h"
#import <OSCache.h>

@interface SSSessionLogger () <OSCacheDelegate>

@property (nonatomic, strong) NSOperationQueue *logQueue;
@property (nonatomic, strong) OSCache *logCache;

- (instancetype) init;

- (NSOutputStream *) streamForFileAtPath:(NSString *)path;

+ (NSArray *) allLogURLs;

+ (NSString *) pathForLogWithFilename:(NSString *)filename;

+ (NSString *) contentsOfLogAtPath:(NSString *)path;

@end

@implementation SSSessionLogger

- (instancetype)init {
    if ((self = [super init])) {
        _logQueue = [NSOperationQueue ss_serialOperationQueue];
        _logCache = [OSCache new];
        [self.logCache setName:@"Logging Cache"];
        self.logCache.delegate = self;
    }

    return self;
}

- (void)dealloc {
    self.logCache.delegate = nil;
}

#pragma mark - Cache / Streams

- (NSOutputStream *)streamForFileAtPath:(NSString *)path {
    if ([path length] == 0) {
        return nil;
    }

    NSOutputStream *outputStream;

    @synchronized (self.logCache) {
        outputStream = [self.logCache objectForKey:path];

        if (!outputStream) {
            outputStream = [NSOutputStream outputStreamToFileAtPath:path append:YES];
            [self.logCache setObject:outputStream forKey:path];
            [outputStream open];
        }
    }

    return outputStream;
}

- (void)closeStreamForFileName:(NSString *)name {
    if ([name length] == 0) {
        return;
    }

    NSString *filePath = [self.class pathForLogWithFilename:name];

    if ([filePath length] == 0) {
        return;
    }

    [self.logQueue ss_addBlockOperationWithBlock:^(SSBlockOperation *operation) {
        if ([operation isCancelled]) {
            return;
        }

        NSOutputStream *outputStream = [self streamForFileAtPath:filePath];

        if (outputStream) {
            [outputStream close];
            [self.logCache removeObjectForKey:filePath];
        }
    }];
}

#pragma mark - Log Paths

+ (NSString *)SPLPublicDataPath {
    static NSString *path;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        //user documents folder
        path = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        path = [[NSString alloc] initWithString:path];
    });

    return path;
}

+ (NSArray *) allLogURLs {
    NSFileManager *manager = [NSFileManager defaultManager];

    NSURL *logFolder = [NSURL URLWithString:[self SPLPublicDataPath]];

    NSArray *URLs = [manager contentsOfDirectoryAtURL:logFolder
                           includingPropertiesForKeys:@[ NSURLNameKey, NSURLPathKey, NSURLCreationDateKey ]
                                              options:0
                                                error:nil];

    return URLs;
}

+ (NSString *)pathForLogWithFilename:(NSString *)filename {
  return [[self SPLPublicDataPath] stringByAppendingPathComponent:filename];
}

#pragma mark - Reading

+ (NSString *)logFileNameForHost:(NSString *)hostname {
    static NSDateFormatter *formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        formatter = [NSDateFormatter new];
        formatter.dateStyle = NSDateFormatterShortStyle;
        formatter.timeStyle = NSDateFormatterMediumStyle;
    });

    return [[[NSString stringWithFormat:@"%@ - %@.txt",
             ([hostname length] > 0
              ? hostname
              : @"World"),
             [formatter stringFromDate:[NSDate date]]]
            stringByReplacingOccurrencesOfString:@"/" withString:@"-"]
            stringByReplacingOccurrencesOfString:@":" withString:@"-"];
}

+ (NSString *)contentsOfLogWithFileName:(NSString *)name {
    return [self contentsOfLogAtPath:[self pathForLogWithFilename:name]];
}

+ (NSString *)contentsOfLogAtPath:(NSString *)path {
    if ([path length] == 0) {
        return nil;
    }

    NSData *fileData = [[NSFileManager defaultManager] contentsAtPath:path];

    if (!fileData) {
        return nil;
    }

    return [[NSString alloc] initWithData:fileData encoding:NSUTF8StringEncoding];
}

#pragma mark - Writing

- (void)appendText:(NSString *)text toFileWithName:(NSString *)filename {
    [self appendText:text
      toFileWithName:filename
          completion:nil];
}

- (void)appendText:(NSString *)text toFileWithName:(NSString *)filename completion:(void (^)(BOOL))completion {
    if ([text length] == 0 || [filename length] == 0) {
        return;
    }

    NSString *filePath = [self.class pathForLogWithFilename:filename];

    if ([filePath length] == 0) {
        return;
    }

    [self.logQueue ss_addBlockOperationWithBlock:^(SSBlockOperation *operation) {
        if ([operation isCancelled]) {
            return;
        }

        NSOutputStream *outputStream = [self streamForFileAtPath:filePath];

        if (!outputStream) {
            return;
        }

        NSData *dataToWrite = [text dataUsingEncoding:NSUTF8StringEncoding];

        BOOL success = ([outputStream write:[dataToWrite bytes]
                                  maxLength:[dataToWrite length]] > 0);

        if (completion) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion( success );
            });
        }
    }];
}

#pragma mark - OSCacheDelegate

- (BOOL)cache:(OSCache *)cache shouldEvictObject:(id)entry {
    return YES;
}

- (void)cache:(OSCache *)cache willEvictObject:(id)obj {
    if ([obj isKindOfClass:[NSOutputStream class]]) {
        [(NSOutputStream *)obj close];
    }
}

@end
