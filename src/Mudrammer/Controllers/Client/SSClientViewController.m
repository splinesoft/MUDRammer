//
//  SSClientViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/22/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import MessageUI;

#import "SSClientViewController.h"
#import "SSMudView.h"
#import "SSThemePickerController.h"
#import "SSSettingsViewController.h"
#import "SSWorldEditViewController.h"
#import "SSClientContainer.h"
#import "SSMUDSocket.h"
#import "SSConnectButton.h"
#import "SSSessionLogger.h"
#import <TTTAttributedLabel.h>
#import "SSWorldListViewController.h"
#import "SSWorldDisplayController.h"
#import "JSQSystemSoundPlayer+SSAdditions.h"
#import <UserVoice.h>
#import <Masonry.h>
#import "SPLWorldTickerManager.h"
#import "SPLMUDTitleView.h"
#import "SPLMSSPViewController.h"
#import "SSClientViewController+Interactions.h"
#import "SSTextTableView.h"
#import "SSTGAEditor.h"
#import "SPLHandoffWebViewController.h"
#import "SPLTimerManager.h"

#define kObservedProperties         @[ kThemeFontSize, kThemeFontName ]

typedef void (^SPLSettingsCloseBlock) (void);

@interface SSClientViewController () <SSMUDSocketDelegate,
                                      SSMudViewDelegate,
                                      UIPopoverControllerDelegate,
                                      SettingsDelegate>
- (SSClientViewController *) init;

// socket
- (void) sendNAWS;

// user actions
- (void) voiceOverStatusDidChange:(NSNotification *)note;
- (void) editCurrentWorld:(id)sender;
- (void) tappedSettings:(id)sender;
- (void) tappedWorldSelect:(id)sender;

// send text
- (void) sendText:(NSString *)text appendToHistory:(BOOL)appendToHistory;

// UI updating
- (void) updateWorldToolbar;
- (void) closeSettingsWithCompletion:(SPLSettingsCloseBlock)completion;

// Append text to the mudview. If userInput is YES and local echo is disabled, does not append anything.
- (void) appendText:(NSString *)text isUserInput:(BOOL)isUserInput;

// Append to log
- (void) appendTextToLog:(NSString *)cleanText;

@property (nonatomic, strong) SPLWorldTickerManager *tickerManager;
@property (nonatomic, strong) SSSessionLogger *logger;

@property (nonatomic, strong) SSConnectButton *connectButton;
@property (nonatomic, strong) SPLMUDTitleView *titleView;

@property (nonatomic, strong) FBKVOController *kvoController;

@property (nonatomic, strong) UIBarButtonItem *settingsButton;
@property (nonatomic, strong) UIBarButtonItem *editWorldButton;

@property (nonatomic, strong) UIPopoverController *SSPopoverController;

@property (nonatomic, assign) NSUInteger tickerIdentifier;

// Socket
@property (nonatomic, strong) NSOperationQueue *readParsingQueue;
@property (nonatomic, strong) NSOperationQueue *writeQueue;

@end

@implementation SSClientViewController
{

    // world access
    World *currentWorld;

    // solely to fade in/out the edit world button
    NSFetchedResultsController *defaultWorldFetcher;

    // logging
    NSString *logFileName;
}

#pragma mark - init

- (SSClientViewController *) init {
    if ((self = [super init])) {
        _tickerManager = [[SPLWorldTickerManager alloc] initWithTimerManager:[SPLTimerManager new]];
        _logger = [SSSessionLogger new];

        _socket = [[SSMUDSocket alloc] initWithSocket:[GCDAsyncSocket new]
                                             delegate:self];
        _kvoController = [FBKVOController controllerWithObserver:self];

        // text processing
        _readParsingQueue = [NSOperationQueue ss_serialOperationQueueNamed:@"Read Queue"];
        _writeQueue = [NSOperationQueue ss_serialOperationQueueNamed:@"Write Queue"];

        _titleView = [[SPLMUDTitleView alloc] initWithFrame:CGRectMake(0, 0, ([[UIDevice currentDevice] isIPad] ? 280 : 160), 44)];
        [self updateTitle:NSLocalizedString(@"DISCONNECTED", @"Disconnected")];

        @weakify(self);
        self.titleView.MSSPButtonBlock = ^{
            @strongify(self);
            SPLMSSPViewController *MSSPVC = [[SPLMSSPViewController alloc] initWithMSSPData:self.titleView.MSSPData];
            MSSPVC.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] bk_initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                                      handler:^(id sender)
            {
                [self dismissViewControllerAnimated:YES completion:nil];
            }];

            UINavigationController *nav = [MSSPVC wrappedNavigationController];

            nav.modalPresentationStyle = UIModalPresentationFormSheet;

            [self presentViewController:nav animated:YES completion:nil];
        };
        self.navigationItem.titleView = self.titleView;

        // Voiceover enabling
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(voiceOverStatusDidChange:)
                                                     name:UIAccessibilityVoiceOverStatusChanged
                                                   object:nil];

        // font changes cause NAWS
        for (NSString *observed in kObservedProperties) {
            [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                                keyPath:observed
                                options:NSKeyValueObservingOptionNew
                                  block:^(SSClientViewController *client, id object, NSDictionary *change) {
                                      [client setNeedsStatusBarAppearanceUpdate];
                                      [client sendNAWS];
                                  }];
        }
    }

    return self;
}

