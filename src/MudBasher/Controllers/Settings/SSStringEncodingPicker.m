//
//  SSStringEncodingPicker.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 12/8/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSStringEncodingPicker.h"
#import "SSStringCoder.h"

@interface SSStringEncodingPicker ()

@property (nonatomic, strong) SSArrayDataSource *dataSource;
@property (nonatomic, strong) SSStringCoder *coder;

- (void) userDefaultsChanged;

@end

@implementation SSStringEncodingPicker

- (instancetype) init {
    if ((self = [self initWithStyle:UITableViewStylePlain])) {
        _coder = [SSStringCoder new];

        self.clearsSelectionOnViewWillAppear = YES;
        self.title = NSLocalizedString(@"STRING_ENCODING", nil);

        [SSThemes configureTable:self.tableView];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userDefaultsChanged)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
    }

    return self;
}

- (CGSize)preferredContentSize {
    return [self.tableView sizeThatFits:CGSizeMake(320.0f, CGFLOAT_MAX)];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    _dataSource = [[SSArrayDataSource alloc] initWithItems:[SSStringCoder availableStringEncodings]];
    _dataSource.cellClass = [SSBaseTableCell class];
    _dataSource.tableActionBlock = ^BOOL(SSCellActionType action,
                                         UITableView *tableView,
                                         NSIndexPath *indexPath) {
        return NO;
    };
    _dataSource.cellConfigureBlock = ^(SSBaseTableCell *cell,
                                       SSStringEncoding *encoding,
                                       UITableView *tableView,
                                       NSIndexPath *indexPath) {
        [SSThemes configureCell:cell];

        cell.textLabel.text = encoding.localizedName;

        cell.accessoryType = ([encoding.localizedName isEqualToString:[[NSUserDefaults standardUserDefaults]
                                                                       stringForKey:kPrefStringEncoding]]
                              ? UITableViewCellAccessoryCheckmark
                              : UITableViewCellAccessoryNone);
    };
    _dataSource.tableView = self.tableView;
}

#pragma mark - Defaults

- (void)userDefaultsChanged {
    [self.tableView performSelectorOnMainThread:@selector(reloadData)
                                     withObject:nil
                                  waitUntilDone:NO];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SSStringEncoding *currentEncoding = [self.coder currentStringEncoding];
    SSStringEncoding *newEncoding = [self.dataSource itemAtIndexPath:indexPath];

    DLog(@"selected %@", newEncoding);

    if ([currentEncoding.localizedName isEqualToString:newEncoding.localizedName]) {
        [tableView deselectRowAtIndexPath:indexPath
                                 animated:YES];
    } else {
        NSMutableArray *reloadRows = [NSMutableArray arrayWithObject:indexPath];
        NSIndexPath *oldIndex = [_dataSource indexPathForItem:currentEncoding];

        [[NSNotificationCenter defaultCenter] removeObserver:self];

        [[NSUserDefaults standardUserDefaults] setObject:newEncoding.localizedName
                                                  forKey:kPrefStringEncoding];

        if (oldIndex) {
            [reloadRows addObject:oldIndex];
        }

        [tableView reloadRowsAtIndexPaths:reloadRows
                         withRowAnimation:UITableViewRowAnimationFade];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userDefaultsChanged)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];
    }
}

@end
