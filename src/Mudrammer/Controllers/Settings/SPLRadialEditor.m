//
//  SPLRadialEditor.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/27/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLRadialEditor.h"
#import "SSSegmentCell.h"
#import "SSTextEntryCell.h"
#import "SSRadialControl.h"

static NSUInteger const kMaxRadialCommands = 8;

@interface SPLRadialEditor ()

@property (nonatomic, strong) SSSectionedDataSource *dataSource;

@property (nonatomic, strong) UIBarButtonItem *insertButton;

- (void) userDefaultsDidChange;

// Set Command editing section visible
- (void) setCommandSectionVisible:(BOOL)visible;

- (void) toggleEditing:(id)sender;

// Save changes back to defaults
- (void) saveChangesToDefaults;

- (void) addCommandRow:(UIBarButtonItem *)sender;

- (void) changeRadialPrefToIndex:(NSInteger)index;

@end

@implementation SPLRadialEditor

- (instancetype)init {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {

        _insertButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                      target:self
                                                                      action:@selector(addCommandRow:)];

        _dataSource = [[SSSectionedDataSource alloc] initWithSection:
                       [SSSection sectionWithNumberOfItems:1
                                                    header:nil
                                                    footer:NSLocalizedString(@"RADIAL_ENABLE_HELP", nil)
                                                identifier:nil]];

        self.dataSource.rowAnimation = UITableViewRowAnimationFade;
        self.dataSource.shouldRemoveEmptySections = NO;

        @weakify(self);
        self.dataSource.cellCreationBlock = ^id(id value,
                                                UITableView *tableView,
                                                NSIndexPath *indexPath) {

            switch ((SPLRadialEditorSection)indexPath.section) {

                case SPLRadialEditorSectionEnable:
                    return [SSSegmentCell cellForTableView:tableView];

                case SPLRadialEditorSectionCommands:
                    return [SSTextEntryCell cellForTableView:tableView];

                case SPLRadialEditorNumSections:
                    return nil;
            }
        };

        self.dataSource.cellConfigureBlock = ^(SSBaseTableCell *aCell,
                                               id value,
                                               UITableView *tableView,
                                               NSIndexPath *indexPath) {

            switch ((SPLRadialEditorSection)indexPath.section) {

                case SPLRadialEditorSectionEnable: {
                    SSSegmentCell *cell = (SSSegmentCell *)aCell;

                    [SSThemes configureCell:cell];

                    [cell configureWithLabel:NSLocalizedString(@"RADIAL", nil)
                                    segments:@[ NSLocalizedString(@"LEFT", nil),
                                                NSLocalizedString(@"OFF", nil),
                                                NSLocalizedString(@"RIGHT", nil) ]
                               selectedIndex:[[NSUserDefaults standardUserDefaults] integerForKey:kPrefRadialControl]
                               changeHandler:^(NSInteger index) {
                                   @strongify(self);
                                   [self changeRadialPrefToIndex:index];
                               }];

                    break;
                }

                case SPLRadialEditorSectionCommands: {
                    SSTextEntryCell *cell = (SSTextEntryCell *)aCell;

                    cell.textField.text = value;

                    cell.changeHandler = ^(UITextField *textField) {
                        @strongify(self);

                        if ([textField isFirstResponder]) {
                            [textField resignFirstResponder];
                        }

                        NSString *text = [textField.text copy];

                        if ([text length] == 0) {
                            if (indexPath.row < (NSInteger)[self.dataSource numberOfItemsInSection:indexPath.section]) {
                                [self.dataSource removeItemAtIndexPath:indexPath];
                            }
                        } else {
                            SSSection *section = [self.dataSource sectionAtIndex:SPLRadialEditorSectionCommands];

                            if ((NSUInteger)indexPath.row < [section.items count]) {
                                (section.items)[(NSUInteger)indexPath.row] = text;
                            }
                        }

                        [self saveChangesToDefaults];
                    };

                    break;
                }

                case SPLRadialEditorNumSections:
                    break;
            }
        };

        self.dataSource.tableActionBlock = ^BOOL(SSCellActionType action,
                                                 UITableView *tableView,
                                                 NSIndexPath *indexPath) {

            switch ((SPLRadialEditorSection)indexPath.section) {

                case SPLRadialEditorSectionEnable:
                    return NO;

                case SPLRadialEditorSectionCommands:
                    return YES;

                case SPLRadialEditorNumSections:
                    return NO;
            }
        };

        self.dataSource.tableDeletionBlock = ^(SSSectionedDataSource *dataSource,
                                               UITableView *tableView,
                                               NSIndexPath *indexPath) {
            @strongify(self);

            [dataSource removeItemAtIndexPath:indexPath];

            [self saveChangesToDefaults];
        };

        // Observe pref changes
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userDefaultsDidChange)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
    }

    return self;
}