+ (SSClientViewController *) client {
    SSClientViewController *client = [[SSClientViewController alloc] init];

    return client;
}

+ (SSClientViewController *)clientWithWorld:(NSManagedObjectID *)world {
    SSClientViewController *client = [SSClientViewController client];

    [client updateCurrentWorld:world
            connectAfterUpdate:[[NSUserDefaults standardUserDefaults]
                                boolForKey:kPrefConnectOnStartup]];

    return client;
}

- (UIRectEdge)edgesForExtendedLayout {
    return UIRectEdgeBottom;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self setNavVisible:YES];

    // Hacks around initial welcome on iPhone
    if ([self isConnected]) {
        [self.mudView setEditable:YES];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if ([self isConnected] && [[NSUserDefaults standardUserDefaults] boolForKey:kPrefInitialSetupComplete]) {
        [[SSAppDelegate sharedApplication].notificationObserver registerForLocalNotifications];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    if ([self.SSPopoverController isPopoverVisible]) {
        [self.SSPopoverController dismissPopoverAnimated:animated];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_writeQueue cancelAllOperations];
    [self.socket resetSocket];
    self.socket.SSdelegate = nil;
    [self.socket disconnect];
    _socket = nil;

    self.connectButton.connectDelegate = nil;
    self.SSPopoverController.delegate = nil;

    _delegate = nil;
    _hostname = nil;
    defaultWorldFetcher = nil;

    self.mudView.delegate = nil;
    [self.mudView removeFromSuperview];
    _mudView = nil;
    [_readParsingQueue cancelAllOperations];
    [self.tickerManager disableTickersForIdentifier:self.tickerIdentifier];
}

#pragma mark - view and backgrounding

- (void)updateWorldToolbar {
    // settings button
    if (!self.settingsButton) {
        _settingsButton = [[UIBarButtonItem alloc] initWithImage:[SPLImagesCatalog settingsImage]
                                                            style:UIBarButtonItemStylePlain
                                                            target:self
                                                          action:@selector(tappedSettings:)];
        self.settingsButton.accessibilityLabel = NSLocalizedString(@"SETTINGS", nil);
        self.settingsButton.accessibilityHint = @"Shows app settings.";
    }

    // current-world editor button
    if (!self.editWorldButton) {
        _editWorldButton = [[UIBarButtonItem alloc] initWithImage:[SPLImagesCatalog worldEditImage]
                                                            style:UIBarButtonItemStylePlain
                                                           target:self
                                                           action:@selector(editCurrentWorld:)];
        self.editWorldButton.accessibilityLabel = NSLocalizedString(@"EDIT_WORLD", nil);
        self.editWorldButton.accessibilityHint = @"Edits the current world.";
    }

    if (!self.worldSelectButton) {
        // DRAWS ON MAIN THREAD
        UIImage *worldSelectImage = [[SSClientContainer worldDisplayDrawer] worldSelectButtonImage];

        _worldSelectButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.worldSelectButton addTarget:self
                                   action:@selector(tappedWorldSelect:)
                         forControlEvents:UIControlEventTouchUpInside];

        [self.worldSelectButton setImage:worldSelectImage
                                forState:UIControlStateNormal];

        [self.worldSelectButton setFrame:CGRectMake(0, 0, 40, 40)];

        self.worldSelectButton.accessibilityLabel = NSLocalizedString(@"SESSION_SELECT", nil);
        self.worldSelectButton.accessibilityHint = @"Shows the currently connected Worlds.";
    }

    if (!self.connectButton) {
        _connectButton = [SSConnectButton new];
        self.connectButton.connectDelegate = self;
    }

    NSMutableArray *leftItems = [NSMutableArray array];

    if ([[UIDevice currentDevice] isIPad]) {
        [leftItems addObject:[UIBarButtonItem fixedWidthBarButtonItemWithWidth:20.0f]];
    }

    [leftItems addObject:self.settingsButton];

    if (currentWorld) {
        if ([[UIDevice currentDevice] isIPad]) {
            [leftItems addObjectsFromArray:@[
                [UIBarButtonItem fixedWidthBarButtonItemWithWidth:50.0f],
                self.editWorldButton
            ]];
        } else {
            [leftItems addObject:self.editWorldButton];
        }
    }

    self.navigationController.navigationBar.tintColor = [UIColor whiteColor];

    [self.navigationItem setLeftBarButtonItems:leftItems
                                      animated:NO];

    NSMutableArray *rightItems = [NSMutableArray array];

    if ([[UIDevice currentDevice] isIPad]) {
        [rightItems addObject:[UIBarButtonItem fixedWidthBarButtonItemWithWidth:20.0f]];
    }

    UIBarButtonItem *connectBarButton = [self.connectButton wrappedBarButtonItem];
    self.connectButton.targetBarButton = connectBarButton;
    [rightItems addObject:connectBarButton];

    if (([[UIDevice currentDevice] isIPad])) {
        [rightItems addObject:[UIBarButtonItem fixedWidthBarButtonItemWithWidth:50.0f]];
    }

    [rightItems addObject:[self.worldSelectButton wrappedBarButtonItem]];

    [self.navigationItem setRightBarButtonItems:rightItems
                                       animated:NO];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    // mud view
    _mudView = [[SSMudView alloc] initWithFrame:CGRectZero];
    self.mudView.delegate = self;
    [self.view addSubview:self.mudView];
    [self.mudView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.view);
    }];
    [self.mudView setEditable:NO];
    [self.mudView.tableView addCenteredHeaderWithImage:([[SSThemes sharedThemer] isUsingDarkTheme]
                                                        ? [SPLImagesCatalog tildeWhiteImage]
                                                        : [SPLImagesCatalog tildeDarkImage])
                                                 alpha:0.5f];

    // setup navbar
    [self updateWorldToolbar];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [super didRotateFromInterfaceOrientation:fromInterfaceOrientation];

    [self sendNAWS];
}

