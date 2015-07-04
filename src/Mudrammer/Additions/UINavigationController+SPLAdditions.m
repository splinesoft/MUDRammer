//
//  UINavigationController+SPLAdditions.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/22/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "UINavigationController+SPLAdditions.h"
#import "SPLHandoffWebViewController.h"

@implementation UINavigationController (SPLAdditions)

- (BOOL)SPLNavigationIsAtRoot {
    return [self viewControllers].count > 0
        && [[self visibleViewController] isEqual:[self viewControllers].firstObject];
}

- (UIViewController *)SPLPresentWebViewControllerForURL:(NSURL *)url {
    if ([SFSafariViewController class]) {
        SFSafariViewController *safariVC = [[SFSafariViewController alloc] initWithURL:url];
        safariVC.delegate = self;
        [self presentViewController:safariVC animated:YES completion:^{
            [[SSAppDelegate sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
        }];
        return safariVC;
    }
    
    SPLHandoffWebViewController *handoffWebView = [[SPLHandoffWebViewController alloc] initWithURL:url];
    [self pushViewController:handoffWebView animated:YES];
    return handoffWebView;
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(nonnull SFSafariViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:^{
        [[SSAppDelegate sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    }];
}

@end
