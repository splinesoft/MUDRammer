//
//  SSSettingsViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSSettingsViewController.h"
#import "SSThemePickerController.h"
#import "SSWorldListViewController.h"
#import "SSWorldEditViewController.h"
#import "SSTGAEditor.h"
#import "SSValueCell.h"
#import "SSAdvSettingsController.h"
#import "SSBooleanCell.h"
#import <FBKVOController.h>
#import "SSSegmentCell.h"
#import "SPLRadialEditor.h"
#import "SSRadialControl.h"
#import "SPLAlerts.h"

#define OBS @[ kThemeBackgroundColor, kThemeFontColor ]

@interface SSSettingsViewController ()

@property (nonatomic, strong) SSSectionedDataSource *dataSource;

@property (nonatomic, strong) FBKVOController *kvoController;

// Init
- (SSSettingsViewController *) init;

// Actions
- (void) closeSettings:(id)sender;
- (void) userDefaultsChanged:(NSNotification *)note;

// Cell configure
- (void) configureBooleanCell:(SSBooleanCell *)cell atIndexPath:(NSIndexPath *)indexPath;

@end

@implementation SSSettingsViewController

- (SSSettingsViewController *) init {
    if( ( self = [self initWithStyle:UITableViewStyleGrouped] ) ) {
        self.title = NSLocalizedString(@"SETTINGS", @"Settings");
        self.clearsSelectionOnViewWillAppear = YES;

        [SSThemes configureTable:self.tableView];

        if( ![[UIDevice currentDevice] isIPad] ) {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                  target:self
                                                                                                  action:@selector(closeSettings:)];
        }

        _kvoController = [FBKVOController controllerWithObserver:self];

        for( NSString *key in OBS ) {
            [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                                keyPath:key
                                options:NSKeyValueObservingOptionNew
                                  block:^(SSSettingsViewController *vc, id object, NSDictionary *change) {
                                      [SSThemes configureTable:vc.tableView];
                                      [vc.tableView reloadData];
                                  }];
        }

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userDefaultsChanged:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
    }

    return self;
}

- (CGSize)preferredContentSize {
    return [self.tableView sizeThatFits:CGSizeMake(320, CGFLOAT_MAX)];
}

