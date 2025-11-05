//
//  SSWorldListViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSWorldListViewController.h"
#import "SSWorldEditViewController.h"
#import "SSWorldCell.h"
#import <SSDataSources.h>

@interface SSWorldListViewController ()

@property (nonatomic, copy) WorldPickerSelectionBlock completeBlock;
@property (nonatomic, strong) SSCoreDataSource *dataSource;

- (SSWorldListViewController *) init;
- (void) addWorld:(id)sender;

@end

@implementation SSWorldListViewController

- (instancetype)init {
    if ((self = [self initWithStyle:UITableViewStylePlain])) {
        [SSThemes configureTable:self.tableView];

        self.title = NSLocalizedString(@"WORLDS", @"Worlds");

        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(addWorld:)];

        addButton.accessibilityLabel = NSLocalizedString(@"NEW_WORLD", nil);
        addButton.accessibilityHint = @"Adds a new world.";
        self.navigationItem.rightBarButtonItem = addButton;
    }

    return self;
}

+ (SSWorldListViewController *)worldPickerViewControllerWithCompletion:(WorldPickerSelectionBlock)block {
    SSWorldListViewController *picker = [self new];

    picker.completeBlock = block;

    return picker;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // data source
    NSFetchRequest *worldFetch = [World MR_requestAllSortedBy:[World defaultSortField]
                                                    ascending:[World defaultSortAscending]
                                                withPredicate:[World predicateForRecordsWithHidden:NO]
                                                    inContext:[NSManagedObjectContext MR_defaultContext]];

    @weakify(self);
    SSCellConfigureBlock worldConfig = ^(SSWorldCell *cell,
                                         World *world,
                                         UITableView *tableView,
                                         NSIndexPath *indexPath ) {
        @strongify(self);
        cell.textLabel.text = world.name;
        cell.textLabel.adjustsFontSizeToFitWidth = YES;
        cell.textLabel.minimumScaleFactor = 0.6f;
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@:%@",
                                     world.hostname,
                                     world.port];

        if (self.completeBlock)
            cell.accessoryType = UITableViewCellAccessoryNone;
    };

    _dataSource = [[SSCoreDataSource alloc] initWithFetchRequest:worldFetch
                                                       inContext:[NSManagedObjectContext MR_defaultContext]
                                              sectionNameKeyPath:nil];
    self.dataSource.cellClass = [SSWorldCell class];
    self.dataSource.cellConfigureBlock = worldConfig;
    self.dataSource.tableActionBlock = ^BOOL(SSCellActionType action,
                                             UITableView *tableView,
                                             NSIndexPath *indexPath) {
        // Allow deletion only
        // we can edit if this is not a picker VC
        @strongify(self);
        return action == SSCellActionTypeEdit && self.completeBlock == nil;
    };
    self.dataSource.tableDeletionBlock = ^(SSCoreDataSource *aDataSource,
                                           UITableView *tableView,
                                           NSIndexPath *indexPath) {

        World *world  = [aDataSource itemAtIndexPath:indexPath];
        NSManagedObjectID *worldId = [world objectID];

        if( !worldId )
            return;

        [MagicalRecord saveWithBlock:^(NSManagedObjectContext *deleteContext) {
            World *w = [World existingObjectWithId:worldId inContext:deleteContext];

            if( w ) {
                [w deleteObject];
            }
        }];
    };
    self.dataSource.rowAnimation = UITableViewRowAnimationFade;
    self.dataSource.tableView = self.tableView;
}

- (CGSize)preferredContentSize {
    return [self.tableView sizeThatFits:CGSizeMake(320, CGFLOAT_MAX)];
}

- (void)dealloc {
    _dataSource = nil;
    _completeBlock = nil;
}

#pragma mark - actions

- (void)addWorld:(id)sender {
    [World createObjectWithCompletion:^(NSManagedObjectID *newWorldId) {
        SSWorldEditViewController *editor = [SSWorldEditViewController editorForWorld:newWorldId];

        [self.navigationController pushViewController:editor
                                             animated:YES];
    }];
}

#pragma mark - tableview delegate

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    World *world = [self.dataSource itemAtIndexPath:indexPath];

    [tv deselectRowAtIndexPath:indexPath animated:YES];

    if( self.completeBlock )
        self.completeBlock( [world objectID] );
    else
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWorldChanged
                                                            object:[world objectID]];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
    World *world = [self.dataSource itemAtIndexPath:indexPath];

    [self.navigationController pushViewController:[SSWorldEditViewController editorForWorld:[world objectID]]
                                         animated:YES];
}

@end
