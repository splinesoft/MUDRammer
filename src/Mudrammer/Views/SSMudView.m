//
//  SSMudView.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/25/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

#import "SSMudView.h"
#import "SSRadialControl.h"
#import "SSSettingsViewController.h"
#import "SSSpeechSynthesizer.h"
#import <Masonry.h>
#import <DAKeyboardControl.h>
#import <TTTAttributedLabel.h>
#import "SSMUDToolbar.h"
#import "SSTextTableView.h"
#import "SPLTerminalDataSource.h"
#import "SSTextViewCell.h"
#import "NSAttributedString+SPLAdditions.h"
#import <SAMRateLimit.h>

@interface SSMudView () <SSRadialDelegate, SSMUDToolbarDelegate>

- (void) userDefaultsChanged:(NSNotification *)note;

- (void) repositionRadialControls;

- (void) sendUserInput:(NSString *)text;

@property (nonatomic, strong) SSRadialControl *movementControl;
@property (nonatomic, strong) SSRadialControl *radialControl;

@property (nonatomic, strong) FBKVOController *kvoController;

@property (nonatomic, strong) SSSpeechSynthesizer *synthesizer;

// Scrolling for navbar
@property (nonatomic, assign) BOOL shouldHideTopNav;
@property (nonatomic, assign) CGFloat startContentOffset;
@property (nonatomic, assign) CGFloat lastContentOffset;
@property (nonatomic, assign) BOOL isUserScrolling;

// Text selection
@property (nonatomic, copy) NSString *lastSelectedText;
@property (nonatomic, copy) NSIndexPath *lastMenuIndex;

@end

@implementation SSMudView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = [SSThemes valueForThemeKey:kThemeBackgroundColor];

        // Input toolbar
        _inputToolbar = [[SSMUDToolbar alloc] initWithFrame:CGRectZero];
        self.inputToolbar.toolbarDelegate = self;
        [self addSubview:self.inputToolbar];
        [self.inputToolbar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.and.left.and.right.equalTo(self);
            make.height.greaterThanOrEqualTo(@44);
        }];

        // tableview
        _tableView = [[SSTextTableView alloc] initWithFrame:CGRectZero];
        self.tableView.delegate = self;
        [self addSubview:self.tableView];
        [self.tableView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.and.left.and.right.equalTo(self);
            make.bottom.equalTo(self.inputToolbar.mas_top);
        }];

        // movement control
        _movementControl = [SSRadialControl radialControl];
        self.movementControl.delegate = self;
        [self.movementControl setEnabled:NO];
        [self addSubview:self.movementControl];

        // radial control
        _radialControl = [SSRadialControl radialControl];
        self.radialControl.delegate = self;
        [self.radialControl setEnabled:NO];
        [self addSubview:self.radialControl];

        // Speech toolbar
        _synthesizer = [SSSpeechSynthesizer new];
        self.synthesizer.timeoutDelay = 16.0f;

        // user defaults, for movement control switching
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userDefaultsChanged:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];

        // Background change
        _kvoController = [FBKVOController controllerWithObserver:self];

        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeBackgroundColor
                            options:NSKeyValueObservingOptionNew
                              block:^(SSMudView *mudView, id object, NSDictionary *change) {
                                  UIColor *newColor = change[NSKeyValueChangeNewKey];
                                  if (!newColor) newColor = [UIColor blackColor];
                                  mudView.backgroundColor = newColor;
                              }];

        // Data source
        _dataSource = [[SPLTerminalDataSource alloc] initWithItems:nil];

        @weakify(self);
        self.dataSource.cellClass = [SSTextViewCell class];
        self.dataSource.tableActionBlock = ^BOOL(SSCellActionType action,
                                                 UITableView *tableView,
                                                 NSIndexPath *indexPath) {
            return NO;
        };
        self.dataSource.rowAnimation = UITableViewRowAnimationNone;
        self.dataSource.cellConfigureBlock = ^(SSTextViewCell *cell,
                                               SSAttributedLineGroupItem *line,
                                               UITableView *tableView,
                                               NSIndexPath *indexPath) {
            @strongify(self);
            cell.textView.linkAttributes = @{ (id)kCTForegroundColorAttributeName : (id)((UIColor *)[SSThemes valueForThemeKey:kThemeLinkColor]).CGColor };
            cell.textView.activeLinkAttributes = @{ (id)kCTForegroundColorAttributeName : (id)((UIColor *)[SSThemes valueForThemeKey:kThemeFontColor]).CGColor };
            cell.textView.delegate = self.delegate;

            if ([line.line length] > 0) {
                cell.textView.text = line.line;
                cell.textView.accessibilityLabel = [line.line string];
            } else {
                cell.textView.text = nil;
                cell.textView.accessibilityLabel = nil;
            }
        };

        self.dataSource.tableView = self.tableView;
    }

    return self;
}

