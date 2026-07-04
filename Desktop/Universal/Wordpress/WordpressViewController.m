//
// WordpressViewController.m
//
// Copyright (c) 2016 Sherdle. All rights reserved.
//


#import "WordpressViewController.h"
#import "AssistTableCell.h"
#import "AssistTableHeaderView.h"
#import "AssistTableFooterView.h"

#import "NSString+HTML.h"
#import "MWFeedParser.h"

#import "WordpressDetailViewController.h"
#import "SWRevealViewController.h"
#import "KILabel.h"
#import "AppDelegate.h"
#import "UITableView+FDTemplateLayoutCell.h"

#import "JSONProvider.h"
#import "JetPackProvider.h"
#import "RestProvider.h"

#define HEADERVIEW_HEIGHT 175
#define WORDPRESSCORRECTION false

@implementation WordpressViewController
@synthesize params;

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 166;
    
    [self.tableView addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    [self.tableView addGestureRecognizer: self.revealViewController.tapGestureRecognizer];
    
    if (WORDPRESSCORRECTION)
        page = -1;
    
    if ([params[0] containsString:@"http"] && [params[0] containsString:@"wp-json/wp/v2/"])
        provider = [RestProvider alloc];
    else if ([params[0] containsString:@"http"] )
        provider = [JSONProvider alloc];
    else
        provider = [JetPackProvider alloc];
    
    //Configure the search
    searchButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(searchClicked:)];
    self.navigationItem.rightBarButtonItem = searchButton;
    
    cancelButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"cancel", @"")
        style:UIBarButtonItemStylePlain
        target:self
        action:@selector(searchBarCancelButtonClicked:)];

    searchBar = [[UISearchBar alloc] init];
    searchBar.searchBarStyle = UISearchBarStyleDefault;
    searchBar.placeholder = NSLocalizedString(@"search", @"");
    //_searchBar.showsCancelButton = YES;
    searchBar.delegate = self;
    
    [self loadMore];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}


-(void) fetchData
{
    NSString *category = @"";
    if ([params count] > 1)
        category = params[1];
    
    NSString *strURl = [provider getUrl:params[0] forPage:page withCategory:category withSearch:query];
    NSLog(@"%@",strURl);
    
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithURL:[NSURL URLWithString:strURl]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                if (data == nil) {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil)message:NO_CONNECTION_TEXT preferredStyle:UIAlertControllerStyleAlert];
                    
                    UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil];
                    [alertController addAction:ok];
                    [self presentViewController:alertController animated:YES completion:nil];
                    
                    //Complete the refresh / load more operation visually
                    [self refreshCompleted];
                    [self loadMoreCompleted];
                    
                    return ;
                }
                else  {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        
                        if (!parsedItems){
                            parsedItems = [[NSMutableArray alloc]init];
                        }
                    
                        parsedItems = [provider parseJSON:data into:parsedItems withResponse:response];
                        int totalPage = [provider totalPages];
                            
                        dispatch_async(dispatch_get_main_queue(), ^{
                                
                                //Show the updated table
                                [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                                
                                //Check if we can load more
                                if (page >= totalPage)
                                    self.canLoadMore = NO;
                                else
                                    self.canLoadMore = YES;
                                
                                //Complete the refresh / load more operation visually
                                [self loadMoreCompleted];
                                [self refreshCompleted];
                                
                        });
                            
                    });
                    
                }

                
    }] resume];
    
}

#pragma mark Loading more and refreshing
- (void) pinHeaderView
{
    [super pinHeaderView];
    
    // do custom handling for the header view
    AssistTableHeaderView *hv = (AssistTableHeaderView *)self.headerView;
    [hv.activityIndicator startAnimating];
    hv.title.text = NSLocalizedString(@"loading_process", nil);
}

- (void) unpinHeaderView
{
    [super unpinHeaderView];
    
    // do custom handling for the header view
    [[(AssistTableHeaderView *)self.headerView activityIndicator] stopAnimating];
}

- (void) headerViewDidScroll:(BOOL)willRefreshOnRelease scrollView:(UIScrollView *)scrollView
{
    AssistTableHeaderView *hv = (AssistTableHeaderView *)self.headerView;
    if (willRefreshOnRelease)
        hv.title.text = NSLocalizedString(@"release_to_refresh", nil);
    else
        hv.title.text = NSLocalizedString(@"pull_to_refresh", nil);
}

- (BOOL) refresh
{
    if (![super refresh])
        return NO;
    
    [self performSelector:@selector(addItemsOnTop) withObject:nil];
    // See -addItemsOnTop for more info on how to finish loading
    return YES;
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
        // Do something if there are no more items to load
        
        // Just show a textual info that there are no more items to load
        fv.infoLabel.hidden = NO;
    }
}

- (BOOL) loadMore
{
    if (![super loadMore])
        return NO;
    
    // Do your async loading here
    [self addItemsOnBottom];
    // See -addItemsOnBottom for more info on what to do after loading more items
    
    return YES;
}

- (void) addItemsOnTop
{
    parsedItems = nil;
    page = 1;
    query = false;
    [self fetchData];
}

- (void) addItemsOnBottom
{
    page=page+1;
    if (page == 1 && WORDPRESSCORRECTION){
        page = 2;
    }
    
    [self fetchData];
}