- (void)setNavVisible:(BOOL)visible {
    if (![[self.navigationController visibleViewController] isEqual:self]) {
        return;
    }

    if (!visible && [self.SSPopoverController isPopoverVisible]) {
        return;
    }

    if (!visible && [[NSUserDefaults standardUserDefaults] boolForKey:kPrefTopBarAlwaysVisible]) {
        return;
    }

    if (!visible && UIAccessibilityIsVoiceOverRunning()) {
        return;
    }

    if( !self.presentedViewController
       && [[UIApplication sharedApplication] isStatusBarHidden] == visible )
        [[UIApplication sharedApplication] setStatusBarHidden:!visible
                                                withAnimation:UIStatusBarAnimationFade];

    [self setNeedsStatusBarAppearanceUpdate];

    if( [self.navigationController isNavigationBarHidden] == visible )
        [self.navigationController setNavigationBarHidden:!visible
                                                 animated:YES];

    if( !visible && [self.SSPopoverController isPopoverVisible] )
        [self closeSettingsWithCompletion:nil];
}

- (void)voiceOverStatusDidChange:(NSNotification *)note {
    dispatch_async( dispatch_get_main_queue(), ^{
        BOOL enabled = UIAccessibilityIsVoiceOverRunning();

        if (enabled) {
            [self setNavVisible:YES];
        }
    });
}

- (void)hideKeyboard {
    [self.mudView endEditing:YES];
}

- (void)updateTitle:(NSString *)title {
    self.title = title;
    [self.titleView setTitle:title];
}

#pragma mark - UIPopoverControllerDelegate

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController {
    return YES;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)aPopoverController {
    self.SSPopoverController.delegate = nil;

    if ([self.SSPopoverController isPopoverVisible]) {
        [self.SSPopoverController dismissPopoverAnimated:NO];
    }

    _SSPopoverController = nil;

    if ([self isConnected]) {
        [self.mudView setKeyboardPanningEnabled:YES];
    }

    [SSClientContainer sharedClientContainer].recognizesPanGesture = YES;
}

#pragma mark - UINavigationControllerDelegate

- (void)navigationController:(UINavigationController *)navigationController
      willShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {

    if (![navigationController isEqual:self.navigationController] || ![viewController isEqual:self]) {
        [self.mudView setKeyboardPanningEnabled:NO];
    }
}

- (void)navigationController:(UINavigationController *)navigationController
       didShowViewController:(UIViewController *)viewController
                    animated:(BOOL)animated {

    if ([navigationController isEqual:self.navigationController] && [viewController isEqual:self]) {
        if ([self isConnected]) {
            [self.mudView setKeyboardPanningEnabled:YES];
        }

        [SSClientContainer sharedClientContainer].recognizesPanGesture = YES;
    }

    if ([self.SSPopoverController isPopoverVisible] && [navigationController isEqual:self.SSPopoverController.contentViewController]) {
        CGSize s = [viewController preferredContentSize];

        if (!CGSizeEqualToSize(s, CGSizeZero)) {
            [self.SSPopoverController setPopoverContentSize:CGSizeMake(320.0f, s.height) animated:animated];
        }
    }
}

#pragma mark - button actions

