# SPLUserActivity

[![Circle CI](https://circleci.com/gh/splinesoft/SPLUserActivity.svg?style=svg&circle-token=d7b0f2b0e1b33492be0a6cee7eb94c6e904ebe17)](https://circleci.com/gh/splinesoft/SPLUserActivity) [![Coverage Status](https://coveralls.io/repos/splinesoft/SPLUserActivity/badge.svg)](https://coveralls.io/r/splinesoft/SPLUserActivity)

[Handoff](https://developer.apple.com/library/prerelease/ios/documentation/UserExperience/Conceptual/Handoff/AdoptingHandoff/AdoptingHandoff.html) is a powerful new feature in iOS 8 and OS X 10.10 that allows a user to begin an activity on one device and continue it on another device signed into the same iCloud account.

`SPLUserActivity` is a collection of objects that make it easy to adopt Handoff for different types of activities.

`SPLUserActivity` powers Handoff for the web browser in my app [MUDRammer - A Modern MUD Client for iPhone and iPad](https://itunes.apple.com/us/app/mudrammer-a-modern-mud-client/id597157072?mt=8).

## `SPLWebActivity`

`SPLWebActivity` powers a Handoff activity for web browsing. It allows a user to continue browsing from the same web page on another device.

### Examples

Check out `Example` for a simple app that displays a `WKWebView` and broadcasts a Handoff activity as the user browses between web pages. Note that Handoff won't function in the simulator - you'll need to run it on a device.

### `WKWebView`

If your app uses a `WKWebView`, initialize a `SPLWebActivity` by passing your webview:

```objc
WKWebView *myWebView = ...

SPLWebActivity *webActivity = [SPLWebActivity activityWithWKWebView:myWebView];
```

That's it -- you're done! `SPLWebActivity` will start broadcasting a Handoff event right away. Thanks to the magic of KVO, `SPLWebActivity` will observe your `WKWebView` and will automatically update its activity URL and page title as the user navigates between web pages.

### `UIWebView`

If your app uses a `UIWebView`, initialize a `SPLWebActivity` by passing your webview:

```objc
UIWebView *myWebView = ...

self.webActivity = [SPLWebActivity activityWithUIWebView:myWebView];
```

As with `WKWebView`, `SPLWebActivity` will begin broadcasting a Handoff event right away. However, `UIWebView` does not conform to KVO, so you'll need to tell `SPLWebActivity` to update itself as the user navigates between web pages:

```objc
#pragma mark - UIWebViewDelegate

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [self.webActivity setNeedsUpdate];
}
```

After receiving a `setNeedsUpdate` message, `SPLWebActivity` will query your `UIWebView` for the user's current URL and update its Handoff activity.

### URLs

`SPLWebActivity` also allows your user to browse any URL on another device -- no webview required.

```objc
SPLWebActivity *myActivity = [SPLWebActivity activityWithURL:[NSURL URLWithString:@"http://splinesoft.net"]];
```

## Continue Events

You may optionally specify a block that will be called when the user continues an activity on another device.

```objc
myActivity.activityContinuedBlock = ^{
	NSLog(@"I've just continued an activity!");
};
```

## Cleanup

When your user activity is no longer relevant -- perhaps when your webview is popped off the navigation stack, or when the activity is no longer available -- make sure to invalidate the activity.

```objc
[myActivity invalidate];
```

An invalidated activity can no longer `becomeCurrent` and cannot be reused. If you'd like to broadcast a Handoff event again, create a new instance of `SPLWebActivity`.

## Install

Install with [CocoaPods](http://cocoapods.org). Add to your `Podfile`:

```
pod 'SPLUserActivity'
```

## Thanks!

`SPLUserActivity` is a [@jhersh](https://github.com/jhersh) production -- ([electronic mail](mailto:jon@her.sh) | [@jhersh](https://twitter.com/jhersh))