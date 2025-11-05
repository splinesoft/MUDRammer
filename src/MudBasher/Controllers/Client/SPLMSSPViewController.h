//
//  SPLMSSPViewController.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 11/28/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

/**
 *  Visualizes MMSP data/status received from a MUD.
 */

@import UIKit;

@interface SPLMSSPViewController : UITableViewController

- (instancetype) initWithMSSPData:(NSDictionary *)data;

@end