- (void)tappedSettings:(id)sender {
    if ([self.SSPopoverController isPopoverVisible]) {
        UINavigationController *nav = (UINavigationController *)[self.SSPopoverController contentViewController];

        if ([[nav visibleViewController] isKindOfClass:[SSSettingsViewController class]]) {
            [self.SSPopoverController dismissPopoverAnimated:YES];
            return;
        } else {
            [self.SSPopoverController dismissPopoverAnimated:NO];
            // fall through
        }
    }

    [self.mudView endEditing:YES];

    SSSettingsViewController *settings = [SSSettingsViewController new];
    settings.delegate = self;
    UINavigationController *settingsNav = [settings wrappedNavigationController];
    settingsNav.delegate = self;

    if ([[UIDevice currentDevice] isIPad]) {
        _SSPopoverController = [[UIPopoverController alloc] initWithContentViewController:settingsNav];

        [self.SSPopoverController presentPopoverFromBarButtonItem:self.settingsButton
                                         permittedArrowDirections:UIPopoverArrowDirectionUp
                                                         animated:YES];
        self.SSPopoverController.delegate = self;
    } else {
        [self presentViewController:settingsNav
                           animated:YES
                         completion:nil];
    }
}

- (void)editCurrentWorld:(id)sender {
    if ([self.SSPopoverController isPopoverVisible]) {
        UINavigationController *nav = (UINavigationController *)[self.SSPopoverController contentViewController];

        if( [[nav visibleViewController] class] == [SSWorldEditViewController class] ) {
            [self.SSPopoverController dismissPopoverAnimated:YES];
            return;
        } else {
            [self.SSPopoverController dismissPopoverAnimated:NO];
            // fall through
        }
    }

    if( !currentWorld )
        return;

    NSManagedObjectID *currentId = [currentWorld objectID];

    if( !currentId )
        return;

    [self.mudView endEditing:YES];

    @weakify(self);

    SSWorldEditViewController *editor = [SSWorldEditViewController editorForWorld:currentId];
    editor.saveCompletionBlock = ^(BOOL didSave) {
        @strongify(self);
        [self closeSettingsWithCompletion:nil];
    };
    UINavigationController *nav = [editor wrappedNavigationController];
    nav.delegate = self;

    if( [[UIDevice currentDevice] isIPad] ) {
        _SSPopoverController = [[UIPopoverController alloc] initWithContentViewController:nav];

        [self.SSPopoverController presentPopoverFromBarButtonItem:self.editWorldButton
                                         permittedArrowDirections:UIPopoverArrowDirectionUp
                                                         animated:YES];

        self.SSPopoverController.delegate = self;

        // remove cancel button
        editor.navigationItem.leftBarButtonItem = nil;
    } else {
        [self presentViewController:nav
                           animated:YES
                         completion:nil];
    }
}

- (void)tappedWorldSelect:(id)sender {
    [self.mudView endEditing:YES];

    if( [self.SSPopoverController isPopoverVisible] )
        [self.SSPopoverController dismissPopoverAnimated:NO];

    [[SSClientContainer sharedClientContainer] showRightPanelAnimated:YES];
}

#pragma mark - current world

- (NSString *)currentWorldDescription {
    if( currentWorld )
        return [currentWorld worldDescription];

    if( self.hostname && self.port )
        return [NSString stringWithFormat:@"%@:%@",
                self.hostname,
                self.port];

    return @"Nowhere at all";
}

- (void)updateCurrentWorld:(NSManagedObjectID *)newWorld connectAfterUpdate:(BOOL)connectAfterUpdate {
    [self closeSettingsWithCompletion:^{
        World *world = [World existingObjectWithId:newWorld
                                         inContext:[NSManagedObjectContext MR_defaultContext]];

        if (!world) {
            return;
        }

        [world setDefaultWorld];

        logFileName = [SSSessionLogger logFileNameForHost:world.hostname];

        if (![currentWorld isEqual:world]) {
            currentWorld = world;

            defaultWorldFetcher.delegate = nil;
            defaultWorldFetcher = nil;
            // default world
            defaultWorldFetcher = [World MR_fetchAllGroupedBy:nil
                                                withPredicate:[NSPredicate predicateWithFormat:@"(self = %@)", currentWorld]
                                                     sortedBy:[World defaultSortField]
                                                    ascending:[World defaultSortAscending]
                                                     delegate:self];
        }

        [self updateWorldToolbar];

        self.hostname = currentWorld.hostname;
        self.port = currentWorld.port;

        if ([self isConnected]) {
            [self disconnect];
            [self.titleView setMSSPData:nil];
        }

        [self.mudView purgeHistory];
        [self.mudView clearText];

        @weakify(self);

        if (connectAfterUpdate) {
            CGFloat delayInSeconds = 0.4f;
            dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
            dispatch_after(popTime, dispatch_get_main_queue(), ^{
                @strongify(self);
                [self connect];
            });
        }
    }];
}

#pragma mark - settings delegate