- (void)setKeyboardPanningEnabled:(BOOL)enabled {
    [self removeKeyboardControl];

    if( enabled ) {
        // drag-to-dismiss keyboard
        @weakify(self);
        [self addKeyboardNonpanningWithFrameBasedActionHandler:nil
                                  constraintBasedActionHandler:^(CGRect keyboardFrame, BOOL opening, BOOL closing)
        {
            @strongify(self);
//            DLog(@"%@ %i %i", NSStringFromCGRect(keyboardFrame), opening, closing);

            BOOL isNearBottom = [self.tableView isNearBottom];
            BOOL kbPref = [[NSUserDefaults standardUserDefaults] boolForKey:kPrefBTKeyboard];
            CGFloat keyboardHeight = CGRectGetHeight(keyboardFrame);

            if (!kbPref) {
                [self mas_updateConstraints:^(MASConstraintMaker *make) {
                    if (closing || keyboardHeight <= 0) {
                        make.bottom.equalTo(self.superview);
                    } else if (opening && keyboardHeight > 0) {
                        make.bottom.equalTo(self.superview).offset(-keyboardHeight);
                    }
                }];
            }

            [self repositionRadialControls];

            if (isNearBottom && (opening || closing)) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                     [self.tableView scrollToBottom];
                });
            }
        }];
    } else if (self.window) {
        [self mas_updateConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self.superview);
        }];
        [self repositionRadialControls];

        [self setNeedsLayout];
    }
}

- (void)dealloc {
    [self.movementControl removeFromSuperview];
    [self.radialControl removeFromSuperview];
    [self.tableView removeFromSuperview];

    [self stopSpeaking];

    _dataSource.tableView = nil;
    _delegate = nil;
    _tableView.delegate = nil;
    _tableView.dataSource = nil;
    _tableView = nil;
    _dataSource = nil;
    self.inputToolbar.toolbarDelegate = nil;

    [self removeKeyboardControl];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - movement control

- (void)layoutSubviews {
    BOOL isNearBottom = [self.tableView isNearBottom];

    [super layoutSubviews];

    if (isNearBottom) {
        [self.tableView scrollToBottom];
    }
}

- (void)userDefaultsChanged:(NSNotification *)note {
    dispatch_async(dispatch_get_main_queue(), ^{
        self.shouldHideTopNav = ![[NSUserDefaults standardUserDefaults] boolForKey:kPrefTopBarAlwaysVisible];

        [self.radialControl setEnabled:([self.inputToolbar.textView isEditable]
                                        && [SSRadialControl radialControlIsEnabled:kPrefRadialControl])];

        [self.movementControl setEnabled:([self.inputToolbar.textView isEditable]
                                          && [SSRadialControl radialControlIsEnabled:kPrefMoveControl])];

        [self repositionRadialControls];
    });
}

- (void)repositionRadialControls {
    CGFloat controlSize = SPLFloat_floor(CGRectGetWidth(self.movementControl.frame));
    CGFloat sideOffset = SPLFloat_floor(controlSize / 1.6f);
    CGFloat bottomOffset = MIN(sideOffset, SPLFloat_floor((CGRectGetHeight(self.tableView.frame) - controlSize) / 2.0f));

    if ([[UIDevice currentDevice] isIPad]) {
        bottomOffset *= 2;
        sideOffset *= 2;
    }

    [self.movementControl mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.and.width.equalTo(@(controlSize));
        make.bottom.lessThanOrEqualTo(self.inputToolbar.mas_top).offset(-bottomOffset);

        if ([SSRadialControl positionForRadialControl:kPrefMoveControl] == SSRadialControlPositionLeft) {
            make.left.equalTo(self).offset(sideOffset);
        } else {
            make.right.equalTo(self).offset(-sideOffset);
        }
    }];

    [self.radialControl mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.and.width.equalTo(@(controlSize));
        make.bottom.lessThanOrEqualTo(self.inputToolbar.mas_top).offset(-bottomOffset);

        if ([SSRadialControl positionForRadialControl:kPrefRadialControl] == SSRadialControlPositionLeft) {
            make.left.equalTo(self).offset(sideOffset);
        } else {
            make.right.equalTo(self).offset(-sideOffset);
        }
    }];
}

