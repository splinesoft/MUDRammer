//
//  World.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/10/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "World.h"

static NSCharacterSet *disallowedHostCharacters;

@interface World ()
+ (void) createDefaultWorlds;
@end

@implementation World

@dynamic hostname;
@dynamic name;
@dynamic port;
@dynamic aliases;
@dynamic triggers;
@dynamic gags;
@dynamic isDefault;
@dynamic isSecure;
@dynamic tickers;
@dynamic connectCommand;

+ (instancetype)createObjectInContext:(NSManagedObjectContext *)context {
    World *w = [super createObjectInContext:context];

    w.port = @(23);
    w.isDefault = @NO;
    w.isSecure = @NO;

    return w;
}

+ (World *) worldFromDictionary:(NSDictionary *)dict inContext:(NSManagedObjectContext *)context {
    World *world = [World createObjectInContext:context];

    [world setValuesForKeysWithDictionary:dict];
    world.isHidden = @(NO);

    return world;
}

+ (World *)worldFromURL:(NSURL *)url {
    World *w = [World createObject];

    w.hostname = [url host];

    if( [url port] )
        w.port = [url port];

    return w;
}

+ (NSString *)defaultSortField {
    return @"name,hostname";
}

+ (BOOL)defaultSortAscending {
    return YES;
}

- (BOOL)canSave {
    return [self.hostname length] > 0
        && [self.port intValue] > 0
        && [self.port intValue] <= UINT16_MAX;
}

- (void)deepCloneWithCompletion:(void (^)(void))completion {
    NSManagedObjectID *worldId = [self objectID];

    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *localContext) {
        World *from = [World existingObjectWithId:worldId
                                        inContext:localContext];

        World *world = [World MR_createEntityInContext:localContext];
        world.name = from.name;
        world.hostname = from.hostname;
        world.port = from.port;
        world.isSecure = from.isSecure;
        world.isHidden = @NO;
        world.connectCommand = from.connectCommand;

        [localContext MR_saveToPersistentStoreAndWait];

        for (Trigger *fromTrigger in from.triggers) {
            Trigger *trigger = [Trigger MR_createEntityInContext:localContext];
            trigger.trigger = fromTrigger.trigger;
            trigger.isEnabled = fromTrigger.isEnabled;
            trigger.commands = fromTrigger.commands;
            trigger.soundFileName = fromTrigger.soundFileName;
            trigger.highlightColor = fromTrigger.highlightColor;
            trigger.vibrate = fromTrigger.vibrate;
            trigger.triggerType = fromTrigger.triggerType;
            trigger.isHidden = @NO;
            trigger.world = world;
        }

        for (Ticker *fromTicker in from.tickers) {
            Ticker *ticker = [Ticker MR_createEntityInContext:localContext];
            ticker.interval = fromTicker.interval;
            ticker.isEnabled = fromTicker.isEnabled;
            ticker.isHidden = @NO;
            ticker.commands = fromTicker.commands;
            ticker.soundFileName = fromTicker.soundFileName;
            ticker.world = world;
        }

        for (Gag *fromGag in from.gags) {
            Gag *gag = [Gag MR_createEntityInContext:localContext];
            gag.isEnabled = fromGag.isEnabled;
            gag.isHidden = @NO;
            gag.gag = fromGag.gag;
            gag.gagType = fromGag.gagType;
            gag.world = world;
        }

        for (Alias *fromAlias in from.aliases) {
            Alias *alias = [Alias MR_createEntityInContext:localContext];
            alias.isHidden = @NO;
            alias.commands = fromAlias.commands;
            alias.isEnabled = fromAlias.isEnabled;
            alias.name = fromAlias.name;
            alias.world = world;
        }
    } completion:^(BOOL didSave, NSError *error) {
        if (completion) {
            completion();
        }
    }];
}

#pragma mark - creation helpers

