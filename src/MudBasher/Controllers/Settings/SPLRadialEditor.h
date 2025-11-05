//
//  SPLRadialEditor.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 3/27/14.
//  Copyright (c) 2014 Jonathan Hersh. All rights reserved.
//

/**
 *  Editor for the second customizable radial control.
 */

@import UIKit;

typedef NS_ENUM(NSUInteger, SPLRadialEditorSection) {
    SPLRadialEditorSectionEnable,
    SPLRadialEditorSectionCommands,
    SPLRadialEditorNumSections
};

@interface SPLRadialEditor : UITableViewController

@end
