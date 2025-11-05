//
//  SSAliasForm.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/15/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSAliasForm.h"
#import "SSTGAEditor.h"
#import "SSMultilineElement.h"

@implementation SSAliasForm

+ (instancetype)formForAlias:(Alias *)alias {
    SSAliasForm *form = [[SSAliasForm alloc] init];

    BOOL isNewRecord = [alias.isHidden boolValue];

    form.title = ( isNewRecord
                   ? NSLocalizedString(@"NEW_ALIAS", @"New Alias")
                   : NSLocalizedString(@"EDIT_ALIAS", @"Edit Alias") );
    form.shouldFocusFirstTextFieldOnLoad = isNewRecord;

    // Name & Commands
    QSection *section = [[QSection alloc] init];
    section.footer = NSLocalizedString(@"ALIAS_EDIT_HELP", nil);

    QEntryElement *aliasName = [[QEntryElement alloc] initWithTitle:NSLocalizedString(@"ALIAS", @"Alias")
                                                              Value:alias.name
                                                        Placeholder:nil];
    aliasName.key = @"name";
    aliasName.autocapitalizationType = UITextAutocapitalizationTypeNone;
    aliasName.autocorrectionType = UITextAutocorrectionTypeNo;
    [section addElement:aliasName];

    SSMultilineElement *aliasCommands = [[SSMultilineElement alloc] initWithTitle:NSLocalizedString(@"COMMANDS", @"Command(s)")
                                                                            value:alias.commands];
    aliasCommands.key = @"commands";
    aliasCommands.autocorrectionType = UITextAutocorrectionTypeNo;
    aliasCommands.autocapitalizationType = UITextAutocapitalizationTypeNone;
    aliasCommands.presentationMode = QPresentationModeNormal;
    [section addElement:aliasCommands];

    [form addSection:section];

    // Delete button
    if( !isNewRecord ) {
        QSection *deleteSection = [[QSection alloc] initWithTitle:nil];

        QButtonElement *deleteButton = [[QButtonElement alloc] initWithTitle:NSLocalizedString(@"DELETE_ALIAS", nil)];
        deleteButton.controllerAction = NSStringFromSelector(@selector(deleteCurrentRecord));
        deleteButton.appearance = form.appearance;

        [deleteSection addElement:deleteButton];

        [form addSection:deleteSection];
    }

    return form;
}

@end