- (void) closeSettingsWithCompletion:(SPLSettingsCloseBlock)completion {
    void (^actualCompletion)(void) = ^{
        [self setNeedsStatusBarAppearanceUpdate];

        if ([self isConnected]) {
            [self.mudView setKeyboardPanningEnabled:YES];
        }

        [SSClientContainer sharedClientContainer].recognizesPanGesture = YES;

        if (completion) {
            completion();
        }
    };

    if( [self.SSPopoverController isPopoverVisible] ) {
        [self.SSPopoverController dismissPopoverAnimated:YES];

        actualCompletion();
    } else if( self.presentedViewController ) {
        [self dismissViewControllerAnimated:YES
                                 completion:actualCompletion];
    } else
        actualCompletion();
}

- (void)settingsViewDidClose:(SSSettingsViewController *)settingsViewController {
    [self closeSettingsWithCompletion:nil];
}

- (void)settingsViewShouldOpenAboutURL:(SSSettingsViewController *)settingsViewController {
    [self closeSettingsWithCompletion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationURLTapped
                                                            object:[NSURL URLWithString:kMUDRammerHelpURL]];
    }];
}

- (void)settingsViewShouldOpenContact:(SSSettingsViewController *)settingsViewController {
    @weakify(self);

    [self closeSettingsWithCompletion:^{
        @strongify(self);

        if (![[UIDevice currentDevice] isIPad]) {
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        }

        [UserVoice setDelegate:self];
        [UserVoice presentUserVoiceInterfaceForParentViewController:self];
    }];
}

- (void)settingsViewShouldSendSessionLog:(SSSettingsViewController *)settingsViewController {
    @weakify(self);

    [self closeSettingsWithCompletion:^{
        @strongify(self);

        if (![MFMailComposeViewController canSendMail] || [logFileName length] == 0) {
            return;
        }

        void (^LogProcessOperation) (void) = ^{
            NSString *logString = [SSSessionLogger contentsOfLogWithFileName:logFileName];

            if ([logString length] == 0) {
                return;
            }

            logString = [logString stringByAppendingString:NSLocalizedString(@"LOG_FOOTER", @"Log footer")];

            dispatch_async( dispatch_get_main_queue(), ^{
                MFMailComposeViewController *mailView = [MFMailComposeViewController new];
                [mailView setSubject:[NSString stringWithFormat:@"%@ log",
                                      self.hostname]];
                [mailView setMessageBody:logString
                                  isHTML:NO];
                [mailView bk_setCompletionBlock:^(MFMailComposeViewController *composer, MFMailComposeResult result, NSError *error) {}];

                [self presentViewController:mailView
                                   animated:YES
                                 completion:^{
                                     // MAIL HACK
                                     [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
                                 }];
            });
        };

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), LogProcessOperation);
    }];
}

#pragma mark - connect, disconnect actions

- (void)connect {
    if( [self.hostname length] == 0 || !self.port )
        return;

    if( [self isConnected] )
        return;

    [self updateTitle:NSLocalizedString(@"CONNECTING", @"Connecting")];

    [self appendText:[NSString stringWithFormat:NSLocalizedString(@"CONNECTING_TO_%@_%@", @"Connecting to"),
                         self.hostname,
                         self.port]
         isUserInput:NO];

    NSError *err = nil;

    if (!self.socket) {
        _socket = [[SSMUDSocket alloc] initWithSocket:[GCDAsyncSocket new]
                                             delegate:self];
    }

    BOOL connected = [self.socket connectToHostname:self.hostname
                                             onPort:[self.port unsignedIntegerValue]
                                              error:&err];

    if (!connected) {
        [self appendText:[err localizedDescription]
             isUserInput:NO];
    }

    [self.connectButton setConnected:[self isConnected]];
}

- (BOOL)isConnected {
    return self.socket && ![self.socket isDisconnected];
}

- (void)disconnect {
    self.socket.SSdelegate = nil;
    [self.socket disconnect];
    _socket = nil;
}

- (void)clearText {
    [self.readParsingQueue cancelAllOperations];
    [self.writeQueue cancelAllOperations];
    [self.mudView clearText];
}

#pragma mark - MUD view delegate

- (void)appendText:(NSString *)text isUserInput:(BOOL)isUserInput {
    if (isUserInput) {
        if ([[[NSUserDefaults standardUserDefaults] objectForKey:kPrefLocalEcho] boolValue]) {
            [self.mudView appendText:text
                         isUserInput:YES
                               speak:[self isViewVisible]];
            [self appendTextToLog:[text stringByAppendingString:@"\n"]];
        } else {
            [self appendTextToLog:@"\n"];
        }
    } else {
        [self.mudView appendText:text
                     isUserInput:NO
                           speak:[self isViewVisible]];
    }
}

- (void)mudView:(SSMudView *)mv didReceiveUserCommand:(NSString *)command {
    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefSemicolonCommands]
        && [command stringContainsString:SPLCurrentCommandDelimiter()]) {
        [[command componentsSeparatedByString:SPLCurrentCommandDelimiter()] bk_each:^(NSString *str) {
            [self sendText:str appendToHistory:YES];
        }];
    } else {
        [self sendText:command appendToHistory:YES];
    }
}

