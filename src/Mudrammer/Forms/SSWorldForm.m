//
//  SSWorldForm.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/15/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSWorldForm.h"
#import "SSWorldEditViewController.h"
#import "SSPortElement.h"
#import "JSQSystemSoundPlayer+SSAdditions.h"
#import "SSMultilineElement.h"

NSUInteger const kFormMaxInputLength = 1024;

@interface SSWorldForm ()

@property (nonatomic, strong) World *world;
@property (nonatomic, assign) BOOL isNewWorld;

@end

@implementation SSWorldForm

+ (instancetype)formForWorld:(World *)world {
    SSWorldForm *form = [[SSWorldForm alloc] init];
    form.world = world;
    form.isNewWorld = [world.isHidden boolValue];

    if( !form.isNewWorld )
        form.title = [world worldDescription];
    else
        form.title = NSLocalizedString(@"NEW_WORLD", @"New World");

    form.shouldFocusFirstTextFieldOnLoad = form.isNewWorld;

    return form;
}

- (void)refreshWorldFormForController:(SSWorldEditViewController *)controller {
    @weakify(controller);
    [self.sections removeAllObjects];

    [self.world refreshObject];

    self.isNewWorld = [_world.isHidden boolValue];

    if( !self.isNewWorld )
        self.title = [_world worldDescription];
    else
        self.title = NSLocalizedString(@"NEW_WORLD", @"New World");

    // Top section - hostname and port
    QSection *section = [[QSection alloc] init];

    QEntryElement *hostElement = [[QEntryElement alloc] initWithTitle:NSLocalizedString(@"HOSTNAME", @"Host Name")
                                                                Value:_world.hostname
                                                          Placeholder:@"nanvaent.org"];
    hostElement.key = @"hostname";
    hostElement.autocapitalizationType = UITextAutocapitalizationTypeNone;
    hostElement.autocorrectionType = UITextAutocorrectionTypeNo;
    hostElement.keyboardType = UIKeyboardTypeURL;
    hostElement.maxLength = kFormMaxInputLength;
    [section addElement:hostElement];

    SSPortElement *portElement = [[SSPortElement alloc] initWithTitle:NSLocalizedString(@"PORT", @"World Port")
                                                                value:_world.port];
    portElement.fractionDigits = 0;
    portElement.keyboardType = UIKeyboardTypeNumberPad;
    portElement.key = @"port";
    [section addElement:portElement];

    QBooleanElement *secureElement = [[QBooleanElement alloc] initWithTitle:@"SSL/TLS"
                                                                  BoolValue:[_world.isSecure boolValue]];
    secureElement.key = @"isSecure";
    [section addElement:secureElement];

    [self addSection:section];

    // Second section - nickname & connect command
    QSection *nickSection = [[QSection alloc] init];
    nickSection.footer = [NSString stringWithFormat:NSLocalizedString(@"WORLD_CONNECT_COMMAND_FOOTER_%@", nil),
                          @(kConnectCommandsDelay)];

    QEntryElement *nickElement = [[QEntryElement alloc] initWithTitle:NSLocalizedString(@"NAME", @"World Name")
                                                                Value:_world.name
                                                          Placeholder:NSLocalizedString(@"OPTIONAL", nil)];
    nickElement.key = @"name";
    nickElement.autocorrectionType = UITextAutocorrectionTypeNo;
    nickElement.maxLength = kFormMaxInputLength;
    [nickSection addElement:nickElement];

    QEntryElement *commandElement = [[QEntryElement alloc] initWithTitle:NSLocalizedString(@"WORLD_CONNECT_COMMAND", nil)
                                                                   Value:_world.connectCommand
                                                             Placeholder:NSLocalizedString(@"OPTIONAL", nil)];
    commandElement.key = @"connectCommand";
    commandElement.autocapitalizationType = UITextAutocapitalizationTypeNone;
    commandElement.autocorrectionType = UITextAutocorrectionTypeNo;
    commandElement.maxLength = kFormMaxInputLength;
    [nickSection addElement:commandElement];

    [self addSection:nickSection];

    // Triggers, Aliases, Gags, Disabled Triggers
    if( self.isNewWorld )
        return;

    // Triggers
    QSection *triggerSection = [[QSection alloc] initWithTitle:NSLocalizedString(@"TRIGGERS", @"Triggers")];
    triggerSection.footer = NSLocalizedString(@"TRIGGER_HELP", @"Fire some actions whenever specified text is received.");

    // New Trigger
    QButtonElement *newTriggerBtn = [[QButtonElement alloc] initWithTitle:NSLocalizedString(@"NEW_TRIGGER", @"New Trigger")];
    newTriggerBtn.controllerAction = NSStringFromSelector(@selector(newTrigger));
    [triggerSection addElement:newTriggerBtn];

    [[self.world orderedTriggersWithActive:YES] bk_each:^(Trigger *trigger) {
        QLabelElement *triggerElement = [[QLabelElement alloc] initWithTitle:trigger.trigger
                                                                       Value:trigger.commands];
        triggerElement.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        triggerElement.onSelected = ^{
            @strongify(controller);
            [controller editRecord:[trigger objectID]];
        };
        triggerElement.keepSelected = NO;
        [triggerSection addElement:triggerElement];
    }];

    [self addSection:triggerSection];

    // Aliases
    QSection *aliasSection = [[QSection alloc] initWithTitle:NSLocalizedString(@"ALIASES", @"Aliases")];
    aliasSection.footer = NSLocalizedString(@"ALIAS_HELP", @"Create commands that expand into one or more actions.");

    // New Alias
    QButtonElement *newAliasBtn = [[QButtonElement alloc] initWithTitle:NSLocalizedString(@"NEW_ALIAS", @"New Alias")];
    newAliasBtn.controllerAction = NSStringFromSelector(@selector(newAlias));
    [aliasSection addElement:newAliasBtn];

    [[self.world orderedAliases] bk_each:^(Alias *alias) {
        QLabelElement *aliasElement = [[QLabelElement alloc] initWithTitle:alias.name
                                                                     Value:alias.commands];
        aliasElement.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        aliasElement.onSelected = ^{
            @strongify(controller);
            [controller editRecord:[alias objectID]];
        };
        aliasElement.keepSelected = NO;
        [aliasSection addElement:aliasElement];
    }];

    [self addSection:aliasSection];

    // Tickers
    QSection *tickerSection = [[QSection alloc] initWithTitle:NSLocalizedString(@"TICKERS", nil)];
    tickerSection.footer = NSLocalizedString(@"TICKER_HELP", nil);

    // New Ticker
    QButtonElement *newTickerBtn = [[QButtonElement alloc] initWithTitle:NSLocalizedString(@"NEW_TICKER", nil)];
    newTickerBtn.controllerAction = NSStringFromSelector(@selector(newTicker));
    [tickerSection addElement:newTickerBtn];

    [[self.world orderedTickers] bk_each:^(Ticker *ticker) {
        NSString *tickerLabel;

        if ([ticker.commands length] > 0) {
            tickerLabel = ticker.commands;
        } else if ([ticker.soundFileName length] > 0 && ![ticker.soundFileName isEqualToString:@"None"]) {
            SSSound *sound = [JSQSystemSoundPlayer soundForFileName:ticker.soundFileName];

            if (sound) {
                tickerLabel = sound.soundName;
            } else {
                tickerLabel = @"";
            }
        } else {
            tickerLabel = @"";
        }

        NSString *tickerValue = [NSString stringWithFormat:NSLocalizedString(@"TICKER_STATUS_INTERVAL_%@_%@", nil),
                                 ([ticker.isEnabled boolValue]
                                  ? NSLocalizedString(@"ON", nil)
                                  : NSLocalizedString(@"OFF", nil)),
                                 ticker.interval];

        QLabelElement *tickerElement = [[QLabelElement alloc] initWithTitle:tickerLabel
                                                                      Value:tickerValue];
        tickerElement.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        tickerElement.onSelected = ^{
            @strongify(controller);
            [controller editRecord:[ticker objectID]];
        };
        tickerElement.keepSelected = NO;
        [tickerSection addElement:tickerElement];
    }];

    [self addSection:tickerSection];

    // Gags
    QSection *gagSection = [[QSection alloc] initWithTitle:NSLocalizedString(@"GAGS", @"Gags")];
    gagSection.footer = NSLocalizedString(@"GAG_HELP", nil);

    // New Gag
    QButtonElement *newGagBtn = [[QButtonElement alloc] initWithTitle:NSLocalizedString(@"NEW_GAG", @"New Gag")];
    newGagBtn.controllerAction = NSStringFromSelector(@selector(newGag));
    [gagSection addElement:newGagBtn];

    [[self.world orderedGags] bk_each:^(Gag *gag) {
        QLabelElement *gagElement = [[QLabelElement alloc] initWithTitle:( [gag.gag length] > 0
                                                                          ? gag.gag
                                                                          : NSLocalizedString(@"GAG_EMPTY", @"Empty Gag") )
                                                                   Value:nil];
        gagElement.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        gagElement.onSelected = ^{
            @strongify(controller);
            [controller editRecord:[gag objectID]];
        };
        gagElement.keepSelected = NO;
        [gagSection addElement:gagElement];
    }];

    [self addSection:gagSection];

    // Inactive triggers
    NSArray *inactives = [self.world orderedTriggersWithActive:NO];

    if( [inactives count] > 0 ) {
        QSection *inactiveTriggerSection = [[QSection alloc] initWithTitle:NSLocalizedString(@"TRIGGERS_INACTIVE", @"Triggers (Inactive)")];

        [inactives bk_each:^(Trigger *trigger) {
            QLabelElement *triggerElement = [[QLabelElement alloc] initWithTitle:trigger.trigger
                                                                           Value:trigger.commands];
            triggerElement.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            triggerElement.onSelected = ^{
                @strongify(controller);
                [controller editRecord:[trigger objectID]];
            };
            triggerElement.keepSelected = NO;
            [triggerSection addElement:triggerElement];
        }];

        [self addSection:inactiveTriggerSection];
    }

    // Deep clone
    QSection *cloneSection = [[QSection alloc] initWithTitle:nil];
    cloneSection.footer = NSLocalizedString(@"WORLD_CLONE_HELP", nil);

    QButtonElement *cloneButton = [[QButtonElement alloc] initWithTitle:NSLocalizedString(@"WORLD_CLONE", nil)];
    cloneButton.controllerAction = NSStringFromSelector(@selector(deepClone));
    [cloneSection addElement:cloneButton];

    [self addSection:cloneSection];
}

@end
