//
//  SPLWebActivity.m
//  SPLWebActivity
//
//  Created by Jonathan Hersh on 3/1/15.
//  Copyright (c) 2015 Splinesoft. All rights reserved.
//

#import "SPLWebActivity.h"

static char SPLWebActivityContext;

@interface SPLWebActivity ()

@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, weak) WKWebView *webKitWebView;

@end

@implementation SPLWebActivity

+ (instancetype)activityWithUIWebView:(UIWebView *)webView {
    NSParameterAssert(webView);
    
    SPLWebActivity *activity = [[self alloc] initWithType:NSUserActivityTypeBrowsingWeb];
    activity.userActivity.webpageURL = webView.request.URL;
    activity.userActivity.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    activity.webView = webView;
    
    [activity.userActivity becomeCurrent];

    return activity;
}

+ (instancetype)activityWithWKWebView:(WKWebView *)webView {
    NSParameterAssert(webView);
    
    SPLWebActivity *activity = [[self alloc] initWithType:NSUserActivityTypeBrowsingWeb];
    activity.webKitWebView = webView;
    
    [webView addObserver:activity
              forKeyPath:NSStringFromSelector(@selector(URL))
                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                 context:&SPLWebActivityContext];
    
    [webView addObserver:activity
              forKeyPath:NSStringFromSelector(@selector(title))
                 options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew
                 context:&SPLWebActivityContext];
    
    [activity.userActivity becomeCurrent];
    
    return activity;
}

+ (instancetype)activityWithURL:(NSURL *)url {
    NSParameterAssert(url);
    
    SPLWebActivity *activity = [[self alloc] initWithType:NSUserActivityTypeBrowsingWeb];
    activity.userActivity.webpageURL = url;
    
    [activity.userActivity becomeCurrent];
    
    return activity;
}

#pragma mark - Lifecycle

- (void)invalidate {
    [super invalidate];
    
    [self.webKitWebView removeObserver:self
                            forKeyPath:NSStringFromSelector(@selector(URL))
                               context:&SPLWebActivityContext];
    [self.webKitWebView removeObserver:self
                            forKeyPath:NSStringFromSelector(@selector(title))
                               context:&SPLWebActivityContext];
}

#pragma mark - NSUserActivityDelegate

- (void)userActivityWillSave:(NSUserActivity *)userActivity {
    [super userActivityWillSave:userActivity];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.webKitWebView) {
            self.userActivity.webpageURL = self.webKitWebView.URL;
            self.userActivity.title = self.webKitWebView.title;
        }
        
        if (self.webView) {
            self.userActivity.webpageURL = self.webView.request.URL;
            self.userActivity.title = [self.webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        }
    });
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == &SPLWebActivityContext) {
        id newValue = change[NSKeyValueChangeNewKey];
        
        if (!newValue || [newValue isEqual:[NSNull null]]) {
            return;
        }
        
        if ([keyPath isEqualToString:NSStringFromSelector(@selector(URL))]) {
            self.userActivity.webpageURL = newValue;
        } else if ([keyPath isEqualToString:NSStringFromSelector(@selector(title))]) {
            self.userActivity.title = newValue;
        }
        
        [self setNeedsUpdate];
    } else {
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

@end
