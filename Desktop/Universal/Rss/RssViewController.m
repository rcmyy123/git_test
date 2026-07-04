//
//  RssViewController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//
//  Implements: MWFeedParser
//  Copyright (c) 2010 Michael Waterfall
//

#import "RssViewController.h"
#import "NSString+HTML.h"
#import "MWFeedParser.h"
#import "RssDetailViewController.h"
#import "AssistTableCell.h"
#import "AssistTableHeaderView.h"
#import "AssistTableFooterView.h"
#import "SWRevealViewController.h"
#import "AppDelegate.h"

@implementation RssViewController

@synthesize itemsToDisplay,params;

#pragma mark - View lifecycle

- (void)viewDidLoad {
    
    // Super
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 166;

    
    [self.tableView addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    [self.tableView addGestureRecognizer: self.revealViewController.tapGestureRecognizer];
    
    formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    parsedItems = [[NSMutableArray alloc] init];
    self.itemsToDisplay = [NSArray array];
    
    NSURL *feedURL = [NSURL URLWithString:params[0]];
    
    feedParser = [[MWFeedParser alloc] initWithFeedURL:feedURL];
    feedParser.delegate = self;
    feedParser.feedParseType = ParseTypeFull; // Parse feed info and all items
    feedParser.connectionType = ConnectionTypeAsynchronously;
    [feedParser parse];
    
    [self loadMore];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
}

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

// Reset and reparse
- (BOOL)refresh {
    if (![super refresh])
        return NO;
    
    self.tableView.userInteractionEnabled = NO;
    [parsedItems removeAllObjects];
    [feedParser stopParsing];
    [feedParser parse];
    //self.tableView.alpha = 0.3;
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
        fv.infoLabel.hidden = YES;
    }
}

- (void)updateTableWithParsedItems {
    self.itemsToDisplay = parsedItems ;//sortedArrayUsingDescriptors: [NSArray arrayWithObject:[[NSSortDescriptor alloc] initWithKey:@"date" ascending:NO]]];
    //self.tableView.alpha = 1;
    self.canLoadMore = NO;
    [self refreshCompleted];
    [self loadMoreCompleted];
    [self.tableView reloadData];
    self.tableView.userInteractionEnabled = YES;
}

#pragma mark - MWFeedParserDelegate

- (void)feedParserDidStart:(MWFeedParser *)parser {
    //NSLog(@"Started Parsing: %@", parser.url);
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedInfo:(MWFeedInfo *)info {
    // NSLog(@"Parsed Feed Info: “%@”", info.title);
    //self.title = info.title; //if you want the title to be the feed title unquote
}

- (void)feedParser:(MWFeedParser *)parser didParseFeedItem:(MWFeedItem *)item {
   // NSLog(@"Parsed Feed Item: “%@”", item.title);
    if (item) [parsedItems addObject:item];
}

- (void)feedParserDidFinish:(MWFeedParser *)parser {
   // NSLog(@"Finished Parsing%@", (parser.stopped ? @" (Stopped)" : @""));
    [self updateTableWithParsedItems];
}

- (void)feedParser:(MWFeedParser *)parser didFailWithError:(NSError *)error {
    NSLog(@"Finished Parsing With Error: %@", error);
    if (parsedItems.count == 0) {
        //self.title = @"Failed"; // Show failed message in title
        
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil)message:NO_CONNECTION_TEXT preferredStyle:UIAlertControllerStyleAlert];
            
        UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
        
        [self refreshCompleted];
        [self loadMoreCompleted];
        
    } else {
        UIAlertController *alertController = [UIAlertController    alertControllerWithTitle:NSLocalizedString(@"parse_incomplete_title", nil) message:NSLocalizedString(@"parse_incomplete_message", nil) preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"parse_incomplete_button", nil)
                                                     style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        
        [self presentViewController:alertController animated:YES completion:nil];
        
        [self updateTableWithParsedItems];
    }
    //[self updateTableWithParsedItems];
}

#pragma mark - Table view data source

// Customize the number of sections in the table view.
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

// Customize the number of rows in the table view.
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return itemsToDisplay.count;
}

// Customize the appearance of table view cells.
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    AssistTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];

    if (indexPath.row >= itemsToDisplay.count) {
        NSLog(@"Row requested for inexistent array element %ld, when there are %lud itemsToDisplay", (long)indexPath.row, (long) itemsToDisplay.count);
        return cell;
    }
    
    // Configure the cell.
    MWFeedItem *item = [itemsToDisplay objectAtIndex:indexPath.row];
    if (item) {
        NSString *itemTitle = item.title ? [item.title stringByConvertingHTMLToPlainText] : @"[No Title]";
        NSString *itemSummary = item.summary ? [item.summary stringByConvertingHTMLToPlainText] : @"[No Summary]";
        
        cell.lblTitle.text = itemTitle;
        cell.lblSummary.text = itemSummary;
        
        if (item.date) {
            NSString *date = [NSString stringWithFormat:@"%@",item.date];
            cell.lblDate.text = date;
        }
        

        if (item.media) {
            [cell setNoImage:NO]; 
            [cell.image sd_setImageWithURL:[NSURL URLWithString:item.media]
                     placeholderImage:[UIImage imageNamed:@"placeholder"] options:indexPath.row == 0 ? SDWebImageRefreshCached : 0];
        } else {
            [cell setNoImage:YES];
        }
        
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showDetails"]) {
        NSIndexPath *indexPath = sender;
        RssDetailViewController *detailView = (RssDetailViewController *)segue.destinationViewController;
        detailView.item = (MWFeedItem *)[itemsToDisplay objectAtIndex:indexPath.row];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"showDetails" sender:indexPath];
    
    // Deselect
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
