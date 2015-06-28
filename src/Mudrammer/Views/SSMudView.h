//
//  SSMudView.h
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/25/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;

@protocol SSMudViewDelegate, SSMUDToolbarDelegate, TTTAttributedLabelDelegate;
@class SSMUDToolbar, SSTextTableView, SSAttributedLineGroup, SPLTerminalDataSource;

@interface SSMudView : UIView <UITableViewDelegate>

@property (nonatomic, weak) id <SSMudViewDelegate> delegate;

@property (nonatomic, strong, readonly) SSTextTableView *tableView;
@property (nonatomic, strong, readonly) SPLTerminalDataSource *dataSource;
@property (nonatomic, strong, readonly) SSMUDToolbar *inputToolbar;

// append received text
- (void) clearText;
- (void) appendText:(NSString *)text isUserInput:(BOOL)isUserInput speak:(BOOL)speak;
- (void) appendAttributedLineGroup:(SSAttributedLineGroup *)group speak:(BOOL)speak;

// sets whether our input bar is editable
@property (nonatomic, getter=isEditable) BOOL editable;

// history
- (void) addHistoryCommand:(NSString *)command;
- (void) purgeHistory;

// keyboard panning toggle
- (void) setKeyboardPanningEnabled:(BOOL)enabled;

// speech control
- (void) appendTTS:(NSString *)text;
- (void) stopSpeaking;
- (void) continueSpeaking;

@end

@protocol SSMudViewDelegate <TTTAttributedLabelDelegate, NSObject>

@required

// The user typed something and pressed enter.
- (void) mudView:(SSMudView *)mudView didReceiveUserCommand:(NSString *)command;

@optional

// A movement control has fired a command.
- (void) mudView:(SSMudView *)mudView moveControlDidMoveToDirection:(NSString *)direction;

// The user has scrolled the mud view a nontrivial amount; enough that a
// navbar show/hide may be triggered.
- (void) mudView:(SSMudView *)mudView scrollOffsetChangedSignificantlyInDirection:(BOOL)didScrollDown;

/**
 *  The user has created a trigger or gag from a line of text in the current world.
 *  Show an editor to finish creating the record.
 */
- (void) mudView:(SSMudView *)mudView shouldCreateRecordWithText:(NSString *)text type:(Class)recordType;

@end
