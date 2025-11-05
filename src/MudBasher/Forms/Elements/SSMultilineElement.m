//
//  SSMultilineElement.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 9/20/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSMultilineElement.h"
#import <QuickDialog.h>
#import <QTableViewCell.h>
#import <QEntryTableViewCell.h>

@implementation SSMultilineElement

- (UITableViewCell *)getCellForTableView:(QuickDialogTableView *)tableView controller:(QuickDialogController *)controller {
    QEntryTableViewCell *cell = (QEntryTableViewCell *) [super getCellForTableView:tableView controller:controller];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.selectionStyle = self.enabled ? UITableViewCellSelectionStyleGray : UITableViewCellSelectionStyleNone;
    cell.textField.enabled = NO;
    cell.textField.textAlignment = NSTextAlignmentRight;

    return cell;
}

- (void)selected:(QuickDialogTableView *)tableView
      controller:(QuickDialogController *)controller
       indexPath:(NSIndexPath *)indexPath {
    QMultilineTextViewController *textController = [[QMultilineTextViewController alloc] initWithTitle:self.title];
    SSThemes *themer = [SSThemes sharedThemer];

    textController.entryElement = self;
    textController.entryCell = (QEntryTableViewCell *) [tableView cellForElement:self];
    textController.resizeWhenKeyboardPresented = YES;
    textController.textView.text = self.textValue;
    textController.textView.autocapitalizationType = self.autocapitalizationType;
    textController.textView.autocorrectionType = self.autocorrectionType;
    textController.textView.keyboardAppearance = self.keyboardAppearance;
    textController.textView.keyboardType = self.keyboardType;
    textController.textView.secureTextEntry = self.secureTextEntry;
    textController.textView.autocapitalizationType = self.autocapitalizationType;
    textController.textView.returnKeyType = self.returnKeyType;
    textController.textView.editable = self.enabled;

    // SS
    textController.edgesForExtendedLayout = UIRectEdgeNone;
    textController.textView.backgroundColor = [themer valueForThemeKey:kThemeBackgroundColor];
    textController.textView.font = themer.currentFont;
    textController.textView.textColor = [themer valueForThemeKey:kThemeFontColor];

    @weakify(self,tableView,textController);
    textController.willDisappearCallback = ^{
        @strongify(self,tableView,textController);
        self.textValue = textController.textView.text;
        [tableView reloadCellForElements:self, nil];
    };
    [controller displayViewController:textController withPresentationMode:self.presentationMode];
}

@end