- (CGSize)preferredContentSize {
    return CGSizeMake(320, 500);
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.rowHeight = 44.f;

    [SSThemes configureTable:self.tableView];

    BOOL isEnabled = [SSRadialControl radialControlIsEnabled:kPrefRadialControl];

    [self setCommandSectionVisible:isEnabled];

    self.dataSource.tableView = self.tableView;

    if (isEnabled) {
        self.navigationItem.rightBarButtonItems = @[
            self.insertButton,
            [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                          target:self
                                                          action:@selector(toggleEditing:)]
        ];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self saveChangesToDefaults];
}

#pragma mark - Actions

- (void)toggleEditing:(id)sender {
    BOOL isEditing = ![self.tableView isEditing];

    [self.tableView setEditing:isEditing
                      animated:YES];

    NSMutableArray *rightItems = [NSMutableArray new];

    if (!isEditing) {
        [rightItems addObject:self.insertButton];
    }

    [rightItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:(isEditing
                                                                                ? UIBarButtonSystemItemDone
                                                                                : UIBarButtonSystemItemEdit)
                                                                        target:self
                                                                        action:@selector(toggleEditing:)]];

    self.navigationItem.rightBarButtonItems = rightItems;
}

- (void)setCommandSectionVisible:(BOOL)visible {
    if (visible && [self.dataSource numberOfSections] == SPLRadialEditorNumSections) {
        return;
    }

    if (!visible && [self.dataSource numberOfSections] == SPLRadialEditorNumSections - 1) {
        return;
    }

    if (visible) {
        [self.dataSource appendSection:
         [SSSection sectionWithItems:[[NSUserDefaults standardUserDefaults] arrayForKey:kPrefRadialCommands]
                              header:NSLocalizedString(@"RADIAL_COMMANDS", nil)
                              footer:NSLocalizedString(@"RADIAL_EXTRA_HELP", nil)
                          identifier:nil]];
    } else if ([self.dataSource numberOfSections] > 1) {
        [self.dataSource removeSectionAtIndex:SPLRadialEditorSectionCommands];
    }
}

- (void)addCommandRow:(UIBarButtonItem *)sender {
    if ([self.dataSource numberOfItemsInSection:SPLRadialEditorSectionCommands] >= kMaxRadialCommands) {
        return;
    }

    if ([[self.dataSource sectionAtIndex:SPLRadialEditorSectionCommands].items indexOfObject:@""] != NSNotFound) {
        return;
    }

    NSIndexPath *newIndex = [NSIndexPath indexPathForRow:0 inSection:SPLRadialEditorSectionCommands];

    [self.dataSource insertItem:@""
                    atIndexPath:newIndex];

    for (SSBaseTableCell *cell in [self.tableView visibleCells]) {
        if ([[self.tableView indexPathForCell:cell] isEqual:newIndex]) {
            [((SSTextEntryCell *)cell).textField becomeFirstResponder];
            break;
        }
    }
}

- (void)changeRadialPrefToIndex:(NSInteger)index {
    if ([self.tableView isEditing]) {
        [self toggleEditing:nil];
    }

    if (index == SSRadialControlPositionOff) {
        self.navigationItem.rightBarButtonItems = nil;
    } else {
        self.navigationItem.rightBarButtonItems = @[ self.insertButton,
                                                     [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                                   target:self
                                                                                                   action:@selector(toggleEditing:)]
                                                     ];
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSUserDefaultsDidChangeNotification
                                                  object:nil];

    [SSRadialControl updateRadialPreference:kPrefRadialControl
                                 toPosition:(SSRadialControlPosition)index];

    [self setCommandSectionVisible:(index != SSRadialControlPositionOff)];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsDidChange)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];
}

#pragma mark - User Defaults

- (void)userDefaultsDidChange {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView endEditing:YES];
        [self.tableView reloadData];
    });
}

- (void)saveChangesToDefaults {
    if ([self.dataSource numberOfSections] == 1) {
        return;
    }

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSUserDefaultsDidChangeNotification
                                                  object:nil];

    SSSection *commandSection = [self.dataSource sectionAtIndex:SPLRadialEditorSectionCommands];

    [[NSUserDefaults standardUserDefaults] setObject:[commandSection items]
                                              forKey:kPrefRadialCommands];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(userDefaultsDidChange)
                                                 name:NSUserDefaultsDidChangeNotification
                                               object:nil];

    self.insertButton.enabled = !([self.dataSource numberOfItemsInSection:SPLRadialEditorSectionCommands] >= kMaxRadialCommands);
}

#pragma mark - UITableViewDelegate

- (NSIndexPath *)tableView:(UITableView *)tableView
targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)sourceIndexPath
       toProposedIndexPath:(NSIndexPath *)proposedDestinationIndexPath
{
    if (proposedDestinationIndexPath.section != SPLRadialEditorSectionCommands) {
        return [NSIndexPath indexPathForRow:0 inSection:SPLRadialEditorSectionCommands];
    }

    return proposedDestinationIndexPath;
}

@end