#pragma mark - history operations

- (void)addHistoryCommand:(NSString *)command {
    [self.inputToolbar.historyControl addCommand:command];
}

- (void)purgeHistory {
    [self.inputToolbar.historyControl purgeCommandHistory];
}

#pragma mark - Text operations

- (void)clearText {
    [self stopSpeaking];

    // shenanigans. try to avoid deleting hundreds of rows
    self.tableView.dataSource = nil;
    self.dataSource.tableView = nil;
    [self.dataSource clearItems];
    self.dataSource.tableView = self.tableView;
    [self.tableView reloadData];
}

- (void)appendAttributedLineGroup:(SSAttributedLineGroup *)group speak:(BOOL)speak {
    [self.dataSource appendAttributedLineGroup:group];

    if (speak) {
        [[group cleanTextLinesWithCommands:NO] bk_each:^(NSString *line) {
            if ([line length] > 0) {
                [self appendTTS:line];
            }
        }];
    }
}

- (void)appendText:(NSString *)text isUserInput:(BOOL)isUserInput speak:(BOOL)speak {
    if (speak) {
        [self appendTTS:text];
    }

    [self.dataSource appendText:text isUserInput:isUserInput];
}

- (BOOL)isEditable {
    return self.inputToolbar.textView.editable;
}

- (void)setEditable:(BOOL)editable {
    [self setKeyboardPanningEnabled:editable];

    [SSRadialControl validateRadialPositions];

    [self.movementControl setEnabled:([SSRadialControl radialControlIsEnabled:kPrefMoveControl] && editable)];

    [self.radialControl setEnabled:([SSRadialControl radialControlIsEnabled:kPrefRadialControl] && editable)];

    self.inputToolbar.textView.alpha = ( editable ? 1.0f : 0.3f );

    [self.inputToolbar setInputBarEnabled:editable];
}

#pragma mark - input toolbar delegate

- (void)sendUserInput:(NSString *)text {
    if (!text) {
        text = @"";
    }

    [self stopSpeaking];

    id del = self.delegate;

    if ([del respondsToSelector:@selector(mudView:didReceiveUserCommand:)]) {
        [del mudView:self didReceiveUserCommand:text];
    }
}

