//
//  CMFontSelectTableViewController.m
//  CMTextStylePicker
//
//  Created by Chris Miles on 20/10/10.
//  Copyright (c) Chris Miles 2010.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import "CMFontSelectTableViewController.h"

#define kSelectedLabelTag		1001
#define kFontNameLabelTag		1002

@implementation CMFontSelectTableViewController

@synthesize fontFamilyNames, selectedFont;


#pragma mark -
#pragma mark FontStyleSelectTableViewControllerDelegate methods

- (void)fontStyleSelectTableViewController:(CMFontStyleSelectTableViewController *)fontStyleSelectTableViewController didSelectFont:(UIFont *)font {
	self.selectedFont = font;

    id del = self.delegate;
	[del fontSelectTableViewController:self didSelectFont:self.selectedFont];
	[self.tableView reloadData];
}


#pragma mark -
#pragma mark View lifecycle

- (void)loadView {
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.delegate = self;
    tableView.dataSource = self;
    self.view = tableView;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if( !self.fontFamilyNames )
        self.fontFamilyNames = [[UIFont familyNames] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
    else
        self.fontFamilyNames = [self.fontFamilyNames sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];

    [SSThemes configureTable:self.tableView];
}

- (CGSize)preferredContentSize {
    return [self.tableView sizeThatFits:CGSizeMake(320.0f, CGFLOAT_MAX)];
}

#pragma mark -
#pragma mark Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // Return the number of rows in the section.
    return (NSInteger)[self.fontFamilyNames count];
}


// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *CellIdentifier = @"FontSelectTableCell";

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];

		CGRect frame = CGRectMake(10.0, 0.0, 25.0, cell.contentView.frame.size.height);
		UILabel *selectedLabel = [[UILabel alloc] initWithFrame:frame];
		selectedLabel.tag = kSelectedLabelTag;
		selectedLabel.font = [UIFont systemFontOfSize:24.0];
        selectedLabel.backgroundColor = [UIColor clearColor];
        selectedLabel.textColor = [[SSThemes sharedThemer] valueForThemeKey:kThemeFontColor];
		[cell.contentView addSubview:selectedLabel];

		frame = CGRectMake(35.0, 0.0, cell.frame.size.width-70.0f, cell.frame.size.height);
		UILabel *fontNameLabel = [[UILabel alloc] initWithFrame:frame];
        fontNameLabel.backgroundColor = [UIColor clearColor];
        fontNameLabel.adjustsFontSizeToFitWidth = YES;
        fontNameLabel.textColor = [[SSThemes sharedThemer] valueForThemeKey:kThemeFontColor];
		fontNameLabel.tag = kFontNameLabelTag;
		[cell.contentView addSubview:fontNameLabel];
    }

    // Configure the cell...
	NSString *fontFamilyName = (self.fontFamilyNames)[(NSUInteger)indexPath.row];

	UILabel *fontNameLabel = (UILabel *)[cell viewWithTag:kFontNameLabelTag];

	fontNameLabel.text = fontFamilyName;
	fontNameLabel.font = [UIFont fontWithName:fontFamilyName size:18.0];

	if ([[UIFont fontNamesForFamilyName:fontFamilyName] count] > 1) {
		cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
	}
	else {
		cell.accessoryType = UITableViewCellAccessoryNone;
	}

	UILabel *selectedLabel = (UILabel *)[cell viewWithTag:kSelectedLabelTag];
	if ([self.selectedFont.familyName isEqualToString:fontFamilyName] || [self.selectedFont.fontName isEqualToString:fontFamilyName]) {
		selectedLabel.text = @"✓";
	}
	else {
		selectedLabel.text = @"";
	}

    [SSThemes configureCell:cell];

    return cell;
}

#pragma mark -
#pragma mark UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath {
	CMFontStyleSelectTableViewController *fontStyleSelectTableViewController = [CMFontStyleSelectTableViewController new];
	fontStyleSelectTableViewController.fontFamilyName = (self.fontFamilyNames)[(NSUInteger)indexPath.row];
	fontStyleSelectTableViewController.selectedFont = self.selectedFont;
	fontStyleSelectTableViewController.delegate = self;
    fontStyleSelectTableViewController.title = (self.fontFamilyNames)[(NSUInteger)indexPath.row];
	[self.navigationController pushViewController:fontStyleSelectTableViewController animated:YES];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSUInteger currentRow = [self.fontFamilyNames indexOfObject:self.selectedFont.familyName];

    if (currentRow == NSNotFound) {
        currentRow = [self.fontFamilyNames indexOfObject:self.selectedFont.fontName];
    }

    if (currentRow == (NSUInteger)indexPath.row) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }

	NSString *fontName = (self.fontFamilyNames)[(NSUInteger)indexPath.row];
	self.selectedFont = [UIFont fontWithName:fontName size:self.selectedFont.pointSize];

    id del = self.delegate;
	[del fontSelectTableViewController:self didSelectFont:self.selectedFont];

    NSMutableArray *toReload = [NSMutableArray arrayWithObject:indexPath];

    if( currentRow != NSNotFound )
        [toReload addObject:[NSIndexPath indexPathForRow:(NSInteger)currentRow inSection:0]];

    [tableView reloadRowsAtIndexPaths:toReload
                     withRowAnimation:UITableViewRowAnimationFade];
}


#pragma mark -
#pragma mark Memory management

- (void)didReceiveMemoryWarning {
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

    // Relinquish ownership any cached data, images, etc that aren't in use.
}

@end

