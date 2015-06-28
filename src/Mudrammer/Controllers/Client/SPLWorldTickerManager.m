//
//  SPLWorldTickerManager.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLWorldTickerManager.h"
#import <OSCache.h>
#import "SPLTimerManager.h"

@interface SPLWorldTickerData : NSObject <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) NSFetchedResultsController *controller;
@property (nonatomic, strong) NSMutableArray *tickerIdentifiers;
@property (nonatomic, assign) NSUInteger identifierPrefix;
@property (nonatomic, copy) SPLTickerFireBlock tickerBlock;
@property (nonatomic, weak) SPLTimerManager *timerManager;

- (void) enableTicker:(Ticker *)ticker;
- (void) disableTicker:(Ticker *)ticker;

@end

@interface SPLWorldTickerManager () <OSCacheDelegate>

@property (nonatomic, strong) OSCache *cache;
@property (nonatomic, assign) NSUInteger lastIdentifier;
@property (nonatomic, strong) SPLTimerManager *timerManager;

+ (NSString *) tickerIdentifierForTicker:(Ticker *)ticker prefix:(NSUInteger)prefix;

@end

@implementation SPLWorldTickerManager

- (instancetype)initWithTimerManager:(SPLTimerManager *)timerManager {
    if ((self = [super init])) {
        _cache = [OSCache new];
        [self.cache setName:@"WorldTickerManager Cache"];
        self.cache.delegate = self;

        _lastIdentifier = 0;
        _timerManager = timerManager;
    }

    return self;
}

- (void)dealloc {
    self.cache.delegate = nil;
}

#pragma mark - Observing Tickers

+ (NSString *)tickerIdentifierForTicker:(Ticker *)ticker
                                 prefix:(NSUInteger)prefix {

    NSManagedObjectID *objectId = [ticker objectID];
    NSString *urlString = [[objectId URIRepresentation] absoluteString];

    return [NSString stringWithFormat:@"%@-%@",
            @(prefix),
            urlString];
}

- (NSUInteger)enableAndObserveTickersForWorld:(World *)world
                                  tickerBlock:(SPLTickerFireBlock)tickerBlock {

    self.lastIdentifier++;

    DLog(@"starting tickers %@", @(self.lastIdentifier));

    SPLWorldTickerData *data = [SPLWorldTickerData new];
    data.tickerIdentifiers = [NSMutableArray new];
    data.tickerBlock = tickerBlock;
    data.identifierPrefix = self.lastIdentifier;
    data.timerManager = self.timerManager;

    // FRC observer
    NSFetchedResultsController *controller = [Ticker MR_fetchAllSortedBy:[Ticker defaultSortField]
                                                               ascending:[Ticker defaultSortAscending]
                                                           withPredicate:[Ticker predicateForTickersWithWorld:world]
                                                                 groupBy:nil
                                                                delegate:data];

    data.controller = controller;
    data.controller.delegate = data;

    for (Ticker *ticker in controller.fetchedObjects) {
        if (![ticker.isEnabled boolValue]) {
            continue;
        }

        [data enableTicker:ticker];
    }

    [self.cache setObject:data
                   forKey:@(self.lastIdentifier)];

    return self.lastIdentifier;
}

- (void)disableTickersForIdentifier:(NSUInteger)identifier {
    DLog(@"Stopping tickers %@", @(identifier));
    SPLWorldTickerData *data = [self.cache objectForKey:@(identifier)];

    for (NSString *tickerID in data.tickerIdentifiers) {
        [self.timerManager cancelRepeatingTimerWithName:tickerID];
    }

    data.controller.delegate = nil;

    [self.cache removeObjectForKey:@(identifier)];
}

#pragma mark - OSCacheDelegate

- (BOOL)cache:(OSCache *)cache shouldEvictObject:(id)entry {
    return NO;
}

- (void)cache:(OSCache *)cache willEvictObject:(id)entry {

}

@end

@implementation SPLWorldTickerData

- (void)enableTicker:(Ticker *)ticker {
    NSManagedObjectID *tickerId = [ticker objectID];
    NSString *tickerIdentifier = [SPLWorldTickerManager tickerIdentifierForTicker:ticker
                                                                           prefix:self.identifierPrefix];

    if (![self.tickerIdentifiers containsObject:tickerIdentifier]) {
        [self.tickerIdentifiers addObject:tickerIdentifier];
    }

    @weakify(self);
    SPLTimerManager *manager = self.timerManager;
    [manager scheduleRepeatingTimerWithName:tickerIdentifier
                                   interval:[ticker.interval unsignedIntegerValue]
                                      block:^{
                                          @strongify(self);
                                          if (self.tickerBlock) {
                                              self.tickerBlock(tickerId);
                                          }
                                      }];
}

- (void)disableTicker:(Ticker *)ticker {
    NSString *identifier = [SPLWorldTickerManager tickerIdentifierForTicker:ticker
                                                                     prefix:self.identifierPrefix];

    SPLTimerManager *manager = self.timerManager;
    [manager cancelRepeatingTimerWithName:identifier];
    [self.tickerIdentifiers removeObject:identifier];
}

#pragma mark - NSFetchedResultsControllerDelegate

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    Ticker *ticker = (Ticker *)anObject;
    NSString *tickerIdentifier = [SPLWorldTickerManager tickerIdentifierForTicker:ticker
                                                                           prefix:self.identifierPrefix];
    SPLTimerManager *manager = self.timerManager;

    switch (type) {
        case NSFetchedResultsChangeDelete:
            DLog(@"Canceling Ticker %@", tickerIdentifier);
            [self disableTicker:ticker];
            break;

        case NSFetchedResultsChangeInsert:
            DLog(@"Adding Ticker %@", tickerIdentifier);
            [self enableTicker:ticker];
            break;

        case NSFetchedResultsChangeUpdate:
        case NSFetchedResultsChangeMove:

            // Enable or disable if necessary
            if ([ticker.isEnabled boolValue]) {
                if (![manager isTickerEnabledWithIdentifier:tickerIdentifier]) {
                    [self enableTicker:ticker];
                } else {
                    // Ticker is enabled and already firing. Check that intervals match
                    NSNumber *interval = ticker.interval;

                    if (![interval isEqualToNumber:@([manager intervalForTimerWithName:tickerIdentifier])]) {
                        DLog(@"Reschedule ticker to %@", interval);
                        [self disableTicker:ticker];
                        [self enableTicker:ticker];
                    }
                }
            } else if (![ticker.isEnabled boolValue]) {
                [manager cancelRepeatingTimerWithName:tickerIdentifier];
            }

            break;
    }
}

@end
