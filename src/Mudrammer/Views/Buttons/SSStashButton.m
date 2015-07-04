//
//  SSStashButton.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/21/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSStashButton.h"

@interface SSStashButton ()

@property (nonatomic, copy) NSString *stashedText;

- (void) buttonTapped:(id)sender;
@end

@implementation SSStashButton

+ (instancetype)stashButton {
    SSStashButton *button = [SSStashButton buttonWithType:UIButtonTypeCustom];

    button.alpha = 0.7f;

    button.accessibilityLabel = NSLocalizedString(@"COMMAND_STASH", nil);
    button.accessibilityHint = @"Switches the text you've currently typed into the input bar with the text currently stashed.";

    [button addTarget:button
               action:@selector(buttonTapped:)
     forControlEvents:UIControlEventTouchUpInside];

    [button setImage:[SPLImagesCatalog stashEmptyImage]
            forState:UIControlStateNormal];

    return button;
}

- (void)dealloc {
    _delegate = nil;
}

- (BOOL)stashContainsText {
    return [self.stashedText length] > 0;
}

- (void)buttonTapped:(id)sender {
    id del = self.delegate;

    if ([del respondsToSelector:@selector(stashButton:didTapStash:)]) {
        _stashedText = [del stashButton:self
                            didTapStash:self.stashedText];

        UIImage *img = ( [self.stashedText length] > 0
                         ? [SPLImagesCatalog stashFullImage]
                         : [SPLImagesCatalog stashEmptyImage] );

        [self setImage:img forState:UIControlStateNormal];
    }
}

- (void)setEnabled:(BOOL)enabled {
    [super setEnabled:enabled];

    self.alpha = ( enabled ? 0.7f : 0.3f );
}

@end
