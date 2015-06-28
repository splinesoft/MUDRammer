//
//  SSAdvSettingsController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 4/25/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSAdvSettingsController.h"
#import <SSDataSources.h>
#import "SSBooleanCell.h"
#import "SSStringCoder.h"
#import "SSValueCell.h"
#import "SSStringEncodingPicker.h"
#import <VTAcknowledgementsViewController.h>
#import "SSTextEntryCell.h"
#import <Masonry.h>

@interface SSAdvSettingsController ()

@property (nonatomic, strong) SSSectionedDataSource *dataSource;
@property (nonatomic, strong) SSStringCoder *coder;

- (instancetype) init;

- (SSSection *) sectionForIndex:(SSAdvancedSection)section;

- (void) userDefaultsChanged;

@end

@implementation SSAdvSettingsController

- (instancetype)init {
    if ((self = [self initWithStyle:UITableViewStyleGrouped])) {
        _coder = [SSStringCoder new];

        self.clearsSelectionOnViewWillAppear = YES;
        self.title = NSLocalizedString(@"ADVANCED", @"Advanced");

        [SSThemes configureTable:self.tableView];
    }

    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsChanged)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];

    NSMutableArray *sections = [NSMutableArray array];

    for( NSUInteger i = 0; i < SSAdvancedNumSections; i++ )
        [sections addObject:[self sectionForIndex:i]];

    _dataSource = [[SSSectionedDataSource alloc] initWithSections:sections];

    @weakify(self);

    self.dataSource.tableActionBlock = ^BOOL(SSCellActionType action,
                                             UITableView *tableView,
                                             NSIndexPath *indexPath) {
        return NO;
    };
    self.dataSource.cellCreationBlock = ^id(NSNumber *item,
                                            UITableView *tableView,
                                            NSIndexPath *indexPath) {

        switch (indexPath.section) {
            case SSAdvancedSectionStringEncoding:
                return [SSValueCell cellForTableView:tableView];
            case SSAdvancedSectionAcknowledgements:
                return [SSBaseTableCell cellForTableView:tableView];
            case SSAdvancedSectionSemicolonCommands: {
                if (indexPath.row == 0) {
                    return [SSBooleanCell cellForTableView:tableView];
                } else {
                    SSTextEntryCell *cell = [SSTextEntryCell cellForTableView:tableView];
                    [cell.textField mas_remakeConstraints:^(MASConstraintMaker *make) {
                        make.top.and.bottom.equalTo(cell.contentView);
                        make.right.equalTo(cell.contentView).offset(-16);
                        make.width.equalTo(@110);
                    }];

                    return cell;
                }
            }
            default:
                return [SSBooleanCell cellForTableView:tableView];
        }
    };
    self.dataSource.cellConfigureBlock = ^(SSBaseTableCell *cell,
                                           NSNumber *item,
                                           UITableView *tableView,
                                           NSIndexPath *indexPath) {
        @strongify(self);
        if (indexPath.section == SSAdvancedSectionAcknowledgements) {
            cell.textLabel.text = [VTAcknowledgementsViewController localizedTitle];
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            [SSThemes configureCell:cell];
        } else if (indexPath.section == SSAdvancedSectionStringEncoding) {
            cell.textLabel.text = NSLocalizedString(@"STRING_ENCODING", nil);
            cell.detailTextLabel.text = [self.coder currentStringEncoding].localizedName;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.selectionStyle = UITableViewCellSelectionStyleGray;
            [SSThemes configureCell:cell];
        } else if (indexPath.section == SSAdvancedSectionSemicolonCommands && indexPath.row == 1) {
            SSTextEntryCell *textCell = (SSTextEntryCell *)cell;
            textCell.textLabel.text = NSLocalizedString(@"SEMICOLON_CMDS_DELIMITER", nil);
            textCell.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:kPrefSemicolonDefaultDelimiter
                                                                                       attributes:
                                                        @{ NSFontAttributeName : [[SSThemes currentFont] fontWithSize:18.f],
                                                           NSForegroundColorAttributeName : [SSThemes valueForThemeKey:kThemeFontColor] }];
            textCell.textField.font = [[SSThemes currentFont] fontWithSize:18.f];
            textCell.textField.text = SPLCurrentCommandDelimiter();
            textCell.textField.textAlignment = NSTextAlignmentRight;
            textCell.textFieldShouldReturn = YES;
            textCell.changeHandler = ^(UITextField *textField) {
                NSString *delimiter = ([textField.text length] > 0
                                       ? textField.text
                                       : kPrefSemicolonDefaultDelimiter);

                [[NSNotificationCenter defaultCenter] removeObserver:self];

                [[NSUserDefaults standardUserDefaults] setObject:delimiter
                                                          forKey:kPrefSemicolonCommandDelimiter];

                [[NSNotificationCenter defaultCenter] addObserver:self
                                                         selector:@selector(userDefaultsChanged)
                                                             name:NSUserDefaultsDidChangeNotification
                                                           object:nil];
            };
        } else {
            SSBooleanCell *boolCell = (SSBooleanCell *)cell;
            NSString *label;
            BOOL isSelected = NO;
            NSString *pref;
            SSBooleanChangeHandler changeHandler;
            boolCell.selectionStyle = UITableViewCellSelectionStyleNone;
            boolCell.accessoryType = UITableViewCellAccessoryNone;

            switch ((SSAdvancedSection)indexPath.section) {

                case SSAdvancedSectionTop: {

                    switch ((SSAdvancedTopRow)indexPath.row) {
                        case SSAdvancedTopRowCharBar:
                            label = NSLocalizedString(@"CHARACTER_BAR", nil);
                            pref = kPrefInputAccessoryBar;
                            break;

                        case SSAdvancedTopRowConnectLaunch:
                            label = NSLocalizedString(@"CONNECT_ON_STARTUP", nil);
                            pref = kPrefConnectOnStartup;
                            break;

                        case SSAdvancedTopRowNavPref:
                            label = NSLocalizedString(@"TOP_BAR_VISIBLE", nil);
                            pref = kPrefTopBarAlwaysVisible;
                            break;

                        default:
                            break;
                    }

                    break;
                }

                case SSAdvancedSectionInputKeep: {

                    switch ((SSInputRow)indexPath.row) {
                        case SSInputRowDarkKeyboard:
                            label = NSLocalizedString(@"KEYBOARD_APPEARANCE", nil);
                            pref = kPrefKeyboardStyle;
                            break;
                        case SSInputRowAutocapitalize:
                            label = NSLocalizedString(@"AUTOCAPITALIZE", nil);
                            pref = kPrefAutocapitalization;
                            break;
                        case SSInputRowInputKeep:
                            label = NSLocalizedString(@"KEEP_TEXT", @"Keep Input Text");
                            pref = kPrefInputKeepsCommands;
                            break;
                        default:
                            break;
                    }

                    break;
                }

                case SSAdvancedSectionSimpleTelnet:
                    label = NSLocalizedString(@"SIMPLE_TELNET", @"Simple Telnet");
                    pref = kPrefSimpleTelnetMode;

                    break;

                case SSAdvancedSectionBTKeyboard:
                    label = NSLocalizedString(@"BTKEYBOARD", nil);
                    pref = kPrefBTKeyboard;

                    break;

                case SSAdvancedSectionSemicolonCommands:
                    label = NSLocalizedString(@"SEMICOLON_CMDS", nil);
                    pref = kPrefSemicolonCommands;

                    break;

                default:

                    return; // not good.
            }

            if (pref && !changeHandler) {
                isSelected = [[NSUserDefaults standardUserDefaults] boolForKey:pref];

                changeHandler = ^(BOOL isOn) {
                    [[NSNotificationCenter defaultCenter] removeObserver:self];

                    [[NSUserDefaults standardUserDefaults] setBool:isOn
                                                            forKey:pref];

                    [[NSNotificationCenter defaultCenter] addObserver:self
                                                             selector:@selector(userDefaultsChanged)
                                                                 name:NSUserDefaultsDidChangeNotification
                                                               object:nil];

                    if ([pref isEqualToString:kPrefSemicolonCommands]) {
                        if (isOn && [self.dataSource numberOfItemsInSection:SSAdvancedSectionSemicolonCommands] == 1) {
                            [self.dataSource appendItems:@[ @0 ] toSection:SSAdvancedSectionSemicolonCommands];
                        } else if (!isOn && [self.dataSource numberOfItemsInSection:SSAdvancedSectionSemicolonCommands] == 2) {
                            [self.dataSource removeItemsInRange:NSMakeRange(1, 1) inSection:SSAdvancedSectionSemicolonCommands];
                        }
                    }
                };
            }

            [boolCell configureWithLabel:label
                                selected:isSelected
                           changeHandler:changeHandler];

            [SSThemes configureCell:boolCell];
        }
    };

    self.dataSource.tableView = self.tableView;
}

