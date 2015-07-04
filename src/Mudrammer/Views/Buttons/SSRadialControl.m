//
//  SSRadialControl.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/24/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSRadialControl.h"
#import <Masonry.h>
#import <TTTAttributedLabel.h>

static CGFloat const kControlRadius = 60.0f;
static CGSize const kControlSize = (CGSize) { 80, 80 };

// Minimum drag distance to trigger an update
#define kMinRadius       SPLFloat_floor( kControlRadius / 2.0f )

static CGFloat const kAlphaActive = 1.0f;
static CGFloat const kAlphaInactive = 0.2f;
static CGFloat const kFadeDuration = 0.15f;

@interface SSRadialControl ()

@property (nonatomic, strong) TTTAttributedLabel *directionLabel;

- (void) keyboardWillShowOrHide:(NSNotification *)note;

- (void) didPan:(UIPanGestureRecognizer *)panner;
- (void) didTap:(UITapGestureRecognizer *)tapper;

CGFloat DistanceBetweenPoints(CGPoint point, CGPoint point2);
NSInteger PointsToDegree( CGPoint a, CGPoint b, CGPoint c );

@end

@implementation SSRadialControl
{
    UIImageView *grabber;
    UIImageView *background;

    UIPanGestureRecognizer *panner;
    UITapGestureRecognizer *tapper;
    BOOL isPanning;
}

- (instancetype) initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [UIColor clearColor];

        // background
        UIImage *bgImg = [SPLImagesCatalog gesturePannerBGImage];
        background = [[UIImageView alloc] initWithImage:bgImg];
        background.alpha = 0.0f;
        background.center = self.center;
        [self addSubview:background];

        // grabber
        grabber = [[UIImageView alloc] initWithImage:[SPLImagesCatalog gesturePannerImage]];
        grabber.center = self.center;
        grabber.alpha = 0.0f;
        [self insertSubview:grabber aboveSubview:background];

        // label
        _directionLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
        _directionLabel.center = background.center;
        _directionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30];
        _directionLabel.backgroundColor = [UIColor clearColor];
        _directionLabel.alpha = 0.0f;
        _directionLabel.textColor = [UIColor darkGrayColor];
        _directionLabel.textAlignment = NSTextAlignmentCenter;
        _directionLabel.adjustsFontSizeToFitWidth = YES;
        _directionLabel.minimumScaleFactor = 0.5f;
        _directionLabel.numberOfLines = 1;
        _directionLabel.kern = 0.0;
        _directionLabel.lineBreakMode = NSLineBreakByClipping;
        _directionLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
        [self insertSubview:_directionLabel aboveSubview:background];
        [_directionLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.equalTo(@(kControlSize.width - 28));
            make.height.equalTo(@34);
            make.centerX.equalTo(self);
            make.centerY.equalTo(self).offset(-1);
        }];

        // panning
        panner = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                         action:@selector(didPan:)];
        panner.delegate = self;

        [self addGestureRecognizer:panner];

        // tapping
        tapper = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                         action:@selector(didTap:)];
        tapper.delegate = self;
        tapper.numberOfTapsRequired = 1;
        tapper.delaysTouchesBegan = NO;
        tapper.delaysTouchesEnded = NO;
        [self addGestureRecognizer:tapper];

        // dynamics
        [self addCenteredInterpolatingMotionEffectWithBounds:6];

        // Cancel gestures when keyboard shows or hides
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShowOrHide:)
                                                     name:UIKeyboardWillShowNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShowOrHide:)
                                                     name:UIKeyboardWillHideNotification
                                                   object:nil];
    }

    return self;
}

+ (instancetype)radialControl {
    return [[self alloc] initWithFrame:CGRectMake(0, 0, kControlSize.width, kControlSize.height)];
}

