//
//  SSWorldDisplayController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/14/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSWorldDisplayController.h"
#import "SSWorldCell.h"
#import "SSWorldListViewController.h"
#import <SSDataSources.h>
#import <Masonry.h>
#import "SPLCheckMarkView.h"

CGFloat const kWorldHeaderHeight = 20.0f;
CGFloat const kWorldDisplayWidth = 220;
static NSUInteger const kAddWorldRowId = 1337;

// Client statuses.
typedef NS_ENUM(NSUInteger, SPLClientStatus) {
    SPLClientStatusNoClient, // No client at this index
    SPLClientStatusDisconnected,
    SPLClientStatusConnected,
    SPLClientStatusConnectedUnread
};

@interface SSWorldDisplayController () <UITableViewDelegate>

@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) SSArrayDataSource *dataSource;
@property (nonatomic, strong) NSMutableIndexSet *unreadClientIndexes;
@property (nonatomic, strong) FBKVOController *kvoController;

- (void) closeWorldPicker;

// Client status
- (void) updateWorldStatusButtons;
- (SPLClientStatus) statusForClientAtIndex:(NSInteger)index;
- (UIImage *) imageForClientAtIndex:(NSInteger)index;

@end

@implementation SSWorldDisplayController

- (instancetype)init {
    if ((self = [self initWithStyle:UITableViewStylePlain])) {
        _unreadClientIndexes = [NSMutableIndexSet indexSet];
        _selectedIndex = NSNotFound;
        _kvoController = [FBKVOController controllerWithObserver:self];

        self.clearsSelectionOnViewWillAppear = YES;
        self.title = NSLocalizedString(@"ACTIVE_WORLDS", nil);

        // backgrounding notification
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(applicationDidEnterBackground:)
                                                     name:UIApplicationDidEnterBackgroundNotification
                                                   object:nil];

        // Theme changes
        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeBackgroundColor
                            options:NSKeyValueObservingOptionNew
                              block:^(SSWorldDisplayController *controller, id object, NSDictionary *change) {
                                  [SSThemes configureTable:controller.tableView];
                                  controller.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
                                  [controller.tableView reloadData];
                              }];

        @weakify(self);

        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeName
                            options:NSKeyValueObservingOptionNew
                              block:^(id table, id object, NSDictionary *change) {
                                  @strongify(self);
                                  [self.tableView addCenteredFooterWithImage:([[SSThemes sharedThemer] isUsingDarkTheme]
                                                                              ? [SPLImagesCatalog tildeWhiteImage]
                                                                              : [SPLImagesCatalog tildeDarkImage])
                                                                       alpha:0.5f];
                              }];

        _dataSource = [[SSArrayDataSource alloc] initWithItems:@[ @(kAddWorldRowId) ]];
        self.dataSource.tableActionBlock = ^BOOL(SSCellActionType action,
                                                 UITableView *tableView,
                                                 NSIndexPath *indexPath) {
            @strongify(self);

            // Allow only editing
            if (action != SSCellActionTypeEdit) {
                return NO;
            }

            NSInteger clientCount = [self numberOfClients];

            return indexPath.row < clientCount && clientCount >= 2;
        };
        self.dataSource.tableDeletionBlock = ^(SSArrayDataSource *dataSource,
                                               UITableView *tableView,
                                               NSIndexPath *indexPath) {
            @strongify(self);
            [self removeClientAtIndex:indexPath.row];
        };
        self.dataSource.cellConfigureBlock = ^(SSBaseTableCell *cell,
                                               id object,
                                               UITableView *tableView,
                                               NSIndexPath *indexPath) {
            @strongify(self);
            [SSThemes configureCell:cell];

            cell.textLabel.numberOfLines = 2;

            if ([object isKindOfClass:[NSNumber class]]) {
                cell.textLabel.text = NSLocalizedString(@"ADD_CONNECTION", @"Add Connection");
                cell.imageView.image = [SPLImagesCatalog worldAddImage];
            } else {
                SSClientViewController *client = [self clientAtIndex:indexPath.row];

                if( client ) {
                    cell.textLabel.text = [client currentWorldDescription];
                    cell.imageView.image = [self imageForClientAtIndex:indexPath.row];
                }
            }

            if (indexPath.row == self.selectedIndex) {
                cell.accessoryView = [SPLCheckMarkView checkWithColor:[[SSThemes sharedThemer] valueForThemeKey:kThemeFontColor]];
            } else {
                cell.accessoryView = nil;
            }
        };
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleLeftMargin;
    self.tableView.scrollEnabled = NO;
    self.tableView.delegate = self;

    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, kWorldDisplayWidth, 20.f)];
    headerView.backgroundColor = [UIColor clearColor];
    self.tableView.tableHeaderView = headerView;

    [self.tableView registerClass:[SSBaseHeaderFooterView class]
forHeaderFooterViewReuseIdentifier:[SSBaseHeaderFooterView identifier]];

    [SSThemes configureTable:self.tableView];

    [self.tableView addCenteredFooterWithImage:([[SSThemes sharedThemer] isUsingDarkTheme]
                                                ? [SPLImagesCatalog tildeWhiteImage]
                                                : [SPLImagesCatalog tildeDarkImage])
                                         alpha:0.5f];

    self.dataSource.tableView = self.tableView;
    [self.tableView reloadData];

    [[UIApplication sharedApplication] setStatusBarHidden:NO
                                            withAnimation:UIStatusBarAnimationFade];
}

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - World picker

