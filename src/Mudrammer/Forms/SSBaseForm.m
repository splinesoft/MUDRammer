//
//  SSBaseForm.m
//  MUDRammer
//
//  Created by Jonathan Hersh on 5/23/13.
//  Copyright (c) 2013 Zumper. All rights reserved.
//

#import "SSBaseForm.h"
#import "SSQuickDialogController.h"
#import <QuickDialog.h>
#import <QPickerElement.h>
#import "SSFormAppearance.h"

@implementation SSBaseForm

- (instancetype)init {
  if( ( self = [super init] ) ) {
    self.appearance = [SSFormAppearance appearance];
    self.grouped = YES;
    _shouldFocusFirstTextFieldOnLoad = NO;
  }

  return self;
}

#pragma mark - form elements

- (QEntryElement *)firstTextField {
  for( NSUInteger section = 0; section < [self.sections count]; section++ ) {
    QSection *sec = self.sections[section];

    for( NSUInteger element = 0; element < [sec.elements count]; element++ ) {
      QElement *currentElement = sec.elements[element];

      if( ( [currentElement isKindOfClass:[QEntryElement class]]
            && ![currentElement isKindOfClass:[QPickerElement class]] ) )
        return (QEntryElement *)currentElement;
    }
  }

  return nil;
}

@end
