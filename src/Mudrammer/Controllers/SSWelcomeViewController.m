//
//  SSWelcomeViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 1/12/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSWelcomeViewController.h"
#import <Masonry.h>
#import "SSClientContainer.h"
#import "SSWorldDisplayController.h"

@interface SSWelcomeViewController ()

@property (nonatomic, strong) UILabel *label;
@property (nonatomic, strong) UIImageView *imageView;


- (void) tappedButton:(id)sender;
@end

@implementation SSWelcomeViewController

- (instancetype) init {
    if ((self = [super init])) {
        self.title = NSLocalizedString(@"WELCOME", @"Welcome to MUDRammer");
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view.backgroundColor = [[SSThemes sharedThemer] themeAtIndex:0][kThemeBackgroundColor];

    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                          target:self
                                                                                          action:@selector(tappedButton:)];

    _imageView = [[UIImageView alloc] initWithImage:[SPLImagesCatalog shieldImage]];
    self.imageView.alpha = 0.2f;

    [self.view addSubview:self.imageView];
    [self.imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
    }];

    // welcome label
    _label = [UILabel new];
    self.label.backgroundColor = [UIColor clearColor];
    self.label.textAlignment = NSTextAlignmentCenter;
    self.label.numberOfLines = 0;

    NSShadow *shadow = [NSShadow new];
    shadow.shadowColor = [UIColor darkGrayColor];
    shadow.shadowOffset = CGSizeMake(0, 1);

    self.label.attributedText = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"WELCOME_TEXT", nil)
                                                            attributes:@{
                                 NSForegroundColorAttributeName : [UIColor whiteColor],
                                 NSFontAttributeName : [UIFont fontWithName:kDefaultFontName size:20.],
                                 NSShadowAttributeName : shadow,
                            }];

    [self.view addSubview:self.label];
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.equalTo(self.view).sizeOffset(CGSizeMake(-40, -20));
    }];
}

- (void)tappedButton:(id)sender {
    NSUserDefaults *d = [NSUserDefaults standardUserDefaults];
    [d setBool:YES forKey:kPrefInitialSetupComplete];
    [d synchronize];

    SSClientContainer *container = [SSClientContainer sharedClientContainer];

    [container dismissViewControllerAnimated:YES
                                  completion:^
    {
        SSClientViewController *firstClient = [[SSClientContainer worldDisplayDrawer] clientAtIndex:0];
        [firstClient connect];
    }];
}

@end
