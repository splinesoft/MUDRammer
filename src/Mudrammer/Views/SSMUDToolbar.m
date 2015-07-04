//
//  SSMUDToolbar.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 2/1/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SSMUDToolbar.h"
#import "SSAccessoryToolbar.h"
#import "SSSettingsViewController.h"
#import "SSAccessoryToolbar.h"
#import "SSMudHistoryDelegate.h"
#import <UIScreen+SSAdditions.h>
#import <Masonry.h>

UIEdgeInsets const kToolbarInsets = (UIEdgeInsets) { 4, 8, 4, 8 };

@interface SSMUDToolbar () <SSAccessoryToolbarDelegate, SSStashDelegate, SSMudHistoryDelegate>
- (void) userDefaultsDidChange:(NSNotification *)notification;
- (void) setMRAutocorrectEnabled:(BOOL)enabled autocapitalizeEnabled:(BOOL)autocapitalizeEnabled;
- (void) setInputAccessoryBarEnabled:(BOOL)enabled;
- (void) setDarkKeyboardEnabled:(BOOL)enabled;

- (void) refreshTextViewHeight;

@property (nonatomic, strong) UIButton *sendButton;
@property (nonatomic, strong) UILabel *characterLabel;

@end

@implementation SSMUDToolbar

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.backgroundColor = UIColorFromRGB(0xDDDDDD);
        self.tintColor = [UIColor darkGrayColor];

        /* Left button view */
        UIView *stashHistoryView = [[UIView alloc] initWithFrame:CGRectZero];
        stashHistoryView.backgroundColor = [UIColor clearColor];

        // stash
        _stashButton = [SSStashButton stashButton];
        self.stashButton.delegate = self;
        self.stashButton.enabled = NO;
        [self.stashButton sizeToFit];
        [stashHistoryView addSubview:self.stashButton];
        [self.stashButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(stashHistoryView);
            make.centerY.equalTo(stashHistoryView);
        }];

        // history control
        _historyControl = [SSMudHistoryControl new];
        self.historyControl.delegate = self;
        [stashHistoryView addSubview:self.historyControl];
        [self.historyControl mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(stashHistoryView);
            make.top.equalTo(stashHistoryView);
            make.bottom.equalTo(stashHistoryView);
            make.width.equalTo(@68);
        }];

        [self addSubview:stashHistoryView];
        [stashHistoryView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(self).insets(kToolbarInsets);
            make.centerY.equalTo(self);
            make.width.equalTo(@100);
            make.height.equalTo(self);
        }];

        // send button
        _sendButton  = [UIButton buttonWithType:UIButtonTypeCustom];
        _sendButton.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:16.0f];
        _sendButton.accessibilityLabel = NSLocalizedString(@"SEND", nil);
        _sendButton.accessibilityHint = @"Sends your inputted text.";
        [_sendButton setTitle:NSLocalizedString(@"SEND", nil) forState:UIControlStateNormal];
        [_sendButton setTitleColor:[UIColor blueColor] forState:UIControlStateNormal];
        [_sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
        [_sendButton setTitleColor:[UIColor grayColor] forState:UIControlStateSelected];
        [_sendButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
        [_sendButton setTitleShadowColor:[UIColor whiteColor] forState:UIControlStateNormal];
        _sendButton.enabled = NO;
        [_sendButton addTarget:self
                        action:@selector(inputButtonPressed)
              forControlEvents:UIControlEventTouchUpInside];
        [_sendButton sizeToFit];
        [self addSubview:self.sendButton];
        [self.sendButton mas_makeConstraints:^(MASConstraintMaker *make) {
            make.right.equalTo(self).insets(kToolbarInsets);
            make.centerY.equalTo(self);
        }];

        _textView = [[SSGrowingTextView alloc] initWithFrame:CGRectZero textContainer:nil];
        self.textView.textDelegate = self;
        [self addSubview:self.textView];
        [self.textView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(stashHistoryView.mas_right).offset(4);
            make.right.equalTo(self.sendButton.mas_left).insets(kToolbarInsets);
            make.centerY.equalTo(self);
            make.height.equalTo(@(self.textView.minHeight));
        }];

        // char counter
        _characterLabel = [UILabel new];
        _characterLabel.font = [UIFont systemFontOfSize:11.0f];
        _characterLabel.textColor = [UIColor darkGrayColor];
        _characterLabel.backgroundColor = [UIColor clearColor];
        _characterLabel.shadowColor = [UIColor whiteColor];
        _characterLabel.shadowOffset = CGSizeMake(0, 1);
        [self addSubview:_characterLabel];
        self.characterLabel.alpha = 0.0f;
        [self.characterLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.bottom.equalTo(self).offset(-2);
            make.centerX.equalTo(self.sendButton);
        }];

        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

        [self setMRAutocorrectEnabled:[[defaults objectForKey:kPrefAutocorrect] boolValue]
                autocapitalizeEnabled:[defaults boolForKey:kPrefAutocapitalization]];
        [self setInputAccessoryBarEnabled:[defaults boolForKey:kPrefInputAccessoryBar]];
        [self setDarkKeyboardEnabled:[defaults boolForKey:kPrefKeyboardStyle]];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(userDefaultsDidChange:)
                                                     name:NSUserDefaultsDidChangeNotification
                                                   object:nil];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(refreshTextViewHeight)
                                                     name:UIDeviceOrientationDidChangeNotification
                                                   object:nil];
    }

    return self;
}

