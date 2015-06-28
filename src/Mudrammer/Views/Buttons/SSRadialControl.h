//
//  SSRadialControl.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/24/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@protocol SSRadialDelegate;

typedef NS_ENUM(NSInteger, SSRadialControlPosition) {
    SSRadialControlPositionLeft,
    SSRadialControlPositionOff,
    SSRadialControlPositionRight,
};

@interface SSRadialControl : UIControl <UIGestureRecognizerDelegate>

@property (nonatomic, weak) id <SSRadialDelegate> delegate;

// Preferred constructor
+ (instancetype) radialControl;

// Update a radial control preference. Automatically adjusts the other radial control
// pref, if necessary, to move it to the other side.
+ (void) updateRadialPreference:(NSString *)preference toPosition:(SSRadialControlPosition)position;

// Shortcut to validate radial positions.
+ (void) validateRadialPositions;

// Return the position for the specified radial control
+ (SSRadialControlPosition) positionForRadialControl:(NSString *)preference;

// Determine if the radial or move control is enabled (not set to off)
+ (BOOL) radialControlIsEnabled:(NSString *)preference;


@end

@protocol SSRadialDelegate <NSObject>

@optional

- (BOOL) radialControlShouldStartDragging:(SSRadialControl *)control;

- (void) radialControlDidStartDragging:(SSRadialControl *)control;

- (void) radialControlDidEndDragging:(SSRadialControl *)control;

@required

- (NSUInteger) numberOfSectorsInRadialControl:(SSRadialControl *)control;

- (NSString *) centerTextForRadialControl:(SSRadialControl *)control inSector:(NSUInteger)sector;

- (void) radialControl:(SSRadialControl *)control didMoveToSector:(NSUInteger)sector;

@end
