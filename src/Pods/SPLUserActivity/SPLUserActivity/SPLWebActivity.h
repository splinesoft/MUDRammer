//
//  SPLWebActivity.h
//  SPLUserActivity
//
//  Created by Jonathan Hersh on 3/1/15.
//  Copyright (c) 2015 Splinesoft. All rights reserved.
//

#import "SPLUserActivity.h"
@import UIKit;
@import WebKit;

@interface SPLWebActivity : SPLUserActivity

/**
 *  Create an activity that can continue a web browsing session on another
 *  device. The activity is populated with the current URL and page title from the
 *  @c WKWebview specified.
 *
 *  The activity uses KVO on the @c WKWebView to automatically update its 
 *  URL and document title as the webview navigates between pages.
 *
 *  @param webView the webview to use for this activity
 *
 *  @return an initialized activity
 */
+ (instancetype) activityWithWKWebView:(WKWebView *)webView;

/**
 *  Create an activity that can continue a web browsing session on another
 *  device. The activity is populated with the current URL and page title from the
 *  @c UIWebview specified.
 *
 *  You must notify the activity using @c setNeedsUpdate when the UIWebView
 *  navigates to a new page.
 *
 *  @param webView the webview to use for this activity
 *
 *  @return an initialized activity
 */
+ (instancetype) activityWithUIWebView:(UIWebView *)webView;

/**
 *  Create an activity that can start browsing a URL on another device.
 *
 *  @param url the URL to broadcast with Handoff
 *
 *  @return an initialized activity
 */
+ (instancetype) activityWithURL:(NSURL *)url;

@end
