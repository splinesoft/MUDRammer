//
//  SSAdvSettingsController.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 4/25/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@interface SSAdvSettingsController : UITableViewController

typedef NS_ENUM( NSUInteger, SSAdvancedSection ) {
    SSAdvancedSectionTop,
    SSAdvancedSectionInputKeep,
    SSAdvancedSectionSemicolonCommands,
    SSAdvancedSectionStringEncoding,
    SSAdvancedSectionBTKeyboard,
    SSAdvancedSectionSimpleTelnet,
    SSAdvancedSectionAcknowledgements,
    SSAdvancedNumSections
};

typedef NS_ENUM(NSUInteger, SSAdvancedTopRow) {
    SSAdvancedTopRowConnectLaunch,
    SSAdvancedTopRowNavPref,
    SSAdvancedTopRowCharBar,
    SSAdvancedTopNumRows,
};

typedef NS_ENUM(NSUInteger, SSInputRow) {
    SSInputRowDarkKeyboard,
    SSInputRowAutocapitalize,
    SSInputRowInputKeep,
    SSInputNumRows
};

@end
