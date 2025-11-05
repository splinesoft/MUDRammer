//
//  SSSettingsViewController.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import  UIKit;

@protocol SettingsDelegate;

@interface SSSettingsViewController : UITableViewController

typedef NS_ENUM( NSUInteger, SettingsSection ) {
    SettingsSectionTop = 0,
    SettingsSectionActions,
    SettingsSectionLogging,
    SettingsSectionAboutHelp,
    SettingsNumSections
};

typedef NS_ENUM( NSUInteger, SettingsTopSectionRow ) {
    SettingsRowWorlds = 0,
    SettingsRowThemes,
    SettingsTopNumRows
};

typedef NS_ENUM( NSUInteger, SettingsActionSectionRow ) {
    SettingsActionRowAutocorrect,
    SettingsActionRowLocalEcho,
    SettingsActionRowMoveControl,
    SettingsActionRowRadialCommands,
    SettingsActionRowAdvanced,
    SettingsActionNumRows
};

typedef NS_ENUM( NSUInteger, SettingsLoggingRow ) {
    SettingsLoggingToggle,
    SettingsLoggingMailLog,
    SettingsLoggingNumRows
};

typedef NS_ENUM( NSUInteger, SettingsAboutHelpRow ) {
    SettingsSupportRow = 0,
    SettingsAboutAppRow,
    SettingsAboutHelpNumRows
};

@property (nonatomic, weak) id <SettingsDelegate> delegate;

@end

@protocol SettingsDelegate <NSObject>

@optional

- (void) settingsViewDidClose:(SSSettingsViewController *)settingsViewController;

- (void) settingsViewShouldSendSessionLog:(SSSettingsViewController *)settingsViewController;

- (void) settingsViewShouldOpenAboutURL:(SSSettingsViewController *)settingsViewController;

- (void) settingsViewShouldOpenContact:(SSSettingsViewController *)settingsViewController;

@end