- (void)closeWorldPicker {
    [[SSClientContainer sharedClientContainer] dismissViewControllerAnimated:YES
                                                                  completion:nil];
}

#pragma mark - UITableViewDelegate

- (CGFloat) tableHeaderHeight {
    CGFloat statusHeight = CGRectGetHeight([UIApplication sharedApplication].statusBarFrame);

    if (statusHeight > 20) {
        return 20.f;
    }

    return statusHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    SSBaseHeaderFooterView *headerFooter = [tableView dequeueReusableHeaderFooterViewWithIdentifier:
                                            [SSBaseHeaderFooterView identifier]];

    if (!headerFooter) {
        headerFooter = [SSBaseHeaderFooterView new];
    }

    headerFooter.contentView.backgroundColor = tableView.backgroundColor;

    [headerFooter setFrame:CGRectMake(0, 0,
                                      CGRectGetWidth(tableView.frame),
                                      [self tableHeaderHeight])];

    return headerFooter;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self tableHeaderHeight];
}

- (NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([[self clientAtIndex:indexPath.row] isConnected]) {
        return NSLocalizedString(@"DISCONNECT", @"Disconnect");
    }

    return NSLocalizedString(@"REMOVE", @"Remove");
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.row < [self numberOfClients]) {
        NSIndexPath *currentIndex = [NSIndexPath indexPathForRow:(NSInteger)_selectedIndex
                                                       inSection:0];

        [self setSelectedIndex:indexPath.row];
        [[SSClientContainer sharedClientContainer] closeDrawerAnimated:YES];

        NSArray *rows = @[ indexPath ];

        if (currentIndex.row != indexPath.row)
            rows = [rows arrayByAddingObject:currentIndex];

        [tableView reloadRowsAtIndexPaths:rows
                         withRowAnimation:UITableViewRowAnimationFade];

    } else {

        @weakify(self);

        WorldPickerSelectionBlock pickblock = ^(NSManagedObjectID *pickedWorld) {
            @strongify(self);
            if ([[UIDevice currentDevice] isIPad]) {
                [self.popover dismissPopoverAnimated:YES];
                [self addClientWithWorld:pickedWorld];
            } else {
                [[SSClientContainer sharedClientContainer] dismissViewControllerAnimated:YES
                                                                              completion:^{
                                                                                  [self addClientWithWorld:pickedWorld];
                                                                              }];
            }
        };

        SSWorldListViewController *picker = [SSWorldListViewController worldPickerViewControllerWithCompletion:pickblock];
        UINavigationController *nav = [picker wrappedNavigationController];
        //nav.delegate = self;

        if( [[UIDevice currentDevice] isIPad] ) {
            _popover = [[UIPopoverController alloc] initWithContentViewController:nav];
            //_popoverController.delegate = self;
            _popover.popoverContentSize = [picker preferredContentSize];

            [_popover presentPopoverFromRect:[tableView rectForRowAtIndexPath:indexPath]
                                                inView:tableView
                              permittedArrowDirections:UIPopoverArrowDirectionAny
                                              animated:YES];
        } else {
            picker.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                    target:self
                                                                                                    action:@selector(closeWorldPicker)];
            [[SSClientContainer sharedClientContainer] presentViewController:nav
                                                                    animated:YES
                                                                  completion:nil];
        }
    }
}

#pragma mark - Client management

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    if (self.selectedIndex == selectedIndex) {
        [[SSClientContainer sharedClientContainer] closeDrawerAnimated:YES];
        return;
    }

    if (selectedIndex == NSNotFound || selectedIndex >= [self numberOfClients]) {
        return;
    }

    _selectedIndex = selectedIndex;

    if ([self.unreadClientIndexes containsIndex:(NSUInteger)selectedIndex]) {
        [self.unreadClientIndexes removeIndex:(NSUInteger)selectedIndex];
    }

    [SSClientContainer sharedClientContainer].centerPanel =
     (UIViewController *)[self.dataSource itemAtIndexPath:
                          [NSIndexPath indexPathForRow:(NSInteger)_selectedIndex
                                             inSection:0]];

    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0]
                  withRowAnimation:UITableViewRowAnimationFade];

    [self updateWorldStatusButtons];
}

