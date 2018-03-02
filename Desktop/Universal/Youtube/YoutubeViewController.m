//
// AssistTableViewController.m
//
// Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "YoutubeViewController.h"
#import "AssistTableCell.h"
#import "AssistTableHeaderView.h"
#import "AssistTableFooterView.h"

#import "NSString+HTML.h"
#import "MWFeedParser.h"
#import "KILabel.h"
#import "SWRevealViewController.h"
#import "FrontNavigationController.h"

#import "YoutubeDetailViewController.h"
#import "AppDelegate.h"

#define HEADERVIEW_HEIGHT 175
#define PER_PAGE 20

@interface YoutubeViewController ()
// Private helper methods
- (void) addItemsOnTop;
- (void) addItemsOnBottom;

@end

@implementation YoutubeViewController

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 82;
    
    formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    [self.tableView addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    [self.tableView addGestureRecognizer: self.revealViewController.tapGestureRecognizer];
    
    // add the items
    //[self fetchdata];
    
    ////Configure the search
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

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    if (parsedItems == nil) {
        parsedItems = [[NSMutableArray alloc] init];
    }
}

-(void)fetchdata {
    //todo: verify (in addtion; can first condition be removed?
    if (pageToken == nil || [pageToken isEqualToString:@""]) {
        pageToken = @"";
    }
    
    if (parsedItems == nil) {
        parsedItems = [[NSMutableArray alloc]init];
    }
    
    NSString *str;
    
    if (query) {
        NSString *readyQuery = [query stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        str=[NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/search?part=snippet&type=video&channelId=%@&q=%@&maxResults=%i&key=%@&pageToken=%@", _params[1], readyQuery, PER_PAGE, YOUTUBE_CONTENT_KEY, pageToken];
    }  else {
        str=[NSString stringWithFormat:@"https://www.googleapis.com/youtube/v3/playlistItems?part=snippet&playlistId=%@&maxResults=%i&key=%@&pageToken=%@",_params[0], PER_PAGE ,YOUTUBE_CONTENT_KEY,pageToken];
    }
    
    NSLog(@"Request URI: %@", str);
    
    NSURL *url = [[NSURL alloc]initWithString:str];
    
        
    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]
                                                          delegate:nil
                                                     delegateQueue:[NSOperationQueue mainQueue]];
     [[session dataTaskWithURL:url
                completionHandler:^(NSData *data,
                                    NSURLResponse *response,
                                    NSError *connectionError) {
        
        if (data == nil) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil)message:NO_CONNECTION_TEXT preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:ok];
            [self presentViewController:alertController animated:YES completion:nil];
            
            [self loadMoreCompleted];
            [self refreshCompleted];
            
            return ;
        }
        else  {
            jsonDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&connectionError];
            NSArray *jsonArray = [jsonDict valueForKey:@"items"];
            
            if (![jsonDict valueForKey:@"nextPageToken"] || [pageToken isEqualToString: [jsonDict valueForKey:@"nextPageToken"]]){
                self.canLoadMore = NO; // signal that there won't be any more items to load
            } else {
                self.canLoadMore = YES;
                pageToken=[jsonDict valueForKey:@"nextPageToken"];
            }
            
            for (id result in jsonArray)
            {
                [parsedItems addObject:result];
            }
            
            [self.tableView reloadData];
            [self loadMoreCompleted];
            [self refreshCompleted];
        }
        
     // handle response
                    
     }] resume];
    
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

- (BOOL) refresh
{
    if (![super refresh])
        return NO;
    
    // Do your async call here
    // This is just a dummy data loader:
    [self performSelector:@selector(addItemsOnTop) withObject:nil afterDelay:2.0];
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
    query = false;
    parsedItems = nil;
    pageToken = @"";
    [self fetchdata];
    
    // Call this to indicate that we have finished "refreshing".
    // This will then result in the headerView being unpinned (-unpinHeaderView will be called).
    
}