- (void)dealloc {
    _delegate = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    @weakify(self);

    _dataSource = [[SSSectionedDataSource alloc] initWithItems:nil];
    _dataSource.tableActionBlock = ^BOOL(SSCellActionType action,
                                         UITableView *tableView,
                                         NSIndexPath *indexPath) {
        return NO;
    };
    _dataSource.rowAnimation = UITableViewRowAnimationFade;

    // Set up initial sections
    for (NSUInteger i = 0; i < SettingsNumSections; i++) {

        switch ((SettingsSection)i) {

            case SettingsSectionTop:

                [_dataSource appendSection:[SSSection sectionWithNumberOfItems:SettingsTopNumRows]];

                break;

            case SettingsSectionActions:

                [_dataSource appendSection:[SSSection sectionWithNumberOfItems:SettingsActionNumRows]];

                break;

            case SettingsSectionLogging:

                [_dataSource appendSection:
                 [SSSection sectionWithNumberOfItems:SettingsLoggingNumRows - ( [[NSUserDefaults standardUserDefaults]
                                                                                 boolForKey:kPrefLogging]
                                                                               ? 0
                                                                               : 1 )]];

                break;

            case SettingsSectionAboutHelp: {

                SSSection *section = [SSSection sectionWithNumberOfItems:SettingsAboutHelpNumRows];
                section.footer = [UIApplication applicationFullAbout];

                [_dataSource appendSection:section];

                break;
            }
            default:

                break;
        }
    }

    // Cell types
    _dataSource.cellCreationBlock = ^id(NSNumber *unused,
                                        UITableView *table,
                                        NSIndexPath *indexPath) {

        switch ((SettingsSection)indexPath.section) {

            case SettingsSectionTop:
            case SettingsSectionAboutHelp:

                return [SSBaseTableCell cellForTableView:table];

            case SettingsSectionLogging: {

                if (indexPath.row == SettingsLoggingMailLog) {
                    return [SSBaseTableCell cellForTableView:table];
                } else {
                    return [SSBooleanCell cellForTableView:table];
                }

            }

            case SettingsSectionActions:

                switch ((SettingsActionSectionRow)indexPath.row) {

                    case SettingsActionRowAutocorrect:
                    case SettingsActionRowLocalEcho:

                        return [SSBooleanCell cellForTableView:table];

                    case SettingsActionRowMoveControl:

                        return [SSSegmentCell cellForTableView:table];

                    case SettingsActionRowRadialCommands:

                        return [SSBaseTableCell cellForTableView:table];

                    case SettingsActionRowAdvanced:

                        return [SSBaseTableCell cellForTableView:table];

                    default:

                        break;
                }

            default:

                break;

        }

        return nil; // CRASH
    };

    _dataSource.cellConfigureBlock = ^(SSBaseTableCell *cell,
                                       NSNumber *unused,
                                       UITableView *tableView,
                                       NSIndexPath *indexPath) {

        cell.textLabel.minimumScaleFactor = 0.6f;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;

        @strongify(self);
        // Shortcuts
        if ([cell isKindOfClass:[SSBooleanCell class]]) {
            [self configureBooleanCell:(SSBooleanCell *)cell atIndexPath:indexPath];
            return;
        } else if ([cell isKindOfClass:[SSSegmentCell class]]) {
            NSString *label = NSLocalizedString(@"MOVE_CONTROL", @"Move Control");

            [(SSSegmentCell *)cell configureWithLabel:label
                                             segments:@[ NSLocalizedString(@"LEFT", nil),
                                                         NSLocalizedString(@"OFF", nil),
                                                         NSLocalizedString(@"RIGHT", nil) ]
                                        selectedIndex:[[[NSUserDefaults standardUserDefaults]
                                                        objectForKey:kPrefMoveControl] integerValue]
                                        changeHandler:^(NSInteger index) {
                                            @strongify(self);
                                            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                                                            name:NSUserDefaultsDidChangeNotification
                                                                                          object:nil];

                                            [SSRadialControl updateRadialPreference:kPrefMoveControl
                                                                         toPosition:(SSRadialControlPosition)index];

                                            [[NSNotificationCenter defaultCenter] addObserver:self
                                                                                     selector:@selector(userDefaultsChanged:)
                                                                                         name:NSUserDefaultsDidChangeNotification
                                                                                       object:nil];
                                        }];

            [SSThemes configureCell:cell];

            return;
        }

        switch ((SettingsSection)indexPath.section) {

            case SettingsSectionTop:

                switch( indexPath.row ) {
                    case SettingsRowWorlds:

                        cell.textLabel.text = NSLocalizedString(@"WORLDS", @"Worlds");
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

                        break;

                    case SettingsRowThemes:

                        cell.textLabel.text = NSLocalizedString(@"THEMES", @"Themes");
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

                        break;
                    default:
                        break;
                }

                [SSThemes configureCell:cell];

                break;

            case SettingsSectionLogging:

                if( indexPath.row == SettingsLoggingMailLog ) {
                    cell.textLabel.text = NSLocalizedString(@"MAIL_LOG", @"Mail Log");
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

                    [SSThemes configureCell:cell];
                }

                break;

            case SettingsSectionActions:

                if( indexPath.row == SettingsActionRowAdvanced ) {

                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.textLabel.text = NSLocalizedString(@"ADVANCED", @"Advanced");

                    [SSThemes configureCell:cell];

                } else if (indexPath.row == SettingsActionRowRadialCommands) {

                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.textLabel.text = NSLocalizedString(@"RADIAL_CONTROL", nil);

                    [SSThemes configureCell:cell];
                }

                break;

            case SettingsSectionAboutHelp:

                switch( indexPath.row ) {
                    case SettingsAboutAppRow:
                        cell.textLabel.text = NSLocalizedString(@"ABOUT_HELP", @"About/Help");
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        break;

                    case SettingsSupportRow:
                        cell.textLabel.text = NSLocalizedString(@"CONTACT_US", @"Contact Us");
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        break;
                }

                [SSThemes configureCell:cell];

                break;

            default:

                break;
        }

    };

    _dataSource.tableView = self.tableView;
}

#pragma mark - cell config

