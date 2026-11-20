//
//  SSAppDelegate.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/21/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSAppDelegate.h"
#import "SSClientContainer.h"
#import "SSRadialControl.h"
#import "SSWorldDisplayController.h"

@interface SSAppDelegate ()
@property (nonatomic, weak, readwrite) UIWindow *mainWindow;

+ (void)setupCoreData;
- (void)handleURL:(NSURL *)url;
- (void)handleSceneActivation;
@end

@interface SSSceneDelegate : UIResponder <UIWindowSceneDelegate>
@property (nonatomic, strong) UIWindow *window;
@end

@implementation SSAppDelegate

+ (instancetype)sharedDelegate {
    return (SSAppDelegate *)[UIApplication sharedApplication].delegate;
}

#pragma mark - setup and scaffolding

+ (void)setupCoreData {
#ifdef DEBUG
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelAll];
#else
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelOff];
#endif
    [MagicalRecord setShouldDeleteStoreOnModelMismatch:NO];
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:kStoreName];
}

#pragma mark - URL tapped

- (void)handleURL:(NSURL *)url {
    if (url.host.length > 0 && [url.scheme isEqualToString:@"telnet"]) {
        // Is this world already saved?
        World *existing = [World MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"hostname == %@ AND isHidden == NO",
                                                            [[url host] lowercaseString]]
                                                  sortedBy:[World defaultSortField]
                                                 ascending:[World defaultSortAscending]
                                                 inContext:[NSManagedObjectContext MR_defaultContext]];

        if (!existing) {
            World *w = [World worldFromURL:url];
            w.isHidden = @NO;
            [w saveObjectWithCompletion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWorldChanged
                                                                    object:[w objectID]];
            }
                                   fail:nil];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWorldChanged
                                                                object:[existing objectID]];
        }
    }
}

#pragma mark - Application lifecycle

- (BOOL)application:(UIApplication *)application willFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[NSUserDefaults standardUserDefaults] registerDefaults:[self ss_defaultUserDefaults]];
    [self.class setupCoreData];

    [World createDefaultWorldsIfNecessary];

    [SSThemes sharedThemer]; // UIAppearance™ Inside®

    application.idleTimerDisabled = YES;
    application.applicationSupportsShakeToEdit = NO;

    // disallow webview cache
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];

    _notificationObserver = [SPLNotificationManager new];
    return YES;
}

- (UIViewController *)makeRootViewController {
    return [SSClientContainer new];
}

- (NSDictionary *) ss_defaultUserDefaults {
    return @{
             kPrefInitialWorldsCreated  : @NO,
             kPrefLocalEcho             : @YES,
             kPrefAutocorrect           : @NO,
             kPrefMoveControl           : @(SSRadialControlPositionRight),
             kPrefConnectOnStartup      : @YES,
             kPrefStringEncoding        : @"ASCII",
             kPrefKeyboardStyle         : @YES,
             kPrefRadialControl         : @(SSRadialControlPositionLeft),
             kPrefRadialCommands        : @[ @"up", @"in", @"down", @"out", @"look" ],
             kPrefTopBarAlwaysVisible   : @NO,
             kPrefAutocapitalization    : @NO,
             kPrefBTKeyboard            : @NO,
             kPrefSemicolonCommands     : @YES,
             kPrefSemicolonCommandDelimiter : kPrefSemicolonDefaultDelimiter,
    };
}

- (void)handleSceneActivation {
    [self.notificationObserver cancelTimeoutNotification];
    [SSRadialControl validateRadialPositions];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self.notificationObserver cancelTimeoutNotification];
    [MagicalRecord cleanUp];
}

@end

@implementation SSSceneDelegate

- (void)scene:(UIScene *)scene
    willConnectToSession:(UISceneSession *)session
                 options:(UISceneConnectionOptions *)connectionOptions {
    if (![scene isKindOfClass:[UIWindowScene class]]) {
        return;
    }

    SSAppDelegate *appDelegate = [SSAppDelegate sharedDelegate];
    self.window = [[UIWindow alloc] initWithWindowScene:(UIWindowScene *)scene];
    self.window.backgroundColor = [UIColor blackColor];
    appDelegate.mainWindow = self.window;
    self.window.rootViewController = [appDelegate makeRootViewController];
    [self.window makeKeyAndVisible];

    [self scene:scene openURLContexts:connectionOptions.URLContexts];
}

- (void)scene:(UIScene *)scene openURLContexts:(NSSet<UIOpenURLContext *> *)URLContexts {
    SSAppDelegate *appDelegate = [SSAppDelegate sharedDelegate];
    for (UIOpenURLContext *context in URLContexts) {
        [appDelegate handleURL:context.URL];
    }
}

- (void)sceneDidBecomeActive:(UIScene *)scene {
    [[SSAppDelegate sharedDelegate] handleSceneActivation];
}

@end
