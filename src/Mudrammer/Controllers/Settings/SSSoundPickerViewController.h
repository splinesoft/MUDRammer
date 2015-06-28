//
//  SSSoundPickerViewController.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 12/7/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import <UIKit/UIKit.h>

// Block called upon completion with the selected sound filename.
typedef void (^SSSoundSelectedBlock) (NSString *);

@interface SSSoundPickerViewController : UITableViewController

- (instancetype) init;

@property (nonatomic, copy) NSString * selectedFileName;

@property (nonatomic, copy) SSSoundSelectedBlock selectedBlock;

@end
