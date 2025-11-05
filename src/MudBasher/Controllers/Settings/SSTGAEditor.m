//
//  SSTGAEditor.m
//  Mudrammer
//
//  Created by Jonathan Hersh on 1/5/13.
//  Copyright (c) 2013 Jonathan Hersh. All rights reserved.
//

#import "SSTGAEditor.h"

#import "SSSoundPickerViewController.h"
#import "JSQSystemSoundPlayer+SSAdditions.h"

#import "SSTriggerForm.h"
#import "SSAliasForm.h"
#import "SSGagForm.h"

#import "SPLAlerts.h"

@interface SSTGAEditor ()
- (SSTGAEditor *) initWithWorld:(NSManagedObjectID *)w record:(NSManagedObjectID *)rec parentContext:(NSManagedObjectContext *)context;

- (void) cancelEditing:(id)sender;
- (void) saveEditing:(id)sender;

@property (nonatomic, strong) SSMagicManagedObject *record;
@end

@implementation SSTGAEditor
{
    World *currentWorld;

    UIBarButtonItem *saveButton;

    NSManagedObjectContext *editContext;
}

- (SSTGAEditor *) initWithWorld:(NSManagedObjectID *)w record:(NSManagedObjectID *)recId parentContext:(NSManagedObjectContext *)parentContext {

    NSManagedObjectContext *context = [NSManagedObjectContext MR_contextWithParent:parentContext];
    World *world = [World existingObjectWithId:w inContext:context];
    SSMagicManagedObject *rec = [SSMagicManagedObject existingObjectWithId:recId
                                                                 inContext:context];

    SSBaseForm *form;

    if( [rec isKindOfClass:[Trigger class]] )
        form = [SSTriggerForm formForTrigger:(Trigger *)rec];
    else if( [rec isKindOfClass:[Alias class]] )
        form = [SSAliasForm formForAlias:(Alias *)rec];
    else if( [rec isKindOfClass:[Gag class]] )
        form = [SSGagForm formForGag:(Gag *)rec];

    if ((self = [self initWithRoot:form])) {
        editContext = context;
        currentWorld = world;
        _record = rec;

        [SSThemes configureTable:self.quickDialogTableView];

        saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                   target:self
                                                                   action:@selector(saveEditing:)];

        self.navigationItem.rightBarButtonItem = saveButton;
    }

    return self;
}

+ (instancetype)editorForRecord:(NSManagedObjectID *)record inWorld:(NSManagedObjectID *)world parentContext:(NSManagedObjectContext *)parentContext {
    return [[SSTGAEditor alloc] initWithWorld:world
                                       record:record
                                parentContext:parentContext];
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if(![[UIDevice currentDevice] isIPad] || self.navigationController.SPLNavigationIsAtRoot) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                              target:self
                                                                                              action:@selector(cancelEditing:)];
    }
}

#pragma mark - actions

- (void)showSoundPicker {
    SSSoundPickerViewController *picker = [SSSoundPickerViewController new];
    picker.selectedFileName = ((Trigger *)_record).soundFileName;

    @weakify(self);
    picker.selectedBlock = ^(NSString *str) {
        @strongify(self);

        // Manual bind because it's not an entry element?
        [self.record setValue:str forKey:@"soundFileName"];

        QLabelElement *element = (QLabelElement *)[self.root elementWithKey:kSoundElement];

        SSSound *newSound = [JSQSystemSoundPlayer soundForFileName:str];

        element.value = (newSound
                         ? newSound.soundName
                         : @"None");

        [self.quickDialogTableView reloadCellForElements:element, nil];
    };

    [self.navigationController pushViewController:picker
                                         animated:YES];
}

- (void)deleteCurrentRecord {
    [self.quickDialogTableView endEditing:YES];

    @weakify(self);
    NSString *title;

    if( [_record isKindOfClass:[Trigger class]] )
        title = NSLocalizedString(@"DELETE_TRIGGER", nil);
    else if( [_record isKindOfClass:[Alias class]] )
        title = NSLocalizedString(@"DELETE_ALIAS", nil);
    else if( [_record isKindOfClass:[Gag class]] )
        title = NSLocalizedString(@"DELETE_GAG", nil);

    [SPLAlerts SPLShowActionViewWithTitle:nil
                              cancelTitle:NSLocalizedString(@"CANCEL", @"Cancel")
                              cancelBlock:nil
                         destructiveTitle:title
                         destructiveBlock:^{
                             @strongify(self);
                             [self.record deleteObject];
                             [self.record saveObjectWithCompletion:^{
                                 [self.navigationController popViewControllerAnimated:YES];
                             } fail:nil];
                         }
                            barButtonItem:nil
                               sourceView:self.quickDialogTableView
                               sourceRect:self.quickDialogTableView.frame];
}

- (void)SPLDismiss {
    [self.quickDialogTableView endEditing:YES];

    if (self.navigationController.SPLNavigationIsAtRoot) {
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    } else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

- (void)cancelEditing:(id)sender {
    [self SPLDismiss];
}

- (void)saveEditing:(id)sender {
    [self.quickDialogTableView endEditing:YES];

    [self.root fetchValueIntoObject:_record];

    if( ![_record canSave] )
        return;

    _record.isHidden = @(NO);
    [_record setValue:currentWorld forKey:@"world"];

    [_record saveObjectWithCompletion:^{
        [self SPLDismiss];
    } fail:nil];
}

#pragma mark - lifecycle

- (CGSize)preferredContentSize {
    return [self.quickDialogTableView sizeThatFits:CGSizeMake(320.f, CGFLOAT_MAX)];
}

@end
