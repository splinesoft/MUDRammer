//
//  SSSoundPickerViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 12/7/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSSoundPickerViewController.h"
#import <SSDataSources.h>
#import "JSQSystemSoundPlayer+SSAdditions.h"

@interface SSSoundPickerViewController ()

@property (nonatomic, strong) SSArrayDataSource *dataSource;

@end

@implementation SSSoundPickerViewController

- (instancetype)init {
    if ((self = [self initWithStyle:UITableViewStylePlain])) {
        self.title = NSLocalizedString(@"SOUNDS", nil);
        self.clearsSelectionOnViewWillAppear = YES;

        _selectedFileName = @"None";
    }

    return self;
}

- (CGSize)preferredContentSize {
    return [self.tableView sizeThatFits:CGSizeMake(320.0f, CGFLOAT_MAX)];
}

- (void)dealloc {
    _selectedBlock = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [SSThemes configureTable:self.tableView];

    _dataSource = [[SSArrayDataSource alloc] initWithItems:[@[@"None"] arrayByAddingObjectsFromArray:
                                                            [JSQSystemSoundPlayer allSounds]]];
    self.dataSource.cellClass = [SSBaseTableCell class];
    self.dataSource.tableActionBlock = ^BOOL(SSCellActionType action,
                                             UITableView *tableView,
                                             NSIndexPath *indexPath) {
        return NO;
    };

    @weakify(self);
    self.dataSource.cellConfigureBlock = ^(SSBaseTableCell *cell,
                                           id sound,
                                           UITableView *tableView,
                                           NSIndexPath *indexPath) {
        @strongify(self);
        [SSThemes configureCell:cell];
        BOOL selected;

        if ([sound isKindOfClass:[SSSound class]]) {
            cell.textLabel.text = ((SSSound *)sound).soundName;

            selected = [self.selectedFileName isEqualToString:((SSSound *)sound).fileName];
        } else {
            cell.textLabel.text = sound;

            selected = !self.selectedFileName || [self.selectedFileName isEqualToString:sound];
        }

        cell.accessoryType = (selected
                              ? UITableViewCellAccessoryCheckmark
                              : UITableViewCellAccessoryNone );
    };

    self.dataSource.tableView = self.tableView;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    NSIndexPath *oldSoundIndex = ([self.selectedFileName isEqualToString:@"None"]
                                  ? [NSIndexPath indexPathForRow:0 inSection:0]
                                  : [self.dataSource indexPathForItem:
                                     [JSQSystemSoundPlayer soundForFileName:self.selectedFileName]]);

    NSMutableArray *reloadRows = [NSMutableArray arrayWithObject:indexPath];
    id pickedSound = [self.dataSource itemAtIndexPath:indexPath];
    NSString *fileName;

    if ([pickedSound isKindOfClass:[SSSound class]]) {
        fileName = ((SSSound *)pickedSound).fileName;

        [JSQSystemSoundPlayer playSound:pickedSound
                             completion:nil];
    } else {
        fileName = pickedSound;
    }

    if (self.selectedBlock) {
        self.selectedBlock(fileName);
    }

    self.selectedFileName = fileName;

    if (oldSoundIndex && indexPath.row != oldSoundIndex.row) {
        [reloadRows addObject:oldSoundIndex];
    }

    [tableView reloadRowsAtIndexPaths:reloadRows
                     withRowAnimation:UITableViewRowAnimationFade];
}


@end
