//
//  SPLMSSPViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/28/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

#import "SPLMSSPViewController.h"
#import <SSDataSources.h>
#import <TTTAttributedLabel.h>
#import <Masonry.h>
#import "NSDate+SPLAdditions.h"
#import "SPLHandoffWebViewController.h"

@interface SPLMSSPCell : SSBaseTableCell

@property (nonatomic, strong) TTTAttributedLabel *label;

@end

@implementation SPLMSSPCell

- (void)configureCell {
    self.selectionStyle = UITableViewCellSelectionStyleNone;

    _label = [[TTTAttributedLabel alloc] initWithFrame:CGRectZero];
    self.label.verticalAlignment = TTTAttributedLabelVerticalAlignmentCenter;
    self.label.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
    self.label.textColor = [[SSThemes sharedThemer] valueForThemeKey:kThemeFontColor];
    self.label.enabledTextCheckingTypes = NSTextCheckingTypeLink;
    self.label.linkAttributes = @{
          NSUnderlineStyleAttributeName : @1,
          (id)kCTForegroundColorAttributeName : (id)((UIColor *)[[SSThemes sharedThemer] valueForThemeKey:kThemeLinkColor]).CGColor,
    };
    [self.contentView addSubview:self.label];
    [self.label mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.and.right.and.bottom.equalTo(self.contentView);
        make.left.equalTo(self.contentView).offset([[UIDevice currentDevice] isIPad] ? 20 : 16);
    }];
}

@end

@interface SPLMSSPViewController () <TTTAttributedLabelDelegate>

@property (nonatomic, copy) NSDictionary *MSSPData;
@property (nonatomic, strong) SSSectionedDataSource *dataSource;

@end

@implementation SPLMSSPViewController

- (instancetype)initWithMSSPData:(NSDictionary *)data {
    if ((self = [super initWithStyle:UITableViewStyleGrouped])) {
        self.title = NSLocalizedString(@"SERVER_STATUS", nil);

        _MSSPData = data;

        _dataSource = [[SSSectionedDataSource alloc] initWithItems:nil];
        self.dataSource.cellClass = [SPLMSSPCell class];

        @weakify(self);
        self.dataSource.cellConfigureBlock = ^(SPLMSSPCell *cell,
                                               NSString *dataString,
                                               UITableView *tableView,
                                               NSIndexPath *indexPath) {
            @strongify(self);
            [SSThemes configureCell:cell];
            cell.label.text = dataString;
            cell.label.delegate = self;
        };
        self.dataSource.tableActionBlock = ^BOOL(SSCellActionType action,
                                                 UITableView *tableView,
                                                 NSIndexPath *indexPath) {
            return NO;
        };

        [[[data allKeys] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)] bk_each:^(NSString *key) {
            id value = data[key];

            if ([key isEqualToString:@"UPTIME"]) {
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:[value doubleValue]];
                value = [NSString stringWithFormat:@"%@ (%@)",
                         [date SPLShortDateTimeValue],
                         [date SPLTimeSinceValue]];
            }

            SSSection *section = [SSSection sectionWithItems:([value isKindOfClass:[NSArray class]]
                                                              ? value
                                                              : @[ value ])];
            section.header = key;

            [self.dataSource appendSection:section];
        }];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tableView.rowHeight = 44.f;
    self.dataSource.tableView = self.tableView;
}

#pragma mark - TTTAttributedLabelDelegate

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url {
    if ([[url scheme] isEqualToString:@"mailto"]) {
        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mvc = [MFMailComposeViewController new];
            [mvc setToRecipients:@[ [[url absoluteString] stringByReplacingOccurrencesOfString:@"mailto:"
                                                                                    withString:@""] ]];
            [mvc bk_setCompletionBlock:^(MFMailComposeViewController *composer, MFMailComposeResult result, NSError *error) {}];

            [self presentViewController:mvc
                               animated:YES
                             completion:^{
                                 // MAIL HACK
                                 [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
                             }];
        }
    } else {
        [self.navigationController SPLPresentWebViewControllerForURL:url];
    }
}

@end