#pragma mark TableView
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return parsedItems.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AssistTableCell *cell;
    
    if (indexPath.row == 0 && [[[parsedItems objectAtIndex:indexPath.row] valueForKey:@"mediaUrl"] length] != 0){
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"HeaderCell" forIndexPath:indexPath];
        [self configureHeaderCell:cell atIndexPath:indexPath];
    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
        [self configureCell:cell atIndexPath:indexPath];
    }
    
    return cell;
}

- (void)configureHeaderCell:(AssistTableCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSString *url = [[parsedItems objectAtIndex:indexPath.row]valueForKey:@"mediaUrl"];
    [cell.image sd_setImageWithURL:[NSURL URLWithString:url]
                  placeholderImage:[UIImage imageNamed:@"default_placeholder"] options:indexPath.row == 0 ? SDWebImageRefreshCached : 0];
    
    cell.lblHeadTitle.text = [[[parsedItems objectAtIndex:indexPath.row]valueForKey:@"title"] stringByDecodingHTMLEntities];
}

- (void)configureCell:(AssistTableCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSString *title = [[[parsedItems objectAtIndex:indexPath.row]valueForKey:@"title"] stringByDecodingHTMLEntities];
    NSString *summary = [[parsedItems objectAtIndex:indexPath.row]valueForKey:@"excerpt"];
    NSString *date = [[parsedItems objectAtIndex:indexPath.row]valueForKey:@"date"];
    
    cell.lblTitle.text = title;
    
    NSString *itemSummary = [summary stringByConvertingHTMLToPlainText] ;
    cell.lblSummary.text = itemSummary;
    
    if (date) {
        cell.lblDate.text = date;
    }
    
    if ([[[parsedItems objectAtIndex:indexPath.row]valueForKey:@"thumbUrl"] length] > 0){
        [cell setNoImage:NO];
        
        NSString *url = [[parsedItems objectAtIndex:indexPath.row]valueForKey:@"thumbUrl"];
        [cell.image sd_setImageWithURL:[NSURL URLWithString:url]
                      placeholderImage:[UIImage imageNamed:@"default_placeholder"] options:indexPath.row == 0 ? SDWebImageRefreshCached : 0];
    } else {
        [cell setNoImage:YES];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showDetails"]) {
        NSArray *item = sender;
        
        WordpressDetailViewController *detailVC = (WordpressDetailViewController *)segue.destinationViewController;
        detailVC.titleText = [item valueForKey:@"title"];
        detailVC.detailID = [item valueForKey:@"id"];
        detailVC.articleUrl = [item valueForKey:@"url"];
        detailVC.date = [item valueForKey:@"date"];
        detailVC.html = [item valueForKey:@"excerpt"];
        detailVC.author = [item valueForKey:@"author"];
        detailVC.imageUrl = [item valueForKey:@"mediaUrl"];
        detailVC.isJSONAPI = ([provider isKindOfClass:[JSONProvider class]]);
        
        detailVC.apiConfig = params;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSArray *item = [parsedItems objectAtIndex:indexPath.row];
    // this check prevents the bug where parsedItems is nil for a second after the pull-down refresh
    if (item) {
        [self performSegueWithIdentifier:@"showDetails" sender:item];
    }
    
    // Deselect
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Searchbar
- (IBAction)searchClicked:(id)sender {
    
    [self setPullToRefreshEnabled:false];
    AssistTableFooterView *fv = (AssistTableFooterView *)self.tableView.tableFooterView;
    fv.infoLabel.hidden = YES;
    
    //Hiding the search button
    [searchButton setEnabled:NO];
    [searchButton setTintColor: [UIColor clearColor]];

    //Show the cancel button
    self.navigationItem.rightBarButtonItem = cancelButton;
    [cancelButton setTintColor: nil];
        
    //Show the search bar (which will start out hidden).
    self.navigationItem.titleView = searchBar;
    searchBar.alpha = 0.0;
        
    [UIView animateWithDuration:0.2 animations:^{
        searchBar.alpha = 1.0;
    } completion:^(BOOL finished) { }];
    
    [searchBar becomeFirstResponder];
    
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBarSource {
    [self willBeginLoadingMore];
    
    [searchBar resignFirstResponder];
    
    //Reset results and perform queries
    parsedItems = nil;
    page = 1;
    query = [searchBar.text stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    
    [self fetchData];
    
    [self.tableView reloadData];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBarSource {

    [self setPullToRefreshEnabled:true];
    
    //Hide the Search bar
    [UIView animateWithDuration:0.1 animations:^{
        searchBar.alpha = 0.0;
        [cancelButton setTintColor: [UIColor clearColor]];
        
    } completion:^(BOOL finished) {
         //Show the default layout
        self.navigationItem.titleView = nil;
        self.navigationItem.rightBarButtonItem = searchButton;
        [UIView animateWithDuration:0.1 animations:^{
            [searchButton setEnabled:YES];
            [searchButton setTintColor: nil];

         } completion:^(BOOL finished) {}];
    }];
    
    [self willBeginLoadingMore];
    
    //Reset results and load default
    parsedItems = nil;
    page = 1;
    query = false;
    [self fetchData];
    
    [self.tableView reloadData];
}

- (void)dealloc
{
    if ([self isViewLoaded])
    {
        self.tableView.delegate = nil;
        self.tableView.dataSource = nil;
    }
}

@end
