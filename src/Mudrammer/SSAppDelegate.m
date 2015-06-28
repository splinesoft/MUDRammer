//
//  SSAppDelegate.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/21/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSAppDelegate.h"
#import "SSClientContainer.h"
#import <UserVoice.h>
#import "SSRadialControl.h"
#import "SSWorldDisplayController.h"
#import <IFTTTSplashView.h>
#import <HockeySDK.h>
#import <Keys/MudrammerKeys.h>

@interface SSAppDelegate ()
+ (void) setupCoreData;
@end

@implementation SSAppDelegate

#pragma mark - setup and scaffolding

+ (void)setupCoreData {
#ifdef __MUDRAMMER_SYNC_WORLDS_TO_ICLOUD__
    DLog(@"starting icloud");
    //[MagicalRecord setupCoreDataStackWithiCloudContainer:@"4YFMUNMLU8.com.splinesoft.theMUDRammer" localStoreNamed:@"Worlds.sqlite"];
    [MagicalRecord setupCoreDataStackWithiCloudContainer:@"4YFMUNMLU8.com.splinesoft.theMUDRammer"
                                          contentNameKey:@"com.splinesoft.theMUDRammer"
                                         localStoreNamed:@"Worlds.sqlite"
                                 cloudStorePathComponent:nil
                                              completion:^{
                                                  DLog(@"loaded cloud?");
                                              }];
#else
    [MagicalRecord setupCoreDataStackWithAutoMigratingSqliteStoreNamed:kStoreName];
#endif
}

#pragma mark - URL tapped

- (BOOL)application:(UIApplication *)application
            openURL:(NSURL *)url
  sourceApplication:(NSString *)sourceApplication
         annotation:(id)annotation {

    if (!url || ![url host]) {
        return NO;
    }

    if ([[url scheme] isEqualToString:@"telnet"]) {

        // Is this world already saved?
        World *existing = [World MR_findFirstWithPredicate:[NSPredicate predicateWithFormat:@"hostname == %@ AND isHidden == NO",
                                                            [[url host] lowercaseString]]
                                                  sortedBy:[World defaultSortField]
                                                 ascending:[World defaultSortAscending]
                                                 inContext:[NSManagedObjectContext MR_defaultContext]];

        if( !existing ) {
            World *w = [World worldFromURL:url];
            w.isHidden = @NO;
            [w saveObjectWithCompletion:^{
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWorldChanged
                                                                    object:[w objectID]];
            }
                                   fail:nil];
        } else
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationWorldChanged
                                                                object:[existing objectID]];

        return YES;
    }

    return NO;
}

#pragma mark - SSApplication

- (void) ss_willFinishLaunchingWithOptions:(NSDictionary *)options {
    [[IFTTTSplashView sharedSplash] showSplash];

#ifdef DEBUG
//    [[BITHockeyManager sharedHockeyManager] setDebugLogEnabled:YES];
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelAll];
#else
    [MagicalRecord setLoggingLevel:MagicalRecordLoggingLevelOff];
#endif

    [[BITHockeyManager sharedHockeyManager].authenticator setIdentificationType:BITAuthenticatorIdentificationTypeAnonymous];

    [[BITHockeyManager sharedHockeyManager].crashManager setCrashManagerStatus:BITCrashManagerStatusAutoSend];

    MudrammerKeys *keys = [MudrammerKeys new];

    [ARAnalytics setupWithAnalytics:@{
          ARHockeyAppBetaID   : keys.hOCKEYBETA_KEY,
          ARHockeyAppLiveID   : keys.hOCKEYLIVE_KEY,
    }];

    // Disable shake to undo
    [UIApplication sharedApplication].applicationSupportsShakeToEdit = NO;

    // core data
    [self.class setupCoreData];

    // nonblocking
    [World createDefaultWorldsIfNecessary];

    // themes/settings
    [[SSThemes sharedThemer] applyAppThemes];

    // uservoice
    UVConfig *uvconfig = [UVConfig configWithSite:keys.uSERVOICE_FORUM_SITE];
    uvconfig.forumId = keys.uSERVOICE_FORUM_ID.integerValue;
    uvconfig.customFields = @{
        @"Version" : [NSString stringWithFormat:@"%@ (%@)",
                      [UIApplication applicationVersion],
                      [UIApplication applicationBuild]],
    };
    [UserVoice initialize:uvconfig];

    self.idleTimerDisabled = YES;

    // disallow webview cache
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];

    _notificationObserver = [SPLNotificationManager new];
}

- (void) ss_willLaunchBackgroundSetup {

}

- (UIViewController *) ss_appRootViewController {
    return [SSClientContainer new];
}

#pragma mark - Application events

- (void) ss_receivedApplicationEvent:(SSApplicationEvent)eventType {

    switch (eventType) {
        case SSApplicationEventDidBecomeActive:

            [[UIApplication sharedApplication] cancelAllLocalNotifications];

            // Validate radial prefs
            [SSRadialControl validateRadialPositions];

            break;

        case SSApplicationEventWillEnterForeground:

            break;

        case SSApplicationEventDidEnterBackground:
        case SSApplicationEventWillResignActive:

            break;

        case SSApplicationEventWillTerminate:

            [[UIApplication sharedApplication] cancelAllLocalNotifications];

            [MagicalRecord cleanUp];

            break;

        default:
            break;
    }
}

#pragma mark - Notifications

- (void)application:(UIApplication *)application
didRegisterUserNotificationSettings:(UIUserNotificationSettings *)notificationSettings {
    [self.notificationObserver didRegisterUserNotificationSettings:notificationSettings];
}

- (void)application:(UIApplication *)application
handleActionWithIdentifier:(NSString *)identifier
forLocalNotification:(UILocalNotification *)notification
  completionHandler:(void (^)())completionHandler {
    [self.notificationObserver handleActionWithIdentifier:identifier
                                     forLocalNotification:notification
                                               completion:completionHandler];
}

- (void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification {
    // running app received a local notification
    DLog(@"Received local %@", notification);
}

#pragma mark - user defaults

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

@end