- (void)addClientWithWorld:(NSManagedObjectID *)worldId {

    SSClientViewController *newClient = [SSClientViewController client];
    newClient.delegate = self;
    UINavigationController *nav = [newClient wrappedNavigationController];
    nav.delegate = newClient;
    nav.navigationBar.translucent = NO;

    BOOL isFirstWorld = [self numberOfClients] == 0;

    if (!worldId) {
        World *defaultWorld = [World defaultWorldInContext:[NSManagedObjectContext MR_defaultContext]];

        if (defaultWorld)
            worldId = [defaultWorld objectID];
    }

    if (!worldId) {
        DLog(@"**** no default world");
    } else {
        [newClient updateCurrentWorld:worldId
                   connectAfterUpdate:[[NSUserDefaults standardUserDefaults]
                                       boolForKey:kPrefConnectOnStartup]];
    }

    NSMutableArray *reloadRows = [NSMutableArray new];

    if (self.selectedIndex != NSNotFound) {
        [reloadRows addObject:[NSIndexPath indexPathForRow:(NSInteger)_selectedIndex
                                                 inSection:0]];
    }

    [self.dataSource insertItem:nav
                        atIndex:(NSUInteger)[self numberOfClients]];

    if ([self numberOfClients] >= kMaximumOpenClients) {
        id lastItem = [[self.dataSource allItems] lastObject];

        if ([lastItem isKindOfClass:[NSNumber class]]) {
            [self.dataSource removeItemAtIndex:[self.dataSource numberOfItems] - 1];

            self.selectedIndex = (NSInteger)[self.dataSource numberOfItems] - 1;
        }
    } else {
        self.selectedIndex = [self numberOfClients] - 1;
    }

    if ([reloadRows count] > 0) {
        [self.tableView reloadRowsAtIndexPaths:reloadRows
                              withRowAnimation:UITableViewRowAnimationFade];
    }

    [SSClientContainer sharedClientContainer].centerPanel = nav;

    [self updateWorldStatusButtons];

    [[SSClientContainer sharedClientContainer] closeDrawerAnimated:!isFirstWorld];
}

- (void)removeClientAtIndex:(NSInteger)index {
    if (index >= [self numberOfClients]) {
        return;
    }

    SSClientViewController *toRemove = [self clientAtIndex:index];

    if (toRemove) {
        toRemove.delegate = nil;
        [toRemove disconnect];
    }

    if ([self.unreadClientIndexes containsIndex:(NSUInteger)index]) {
        [self.unreadClientIndexes removeIndex:(NSUInteger)index];
    }

    if (index == 0) {
        [self setSelectedIndex:1];
    } else if (self.selectedIndex == index) {
        [self setSelectedIndex:0];
    }

    if ([self numberOfClients] == kMaximumOpenClients) {
        [_dataSource appendItem:@(kAddWorldRowId)];
    }

    [self.dataSource removeItemAtIndex:(NSUInteger)index];

    _selectedIndex = [self.dataSource indexPathForItem:
                      [SSClientContainer sharedClientContainer].centerPanel].row;

    [self updateWorldStatusButtons];
}

#pragma mark - Client access

- (void)selectNextWorld {
    NSInteger clientCount = [self numberOfClients];

    if (clientCount < 2) {
        return;
    }

    if (self.selectedIndex == clientCount - 1) {
        [self setSelectedIndex:0];
    } else {
        [self setSelectedIndex:1 + self.selectedIndex];
    }
}

- (NSInteger)indexOfClient:(SSClientViewController *)client {
    for (NSInteger i = 0; i < [self numberOfClients]; i++) {
        if ([[self clientAtIndex:i] isEqual:client]) {
            return i;
        }
    }

    return NSNotFound;
}

- (SSClientViewController *)clientAtIndex:(NSInteger)index {
    if (index == NSNotFound) {
        return nil;
    }

    id item = [self.dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:index
                                                                  inSection:0]];

    if (!item || ![item isKindOfClass:[UINavigationController class]]) {
        return nil;
    }

    return (SSClientViewController *)[[(UINavigationController *)item viewControllers] firstObject];
}

- (SSClientViewController *)currentVisibleClient {
    return [self clientAtIndex:self.selectedIndex];
}

