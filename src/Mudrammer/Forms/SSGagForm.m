//
//  SSGagForm.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/15/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSGagForm.h"
#import "SSTGAEditor.h"
#import "SSFormAppearance.h"

@implementation SSGagForm

+ (instancetype)formForGag:(Gag *)gag {
    SSGagForm *form = [[SSGagForm alloc] init];

    BOOL isNewRecord = [gag.isHidden boolValue];

    form.title = ( isNewRecord
                  ? NSLocalizedString(@"NEW_GAG", @"New Gag")
                  : NSLocalizedString(@"EDIT_GAG", @"Edit Gag") );
    form.shouldFocusFirstTextFieldOnLoad = isNewRecord;

    // Gag pattern & type
    QSection *section = [[QSection alloc] init];
    section.footer = NSLocalizedString(@"GAG_EDIT_HELP", nil);

    QEntryElement *gagPattern = [[QEntryElement alloc] initWithTitle:NSLocalizedString(@"PATTERN", @"Pattern")
                                                               Value:gag.gag
                                                         Placeholder:nil];
    gagPattern.key = @"gag";
    gagPattern.autocapitalizationType = UITextAutocapitalizationTypeNone;
    gagPattern.autocorrectionType = UITextAutocorrectionTypeNo;
    [section addElement:gagPattern];

    QRadioElement *gagType = [[QRadioElement alloc] initWithItems:[Gag gagTypeLabelArray]
                                                         selected:[gag.gagType integerValue]
                                                            title:NSLocalizedString(@"TYPE", @"Gag Type")];
    gagType.key = @"gagType";
    gagType.presentationMode = QPresentationModeNormal;

    QAppearance *theme = [SSFormAppearance appearance];
    theme.tableGroupedBackgroundColor = [SSThemes valueForThemeKey:kThemeBackgroundColor];
    gagType.appearance = theme;

    [section addElement:gagType];

    [form addSection:section];

    // Delete button
    if( !isNewRecord ) {
        QSection *deleteSection = [[QSection alloc] initWithTitle:nil];

        QButtonElement *deleteButton = [[QButtonElement alloc] initWithTitle:NSLocalizedString(@"DELETE_GAG", nil)];
        deleteButton.appearance = form.appearance;
        deleteButton.controllerAction = NSStringFromSelector(@selector(deleteCurrentRecord));

        [deleteSection addElement:deleteButton];

        [form addSection:deleteSection];
    }

    return form;
}

@end
