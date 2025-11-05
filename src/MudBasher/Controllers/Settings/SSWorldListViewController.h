//
//  SSWorldListViewController.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@interface SSWorldListViewController : UITableViewController

typedef void (^WorldPickerSelectionBlock) (NSManagedObjectID *);

+ (SSWorldListViewController *) worldPickerViewControllerWithCompletion:(WorldPickerSelectionBlock)block;

@end