+ (NSString *)cleanedHostNameForWorldWithHost:(NSString *)host {
    if( !host || [host length] == 0 )
        return @"";

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSMutableCharacterSet *allowedChars = [[NSMutableCharacterSet alloc] init];
        [allowedChars formUnionWithCharacterSet:[NSCharacterSet lowercaseLetterCharacterSet]];
        [allowedChars formUnionWithCharacterSet:[NSCharacterSet decimalDigitCharacterSet]];
        [allowedChars formUnionWithCharacterSet:[NSCharacterSet characterSetWithCharactersInString:@".-"]];

        disallowedHostCharacters = [allowedChars invertedSet];
    });

    if( !disallowedHostCharacters )
        return host;

    NSMutableString *str = [[host lowercaseString] mutableCopy];

    NSRange hostrange = [str rangeOfString:@"://"];

    if( hostrange.location != NSNotFound )
        [str deleteCharactersInRange:NSMakeRange(0, NSMaxRange(hostrange))];

    return [[str componentsSeparatedByCharactersInSet:disallowedHostCharacters]
            componentsJoinedByString:@""];
}

#pragma mark - defaults

- (void)setDefaultWorld {
    if( ![self.isDefault boolValue] ) {
        // Set all other defaults to NO
        NSManagedObjectID *target = [self objectID];

        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *context) {
            NSArray *defaults = [World MR_findAllWithPredicate:[NSPredicate predicateWithFormat:@"isDefault == YES"]
                                                     inContext:context];

            [defaults enumerateObjectsUsingBlock:^(World *world, NSUInteger index, BOOL *stop) {
                world.isDefault = @(NO);
                world.lastModified = [NSDate date];
                world.isHidden = @(NO);
            }];

            World *newDefault = [World existingObjectWithId:target inContext:context];

            if( newDefault ) {
                newDefault.isDefault = @(YES);
                newDefault.lastModified = [NSDate date];
            }
        }];
    }
}

+ (World *)defaultWorldInContext:(NSManagedObjectContext *)context {
    return [World MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"isHidden == NO AND isDefault == YES"]
                                   sortedBy:[World defaultSortField]
                                  ascending:[World defaultSortAscending]
                                  inContext:(context
                                             ?: [NSManagedObjectContext MR_defaultContext] )];
}

+ (void) createDefaultWorldsIfNecessary {
    BOOL hasCloud = NO;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    BOOL hasLocal = [defaults boolForKey:kPrefInitialWorldsCreated];

    if( !hasLocal && !hasCloud )
        [self createDefaultWorlds];
}

+ (void)createDefaultWorlds {
    [MagicalRecord saveWithBlock:^(NSManagedObjectContext *context) {
        NSString *worldFile = [[NSBundle mainBundle] pathForResource:@"DefaultWorlds" ofType:@"plist"];
        NSArray *worldList = [NSArray arrayWithContentsOfFile:worldFile];

        [worldList bk_each:^(NSDictionary *dict) {
            [World worldFromDictionary:dict inContext:context];
        }];
    } completion:^(BOOL success, NSError *err) {
        NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
        [d setBool:YES forKey:kPrefInitialWorldsCreated];
    }];
}

#pragma mark - world access

+ (NSPredicate *)predicateForRecordsWithWorld:(World *)world {
    return [NSPredicate predicateWithFormat:@"world == %@ AND isHidden == NO", world];
}

- (NSArray *)orderedTriggersWithActive:(BOOL)isActive {
    if( !self.triggers || [self.triggers count] == 0 )
        return @[];

    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:[Trigger defaultSortField]
                                                           ascending:[Trigger defaultSortAscending]];
    return [[self.triggers filteredSetUsingPredicate:[NSPredicate predicateWithFormat:@"isEnabled == %i", isActive]]
            sortedArrayUsingDescriptors:@[ sort ]];
}

- (NSArray *)orderedAliases {
    if( !self.aliases || [self.aliases count] == 0 )
        return @[];

    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:[Alias defaultSortField]
                                                           ascending:[Alias defaultSortAscending]];
    return [self.aliases sortedArrayUsingDescriptors:@[ sort ]];
}

- (NSArray *)orderedGags {
    if( !self.gags || [self.gags count] == 0 )
        return @[];

    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:[Gag defaultSortField]
                                                           ascending:[Gag defaultSortAscending]];
    return [self.gags sortedArrayUsingDescriptors:@[ sort ]];
}

