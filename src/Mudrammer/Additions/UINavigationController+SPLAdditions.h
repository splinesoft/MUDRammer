//
//  UINavigationController+SPLAdditions.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/22/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

@import UIKit;
@import SafariServices;

@class SPLHandoffWebViewController;

@interface UINavigationController (SPLAdditions) <SFSafariViewControllerDelegate>

@property (nonatomic, readonly) BOOL SPLNavigationIsAtRoot;

// Create and push onto the navigation stack a web view controller
// for the specified URL.
- (UIViewController *) SPLPresentWebViewControllerForURL:(NSURL *)url;

@end
