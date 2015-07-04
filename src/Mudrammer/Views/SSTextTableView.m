//
//  SSTextTableView.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/22/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSTextTableView.h"
#import "SSTextViewCell.h"
#import "SSMudView.h"
#import <SAMRateLimit.h>
#import "NSAttributedString+SPLAdditions.h"
#import "SPLTerminalDataSource.h"

@interface SSTextTableView ()

- (SPLTerminalDataSource *)MUDDataSource;

- (void) willRotate;
- (void) didRotate;

@property (nonatomic, strong) FBKVOController *kvoController;

@property (nonatomic, assign) BOOL shouldScrollAfterRotate;

@end

@implementation SSTextTableView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame style:UITableViewStylePlain])) {

        // table setup
        self.backgroundColor = [UIColor clearColor];
        self.separatorStyle = UITableViewCellSeparatorStyleNone;
        self.separatorColor = [UIColor clearColor];
        self.indicatorStyle = UIScrollViewIndicatorStyleDefault;

        // observe keypaths for when themes change
        _kvoController = [FBKVOController controllerWithObserver:self];

        @weakify(self);
        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeName
                            options:NSKeyValueObservingOptionNew
                              block:^(id table, id object, NSDictionary *change) {
                                  @strongify(self);
                                  [self addCenteredHeaderWithImage:([[SSThemes sharedThemer] isUsingDarkTheme]
                                                                    ? [SPLImagesCatalog tildeWhiteImage]
                                                                    : [SPLImagesCatalog tildeDarkImage])
                                                             alpha:0.5f];
                              }];

        // Scroll after rotation
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(willRotate)
                                                     name:UIApplicationWillChangeStatusBarOrientationNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didRotate)
                                                     name:UIApplicationDidChangeStatusBarOrientationNotification
                                                   object:nil];
    }

    return self;
}

- (void)dealloc {
    _kvoController = nil;

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (CGSize) charSize {
    if (CGSizeEqualToSize(self.bounds.size, CGSizeZero)) {
        return CGSizeZero;
    }

    NSAttributedString *AString = [NSAttributedString userInputStringForString:@"H"];

    CGRect boundingRect = [AString boundingRectWithSize:(CGSize){ CGFLOAT_MAX, CGFLOAT_MAX }
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                                context:NULL];

    if (CGRectGetHeight(boundingRect) < 1) {
        boundingRect.size.height = kDefaultFontSize;
    }

    if (CGRectGetWidth(boundingRect) < 1) {
        boundingRect.size.width = 5.0f;
    }

    CGSize size = (CGSize) {
        SPLFloat_floor( ( CGRectGetWidth(self.bounds) - kTextInsets.left - kTextInsets.right ) / CGRectGetWidth(boundingRect) ),
        SPLFloat_floor( CGRectGetHeight(self.bounds) / CGRectGetHeight(boundingRect) )
    };

//    DLog(@"%@ %@", NSStringFromCGRect(self.bounds), NSStringFromCGSize(size));

    return size;
}

- (SPLTerminalDataSource *)MUDDataSource {
    return (SPLTerminalDataSource *)self.dataSource;
}

- (void) scrollToBottom {
    if ([self.MUDDataSource numberOfItems] == 0) {
        return;
    }

    if ([self isDragging] || [self isTracking]) {
        return;
    }

    NSUInteger count = [self.MUDDataSource numberOfItems];

    if (count == 0) {
        return;
    }

    [self scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:(NSInteger)(count - 1)
                                                    inSection:0]
                atScrollPosition:UITableViewScrollPositionMiddle
                        animated:NO];
}

- (BOOL)isNearBottom {
    return ( self.contentSize.height <= CGRectGetHeight(self.bounds) ) ||
           ( self.contentOffset.y + ( 1.2f * CGRectGetHeight(self.bounds) ) >= self.contentSize.height );
}

#pragma mark - UIAccessibilityContainer

- (BOOL)isAccessibilityElement {
    return NO;
}

- (NSInteger)accessibilityElementCount {
    return (NSInteger)[self.MUDDataSource numberOfItems];
}

- (id)accessibilityElementAtIndex:(NSInteger)index {
    SSTextViewCell *cell = (SSTextViewCell *)[self cellForRowAtIndexPath:[NSIndexPath indexPathForItem:index inSection:0]];
    return cell;
}