- (void)mudToolbar:(SSMUDToolbar *)toolbar willChangeToHeight:(CGFloat)height {

    BOOL isNearBottom = [self.tableView isNearBottom];

    [self.inputToolbar mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.greaterThanOrEqualTo(@(height));
    }];

    [self.inputToolbar setNeedsLayout];
    [self.tableView setNeedsLayout];

    [UIView animateWithDuration:0.5
                          delay:0
         usingSpringWithDamping:0.7f
          initialSpringVelocity:0.7f
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionLayoutSubviews
                     animations:^{
                         [self layoutIfNeeded];
                     } completion:^(BOOL finished) {
                         if (isNearBottom) {
                             [self.tableView scrollToBottom];
                         }
                     }];
}

- (void)mudToolbar:(SSMUDToolbar *)toolbar didSendInput:(NSString *)input {
    [self sendUserInput:input];
}

#pragma mark - SSRadialDelegate

- (BOOL)radialControlShouldStartDragging:(SSRadialControl *)control {
    return [self.inputToolbar.textView isEditable];
}

- (void)radialControl:(SSRadialControl *)control didMoveToSector:(NSUInteger)sector {
    NSString *direction = [self centerTextForRadialControl:control inSector:sector];

    if (!direction) {
        return;
    }

    [self stopSpeaking];

    id del = self.delegate;

    if ([del respondsToSelector:@selector(mudView:moveControlDidMoveToDirection:)]) {
        [del mudView:self moveControlDidMoveToDirection:(control == self.movementControl
                                                         ? [direction lowercaseString]
                                                         : direction)];
    }
}

- (NSUInteger)numberOfSectorsInRadialControl:(SSRadialControl *)control {
    if (control == self.movementControl) {
        return 8;
    } else {
        return [[[NSUserDefaults standardUserDefaults] arrayForKey:kPrefRadialCommands] count];
    }
}

- (NSString *)centerTextForRadialControl:(SSRadialControl *)control inSector:(NSUInteger)sector {

    if (control == self.movementControl) {
        switch( sector ) {
            case 0:
                return @"N";
            case 1:
                return @"NE";
            case 2:
                return @"E";
            case 3:
                return @"SE";
            case 4:
                return @"S";
            case 5:
                return @"SW";
            case 6:
                return @"W";
            default:
                return @"NW";
        }
    } else {
        NSArray *commands = [[NSUserDefaults standardUserDefaults] arrayForKey:kPrefRadialCommands];

        if (sector < [commands count]) {
            return commands[sector];
        }
    }

    return nil;
}

#pragma mark - AVSpeechSynthesizer

- (void)stopSpeaking {
    [self.synthesizer stopSpeaking];
}

- (void)continueSpeaking {
    [self.synthesizer continueSpeaking];
}

- (void)appendTTS:(NSString *)text {
    [self.synthesizer enqueueLineForSpeaking:text];
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {

    CGFloat defaultSize = SPLFloat_ceil([SSThemes currentFont].pointSize);

    if (!self.dataSource) {
        return defaultSize;
    }

    SSAttributedLineGroupItem *line = [self.dataSource itemAtIndexPath:indexPath];

    if (!line) {
        return defaultSize;
    }

    NSMutableAttributedString *astr = line.line;

    if ([astr length] == 0) {
        return defaultSize;
    }

    CGSize constraints = CGSizeMake(CGRectGetWidth(self.bounds) - kTextInsets.left - kTextInsets.right,
                                    CGFLOAT_MAX);

    CGSize suggestedSize = [TTTAttributedLabel sizeThatFitsAttributedString:astr
                                                            withConstraints:constraints
                                                     limitedToNumberOfLines:0];

    if (suggestedSize.height <= 1) {
        // blank line?
        return defaultSize;
    }

    return suggestedSize.height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    UIMenuController *menuController = [UIMenuController sharedMenuController];

    if ([menuController isMenuVisible]) {
        [menuController setMenuVisible:NO animated:YES];
        return;
    }

    SSAttributedLineGroupItem *line = [self.dataSource itemAtIndexPath:indexPath];

    if (!line || [line.line length] == 0) {
        return;
    }

    self.lastSelectedText = line.line.string;
    self.lastMenuIndex = indexPath;

    [self becomeFirstResponder];

    CGRect rowRect = [tableView rectForRowAtIndexPath:indexPath];
    CGRect convertedRect = [self convertRect:rowRect fromView:tableView];

    menuController.arrowDirection = (CGRectGetMinY(convertedRect) <= 50
                                     ? UIMenuControllerArrowUp
                                     : UIMenuControllerArrowDefault);

    [menuController setTargetRect:convertedRect
                           inView:self];

    menuController.menuItems = @[
        [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"NEW_TRIGGER", nil) action:@selector(newTrigger:)],
        [[UIMenuItem alloc] initWithTitle:NSLocalizedString(@"NEW_GAG", nil) action:@selector(newGag:)]
    ];

    [menuController setMenuVisible:YES animated:YES];
}

