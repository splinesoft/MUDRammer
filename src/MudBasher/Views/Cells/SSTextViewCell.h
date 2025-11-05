//
//  SSTextViewCell.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/19/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import <SSDataSources.h>
#import <TTTAttributedLabel.h>

UIKIT_EXTERN UIEdgeInsets const kTextInsets;

@interface SPLAttributedLabel : TTTAttributedLabel

@end

@interface SSTextViewCell : SSBaseTableCell

@property (nonatomic, strong) SPLAttributedLabel *textView;

@end