- (CGSize)preferredContentSize {
    return [self.tableView sizeThatFits:CGSizeMake(320, CGFLOAT_MAX)];
}

- (void)userDefaultsChanged {
    [self.tableView performSelectorOnMainThread:@selector(reloadData)
                                     withObject:nil
                                  waitUntilDone:NO];
}

#pragma mark - Table view data source

- (SSSection *)sectionForIndex:(SSAdvancedSection)section {
    NSString *header, *footer;
    NSUInteger numRows = 1;

    switch( section ) {
        case SSAdvancedSectionStringEncoding:
            footer = NSLocalizedString(@"STRING_ENCODING_HELP", nil);
            break;

        case SSAdvancedSectionSimpleTelnet:
            footer = NSLocalizedString(@"SIMPLE_TELNET_DESC", @"Simple telnet desc");
            break;

        case SSAdvancedSectionTop:
            footer = NSLocalizedString(@"CHARACTER_BAR_HELP", @"CharBarDesc");
            numRows = SSAdvancedTopNumRows;
            break;

        case SSAdvancedSectionInputKeep:
            footer = NSLocalizedString(@"KEEP_TEXT_HELP", @"Keep Text Help");
            numRows = SSInputNumRows;
            break;

        case SSAdvancedSectionSemicolonCommands:
            footer = NSLocalizedString(@"SEMICOLON_CMDS_HELP", nil);
            numRows = ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefSemicolonCommands]
                       ? 2
                       : 1);

            break;

        case SSAdvancedSectionBTKeyboard:
            footer = NSLocalizedString(@"BTKEYBOARD_HELP", nil);
            break;

        default:
            break;
    }

    return [SSSection sectionWithNumberOfItems:numRows
                                        header:header
                                        footer:footer
                                    identifier:@(section)];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 44.f;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    if (indexPath.section == (NSInteger)[self.dataSource indexOfSectionWithIdentifier:@(SSAdvancedSectionAcknowledgements)]) {

        VTAcknowledgementsViewController *ack = [[VTAcknowledgementsViewController alloc] initWithAcknowledgementsPlistPath:
                                                 [[NSBundle mainBundle] pathForResource:@"Pods-acknowledgements"
                                                                                 ofType:@"plist"]];

        ack.headerText = NSLocalizedString(@"ACK_HEADER", nil);

        ack.navigationItem.leftBarButtonItem = nil;

        [self.navigationController pushViewController:ack
                                             animated:YES];

    } else if (indexPath.section == (NSInteger)[self.dataSource indexOfSectionWithIdentifier:@(SSAdvancedSectionStringEncoding)]) {

        SSStringEncodingPicker *picker = [SSStringEncodingPicker new];

        [self.navigationController pushViewController:picker
                                             animated:YES];

    }
}

@end