#pragma mark - UIResponder

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (![self isFirstResponder]) {
        return NO;
    }

    return action == NSSelectorFromString(@"copy:")
        || action == @selector(newTrigger:)
        || action == @selector(newGag:);
}

- (void)copy:(id)sender {
    if ([self.lastSelectedText length] > 0) {
        UIPasteboard *paste = [UIPasteboard generalPasteboard];
        [paste setString:self.lastSelectedText];
    }
}

#pragma mark - UIMenuController actions

- (void)newTrigger:(id)sender {
    id del = self.delegate;

    if ([del respondsToSelector:@selector(mudView:shouldCreateRecordWithText:type:)]) {
        [del mudView:self shouldCreateRecordWithText:self.lastSelectedText
                type:[Trigger class]];
    }
}

- (void)newGag:(id)sender {
    id del = self.delegate;

    if ([del respondsToSelector:@selector(mudView:shouldCreateRecordWithText:type:)]) {
        [del mudView:self shouldCreateRecordWithText:self.lastSelectedText
                type:[Gag class]];
    }
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    if (![[UIDevice currentDevice] isIPad]) {
        [self endEditing:YES];
    }

    self.startContentOffset = self.lastContentOffset = scrollView.contentOffset.y;

    self.isUserScrolling = YES;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    self.isUserScrolling = NO;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (self.lastMenuIndex && [[UIMenuController sharedMenuController] isMenuVisible]) {
        if ([[self.tableView indexPathsForVisibleRows] containsObject:self.lastMenuIndex]) {
            CGRect newRowRect = [self.tableView rectForRowAtIndexPath:self.lastMenuIndex];
            CGRect convertedRect = [self convertRect:newRowRect fromView:self.tableView];

            [[UIMenuController sharedMenuController] setTargetRect:convertedRect inView:self];
        } else {
            [[UIMenuController sharedMenuController] setMenuVisible:NO animated:YES];
        }
    }

    if (!self.shouldHideTopNav || !self.isUserScrolling) {
        return;
    }

    if (UIAccessibilityIsVoiceOverRunning()) {
        return;
    }

    CGFloat currentOffset = scrollView.contentOffset.y;
    CGFloat differenceFromStart = self.startContentOffset - currentOffset;
    CGFloat differenceFromLast = self.lastContentOffset - currentOffset;
    self.lastContentOffset = currentOffset;

    if (SPLFloat_abs(differenceFromLast) <= 1) {
        return;
    }

    NSInteger action = -1;

    if (differenceFromStart < -40) {
        action = 0;
    } else if (differenceFromStart > 40) {
        action = 1;
    }

    if (action == 0 && [self.tableView isNearBottom]) {
        return;
    }

    if (action == -1) {
        return;
    }

    [SAMRateLimit executeBlock:^{
        id del = self.delegate;
        if ([del respondsToSelector:@selector(mudView:scrollOffsetChangedSignificantlyInDirection:)]) {
            [del mudView:self scrollOffsetChangedSignificantlyInDirection:(BOOL)action];
        }
    }
                          name:NSStringFromClass([self class])
                         limit:0.1];
}

@end
