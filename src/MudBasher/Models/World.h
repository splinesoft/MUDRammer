//
//  World.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/10/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import Foundation;
@import CoreData;
#import <SSMagicManagedObject.h>

@class Alias, Gag, Trigger;

@interface World : SSMagicManagedObject

@property (nonatomic, copy) NSString * hostname;
@property (nonatomic, copy) NSString * name;
@property (nonatomic, strong) NSNumber * port;
@property (nonatomic, strong) NSNumber * isDefault;
@property (nonatomic, strong) NSSet *aliases;
@property (nonatomic, strong) NSSet *triggers;
@property (nonatomic, strong) NSSet *gags;
@property (nonatomic, strong) NSSet *tickers;
@property (nonatomic, strong) NSNumber * isSecure;
@property (nonatomic, copy) NSString * connectCommand;

#pragma mark - create

+ (World *) worldFromDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)context;

// (try to) create a world from a URL
+ (World *) worldFromURL:(NSURL *)url;

// Parse a user-entered hostname into a valid hostname by stripping out invalid characters.
+ (NSString *)cleanedHostNameForWorldWithHost:(NSString *)host;

/**
 *  Deep clone this world, including triggers, aliases, gags, and tickers.
 *
 *  @param completion block called upon completion, with the ID of the newly-saved world
 */
- (void)deepCloneWithCompletion:(void (^)(void))completion;

#pragma mark - default worlds

- (void) setDefaultWorld;

// Find the default world.
+ (World *) defaultWorldInContext:(NSManagedObjectContext *)context;

+ (void) createDefaultWorldsIfNecessary;

#pragma mark - world access

+ (NSPredicate *) predicateForRecordsWithWorld:(World *)world;

// A string including name (if any), hostname:port
- (NSString *) worldDescription;

#pragma mark - triggers, gags, aliases, tickers

- (NSArray *) orderedTriggersWithActive:(BOOL)isActive;
- (NSArray *) orderedAliases;
- (NSArray *) orderedGags;
- (NSArray *) orderedTickers;

// Evaluate all of our aliases for one matching this user input string.
// If we find a matching alias, process it given this input and return a list of command(s) to send.
// If no matching alias, return nil
- (NSArray *) commandsIfMatchingAliasForInput:(NSString *)userInput;

// For each line in this text, evaluate all our gags and remove the line if it matches a gag.
// Returns the indexes of lines to show, gagged indexes having been removed.
- (NSIndexSet *) filteredIndexesByMatchingGagsInLines:(NSArray *)lines;

// For each line in the text, evaluate all our triggers and calculate a list of commands to send back.
// Sets outCommands to command(s) to fire
// Sets outColors to a dictionary of line number : background color
// Sets outSoundName to an NSString of the sound filename to play
- (void) runTriggersForLines:(NSArray *)lines
                 outCommands:(NSArray **)outCommands
                   outColors:(NSDictionary **)outColors
                outSoundName:(NSString **)outSoundName;

@end
