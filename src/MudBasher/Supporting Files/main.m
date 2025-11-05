//
//  main.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/21/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;

#import "SPLTestAppDelegate.h"
#import "SSAppDelegate.h"

int main(int argc, char *argv[])
{
    @autoreleasepool {

        BOOL isTesting = NSClassFromString(@"XCTestCase") != nil;
        Class appDelegateClass = (isTesting
                                  ? [SPLTestAppDelegate class]
                                  : [SSAppDelegate class]);

        return UIApplicationMain(argc, argv,
                                 NSStringFromClass(appDelegateClass),
                                 NSStringFromClass(appDelegateClass));
    }
}
