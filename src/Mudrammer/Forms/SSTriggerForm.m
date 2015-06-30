//
//  SSTriggerForm.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/15/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSTriggerForm.h"
#import "SSTGAEditor.h"
#import "SSColorPickerElement.h"
#import "SSMultilineElement.h"
#import "SSFormAppearance.h"
#import "JSQSystemSoundPlayer+SSAdditions.h"

NSString * const kSoundElement = @"soundFileName";

@implementation SSTriggerForm

+ (instancetype)formForTrigger:(Trigger *)trigger {
    SSTriggerForm *form = [[SSTriggerForm alloc] init];

    BOOL isNewRecord = [trigger.isHidden boolValue];

    form.title = ( isNewRecord
                  ? NSLocalizedString(@"NEW_TRIGGER", @"New Trigger")
                  : NSLocalizedString(@"EDIT_TRIGGER", @"Edit Trigger") );
    form.shouldFocusFirstTextFieldOnLoad = isNewRecord;

    // Trigger Pattern
    QSection *section = [[QSection alloc] initWithTitle:nil];

    QEntryElement *patternElement = [[QEntryElement alloc] initWithTitle:NSLocalizedString(@"PATTERN", @"Pattern")
                                                                   Value:trigger.trigger
                                                             Placeholder:nil];
    patternElement.key = @"trigger";
    patternElement.autocorrectionType = UITextAutocorrectionTypeNo;
    patternElement.autocapitalizationType = UITextAutocapitalizationTypeNone;
    [section addElement:patternElement];

    [form addSection:section];

    // Trigger type & enabled
    QSection *section2 = [[QSection alloc] initWithTitle:nil];

    QBooleanElement *triggerEnabled = [[QBooleanElement alloc] initWithTitle:NSLocalizedString(@"ENABLED", @"Enabled")
                                                                   BoolValue:[trigger.isEnabled boolValue]];
    triggerEnabled.key = @"isEnabled";
    [section2 addElement:triggerEnabled];

    [form addSection:section2];

    // Sound & Highlight
    QSection *section3 = [[QSection alloc] initWithTitle:nil];
    section3.footer = NSLocalizedString(@"TRIGGER_EDIT_HELP", nil);

    SSMultilineElement *commandElement = [[SSMultilineElement alloc] initWithTitle:NSLocalizedString(@"COMMANDS", @"Commands")
                                                                             value:trigger.commands];
    commandElement.key = @"commands";
    commandElement.autocapitalizationType = UITextAutocapitalizationTypeNone;
    commandElement.autocorrectionType = UITextAutocorrectionTypeNo;
    commandElement.presentationMode = QPresentationModeNormal;
    [section3 addElement:commandElement];

    SSSound *sound = [JSQSystemSoundPlayer soundForFileName:trigger.soundFileName];
    NSString *soundName = (sound
                           ? sound.soundName
                           : @"None");

    QLabelElement *soundElement = [[QLabelElement alloc] initWithTitle:NSLocalizedString(@"SOUND", nil)
                                                                 Value:soundName];
    soundElement.controllerAction = NSStringFromSelector(@selector(showSoundPicker));
    soundElement.key = kSoundElement;
    [section3 addElement:soundElement];

    SSColorPickerElement *highlightElement = [SSColorPickerElement new];
    highlightElement.title = NSLocalizedString(@"LINE_HIGHLIGHT",nil);
    highlightElement.key = @"highlightColor";
    highlightElement.items = @[
       @[@"None", [UIColor clearColor]],
       @[@"Black", [UIColor blackColor]],
       @[@"White", [UIColor whiteColor]],
       @[@"Gray", [UIColor grayColor]],
       @[@"Blue",  [UIColor blueColor]],
       @[@"Red",  [UIColor redColor]],
       @[@"Green", [UIColor greenColor]],
       @[@"Yellow", [UIColor yellowColor]],
       @[@"Purple", [UIColor purpleColor]],
       @[@"Magenta", [UIColor magentaColor]]
    ];

    highlightElement.presentationMode = QPresentationModeNormal;
    [highlightElement setColor:trigger.highlightColor];

    QAppearance *theme = [SSFormAppearance appearance];
    theme.tableGroupedBackgroundColor = [[SSThemes sharedThemer] valueForThemeKey:kThemeBackgroundColor];
    highlightElement.appearance = theme;

    [section3 addElement:highlightElement];

    [form addSection:section3];

    // Delete button
    if( !isNewRecord ) {
        QSection *deleteSection = [[QSection alloc] initWithTitle:nil];

        QButtonElement *deleteButton = [[QButtonElement alloc] initWithTitle:NSLocalizedString(@"DELETE_TRIGGER", @"Delete Trigger")];
        deleteButton.controllerAction = NSStringFromSelector(@selector(deleteCurrentRecord));
        deleteButton.appearance = form.appearance;

        [deleteSection addElement:deleteButton];

        [form addSection:deleteSection];
    }

    return form;
}

@end
