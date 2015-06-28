//
//  SPLUserActivity.h
//  SPLUserActivity
//
//  Created by Jonathan Hersh on 3/1/15.
//  Copyright (c) 2015 Splinesoft. All rights reserved.
//

@import Foundation;

/**
 *  An abstract superclass that manages a user activity for Handoff.
 *  Don't use this class directly except to subclass - instead, see
 *  @c SPLWebActivity.
 */
@interface SPLUserActivity : NSObject <NSUserActivityDelegate>

/**
 *  Initialize a user activity with the specified type.
 *
 *  @param type type of the @c NSUserActivity
 *
 *  @return an initialized activity
 */
- (instancetype)initWithType:(NSString *)type;

/**
 *  The user activity managed by this object.
 */
@property (nonatomic, strong, readonly) NSUserActivity *userActivity;

/**
 *  Optional block called when the user activity is continued on another device.
 */
@property (nonatomic, copy) dispatch_block_t activityContinuedBlock;

/**
 *  Invalidate the activity when it is no longer relevant or needed.
 *  Once invalidated, the activity cannot be reused nor made current.
 */
- (void) invalidate;

/**
 *  Mark the activity as needing to be updated from your `UIWebView` or another 
 *  activity source.
 */
- (void) setNeedsUpdate;

@end
