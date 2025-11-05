//
//  SPLWorldTickerManager.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

@import Foundation;
@class SPLTimerManager;

typedef void (^SPLTickerFireBlock) (NSManagedObjectID *tickerID);

@interface SPLWorldTickerManager : NSObject

/**
 *  Access the shared world ticker manager.
 *
 *  @return the shared manager
 */
- (instancetype) initWithTimerManager:(SPLTimerManager *)timerManager;

/**
 *  Start firing tickers for the specified world.
 *  Observes tickers and enables/disables/updates as necessary.
 *
 *  @param world       world whose tickers to observe
 *  @param tickerBlock block fired when a ticker fires
 *
 *  @return an identifier to save for later, when disabling tickers
 */
- (NSUInteger) enableAndObserveTickersForWorld:(World *)world
                                   tickerBlock:(SPLTickerFireBlock)tickerBlock;;

/**
 *  Disable all tickers that match the specified identifier as returned above.
 *
 *  @param identifier identifier for tickers to disable
 */
- (void) disableTickersForIdentifier:(NSUInteger)identifier;

@end
