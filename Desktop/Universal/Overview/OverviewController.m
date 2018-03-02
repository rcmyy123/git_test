//
//  OverviewController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//
//

#import "OverviewController.h"
#import "NSString+HTML.h"
#import "AssistTableCell.h"
#import "AssistTableHeaderView.h"
#import "AssistTableFooterView.h"
#import "FrontNavigationController.h"
#import "SWRevealViewController.h"
#import "AppDelegate.h"
#import "ConfigParser.h"
#import "Tab.h"

@implementation OverviewController

@synthesize params;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;

    [self.tableView addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    [self.tableView addGestureRecognizer: self.revealViewController.tapGestureRecognizer];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"OverviewCell" bundle:nil] forCellReuseIdentifier:@"OverviewCell"];
    
    self.itemsToDisplay = [NSArray array];
    
    ((AssistTableHeaderView *)self.headerView).title.text = @"";
    
    NSString *overview = params[0];
    ConfigParser * configParser = [[ConfigParser alloc] init];
    configParser.delegate = self;
    [configParser parseOverview:overview];
    
    loadedImages = [NSMutableSet new];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

- (void) pinHeaderView
{
    [super pinHeaderView];
    
    // do custom handling for the header view
    //AssistTableHeaderView *hv = (AssistTableHeaderView *)self.headerView;
    //[hv.activityIndicator startAnimating];
    //hv.title.text = NSLocalizedString(@"loading_process", nil);
}

- (void) unpinHeaderView
{
    [super unpinHeaderView];
    
    // do custom handling for the header view
    [[(AssistTableHeaderView *)self.headerView activityIndicator] stopAnimating];
}



// Reset and reparse
- (BOOL)refresh {
    return NO;
}

- (void) willBeginLoadingMore
{
    AssistTableFooterView *fv = (AssistTableFooterView *)self.tableView.tableFooterView;
    [fv.activityIndicator startAnimating];
}

- (void) loadMoreCompleted
{
    [super loadMoreCompleted];
    
    AssistTableFooterView *fv = (AssistTableFooterView *)self.tableView.tableFooterView;
    [fv.activityIndicator stopAnimating];
    
    if (!self.canLoadMore) {
        fv.infoLabel.hidden = YES;
    }
}

- (void)updateTableWithParsedItems {
    self.canLoadMore = NO;
    [self refreshCompleted];
    [self loadMoreCompleted];
    [self.tableView reloadData];
    self.tableView.userInteractionEnabled = YES;
}

#pragma mark - MWFeedParserDelegate

- (void)parseSuccess:(NSMutableArray *)result {
    if (result.count == 0) {
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil)message:NO_CONNECTION_TEXT preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        
        [self refreshCompleted];
        [self loadMoreCompleted];
        
    } else {
        self.itemsToDisplay = result;
        [self updateTableWithParsedItems];
    }
}

- (void)parseFailed:(NSError *)error {
    NSLog(@"Error: %@", error);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil)message:NO_CONNECTION_TEXT preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil];
    [alertController addAction:ok];
    [self presentViewController:alertController animated:YES completion:nil];
    
    [self refreshCompleted];
    [self loadMoreCompleted];

}

#pragma mark - Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.itemsToDisplay.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    CGFloat height = [tableView fd_heightForCellWithIdentifier:@"OverviewCell" cacheByIndexPath:indexPath configuration:^(id cell) {
        [self configureCell:cell atIndexPath:indexPath];
    }];
    
    return height;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"OverviewCell";
    CardCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(CardCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    // Configure the cell.
    Tab *item = [self.itemsToDisplay objectAtIndex:indexPath.row];
    if (item) {
        
        cell.caption.text = item.name;
        
        if (item.icon != nil){
            [cell.photoView  sd_setImageWithURL:[NSURL URLWithString:item.icon]
                               placeholderImage:[UIImage imageNamed:@"default_placeholder"] options:(indexPath.row == 0 ? SDWebImageRefreshCached : 0) completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                                   [self webImageLoadedForCell:cell atIndexPath:indexPath];
                               }];
            cell.photoView.hidden = NO;
            [cell updateImageAspectRatio];
        } else {
            cell.photoView.hidden = YES;
        }
        
    }

}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Tab *item = [self.itemsToDisplay objectAtIndex:indexPath.row];
    UIViewController *controller = [FrontNavigationController createViewController:item withStoryboard:self.storyboard];
    
    [self.navigationController pushViewController:controller animated:YES];
}

@end