- (NSInteger)indexOfAccessibilityElement:(id)element {
    // Special hack for UITableViewWrapperView
    if (![element isKindOfClass:[UITableViewCell class]] && [element isKindOfClass:[UIView class]] && ((UIView *)element).superview == self) {
        return 0;
    }

    NSIndexPath *indexPath = [self indexPathForCell:element];

    if (indexPath) {
        return indexPath.row;
    }

    return NSNotFound;
}

#pragma mark - AccessibilityScroll

- (NSUInteger)SPLCurrentPage {
    if (CGRectEqualToRect(self.bounds, CGRectZero)) {
        return 1;
    }

    if (CGSizeEqualToSize(self.contentSize, CGSizeZero)) {
        return 1;
    }

    if (self.contentOffset.y <= 1.f) {
        return 1;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbad-function-cast"
    return 1 + (NSUInteger)SPLFloat_ceil(self.contentOffset.y / CGRectGetHeight(self.bounds));
#pragma clang diagnostic pop
}

- (NSUInteger)SPLNumberOfPages {
    if (CGRectEqualToRect(self.bounds, CGRectZero)) {
        return 1;
    }

    if (CGSizeEqualToSize(self.contentSize, CGSizeZero)) {
        return 1;
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wbad-function-cast"
    return (NSUInteger)SPLFloat_ceil(self.contentSize.height / CGRectGetHeight(self.bounds));
#pragma clang diagnostic pop
}

- (NSString *)SPLCurrentPageString {
    return [NSString stringWithFormat:@"Page %@ of %@",
            @([self SPLCurrentPage]),
            @([self SPLNumberOfPages])];
}

- (BOOL)SPLCanScrollInDirection:(UIAccessibilityScrollDirection)direction {
    switch (direction) {
        case UIAccessibilityScrollDirectionDown:

            return self.contentOffset.y <= self.contentSize.height - CGRectGetHeight(self.bounds);

        case UIAccessibilityScrollDirectionUp:

            return self.contentOffset.y >= self.contentSize.height - CGRectGetHeight(self.bounds);

        default:

            return NO;
    }
}

- (void)SPLScrollInDirection:(UIAccessibilityScrollDirection)direction {

    CGPoint offset = self.contentOffset;

    switch (direction) {
        case UIAccessibilityScrollDirectionUp: {

            offset.y = MAX(0, offset.y - CGRectGetHeight(self.bounds));
            [self setContentOffset:offset animated:NO];

            // Focus on the last row of this screen
            NSArray *visibleCells = [self visibleCells];

            if ([visibleCells count] > 0) {
                UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, [visibleCells lastObject]);
            }

            break;
        }
        case UIAccessibilityScrollDirectionDown: {

            offset.y = MIN(self.contentSize.height - CGRectGetHeight(self.bounds), offset.y + CGRectGetHeight(self.bounds));
            [self setContentOffset:offset animated:NO];

            // Focus on the first row of this screen
            NSArray *visibleCells = [self visibleCells];

            if ([visibleCells count] > 0) {
                UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, [visibleCells firstObject]);
            }

            break;
        }
        default:
            break;
    }
}

- (NSString *)accessibilityScrollStatusForScrollView:(UIScrollView *)scrollView {
    return [self SPLCurrentPageString];
}

- (BOOL)accessibilityScroll:(UIAccessibilityScrollDirection)direction {
    switch (direction) {
        case UIAccessibilityScrollDirectionUp:
        case UIAccessibilityScrollDirectionDown:

            if (![self SPLCanScrollInDirection:direction]) {
                return NO;
            }

            [self SPLScrollInDirection:direction];
            UIAccessibilityPostNotification(UIAccessibilityPageScrolledNotification, [self SPLCurrentPageString]);

            return YES;

        default:
            return NO;
    }
}

#pragma mark - Rotation

- (void)willRotate {
    self.shouldScrollAfterRotate = [self isNearBottom];
}

- (void)didRotate {
    if (!self.window) {
        return;
    }

    [SAMRateLimit executeBlock:^{
        if (self.shouldScrollAfterRotate) {
            [self performSelector:@selector(scrollToBottom)
                       withObject:nil
                       afterDelay:0.2f];
            self.shouldScrollAfterRotate = NO;
        }
    } name:@"TableRotate" limit:0.3f];
}

@end
