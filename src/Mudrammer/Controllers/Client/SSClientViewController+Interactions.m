//
//  SSClientViewController+Interactions.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 12/20/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SSClientViewController+Interactions.h"
#import "SSMudView.h"
#import "SSMUDSocket.h"
#import <BlocksKit.h>
#import "SSClientContainer.h"
#import "SSWorldDisplayController.h"
#import "SSMUDToolbar.h"

@implementation SSClientViewController (Interactions)

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    DLog(@"URL %@ %@", url, url.absoluteString);

    NSString *urlString = [[url absoluteString] lowercaseString];

    if ([@[ @"gif", @"png", @"jpg", @"jpeg", @"tiff" ] bk_any:^BOOL(NSString *extension) {
        return [urlString hasSuffix:extension];
    }]) {

        JTSImageInfo *info = [JTSImageInfo new];
        info.imageURL = url;

        JTSImageViewController *imageViewController = [[JTSImageViewController alloc] initWithImageInfo:info
                                                                                                   mode:JTSImageViewControllerMode_Image
                                                                                        backgroundStyle:JTSImageViewControllerBackgroundOption_Blurred];

        imageViewController.interactionsDelegate = self;
        imageViewController.optionsDelegate = self;

        [imageViewController showFromViewController:self
                                         transition:JTSImageViewControllerTransition_FromOffscreen];

        return;
    }

    if ([@[ @"http", @"https", @"mailto" ] containsObject:[url scheme]]) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationURLTapped
                                                            object:url];
    }
}

#pragma mark - JTSImageViewControllerInteractionsDelegate

- (BOOL)imageViewerAllowCopyToPasteboard:(JTSImageViewController *)imageViewer {
    return YES;
}

#pragma mark - JTSImageViewControllerOptionsDelegate

- (CGFloat)backgroundBlurRadiusForImageViewer:(JTSImageViewController *)imageViewer {
    return 5.f;
}

#pragma mark - SSConnectButtonDelegate

- (void)connectButton:(SSConnectButton *)button didChangeState:(BOOL)connected {
    if ([self isConnected]) {
        [self.socket.socket disconnect];
    } else {
        [self connect];
    }
}

#pragma mark - UVDelegate (UserVoice)

- (void)userVoiceWasDismissed {
    [UserVoice setDelegate:nil];

    if (![[UIDevice currentDevice] isIPad]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent
                                                        animated:YES];
        });
    }
}

#pragma mark - UIKeyCommand

- (void)keyCommandCycleActiveConnections:(UIKeyCommand *)sender {
    [[SSClientContainer worldDisplayDrawer] selectNextWorld];
    SSClientViewController *newClient = [[SSClientContainer worldDisplayDrawer] currentVisibleClient];
    [newClient.mudView.inputToolbar.textView becomeFirstResponder];
}

- (void)keyCommandSwitchToActiveConnection:(UIKeyCommand *)sender {
    NSInteger desiredIndex = sender.input.integerValue - 1;

    if (desiredIndex >= 0 && desiredIndex < [[SSClientContainer worldDisplayDrawer] numberOfClients]) {
        [[SSClientContainer worldDisplayDrawer] setSelectedIndex:desiredIndex];

        SSClientViewController *newClient = [[SSClientContainer worldDisplayDrawer] currentVisibleClient];
        [newClient.mudView.inputToolbar.textView becomeFirstResponder];
    }
}

@end