- (UIViewController *)selectedViewController {
    if (_selectedIndex < [self numberOfClients]) {
        return [self.dataSource itemAtIndexPath:[NSIndexPath indexPathForRow:self.selectedIndex
                                                                   inSection:0]];
    }

    return nil;
}

#pragma mark - MUD client container

- (NSInteger)numberOfClients {
    return (NSInteger)[[self.dataSource allItems] indexesOfObjectsPassingTest:^BOOL(id object,
                                                                                    NSUInteger index,
                                                                                    BOOL *stop) {
        return [object isKindOfClass:[UIViewController class]];
    }].count;
}

- (void)applicationDidEnterBackground:(NSNotification *)notification {
    for (NSInteger i = 0; i < [self numberOfClients]; i++) {
        if ([[self clientAtIndex:i] isConnected]) {
            [[SSAppDelegate sharedApplication].notificationObserver scheduleTimeoutNotification];
            return;
        }
    }
}

#pragma mark - Client Status Image

- (SPLClientStatus)statusForClientAtIndex:(NSInteger)index {
    SSClientViewController *client = [self clientAtIndex:index];

    if (!client) {
        return SPLClientStatusNoClient;
    }

    BOOL clientIsUnread = [self.unreadClientIndexes containsIndex:(NSUInteger)index];

    if (![client isConnected]) {
        return SPLClientStatusDisconnected;
    } else {
        if (clientIsUnread && index != self.selectedIndex) {
            return SPLClientStatusConnectedUnread;
        } else {
            return SPLClientStatusConnected;
        }
    }
}

- (UIImage *)imageForClientAtIndex:(NSInteger)index {
    switch ([self statusForClientAtIndex:index]) {
        case SPLClientStatusDisconnected:
            return [SPLImagesCatalog connectRedImage];

        case SPLClientStatusConnected:
            return [SPLImagesCatalog connectGreenImage];

        case SPLClientStatusConnectedUnread:
            return [SPLImagesCatalog connectBlueImage];

        default:
            return nil;
    }
}

- (void) drawStatusCircleForWorldAtIndex:(NSInteger)index inRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSaveGState(context);
    {
        UIImage *clientImage = [self imageForClientAtIndex:index];

        if (!clientImage) {
            CGContextSetLineWidth(context, 2.0f);
            CGContextSetStrokeColorWithColor(context, [UIColor whiteColor].CGColor);
            CGContextStrokeEllipseInRect(context, rect);
            CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
            CGContextFillEllipseInRect(context, rect);
        } else {
            rect = CGRectInset(rect, -1, -1);
            [clientImage drawInRect:rect];
        }
    }
    CGContextRestoreGState(context);
}

- (UIImage *)worldSelectButtonImage {

    UIGraphicsBeginImageContextWithOptions(CGSizeMake(36, 36), NO, 0.0);

    [self drawStatusCircleForWorldAtIndex:0 inRect:CGRectMake(2, 2, 13, 13)];
    [self drawStatusCircleForWorldAtIndex:1 inRect:CGRectMake(18, 2, 13, 13)];
    [self drawStatusCircleForWorldAtIndex:2 inRect:CGRectMake(2, 18, 13, 13)];
    [self drawStatusCircleForWorldAtIndex:3 inRect:CGRectMake(18, 18, 13, 13)];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

- (void)updateWorldStatusButtons {
    UIImage *newImage = [self worldSelectButtonImage];

    if (newImage) {
        for (NSInteger i = 0; i < kMaximumOpenClients; i++) {
            SSClientViewController *client = [self clientAtIndex:i];

            if (!client) {
                continue;
            }

            [client.worldSelectButton setImage:newImage
                                      forState:UIControlStateNormal];
        }
    }
}

#pragma mark - SSClientDelegate

- (void) updateClientStatusTableForClient:(SSClientViewController *)client {
    NSInteger index = [self indexOfClient:client];

    if( index == NSNotFound )
        return;

    [self.tableView reloadData];

    [self updateWorldStatusButtons];
}

- (void)clientDidConnect:(SSClientViewController *)client {
    [self updateClientStatusTableForClient:client];
}

- (void)clientDidDisconnect:(SSClientViewController *)client {
    [self updateClientStatusTableForClient:client];
}

- (void)clientDidReceiveText:(SSClientViewController *)client {
    NSInteger index = [self indexOfClient:client];

    if (index != NSNotFound
        && index != [self selectedIndex]
        && ![self.unreadClientIndexes containsIndex:(NSUInteger)index] ) {
        [self.unreadClientIndexes addIndex:(NSUInteger)index];
    }

    [self updateClientStatusTableForClient:client];
}

@end