- (void)configureBooleanCell:(SSBooleanCell *)cell atIndexPath:(NSIndexPath *)indexPath {

    @weakify(self);
    NSString *prefKey, *label;
    BOOL isSelected = NO;
    SSBooleanChangeHandler changeHandler;

    [SSThemes configureCell:cell];

    switch( indexPath.section ) {

        case SettingsSectionActions: {

            switch( indexPath.row ) {

                case SettingsActionRowAutocorrect:
                    prefKey = kPrefAutocorrect;
                    label = NSLocalizedString(@"AUTOCORRECT_ENABLED", @"Autocorrect Typing");
                    break;

                case SettingsActionRowLocalEcho:
                    prefKey = kPrefLocalEcho;
                    label = NSLocalizedString(@"LOCAL_ECHO", @"Local Command Echo");
                    break;

                default:
                    return;
            }

            break;
        }
        case SettingsSectionLogging: {
            prefKey = kPrefLogging;
            label = NSLocalizedString(@"LOGGING_PREF", nil);

            break;
        }
    }

    if (prefKey && !changeHandler) {
        isSelected = [[NSUserDefaults standardUserDefaults] boolForKey:prefKey];

        changeHandler = ^(BOOL isOn) {
            @strongify(self);
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:NSUserDefaultsDidChangeNotification
                                                          object:nil];

            [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:prefKey];

            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(userDefaultsChanged:)
                                                         name:NSUserDefaultsDidChangeNotification
                                                       object:nil];

            if ([prefKey isEqualToString:kPrefLogging]) {

                NSIndexPath *ip = [NSIndexPath indexPathForRow:SettingsLoggingMailLog
                                                     inSection:SettingsSectionLogging];

                NSUInteger count = [self.dataSource numberOfItemsInSection:SettingsSectionLogging];

                if (isOn && count == 1) {
                    [self.dataSource insertItem:@(1)
                                    atIndexPath:ip];
                } else if (!isOn && count == 2) {
                    [self.dataSource removeItemAtIndexPath:ip];
                }
            }
        };
    }

    [cell configureWithLabel:label
                    selected:isSelected
               changeHandler:changeHandler];
}

#pragma mark - KVO

- (void) userDefaultsChanged:(NSNotification *)note {
    dispatch_async( dispatch_get_main_queue(), ^{
        NSMutableIndexSet *indexSet = [NSMutableIndexSet indexSet];
        [indexSet addIndex:SettingsSectionActions];
        [indexSet addIndex:SettingsSectionLogging];
        [self.tableView reloadSections:indexSet
                      withRowAnimation:UITableViewRowAnimationNone];
    });
}

#pragma mark - actions

- (void)closeSettings:(id)sender {
    id del = self.delegate;

    if ([del respondsToSelector:@selector(settingsViewDidClose:)]) {
        [del settingsViewDidClose:self];
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UIViewController *nextVC = nil;
    id del = self.delegate;

    switch( indexPath.section ) {
        case SettingsSectionTop: {
            switch( indexPath.row ) {
                case SettingsRowWorlds:
                    nextVC = [SSWorldListViewController new];

                    break;
                case SettingsRowThemes:
                    nextVC = [SSThemePickerController themePickerController];

                    break;
                default:
                    break;
            }
            break;
        }
        case SettingsSectionLogging: {

            if (indexPath.row == SettingsLoggingMailLog) {

                if (![MFMailComposeViewController canSendMail]) {
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];

                    [SPLAlerts SPLShowAlertViewWithTitle:NSLocalizedString(@"MAIL_LOG", @"Mail Log")
                                                 message:NSLocalizedString(@"MAIL_LOG_ENABLE_EMAIL", nil)
                                             cancelTitle:@"OK"
                                             cancelBlock:nil
                                                 okTitle:nil
                                                 okBlock:nil];

                    return;
                }

                if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefLogging]
                    && [del respondsToSelector:@selector(settingsViewShouldSendSessionLog:)]) {
                    [del settingsViewShouldSendSessionLog:self];
                }
            }

            break;
        }
        case SettingsSectionActions:
            switch( indexPath.row ) {
                case SettingsActionRowAdvanced:
                    nextVC = [SSAdvSettingsController new];
                    break;
                case SettingsActionRowRadialCommands:
                    nextVC = [SPLRadialEditor new];
                    break;
                default:
                    break;
            }
            break;
        case SettingsSectionAboutHelp:
            switch( indexPath.row ) {
                case SettingsAboutAppRow:
                    if ([del respondsToSelector:@selector(settingsViewShouldOpenAboutURL:)]) {
                        [del settingsViewShouldOpenAboutURL:self];
                    }

                    break;
                case SettingsSupportRow:
                    if ([del respondsToSelector:@selector(settingsViewShouldOpenContact:)]) {
                        [del settingsViewShouldOpenContact:self];
                    }

                    break;
            }

            break;
        default:
            break;
    }

    if( nextVC )
        [self.navigationController pushViewController:nextVC
                                             animated:YES];
}

@end
