//
//  SPLTickerForm.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 7/19/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLTickerForm.h"
#import "JSQSystemSoundPlayer+SSAdditions.h"
#import "SSSoundPickerViewController.h"

@interface SPLTickerForm ()

@end

@implementation SPLTickerForm

+ (instancetype)formForTicker:(Ticker *)ticker {
    SPLTickerForm *form = [self new];
    form.ticker = ticker;

    // default value doesn't fill?
    form.isEnabled = [ticker.isEnabled boolValue];

    return form;
}

- (NSArray *) extraFields {
    if ([self.ticker.isHidden boolValue]) {
        return nil;
    }

    return @[
         @{
                 FXFormFieldTitle : NSLocalizedString(@"DELETE_TICKER", nil),
                 FXFormFieldType : FXFormFieldTypeDefault,
                 @"textLabel.textAlignment" : @(NSTextAlignmentCenter),
                 FXFormFieldHeader : @"",
                 @"textLabel.textColor" : [SSThemes valueForThemeKey:kThemeFontColor],
                 @"backgroundColor" : [SSThemes valueForThemeKey:kThemeBackgroundColor],
                 FXFormFieldAction : @"deleteCurrentRecord",
         }
    ];
}

- (NSDictionary *)commandsField {
    return @{
             FXFormFieldTitle : NSLocalizedString(@"COMMANDS", nil),
             FXFormFieldDefaultValue : self.ticker.commands,
             FXFormFieldKey : @"commands",
             @"textField.autocapitalizationType" : @(UITextAutocapitalizationTypeNone),
             @"textField.autocorrectionType" : @(UITextAutocorrectionTypeNo),
             @"contentView.backgroundColor" : [SSThemes valueForThemeKey:kThemeBackgroundColor],
             @"textField.textColor" : [SSThemes valueForThemeKey:kThemeFontColor],
             @"textLabel.textColor" : [SSThemes valueForThemeKey:kThemeFontColor],
    };
}

- (NSDictionary *)intervalField {
    return @{
             FXFormFieldTitle : NSLocalizedString(@"INTERVAL", nil),
             FXFormFieldType  : FXFormFieldTypeUnsigned,
             FXFormFieldDefaultValue : self.ticker.interval,
             FXFormFieldKey : @"interval",
             @"contentView.backgroundColor" : [SSThemes valueForThemeKey:kThemeBackgroundColor],
             @"textField.textColor" : [SSThemes valueForThemeKey:kThemeFontColor],
             @"textLabel.textColor" : [SSThemes valueForThemeKey:kThemeFontColor],
    };
}

- (NSDictionary *)isEnabledField {
    return @{
             FXFormFieldTitle : NSLocalizedString(@"ENABLED", nil),
             @"switchControl.on" : self.ticker.isEnabled,
             FXFormFieldKey : @"isEnabled",
             @"textLabel.textColor" : [SSThemes valueForThemeKey:kThemeFontColor],
             @"switchControl.onTintColor" : [SSThemes valueForThemeKey:kThemeFontColor],
             @"backgroundColor" : [SSThemes valueForThemeKey:kThemeBackgroundColor],
             FXFormFieldFooter : NSLocalizedString(@"TICKER_HELP", nil),
    };
}

- (NSDictionary *)soundFileNameField {
    return @{
             FXFormFieldTitle : NSLocalizedString(@"SOUND", nil),
             FXFormFieldType : FXFormFieldTypeLabel,
             FXFormFieldDefaultValue : self.ticker.soundFileName,
             FXFormFieldKey : @"soundFileName",
             @"textLabel.textColor" : [SSThemes valueForThemeKey:kThemeFontColor],
             @"backgroundColor" : [SSThemes valueForThemeKey:kThemeBackgroundColor],
             FXFormFieldAction : @"showSoundPicker",
             @"accessoryType" : @(UITableViewCellAccessoryDisclosureIndicator),
             FXFormFieldValueTransformer : ^id(id input) {
                 SSSound *sound = [JSQSystemSoundPlayer soundForFileName:input];

                 if (!sound) {
                     return nil;
                 }

                 return sound.soundName;
             },
    };
}

- (NSArray *)excludedFields {
    return @[ @"ticker" ];
}

@end