- (void)mudView:(SSMudView *)mv moveControlDidMoveToDirection:(NSString *)direction {
    if ([direction length] == 0) {
        return;
    }

    if ([[NSUserDefaults standardUserDefaults] boolForKey:kPrefSemicolonCommands]
        && [direction stringContainsString:SPLCurrentCommandDelimiter()]) {
        [[direction componentsSeparatedByString:SPLCurrentCommandDelimiter()] bk_each:^(NSString *str) {
            [self sendText:str appendToHistory:NO];
        }];
    } else {
        [self sendText:direction appendToHistory:NO];
    }
}

- (void)mudView:(SSMudView *)mudView scrollOffsetChangedSignificantlyInDirection:(BOOL)didScrollDown {
    if (![self isViewVisible]) {
        return;
    }

    if (self.navigationController.navigationBarHidden != didScrollDown) {
        return;
    }

    if (!didScrollDown && ![self isConnected]) {
        return;
    }

    [self setNavVisible:didScrollDown];
}

- (void)mudView:(SSMudView *)mudView shouldCreateRecordWithText:(NSString *)text type:(Class)recordType {
    if (!currentWorld) {
        return;
    }

    if (recordType == [Trigger class]) {
        [Trigger createObjectWithCompletion:^(NSManagedObjectID *objectID) {
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *context) {
                Trigger *trigger = [Trigger existingObjectWithId:objectID
                                                       inContext:context];
                trigger.trigger = text;
            } completion:^(BOOL didSave, NSError *error) {
                SSTGAEditor *editor = [SSTGAEditor editorForRecord:objectID
                                                           inWorld:currentWorld.objectID
                                                     parentContext:[NSManagedObjectContext MR_defaultContext]];

                UINavigationController *nav = [editor wrappedNavigationController];
                nav.modalPresentationStyle = UIModalPresentationPageSheet;
                nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

                [self presentViewController:nav
                                   animated:YES
                                 completion:nil];
            }];
        }];
    } else if (recordType == [Gag class]) {
        [Gag createObjectWithCompletion:^(NSManagedObjectID *objectID) {
            [MagicalRecord saveWithBlock:^(NSManagedObjectContext *context) {
                Gag *gag = [Gag existingObjectWithId:objectID
                                           inContext:context];
                gag.gag = text;
            } completion:^(BOOL didSave, NSError *error) {
                SSTGAEditor *editor = [SSTGAEditor editorForRecord:objectID
                                                           inWorld:currentWorld.objectID
                                                     parentContext:[NSManagedObjectContext MR_defaultContext]];

                UINavigationController *nav = [editor wrappedNavigationController];
                nav.modalPresentationStyle = UIModalPresentationPageSheet;
                nav.modalTransitionStyle = UIModalTransitionStyleCoverVertical;

                [self presentViewController:nav
                                   animated:YES
                                 completion:nil];
            }];
        }];
    }
}

#pragma mark - socket actions

- (void)sendText:(NSString *)text appendToHistory:(BOOL)appendToHistory {
    NSManagedObjectID *currentID = [currentWorld objectID];

    @weakify(self);

    SSBlockOperationBlock writeBlock = ^(SSBlockOperation *operation) {
        @strongify(self);

        if ([operation isCancelled]) {
            return;
        }

        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {

            NSMutableArray *commands = [NSMutableArray array];
            BOOL didPrint = NO;

            // Match aliases
            if (currentID) {
                World *bgWorld = [World existingObjectWithId:currentID
                                                   inContext:localContext];

                if( [operation isCancelled] )
                    return;

                if (bgWorld) {
                    NSArray *aliasCommands = [bgWorld commandsIfMatchingAliasForInput:text];

                    if( aliasCommands ) {
                        [commands addObjectsFromArray:aliasCommands];

                        [self appendText:[NSString stringWithFormat:@"(%@)%@",
                                              NSLocalizedString(@"ALIAS", @"Alias"),
                                              text]
                             isUserInput:YES];

                        didPrint = YES;
                    }
                }
            }

            if( [operation isCancelled] )
                return;

            if ([commands count] == 0) {
                [commands addObject:text];
            }

            if (!didPrint && [self.socket shouldEchoText]) {
                [self appendText:text
                     isUserInput:YES];
            }

            [self.socket sendUserCommands:commands];

            dispatch_async(dispatch_get_main_queue(), ^{
                [self setNavVisible:NO];

                if (appendToHistory) {
                    [self.mudView addHistoryCommand:text];
                }

                [self.mudView.tableView scrollToBottom];
            });
        }];
    };

    [self.writeQueue ss_addBlockOperationWithBlock:writeBlock];
}

- (void)sendNAWS {
    if ([self isConnected]) {
        [self.socket sendNAWSWithSize:[self.mudView.tableView charSize]];
    }
}

#pragma mark - socket delegate

