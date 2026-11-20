//
//  SPLHandoffWebViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/21/15.
//  Copyright (c) 2015 splinesoft LLC. All rights reserved.
//

#import "SPLHandoffWebViewController.h"
#import <WebKit/WebKit.h>

@interface SPLHandoffWebViewController () <WKNavigationDelegate>
@property (nonatomic, strong) NSURL *initialURL;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSUserActivity *webActivity;
@end

@implementation SPLHandoffWebViewController

- (instancetype)initWithURL:(NSURL *)url {
    if ((self = [super initWithNibName:nil bundle:nil])) {
        _initialURL = url;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor systemBackgroundColor];
    self.webView = [[WKWebView alloc] initWithFrame:CGRectZero];
    self.webView.navigationDelegate = self;
    self.webView.allowsBackForwardNavigationGestures = YES;
    self.webView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.webView];
    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.webView.topAnchor constraintEqualToAnchor:safeArea.topAnchor],
        [self.webView.bottomAnchor constraintEqualToAnchor:safeArea.bottomAnchor],
        [self.webView.leadingAnchor constraintEqualToAnchor:safeArea.leadingAnchor],
        [self.webView.trailingAnchor constraintEqualToAnchor:safeArea.trailingAnchor],
    ]];
    self.navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction
                                                    target:self action:@selector(sharePage:)],
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh
                                                    target:self action:@selector(reloadPage:)],
    ];
    [self.webView loadRequest:[NSURLRequest requestWithURL:self.initialURL]];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self updateWebActivity];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.webActivity invalidate];
    self.webActivity = nil;
}

- (void)updateWebActivity {
    NSURL *url = self.webView.URL;
    if (!url || !self.view.window) return;
    if (!self.webActivity) {
        self.webActivity = [[NSUserActivity alloc] initWithActivityType:NSUserActivityTypeBrowsingWeb];
    }
    self.webActivity.webpageURL = url;
    self.webActivity.title = self.webView.title;
    [self.webActivity becomeCurrent];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    self.title = webView.title;
    [self updateWebActivity];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (error.code == NSURLErrorCancelled || !self.view.window || self.presentedViewController) return;
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"Unable to Load Page", nil)
                                                                  message:error.localizedDescription
                                                           preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK", nil)
                                            style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)action
 decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSURL *url = action.request.URL;
    NSString *scheme = url.scheme.lowercaseString;
    if ([@[@"http", @"https", @"about"] containsObject:scheme]) {
        decisionHandler(WKNavigationActionPolicyAllow);
        if (!action.targetFrame) [webView loadRequest:action.request];
    } else {
        decisionHandler(WKNavigationActionPolicyCancel);
        if ([scheme isEqualToString:@"telnet"]) {
            [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
        } else if ([scheme isEqualToString:@"mailto"]) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationURLTapped object:url];
        }
    }
}

- (void)reloadPage:(id)sender {
    [self.webView reload];
}

- (void)sharePage:(UIBarButtonItem *)sender {
    NSURL *url = self.webView.URL ?: self.initialURL;
    if (!url) return;
    UIActivityViewController *share = [[UIActivityViewController alloc] initWithActivityItems:@[url]
                                                                    applicationActivities:nil];
    share.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:share animated:YES completion:nil];
}

@end