- (NSArray *)orderedTickers {
    if (!self.tickers || [self.tickers count] == 0) {
        return [NSArray new];
    }

    NSSortDescriptor *sort = [NSSortDescriptor sortDescriptorWithKey:[Ticker defaultSortField]
                                                           ascending:[Ticker defaultSortAscending]];
    return [self.tickers sortedArrayUsingDescriptors:@[ sort ]];
}

- (NSString *)worldDescription {
    if( [self.name length] > 0 )
        return [self.name stringByAppendingString:@" "];

    NSMutableString *ret = [NSMutableString string];

    if( self.hostname )
        [ret appendString:self.hostname];

    [ret appendFormat:@":%@", self.port];

    return ret;
}

#pragma mark - TGA

- (NSArray *)commandsIfMatchingAliasForInput:(NSString *)userInput {
    if( [self.aliases count] == 0 )
        return nil;

    if( [userInput length] > 0 ) {
        // Grab the first word of our command
        NSArray *words = [userInput componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *command = words[0];

        NSSet *matches = [self.aliases bk_select:^BOOL(Alias *alias) {
            return [alias.name length] > 0 && [[alias.name lowercaseString]
                                               isEqualToString:[command lowercaseString]];
        }];

        if( [matches count] > 0 ) {
            Alias *alias = [matches anyObject];

            return [alias aliasCommandsForInput:userInput];
        }
    }

    return nil;
}

- (NSIndexSet *)filteredIndexesByMatchingGagsInLines:(NSArray *)lines {
    NSMutableIndexSet *indexes = [NSMutableIndexSet indexSetWithIndexesInRange:NSMakeRange(0, [lines count])];

    if( [self.gags count] == 0 )
        return indexes;

    [lines enumerateObjectsUsingBlock:^(id line, NSUInteger index, BOOL *linestop) {

        if (![line isKindOfClass:[NSString class]]) {
            return;
        }

        [self.gags enumerateObjectsUsingBlock:^(Gag *gag, BOOL *gagStop) {
            if ([gag matchesLine:line]) {
                [indexes removeIndex:index];
                *gagStop = YES;
    #ifdef __PARSE_ECHO__
                DLog(@"GAGGED %@", line);
    #endif
            }
        }];
    }];

    return indexes;
}

- (void) runTriggersForLines:(NSArray *)lines
                 outCommands:(NSArray *__autoreleasing *)outCommands
                   outColors:(NSDictionary *__autoreleasing *)outColors
                outSoundName:(NSString *__autoreleasing *)outSoundName {
    NSArray *triggers = [self orderedTriggersWithActive:YES];

    if( [triggers count] == 0 || [lines count] == 0 )
        return;

    NSMutableArray *commands = [NSMutableArray array];
    NSMutableDictionary *colors = [NSMutableDictionary new];
    __block NSString *soundName;

    [lines enumerateObjectsUsingBlock:^(id line, NSUInteger index, BOOL *stop) {
        if(![line isKindOfClass:[NSString class]] || [(NSString *)line length] == 0 )
            return;

         [triggers enumerateObjectsUsingBlock:^(Trigger *trigger, NSUInteger tIndex, BOOL *triggerStop) {
             if( !trigger || [trigger.trigger length] == 0 )
                 return;

             [trigger refreshObject];

             if( [trigger matchesLine:line] ) {
#ifdef __PARSE_ECHO__
                 DLog(@"FIRE TRIGGER: %@", trigger.trigger);
#endif

                 [commands addObjectsFromArray:
                  [trigger triggerCommandsForLine:line]];

                 if (trigger.highlightColor)
                     colors[@(index)] = trigger.highlightColor;

                 if ([trigger.soundFileName length] > 0 && ![trigger.soundFileName isEqualToString:@"None"]) {
                     soundName = trigger.soundFileName;
                 }
             }
         }];
     }];

    *outCommands = [commands copy];
    *outColors = [colors copy];
    *outSoundName = [soundName copy];
}

@end