- (void)mudsocketDidConnectToHost:(SSMUDSocket *)sock {

    [self.readParsingQueue cancelAllOperations];
    [self.writeQueue cancelAllOperations];

    @weakify(self);
    [self.readParsingQueue ss_addBlockOperationWithBlock:^(SSBlockOperation *operation) {
        if( [operation isCancelled] )
            return;

        dispatch_sync(dispatch_get_main_queue(), ^{
            @strongify(self);

            if ([self isViewVisible] && [[NSUserDefaults standardUserDefaults] boolForKey:kPrefInitialSetupComplete]) {
                [[SSAppDelegate sharedApplication].notificationObserver registerForLocalNotifications];
            }

            if ([operation isCancelled]) {
                return;
            }

            [self appendText:[NSLocalizedString(@"CONNECTED", @"Connected") stringByAppendingString:@"\n"]
                 isUserInput:NO];

            if( [[currentWorld worldDescription] length] > 0 )
                [self updateTitle:[currentWorld worldDescription]];
            else
                [self updateTitle:[NSString stringWithFormat:@"%@:%@",
                                   self.hostname,
                                   self.port]];

            [self.titleView setMSSPData:nil];

            [self.connectButton setConnected:YES];

            [self.mudView.tableView scrollToBottom];

            [self.mudView setEditable:YES];
            [self.mudView setKeyboardPanningEnabled:YES];

            self.tickerIdentifier = [self.tickerManager enableAndObserveTickersForWorld:currentWorld
                                                                            tickerBlock:^(NSManagedObjectID *tickerId)
            {
                @strongify(self);

                Ticker *ticker = [Ticker existingObjectWithId:tickerId];

                if (!ticker) {
                    return;
                }

                if ([ticker.commands length] > 0) {
                    [self sendText:ticker.commands
                   appendToHistory:YES];
                }

                if ([ticker.soundFileName length] > 0 && ![ticker.soundFileName isEqualToString:@"None"]) {
                    SSSound *sound = [JSQSystemSoundPlayer soundForFileName:ticker.soundFileName];

                    if (sound) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [JSQSystemSoundPlayer playSound:sound
                                                 completion:nil];
                        });
                    }
                }
            }];

            // Connect command
            if ([currentWorld.connectCommand length] > 0) {
                DLog(@"Scheduling connect commands");
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kConnectCommandsDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (![self isConnected] || [currentWorld.connectCommand length] == 0) {
                        return;
                    }

                    [self mudView:self.mudView didReceiveUserCommand:currentWorld.connectCommand];
                });
            }

            id del = self.delegate;

            if ([del respondsToSelector:@selector(clientDidConnect:)]) {
                [del clientDidConnect:self];
            }
        });
    }];
}

- (void)mudsocket:(SSMUDSocket *)sock didDisconnectWithError:(NSError *)err {

    [self.writeQueue cancelAllOperations];

    @weakify(self);
    [self.readParsingQueue ss_addBlockOperationWithBlock:^(SSBlockOperation *operation) {
        if( [operation isCancelled] )
            return;

        NSMutableString *str = [NSMutableString stringWithString:NSLocalizedString(@"DISCONNECTED", @"Disconnected")];

        if( err ) {
            if ([err code] == errSSLProtocol) {
                [str appendString:NSLocalizedString(@"SSL_HANDSHAKE_ERR", nil)];
            } else {
                [str appendFormat:@" (%@)", [err localizedDescription]];
            }
        }

        [str appendString:@"\n"];

        dispatch_sync(dispatch_get_main_queue(), ^{
            @strongify(self);

            if( [operation isCancelled] )
                return;

            [self appendText:str isUserInput:NO];

            [self updateTitle:NSLocalizedString(@"DISCONNECTED", @"Disconnected")];
            [self.titleView setMSSPData:nil];

            [self setNavVisible:YES];

            [self.connectButton setConnected:NO];
            [self.mudView setEditable:NO];

            [self.mudView appendTTS:[NSString stringWithFormat:@"Disconnected from %@", self.hostname]];

            [self.logger closeStreamForFileName:logFileName];

            [self.tickerManager disableTickersForIdentifier:self.tickerIdentifier];

            id del = self.delegate;

            if ([del respondsToSelector:@selector(clientDidDisconnect:)]) {
                [del clientDidDisconnect:self];
            }
        });
    }];
}