- (void)setInputBarEnabled:(BOOL)editable {
    [self.textView setEditable:editable];
    [self.textView setSelectable:editable];
    self.historyControl.enabled = editable;
    [self.historyControl enableSegments];
    self.stashButton.enabled = (editable
                                ? [self.stashButton stashContainsText] || [self.textView.text length] > 0
                                : NO);
    self.sendButton.enabled = editable;
    self.characterLabel.hidden = !editable;
}

- (void)dealloc {
    self.textView.delegate = nil;
    _toolbarDelegate = nil;
    self.stashButton.delegate = nil;
    self.historyControl.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)inputButtonPressed {
    NSString *text = [self.textView.text copy];
    id del = self.toolbarDelegate;

    if ([del respondsToSelector:@selector(mudToolbar:didSendInput:)]) {
        [del mudToolbar:self
           didSendInput:text];
    }

    if ([text length] > 0 && [[NSUserDefaults standardUserDefaults] boolForKey:kPrefInputKeepsCommands]) {
        [self.textView setSelectedRange:NSMakeRange(0, [text length])];
    } else {
        [self.textView setText:@""];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    [super touchesEnded:touches withEvent:event];

    if ([self.textView isEditable] && ![self.textView isFirstResponder]) {
        [self.textView becomeFirstResponder];
    }
}

- (void)refreshTextViewHeight {
    CGFloat newHeight = [self.textView currentContentSize].height;

    [self.textView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@(newHeight));
    }];

    newHeight += kToolbarInsets.top + kToolbarInsets.bottom;

    if (newHeight <= 44.0f) {
        newHeight = 44.0f;
    }

    if (newHeight >= 48.0f) {
        self.characterLabel.alpha = 1.0f;
    } else if (self.characterLabel.alpha > 0) {
        self.characterLabel.alpha = 0.0f;
    }

    id del = self.toolbarDelegate;

    if ([del respondsToSelector:@selector(mudToolbar:willChangeToHeight:)]) {
        [del mudToolbar:self willChangeToHeight:newHeight];
    }
}

#pragma mark - SSGrowingTextViewDelegate

- (void)growingTextViewPressedKeyCommand:(NSString *)direction {
    NSString *currentText = [self.textView.text copy];

    if ([direction isEqualToString:UIKeyInputUpArrow]) {
        if ([self.historyControl isAtStart]) {
            return;
        }

        if ([self.historyControl isAtEnd] && [currentText length] > 0) {
            [self.historyControl addCommand:currentText];
            [self.textView setText:@""];

            // Move twice, to go past the text we've just added to history
            [self.historyControl moveHistory:HistoryDirectionBackwards];
        }

        [self.historyControl moveHistory:HistoryDirectionBackwards];
    } else if (![self.historyControl isAtEnd]) {
        [self.historyControl moveHistory:HistoryDirectionForwards];
    }
}

- (void)growingTextViewSentDirectionalCommand:(NSString *)direction {
    id del = self.toolbarDelegate;

    if ([del respondsToSelector:@selector(mudToolbar:didSendInput:)]) {
        [del mudToolbar:self
           didSendInput:direction];
    }
}

- (void)textViewDidChange:(UITextView *)textView {
    NSString *text = textView.text;

    self.stashButton.enabled = ([self.stashButton stashContainsText] || [text length] > 0);

    self.characterLabel.text = ([text length] > 0
                                ? [NSString stringWithFormat:@"%@", @([text length])]
                                : nil);
    [self.characterLabel sizeToFit];

    [self refreshTextViewHeight];

    // iOS 8 workaround?
    [textView scrollRangeToVisible:textView.selectedRange];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    if ([text isEqualToString:@"\n"]) {
        [self inputButtonPressed];
        return NO;
    }

    return YES;
}

#pragma mark - SSAccessoryToolbarDelegate