- (void)dealloc {
    panner.delegate = nil;
    tapper.delegate = nil;
    _delegate = nil;
    [self removeGestureRecognizer:panner];
    [self removeGestureRecognizer:tapper];

    [self removeAllMotionEffects];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Radial prefs

+ (void)validateRadialPositions {
    [self updateRadialPreference:kPrefMoveControl
                      toPosition:[self positionForRadialControl:kPrefMoveControl]];
}

+ (void)updateRadialPreference:(NSString *)preference toPosition:(SSRadialControlPosition)position {

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [defaults setObject:@(position) forKey:preference];

    // Move the other one, if necessary
    NSString *otherPref = ([preference isEqualToString:kPrefMoveControl]
                           ? kPrefRadialControl
                           : kPrefMoveControl);

    SSRadialControlPosition otherPosition = [self positionForRadialControl:otherPref];

    if (otherPosition != SSRadialControlPositionOff && otherPosition == position) {
        [defaults setObject:@((position == SSRadialControlPositionLeft
                               ? SSRadialControlPositionRight
                               : SSRadialControlPositionLeft))
                     forKey:otherPref];
    }
}

+ (SSRadialControlPosition)positionForRadialControl:(NSString *)preference {
    return (SSRadialControlPosition)[[NSUserDefaults standardUserDefaults] integerForKey:preference];
}

+ (BOOL)radialControlIsEnabled:(NSString *)preference {
    return [self positionForRadialControl:preference] != SSRadialControlPositionOff;
}

#pragma mark - distances

CGFloat DistanceBetweenPoints(CGPoint point, CGPoint point2) {
    if( CGPointEqualToPoint( point, point2 ) )
        return 0;

    CGFloat xDist = point.x - point2.x;
    CGFloat yDist = point.y - point2.y;

    return (CGFloat)sqrt( ( xDist * xDist ) + ( yDist * yDist ) );
}

// assuming b is center, and a is {0, -radius}
NSInteger PointsToDegree( CGPoint a, CGPoint b, CGPoint c )
{
    CGPoint ab = (CGPoint){ b.x - a.x, b.y - a.y };
    CGPoint cb = (CGPoint){ b.x - c.x, b.y - c.y };

    CGFloat dot = (ab.x * cb.x + ab.y * cb.y); // dot product
    CGFloat cross = (ab.x * cb.y - ab.y * cb.x); // cross product

    CGFloat alpha = (CGFloat)atan2(cross, dot);

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbad-function-cast"
    return (NSInteger) SPLFloat_floor(alpha * 180. / M_PI + 0.5);
#pragma clang diagnostic pop
}

- (NSUInteger) currentSector {
    if (CGPointEqualToPoint(background.center, grabber.center)) {
        return 0;
    }

    id del = self.delegate;

    NSUInteger sectors = ([del respondsToSelector:@selector(numberOfSectorsInRadialControl:)]
                          ? [del numberOfSectorsInRadialControl:self]
                          : 1);

    if (sectors <= 1) {
        return 0;
    }

    CGFloat dist = DistanceBetweenPoints(background.center, grabber.center);

    if (dist < kMinRadius) {
        return 0;
    }

    NSInteger deg = PointsToDegree((CGPoint){ 0, kControlRadius }, background.center, grabber.center);

    // -180 to 180, 0 at W

    deg = (deg + 240) % 360;

    // 0 to 360, 0 at N !

    CGFloat sectorWidth = 360.0f / sectors,
            halfSector  = sectorWidth / 2.0f;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbad-function-cast"
    deg = (deg + (NSInteger)SPLFloat_floor(halfSector)) % 360;

    return (NSUInteger) SPLFloat_floor( deg / sectorWidth );
#pragma clang diagnostic pop
}

#pragma mark - enabling

- (void)setEnabled:(BOOL)enabled {
    if (self.enabled == enabled) {
        return;
    }

    [super setEnabled:enabled];

    if (self.superview) {
        [UIView animateWithDuration:kFadeDuration
                         animations:^{
                             if( enabled )
                                 grabber.alpha = kAlphaInactive;
                             else
                                 grabber.alpha = 0.0f;
                         }];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if( !self.enabled )
        return NO;

    CGPoint point = [gestureRecognizer locationInView:self.superview];

    CGFloat distance = DistanceBetweenPoints(self.center, point);

    BOOL isNearby = ( distance <= 45.0f );

    id del = self.delegate;

    if( [del respondsToSelector:@selector(radialControlShouldStartDragging:)]
        && ![del radialControlShouldStartDragging:self] )
        return NO;

    return isNearby;
}

#pragma mark - tapping

- (void)didTap:(UITapGestureRecognizer *)tapper {
    [UIView animateWithDuration:kFadeDuration
                     animations:^{
                         CGPoint newCenter = CGPointMake( grabber.center.x + ( arc4random() % 60 ) - 30,
                                                         grabber.center.y + ( arc4random() % 60 ) - 30 );

                         grabber.center = newCenter;
                         grabber.alpha = kAlphaActive;
                     } completion:^(BOOL finished) {
                         if( !isPanning )
                             [UIView animateWithDuration:kFadeDuration
                                              animations:^{
                                                  grabber.center = background.center;
                                                  grabber.alpha = kAlphaInactive;
                                              }];
                     }];
}

#pragma mark - panning

- (void)didPan:(UIPanGestureRecognizer *)sender {
    id del = self.delegate;

    switch (sender.state) {
        case UIGestureRecognizerStateBegan:
        {
            self.directionLabel.text = nil;

            isPanning = YES;

            [UIView animateWithDuration:kFadeDuration
                             animations:^{
                                 background.alpha = 0.85f;
                                 grabber.alpha = kAlphaActive;
                                 self.directionLabel.alpha = 1.0f;
                             }
                             completion:^(BOOL finished) {
                                 if( [del respondsToSelector:@selector(radialControlDidStartDragging:)] )
                                     [del radialControlDidStartDragging:self];
                             }];

            break;
        }
        case UIGestureRecognizerStateChanged:
        {
            CGPoint target = [sender translationInView:sender.view.superview];

            target.x += background.center.x;
            target.y += background.center.y;

            CGFloat dist = DistanceBetweenPoints(background.center, target);

            // snap to nearest point on circle.
            // who cares how it works? it's trig.
            if( dist > kControlRadius ) {
                CGFloat vX = target.x - background.center.x;
                CGFloat vY = target.y - background.center.y;
                CGFloat magV = (CGFloat)sqrt(vX*vX + vY*vY);
                target.x = background.center.x + vX / magV * kControlRadius;
                target.y = background.center.y + vY / magV * kControlRadius;
            }

            grabber.center = target;

            if( dist >= kMinRadius && [del respondsToSelector:@selector(centerTextForRadialControl:inSector:)] ) {
                NSString *text = [del centerTextForRadialControl:self
                                                        inSector:[self currentSector]];

                if ([text length] > 8) {
                    text = [text substringToIndex:8];
                }

                self.directionLabel.text = text;
            } else {
                self.directionLabel.text = nil;
            }

            break;
        }
        case UIGestureRecognizerStateEnded:
        case UIGestureRecognizerStateCancelled:
        case UIGestureRecognizerStateFailed:
        {
            isPanning = NO;

            CGFloat dist = DistanceBetweenPoints(background.center, grabber.center);
            NSUInteger currentSector = [self currentSector];

            if( sender.state == UIGestureRecognizerStateEnded
                && dist >= kMinRadius
                && [del respondsToSelector:@selector(radialControl:didMoveToSector:)] ) {
                    dispatch_async( dispatch_get_main_queue(), ^{
                        [del radialControl:self
                           didMoveToSector:currentSector];
                    });
            }

            [UIView animateWithDuration:kFadeDuration
                             animations:^{
                                 grabber.center = background.center;
                                 background.alpha = 0.0f;
                                 grabber.alpha = kAlphaInactive;
                                 self.directionLabel.alpha = 0.0f;
                             }
                             completion:^(BOOL finished) {
                                if( [del respondsToSelector:@selector(radialControlDidEndDragging:)] )
                                    [del radialControlDidEndDragging:self];
                             }];

            break;
        }
        case UIGestureRecognizerStatePossible:
            break;
    }
}

- (void)keyboardWillShowOrHide:(NSNotification *)note {

    [panner setEnabled:NO];
    [panner setEnabled:YES];
}

@end
