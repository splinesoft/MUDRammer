//
//  SSWorldEditViewController.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 10/27/12.
//  Copyright (c) 2012 Jonathan Hersh. All rights reserved.
//

@import UIKit;
#import "SSWorldEditViewController.h"
#import "SSTGAEditor.h"
#import "SSWorldForm.h"
#import "SPLTickerForm.h"
#import "SPLFXWorldEditor.h"

@interface SSWorldEditViewController ()
- (SSWorldEditViewController *) initWithWorld:(NSManagedObjectID *)w;

- (void) saveWorld:(id)sender;
- (void) cancelEditing:(id)sender;
@end

@implementation SSWorldEditViewController
{
    World *currentWorld;

    UIBarButtonItem *saveButton;

    NSManagedObjectContext *editContext;
}

- (SSWorldEditViewController *) initWithWorld:(NSManagedObjectID *)w {

    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextWithParent:[NSManagedObjectContext MR_defaultContext]];
    World *world = [World existingObjectWithId:w inContext:context];

    if( ( self = [self initWithRoot:[SSWorldForm formForWorld:world]] ) ) {
        editContext = context;
        currentWorld = world;

        [SSThemes configureTable:self.quickDialogTableView];

        saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                   target:self
                                                                   action:@selector(saveWorld:)];

        if( ![[UIDevice currentDevice] isIPad] ) {
            self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                                  target:self
                                                                                                  action:@selector(cancelEditing:)];
        }

        self.navigationItem.rightBarButtonItem = saveButton;
    }

    return self;
}

+ (instancetype)editorForWorld:(NSManagedObjectID *)world {
    return [[SSWorldEditViewController alloc] initWithWorld:world];
}

- (CGSize)preferredContentSize {
    return [self.quickDialogTableView sizeThatFits:CGSizeMake(320.0f, CGFLOAT_MAX)];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [(SSWorldForm *)self.root refreshWorldFormForController:self];
    [self.quickDialogTableView reloadData];
    self.title = self.root.title;
}

- (void)dealloc {
    _saveCompletionBlock = nil;
}

#pragma mark - saving

- (void)cancelEditing:(id)sender {
    if( self.saveCompletionBlock )
        self.saveCompletionBlock(NO);
    else
        [self.navigationController popViewControllerAnimated:YES];
}

- (void)saveWorld:(id)sender {
    [self.quickDialogTableView endEditing:YES];

    [self.root fetchValueIntoObject:currentWorld];

    // hostname parsing
    currentWorld.hostname = [World cleanedHostNameForWorldWithHost:currentWorld.hostname];

    if( ![currentWorld canSave] )
        return;

    currentWorld.isHidden = @(NO);
    [currentWorld saveObjectWithCompletion:^{
        if( self.saveCompletionBlock )
            self.saveCompletionBlock(YES);
        else
            [self.navigationController popViewControllerAnimated:YES];
    } fail:nil];;
}

#pragma mark - Form actions

- (void)newTrigger {
    [Trigger createObjectWithCompletion:^(NSManagedObjectID *objectId) {
        [self.navigationController pushViewController:
         [SSTGAEditor editorForRecord:objectId
                              inWorld:[currentWorld objectID]
                        parentContext:editContext]
                                                 animated:YES];
    }];
}

- (void)newAlias {
    [Alias createObjectWithCompletion:^(NSManagedObjectID *objectId) {
        [self.navigationController pushViewController:
         [SSTGAEditor editorForRecord:objectId
                              inWorld:[currentWorld objectID]
                        parentContext:editContext]
                                             animated:YES];
    }];
}

- (void)newGag {
    [Gag createObjectWithCompletion:^(NSManagedObjectID *objectId) {
        [self.navigationController pushViewController:
         [SSTGAEditor editorForRecord:objectId
                              inWorld:[currentWorld objectID]
                        parentContext:editContext]
                                             animated:YES];
    }];
}

- (void)newTicker {
    [Ticker createObjectWithCompletion:^(NSManagedObjectID *objectId) {
        [self.navigationController pushViewController:
         [SPLFXWorldEditor editorForRecord:objectId
                                   inWorld:[currentWorld objectID]
                             parentContext:editContext]
                                             animated:YES];
    }];
}

- (void)deepClone {
    [currentWorld deepCloneWithCompletion:nil];
    if (self.saveCompletionBlock) {
        self.saveCompletionBlock(YES);
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)editRecord:(NSManagedObjectID *)TGARecordId {
    UIViewController *editor;

    if ([TGARecordId.entity isEqual:[Ticker MR_entityDescription]]) {
        editor = [SPLFXWorldEditor editorForRecord:TGARecordId
                                           inWorld:[currentWorld objectID]
                                     parentContext:editContext];
    } else {
        editor = [SSTGAEditor editorForRecord:TGARecordId
                                      inWorld:[currentWorld objectID]
                                parentContext:editContext];
    }

    [self.navigationController pushViewController:editor
                                         animated:YES];
}

@end