- (void)accessoryToolbarDidSendCommand:(NSString *)cmd {
    NSString *text = self.textView.text;

    if ([text length] == 0) {
        [self.textView setText:cmd];
    } else {
        NSRange range = self.textView.selectedRange;
        NSMutableString *input = [NSMutableString stringWithString:text];

        if (range.length >= 1) {
            [input replaceCharactersInRange:range
                                 withString:cmd];
        } else {
            [input insertString:cmd atIndex:range.location];
        }

        [self.textView setText:input];
        [self.textView setSelectedRange:NSMakeRange(range.location + [cmd length],
                                                    0)];
    }
}

#pragma mark - user defaults (for autocorrect)

- (void) setMRAutocorrectEnabled:(BOOL)enabled autocapitalizeEnabled:(BOOL)autocapitalizeEnabled {
    UITextAutocorrectionType corrtype;
    UITextSpellCheckingType spelltype;
    UITextAutocapitalizationType autocapType = (autocapitalizeEnabled
                                                ? UITextAutocapitalizationTypeSentences
                                                : UITextAutocapitalizationTypeNone);

    if( enabled ) {
        corrtype = UITextAutocorrectionTypeYes;
        spelltype = UITextSpellCheckingTypeYes;
    } else {
        corrtype = UITextAutocorrectionTypeNo;
        spelltype = UITextSpellCheckingTypeNo;
    }

    dispatch_async( dispatch_get_main_queue(), ^{
        SSGrowingTextView *tv = self.textView;

        if (tv.autocorrectionType == corrtype
            && tv.spellCheckingType == spelltype
            && tv.autocapitalizationType == autocapType) {
            return;
        }

        // hack to force re-evaluation of correction types
        BOOL resign = [tv isFirstResponder];

        if (resign) {
            [tv resignFirstResponder];
        }

        // set new correction types
        tv.autocorrectionType = corrtype;
        tv.spellCheckingType = spelltype;
        tv.autocapitalizationType = autocapType;

        if (resign) {
            [tv becomeFirstResponder];
        }

        [tv setNeedsDisplay];
    });
}

- (void)setDarkKeyboardEnabled:(BOOL)enabled {
    dispatch_async( dispatch_get_main_queue(), ^{
        UIKeyboardAppearance newAppear = (enabled
                                          ? UIKeyboardAppearanceDark
                                          : UIKeyboardAppearanceLight);

        if (self.textView.keyboardAppearance == newAppear) {
            return;
        }

        [self endEditing:YES];

        self.textView.keyboardAppearance = newAppear;
    });
}

- (void)setInputAccessoryBarEnabled:(BOOL)enabled {
    dispatch_async( dispatch_get_main_queue(), ^{
        BOOL isEnabled = self.textView.inputAccessoryView != nil
                      && CGRectGetHeight(self.textView.inputAccessoryView.frame) > 0;

        if (isEnabled == enabled) {
            return;
        }

        [self endEditing:YES];

        if( !enabled ) {
            self.textView.inputAccessoryView = [[UIView alloc] initWithFrame:CGRectZero];
        } else {
            SSAccessoryToolbar *toolbar = [[SSAccessoryToolbar alloc] initWithFrame:
                                           CGRectMake(0, 0, CGRectGetWidth(self.frame), 44)];
            toolbar.accessoryDelegate = self;
            self.textView.inputAccessoryView = toolbar;
        }
    });
}

- (void)userDefaultsDidChange:(NSNotification *)notification {
    // get current autocorrect value
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    [self setMRAutocorrectEnabled:[[defaults objectForKey:kPrefAutocorrect] boolValue]
            autocapitalizeEnabled:[defaults boolForKey:kPrefAutocapitalization]];

    BOOL kbPref = [[NSUserDefaults standardUserDefaults] boolForKey:kPrefBTKeyboard];

    [self setInputAccessoryBarEnabled:(!kbPref && [defaults boolForKey:kPrefInputAccessoryBar])];
    [self setDarkKeyboardEnabled:[defaults boolForKey:kPrefKeyboardStyle]];
}

#pragma mark - stash delegate

- (NSString *) stashButton:(SSStashButton *)button didTapStash:(NSString *)stash {
    NSString *currentText = [self.textView.text copy];
    [self.textView setText:stash];

    button.enabled = [currentText length] > 0 || [stash length] > 0;

    return currentText;
}

#pragma mark - mud history delegate

- (void)mudHistoryControl:(SSMudHistoryControl *)control willChangeToCommand:(NSString *)command {
    if ([self.textView isEditable]) {
        [self.textView setText:command];
    }
}

@end
