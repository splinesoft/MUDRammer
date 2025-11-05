//
//  SSAccessoryToolbar.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 5/19/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSAccessoryToolbar.h"
#import "SSAccessoryButton.h"
#import <Masonry.h>

@interface SSAccessoryToolbar ()

@property (nonatomic, strong) FBKVOController *kvoController;
@property (nonatomic, strong) SSArrayDataSource *SPLDataSource;
@property (nonatomic, strong) UICollectionView *collectionView;

@property (nonatomic, readonly, strong) UICollectionViewFlowLayout *toolbarLayout;

@end

@implementation SSAccessoryToolbar

- (instancetype)initWithFrame:(CGRect)frame {
    if ((self = [super initWithFrame:frame])) {
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        self.backgroundColor = [[SSThemes sharedThemer] valueForThemeKey:kThemeBackgroundColor];

        _collectionView = [[UICollectionView alloc] initWithFrame:frame
                                             collectionViewLayout:[self toolbarLayout]];
        self.collectionView.showsHorizontalScrollIndicator = NO;
        self.collectionView.backgroundColor = [UIColor clearColor];
        self.collectionView.delegate = self;
        [self.collectionView registerClass:[SSAccessoryButton class]
                forCellWithReuseIdentifier:[SSAccessoryButton identifier]];
        [self addSubview:self.collectionView];
        [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.edges.equalTo(self);
        }];

        // Data source
        _SPLDataSource = [[SSArrayDataSource alloc] initWithItems:@[ @"@", @"#", @"%", @"^", @"&", @"*", @"-", @"=",
                                                                     @"+", @":", @";", @"/", @"\\", @"(", @")",
                                                                     @"\"", @"'", @"1", @"2", @"3", @"4",
                                                                     @"5", @"6", @"7", @"8", @"9", @"0" ]];
        self.SPLDataSource.cellClass = [SSAccessoryButton class];
        self.SPLDataSource.cellConfigureBlock = ^(SSAccessoryButton *cell,
                                                  NSString *text,
                                                  UICollectionView *collectionView,
                                                  NSIndexPath *indexPath) {
            [cell configureWithText:text];
        };
        self.SPLDataSource.collectionView = self.collectionView;

        _kvoController = [FBKVOController controllerWithObserver:self];

        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeBackgroundColor
                            options:NSKeyValueObservingOptionNew
                              block:^(SSAccessoryToolbar *toolbar, id object, NSDictionary *change) {
                                  UIColor *newColor = change[NSKeyValueChangeNewKey];
                                  if (!newColor) newColor = [UIColor blackColor];
                                  toolbar.backgroundColor = newColor;
                              }];
        [self.kvoController observe:[SSThemes sharedThemer].currentTheme
                            keyPath:kThemeFontColor
                            options:NSKeyValueObservingOptionNew
                              block:^(SSAccessoryToolbar *toolbar, id object, NSDictionary *change) {
                                  [toolbar.collectionView reloadItemsAtIndexPaths:[toolbar.collectionView indexPathsForVisibleItems]];
                              }];
    }

    return self;
}

- (UICollectionViewFlowLayout *)toolbarLayout {
    UICollectionViewFlowLayout *layout = [UICollectionViewFlowLayout new];
    layout.minimumInteritemSpacing = 0.0f;
    layout.minimumLineSpacing = 0.0f;
    layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;

    return layout;
}

- (void)dealloc {
    self.collectionView.dataSource = nil;
    self.collectionView.delegate = nil;
    _accessoryDelegate = nil;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    NSString *command = [self.SPLDataSource itemAtIndexPath:indexPath];
    id del = self.accessoryDelegate;

    if ([del respondsToSelector:@selector(accessoryToolbarDidSendCommand:)]) {
        [del accessoryToolbarDidSendCommand:command];
    }

    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

#pragma mark - UICollectionViewDelegateFlowLayout

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return CGSizeMake([[UIDevice currentDevice] isIPad] ? 44 : 32, 44);
}

@end
