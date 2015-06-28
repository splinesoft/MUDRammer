//
//  SPLMUDTitleView.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/28/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLMUDTitleView.h"
#import <Masonry.h>

@interface SPLMUDTitleView ()

@property (nonatomic, strong) UILabel *titleLabel;
@property (nonatomic, strong) UIButton *MSSPButton;

@end

@implementation SPLMUDTitleView

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {

        _titleLabel = [UILabel new];
        self.titleLabel.font = [UIFont boldSystemFontOfSize:([[UIDevice currentDevice] isIPad]
                                                             ? 18.0f
                                                             : 16.0f)];
        self.titleLabel.shadowColor = [UIColor darkTextColor];
        self.titleLabel.shadowOffset = CGSizeMake(0, 1);
        self.titleLabel.textColor = [UIColor whiteColor];
        self.titleLabel.backgroundColor = [UIColor clearColor];
        self.titleLabel.textAlignment = NSTextAlignmentCenter;
        [self addSubview:self.titleLabel];
        [self.titleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];

        _MSSPButton = [UIButton buttonWithType:UIButtonTypeSystem];
        self.MSSPButton.layer.cornerRadius = 4.f;
        self.MSSPButton.layer.borderWidth = 1.f;
        self.MSSPButton.layer.borderColor = [UIColor whiteColor].CGColor;
        [self.MSSPButton setTitle:NSLocalizedString(@"SERVER_STATUS", nil)
                         forState:UIControlStateNormal];
        [self.MSSPButton.titleLabel setFont:[UIFont systemFontOfSize:13.f]];

        @weakify(self);
        [self.MSSPButton bk_addEventHandler:^(id sender) {
            @strongify(self);
            if (self.MSSPButtonBlock) {
                self.MSSPButtonBlock();
            }
        }
                           forControlEvents:UIControlEventTouchUpInside];
    }

    return self;
}

- (void)setTitle:(NSString *)title {
    self.titleLabel.text = title;
    [self setNeedsDisplay];
}

- (void)setMSSPData:(NSDictionary *)MSSPData {
    _MSSPData = MSSPData;

    if (MSSPData && [MSSPData count] > 0) {
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.and.right.and.top.equalTo(self);
            make.height.equalTo(@18);
        }];

        [self addSubview:self.MSSPButton];
        [self.MSSPButton mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(self.titleLabel.mas_bottom);
            make.width.equalTo(@100);
            make.centerX.equalTo(self);
            make.height.equalTo(@16);
        }];
    } else {
        [self.titleLabel mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];
        [self.MSSPButton removeFromSuperview];
    }

    [self setNeedsLayout];

    [UIView animateWithDuration:0.3f
                          delay:0.f
         usingSpringWithDamping:0.7f
          initialSpringVelocity:0.7f
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionLayoutSubviews
                     animations:^{
                         [self layoutIfNeeded];
                     }
                     completion:nil];
}

@end
