//
//  SSQuickDialogController.m
//  MUDRammer
//
//  Created by Jonathan Hersh on 4/16/13.
//  Copyright (c) 2013 Zumper. All rights reserved.
//

#import "SSQuickDialogController.h"
#import "SSBaseForm.h"

@implementation SSQuickDialogController {
    BOOL hasFocusedAField;
}

- (instancetype)initWithRoot:(QRootElement *)rootElement {
  if( ( self = [super initWithRoot:rootElement] ) ) {
      _focusesFirstTextFieldOnLoad = NO;
      hasFocusedAField = NO;

      [rootElement.sections bk_each:^(QSection *section) {
          [section.elements bk_each:^(QElement *element) {
              if ([element isKindOfClass:[QEntryElement class]]) {
                  ((QEntryElement *)element).delegate = self;
              }
          }];
      }];
  }

  return self;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    if( hasFocusedAField )
        return;

    if( [self.root isKindOfClass:[SSBaseForm class]]
       && [(SSBaseForm *)self.root shouldFocusFirstTextFieldOnLoad] ) {
      QElement *firstTextField = [(SSBaseForm *)self.root firstTextField];

    if( firstTextField ) {
        hasFocusedAField = YES;
        QEntryTableViewCell *cell = (QEntryTableViewCell *)[self.quickDialogTableView
                                                            cellForElement:firstTextField];

        if( cell )
          [cell.textField becomeFirstResponder];
      }
    }
}

#pragma mark - QuickDialogEntryElementDelegate

- (void)QEntryDidEndEditingElement:(QEntryElement *)element andCell:(QEntryTableViewCell *)cell {
    element.textValue = [element.textValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    [self.quickDialogTableView reloadCellForElements:element, nil];
}

@end