- (void) addItemsOnBottom
{
    count = count + 15;
    [self fetchdata];
    
    /**
    NSString *totalC=[NSString stringWithFormat:@"%@",[[jsonDict valueForKey:@"pageInfo"]valueForKey:@"totalResults"]];
    
    int totalcount= (int)[totalC integerValue];
    
    if (parsedItems.count > totalcount)
        self.canLoadMore = NO; // signal that there won't be any more items to load
    else
        self.canLoadMore = YES;
     **/
    
    // Inform STableViewController that we have finished loading more items
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{

    if (parsedItems == nil) {
        return 0;
    }
    return parsedItems.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AssistTableCell *cell;
    
    if (indexPath.row == 0 && [parsedItems count] > 0) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"HeaderCell" forIndexPath:indexPath];

        NSString *url = [[[[[parsedItems objectAtIndex:indexPath.row] valueForKey:@"snippet"] valueForKey:@"thumbnails"] valueForKey:@"high"] valueForKey:@"url"];
        
        [cell.image sd_setImageWithURL:[NSURL URLWithString:url]
                   placeholderImage:[UIImage imageNamed:@"default_placeholder"] options:indexPath.row == 0 ? SDWebImageRefreshCached : 0];

        cell.lblHeadTitle.text = [[[parsedItems objectAtIndex:indexPath.row] valueForKey:@"snippet"]valueForKey:@"title"];

    } else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
        if (indexPath.row >= parsedItems.count) {
            NSLog(@"Row requested for inexistent array element %lu, when there are %lu itemsToDisplay", (unsigned long) indexPath.row, (unsigned long) parsedItems.count);
            return cell;
        }
        
        NSString *title = [[[parsedItems objectAtIndex:indexPath.row] valueForKey:@"snippet"]valueForKey:@"title"];
        cell.lblTitle.text = title;
        
        NSString *datestring = [[[parsedItems objectAtIndex:indexPath.row] valueForKey:@"snippet"] valueForKey:@"publishedAt"];
        
        NSDateFormatter *dateFormatter = [NSDateFormatter new];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZ"];
        
        NSDate *date11 = [dateFormatter dateFromString:datestring];
        
        [dateFormatter setDateFormat:@"dd-MM-yyyy hh:mm"];
        cell.lblDate.text =[dateFormatter stringFromDate:date11];
        
        [cell.image sd_setImageWithURL:[NSURL URLWithString:[[[[[parsedItems objectAtIndex:indexPath.row] valueForKey:@"snippet"] valueForKey:@"thumbnails"] valueForKey:@"default"] valueForKey:@"url"]]
                     placeholderImage:[UIImage imageNamed:@"youtube.png"] options:indexPath.row == 0 ? SDWebImageRefreshCached : 0];
        cell.image.contentMode = UIViewContentModeScaleAspectFill;
        cell.image.clipsToBounds = YES;
    }
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"showDetails"]) {
        NSIndexPath *indexPath = sender;
        
        NSString *videoId = [[[[parsedItems objectAtIndex:indexPath.row] valueForKey:@"snippet"]valueForKey:@"resourceId"] valueForKey:@"videoId"];
        if ([videoId length] == 0){
            videoId = [[[parsedItems objectAtIndex:indexPath.row] valueForKey:@"id"]valueForKey:@"videoId"];
        }
        
        // Show detail
        NSLog(@"%@",[NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@",videoId]);
        
        YoutubeDetailViewController *detailVC = (YoutubeDetailViewController *)segue.destinationViewController;
        detailVC.summary = [[[parsedItems objectAtIndex:indexPath.row] valueForKey:@"snippet"]valueForKey:@"description"];
        detailVC.imageUrl=[[[[[parsedItems objectAtIndex:indexPath.row] valueForKey:@"snippet"] valueForKey:@"thumbnails"] valueForKey:@"maxres"] valueForKey:@"url"];
        detailVC.titleText=[[[parsedItems objectAtIndex:indexPath.row] valueForKey:@"snippet"]valueForKey:@"title"];
        detailVC.videoUrl=[NSString stringWithFormat:@"http://www.youtube.com/watch?v=%@",videoId];
        detailVC.videoId = videoId;
        
        NSString *datestring= [[[parsedItems objectAtIndex:indexPath.row] valueForKey:@"snippet"]valueForKey:@"publishedAt"];
        NSDateFormatter *dateFormatter=[NSDateFormatter new];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSZZZ"];
        NSDate *date11=[dateFormatter dateFromString:datestring];
        detailVC.date =[NSString stringWithFormat:@"%@",date11];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self performSegueWithIdentifier:@"showDetails" sender:indexPath];
    
    // Deselect
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark Searchbar
- (IBAction)searchClicked:(id)sender {
    
    [self setPullToRefreshEnabled:false];
    
    [searchBar resignFirstResponder];
    
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
    
    //Reset results and perform queries
    parsedItems = nil;
    pageToken = @"";
    self.canLoadMore = YES;
    query = [searchBar.text stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
    [self fetchdata];
    
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
    pageToken = @"";
    query = false;
    self.canLoadMore = YES;
    [self fetchdata];
    
    [self.tableView reloadData];
}


@end
