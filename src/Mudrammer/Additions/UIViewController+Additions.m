//
//  UIViewController+Additions.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/22/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "UIViewController+Additions.h"

@implementation UIViewController (Additions)

- (BOOL)shouldAutorotate {
    return YES;
}

- (NSUInteger)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAll;
}

- (BOOL)isViewVisible {
    return [self isViewLoaded] && self.view.window;
}

#pragma mark -

- (UINavigationController *) wrappedNavigationController {
    return [[UINavigationController alloc] initWithRootViewController:self];
}

@end