- (void)mudsocket:(SSMUDSocket *)sock didReceiveAttributedLineGroup:(SSAttributedLineGroup *)group {
    NSManagedObjectID *worldID = [currentWorld objectID];

    @weakify(self);

    [self.readParsingQueue ss_addBlockOperationWithBlock:^(SSBlockOperation *operation) {
        @strongify(self);

        if ([operation isCancelled]) {
            return;
        }

        [MagicalRecord saveWithBlockAndWait:^(NSManagedObjectContext *localContext) {

            // grab our world in a background context for this operation
            World *bgWorld = nil;

            if (worldID) {
                bgWorld = [World existingObjectWithId:worldID
                                            inContext:localContext];
                [bgWorld refreshObject];
            }

            NSArray *allCleanLines = [group cleanTextLinesWithCommands:YES];
            NSIndexSet *cleanIndexes = [NSIndexSet indexSetWithIndexesInRange:
                                        NSMakeRange(0, [allCleanLines count])];

#ifdef __PARSE_ECHO__
            DLog(@"%@", cleanIndexes);
#endif

            // Indexes of lines passing gag checks
            if (bgWorld) {
                cleanIndexes = [bgWorld filteredIndexesByMatchingGagsInLines:allCleanLines];
            }

#ifdef __PARSE_ECHO__
            DLog(@"%@", cleanIndexes);
#endif

            if ([operation isCancelled]) {
                return;
            }

            NSArray *cleanLines = [allCleanLines objectsAtIndexes:cleanIndexes];
            NSMutableArray *attributedLines = [NSMutableArray arrayWithArray:
                                               [group.lines objectsAtIndexes:cleanIndexes]];

#ifdef __PARSE_ECHO__
            DLog(@"%@", cleanLines);
#endif

            // Fire triggers
            if (bgWorld) {
                NSArray *commands;
                NSDictionary *lineBGColors;
                NSString *soundName;

                [bgWorld runTriggersForLines:cleanLines
                                 outCommands:&commands
                                   outColors:&lineBGColors
                                outSoundName:&soundName];

                if ([soundName length] > 0 && ![soundName isEqualToString:@"None"]) {
                    SSSound *sound = [JSQSystemSoundPlayer soundForFileName:soundName];

                    if (sound) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [JSQSystemSoundPlayer playSound:sound
                                                 completion:nil];
                        });
                    }
                }

                if (commands) {
                    [commands bk_each:^(NSString *cmd) {
                        [self sendText:cmd appendToHistory:NO];
                    }];
                }

                if (lineBGColors) {
                    [lineBGColors enumerateKeysAndObjectsUsingBlock:^(NSNumber *line,
                                                                      UIColor *color,
                                                                      BOOL *stop) {
                        if (!color || [color isEqual:[UIColor clearColor]]) {
                            return;
                        }

                        NSUInteger lineNum = [line unsignedIntegerValue];

                        if (lineNum >= [attributedLines count]) {
                            return;
                        }

                        NSMutableAttributedString *attString = ((SSAttributedLineGroupItem *)attributedLines[lineNum]).line;

                        [attString addAttributes:@{
                               kTTTBackgroundFillColorAttributeName : (id)color.CGColor,
                               kTTTBackgroundLineWidthAttributeName : @0,
                         }
                                           range:NSMakeRange(0, [attString length])];
                    }];
                }
            }

            if ([operation isCancelled] || attributedLines.count == 0) {
                return;
            }

            SSAttributedLineGroup *newGroup = [SSAttributedLineGroup lineGroupWithItems:attributedLines];

            // Append to log
            [self appendTextToLog:[[newGroup cleanTextLinesWithCommands:NO] componentsJoinedByString:@"\n"]];

            // pass lines to the tableview
            [self.mudView appendAttributedLineGroup:newGroup speak:[self isViewVisible]];

            id del = self.delegate;

            if ([del respondsToSelector:@selector(clientDidReceiveText:)]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [del clientDidReceiveText:self];
                });
            }
        }];
    }];
}

- (BOOL)mudsocketShouldAttemptSSL:(SSMUDSocket *)socket {
    return currentWorld && [currentWorld.isSecure boolValue];
}

- (void)mudsocket:(SSMUDSocket *)socket receivedMSSPData:(NSDictionary *)MSSPData {
    [self.titleView setMSSPData:MSSPData];
}

#pragma mark - default world fetching

- (void)controller:(NSFetchedResultsController *)controller
   didChangeObject:(id)anObject
       atIndexPath:(NSIndexPath *)indexPath
     forChangeType:(NSFetchedResultsChangeType)type
      newIndexPath:(NSIndexPath *)newIndexPath {

    if (type == NSFetchedResultsChangeDelete) {
        currentWorld = nil;
        defaultWorldFetcher = nil;
        [self updateWorldToolbar];
        [self.tickerManager disableTickersForIdentifier:self.tickerIdentifier];
    } else {
        if ([anObject isKindOfClass:[World class]]) {
            currentWorld = (World *)anObject;
        }

        self.hostname = currentWorld.hostname;
        self.port = currentWorld.port;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller {
    [self performSelectorOnMainThread:@selector(updateWorldToolbar)
                           withObject:nil
                        waitUntilDone:NO];
}

#pragma mark - Logging

- (void)appendTextToLog:(NSString *)cleanText {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:kPrefLogging]) {
        return;
    }

    if ([cleanText length] == 0) {
        return;
    }

    [self.logger appendText:cleanText
             toFileWithName:logFileName];
}

@end
