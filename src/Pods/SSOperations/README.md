SSOperations
=============

[![Circle CI](https://circleci.com/gh/splinesoft/SSOperations.svg?style=svg&circle-token=d07be6d02465871a05a2d5ca5fa38cb5137c1838)](https://circleci.com/gh/splinesoft/SSOperations) [![Coverage Status](https://coveralls.io/repos/splinesoft/SSOperations/badge.svg)](https://coveralls.io/r/splinesoft/SSOperations)

Handy `NSOperationQueue` and `NSBlockOperation` helpers.

`SSOperations` powers various operations in my app [MUDRammer - a modern MUD client for iPhone and iPad](https://itunes.apple.com/us/app/mudrammer-a-modern-mud-client/id597157072?mt=8).

## Install

Install with [CocoaPods](http://cocoapods.org). Add to your `Podfile`:

```
pod 'SSOperations', :head # YOLO
```

## SSBlockOperation & SSBlockOperationBlock

A simple subclass of `NSBlockOperation` that is passed itself as input when executed.

The primary advantage is that you can inspect, at run-time, whether the operation has been canceled and if so, clean up and exit appropriately.

```objc
SSBlockOperationBlock anOperationBlock = ^(SSBlockOperation *operation) {
	if( [operation isCancelled] )
		return;
		
	// Do some stuff…
	
	if( [operation isCancelled] )
		return;
	
	// Do some more stuff...
};

// Submit this operation to a queue for execution.
[myOperationQueue ss_addBlockOperationWithBlock:anOperationBlock];
```

## NSOperationQueue+SSAdditions.h

A handy way to create an `NSOperationQueue` and submit `SSBlockOperationBlock`s for execution.

```objc
// An operation queue that runs operations serially.
NSOperationQueue *serialQueue = [NSOperationQueue ss_serialOperationQueue];

// An operation queue that runs up to 3 operations concurrently.
NSOperationQueue *threeOperationQueue = [NSOperationQueue ss_concurrentQueueWithConcurrentOperations:3

// An operation queue that runs as many concurrent operations as the system deems appropriate.
// It has a name!
NSOperationQueue *concurrentQueue = [NSOperationQueue ss_concurrentMaxOperationQueueNamed:@"My queue"];

// Submit an `SSBlockOperationBlock` for processing.
[anOperationQueue ss_addBlockOperationWithBlock:anOperationBlock];
```

## Thanks!

`SSOperations` is a [@jhersh](https://github.com/jhersh) production -- ([electronic mail](mailto:jon@her.sh) | [@jhersh](https://twitter.com/jhersh))
