//
// TwitterViewController.m
//
// Copyright (c) 2016 Sherdle. All rights reserved.
//


#import "TwitterViewController.h"
#import "AssistTableHeaderView.h"
#import "AssistTableFooterView.h"

#import "NSString+HTML.h"
#import "MWFeedParser.h"
#import "AppDelegate.h"
#import "SWRevealViewController.h"

#import "SocialFetcher.h"

#import "UITableView+FDTemplateLayoutCell.h"

@implementation TwitterViewController
@synthesize params, screenName;

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateStyle:NSDateFormatterShortStyle];
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    [self.tableView addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    [self.tableView addGestureRecognizer: self.revealViewController.tapGestureRecognizer];
    
    // register cell nib once
    [self.tableView registerNib:[UINib nibWithNibName:@"CardCell" bundle:nil] forCellReuseIdentifier:@"CardCell"];

    // add sample items
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    count = 15;
    
    [[FHSTwitterEngine sharedEngine]permanentlySetConsumerKey:TWITTER_API andSecret:TWITTER_API_SECRET];
    [[FHSTwitterEngine sharedEngine]setDelegate:self];
    [[FHSTwitterEngine sharedEngine]loadAccessToken];
    
    [self willBeginLoadingMore];
    [self fetchTimeline];
}

-(void)fetchTimeline
{
    FHSToken *token = [[FHSToken alloc] init];
    token.key = TWITTER_TOKEN;
    token.secret = TWITTER_TOKEN_SECRET;
    
    [[FHSTwitterEngine sharedEngine]setAccessToken:token];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *tempArray = [[FHSTwitterEngine sharedEngine]getTimelineForUser:screenName isID:NO count:20 sinceID:nil maxID: _latestTweetID];
        
        if (self.tweetsArray == nil){
            self.tweetsArray = [[NSMutableArray alloc]init];
            
            // init image indexPath list as there can be new images in the feed
            loadedImages = [NSMutableSet new];
        }
        
        
        if (![tempArray isKindOfClass: [NSArray class]]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil)message:NO_CONNECTION_TEXT preferredStyle:UIAlertControllerStyleAlert];
            
                UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:ok];
                [self presentViewController:alertController animated:YES completion:nil];
                
                [self refreshCompleted];
                [self loadMoreCompleted];
            });
            
            return ;
            
        } else {
            
            if (tempArray.count == 0)
            {
                return;
            }
            for (id result in tempArray) {
                [self.tweetsArray addObject:result];
                
                long tweetID = [[result valueForKey:@"id"] longValue];
                _latestTweetID = [NSString stringWithFormat: @"%ld", tweetID - 1];
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                [self refreshCompleted];
                [self loadMoreCompleted];
            });
        }
    });
    
    
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
        
        // We can hide the footerView by: [self setFooterViewVisibility:NO];
        
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
    _latestTweetID = nil;
    self.tweetsArray = nil;
    [self fetchTimeline];
    
    
    // Call this to indicate that we have finished "refreshing".
    // This will then result in the headerView being unpinned (-unpinHeaderView will be called).
    [self refreshCompleted];
}

- (void) addItemsOnBottom
{
    [self fetchTimeline];
    
    //TODO Make working when end has reached. Do something like: when returned array lenght == nul --> canloadmore -> NO
   // if (5 == 6)
   //     self.canLoadMore = NO; // signal that there won't be any more items to load
   // else
        self.canLoadMore = YES;
    
    // Inform STableViewController that we have finished loading more items
    
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _tweetsArray.count;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *CellIdentifier = @"CardCell";
    CardCell *cell = [self.tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(CardCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    [cell.countOne setImage:[UIImage imageNamed:@"star"]];
    [cell.countTwo setImage:[UIImage imageNamed:@"retweet"]];
    
    cell.likeCount.text = [NSString stringWithFormat:@"%i",[[[self.tweetsArray objectAtIndex:indexPath.row] objectForKey:@"favorite_count"] intValue]];
    cell.commentCount.text = [NSString stringWithFormat:@"%i",[[[self.tweetsArray objectAtIndex:indexPath.row] objectForKey:@"retweet_count"] intValue]];
    
    [cell.userPic sd_setImageWithURL:[NSURL URLWithString:[[[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"user"] valueForKey:@"profile_image_url_https"]]
                    placeholderImage:[UIImage imageNamed:@"placeholder"] options:indexPath.row == 0 ? SDWebImageRefreshCached : 0];
    
    cell.username.text = [[[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"user"]valueForKey:@"name"];
    
    //TODO possibly also show raw username
    //NSString *username = [NSString stringWithFormat:@"@%@",[[[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"user"]valueForKey:@"screen_name"]];
    
    cell.shareUrl = [NSString stringWithFormat:@"https://twitter.com/%@/status/%@",
                     [[[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"user"]valueForKey:@"screen_name"],
                     [self.tweetsArray[indexPath.row]valueForKey:@"id"]];
    
    cell.caption.text = [[[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"text"] stringByDecodingHTMLEntities];
    
    NSObject *entities = [[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"extended_entities"];
    
    if (entities != nil &&
        [[entities valueForKey:@"media"] objectAtIndex:0] != nil &&
        [[[[entities valueForKey:@"media"]  objectAtIndex:0] valueForKey:@"type"] isEqualToString: @"photo"]) {
        
        NSString *imageUrl = [NSString stringWithFormat:@"%@",[[[entities valueForKey:@"media"] objectAtIndex:0]valueForKey:@"media_url"]];
        
        [cell.photoView sd_setImageWithURL:[NSURL URLWithString:imageUrl]
                          placeholderImage:[UIImage imageNamed:@"default_placeholder"] options:(indexPath.row == 0 ? SDWebImageRefreshCached : 0) completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                              [self webImageLoadedForCell:cell atIndexPath:indexPath];
                          }];
        cell.photoView.hidden = NO;
    }else{
        cell.photoView.hidden = YES;
    }
    
    //lbldate.text=[NSString stringWithFormat:@"%@",[[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"created_at"]];
    NSDateFormatter *df = [[NSDateFormatter alloc] init] ;
    //Wed Dec 01 17:08:03 +0000 2010
    [df setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
    
    NSDate *date = [df dateFromString:[NSString stringWithFormat:@"%@",[[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"created_at"]]];
    
    [df setDateFormat:@"eee MMM dd yyyy"];
    NSString *dateStr = [df stringFromDate:date];
    cell.time.text=dateStr;
    
    //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    //URL click handelers
    cell.caption.urlLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        [AppDelegate openUrl:string withNavigationController:self.navigationController];
    };
    
    cell.caption.hashtagLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        UIApplication *app = [UIApplication sharedApplication];
        
        // NOTE: you must percent escape the query (# becomes %23)
        NSString *cleanQuery = [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        NSURL *twitterURL = [NSURL URLWithString:[NSString stringWithFormat:@"twitter://search?query=%@", cleanQuery]];
        if ([app canOpenURL:twitterURL]) {
            UIApplication *application = [UIApplication sharedApplication];
            [application openURL:twitterURL options:@{} completionHandler:nil];
        } else {
            NSString *safariURL = [NSString stringWithFormat:@"http://mobile.twitter.com/search?q=%@", cleanQuery];
            [AppDelegate openUrl:safariURL withNavigationController:self.navigationController];
        }
    };
    
    cell.caption.userHandleLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        UIApplication *app = [UIApplication sharedApplication];
        
        // NOTE: you must percent escape the query (# becomes %23)
        NSString *cleanQuery = [string stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        NSURL *twitterURL = [NSURL URLWithString:[NSString stringWithFormat:@"twitter://user?screen_name=%@", cleanQuery]];
        if ([app canOpenURL:twitterURL]) {
            UIApplication *application = [UIApplication sharedApplication];
            [application openURL:twitterURL options:@{} completionHandler:nil];
        } else {
            NSString *safariURL = [NSString stringWithFormat:@"http://mobile.twitter.com/%@", cleanQuery];
            
            [AppDelegate openUrl:safariURL withNavigationController:self.navigationController];
        }
    };
    
    cell.delegate = self;
    cell.parentController = self;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES]; // if error remove "self."
    //twitterDetailViewController *twitter=[[twitterDetailViewController alloc]initWithNibName:@"twitterDetailViewController" bundle:nil];
    
    //twitter.openURl=[NSString stringWithFormat:@"https://twitter.com/%@/status/%@",
    // [[[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"user"]valueForKey:@"screen_name"],
    //  [self.tweetsArray[indexPath.row]valueForKey:@"id"]];
    
    //NSDateFormatter *df = [[NSDateFormatter alloc] init] ;
    
    //[df setDateFormat:@"eee MMM dd HH:mm:ss ZZZZ yyyy"];
    
    //NSDate *date = [df dateFromString:[NSString stringWithFormat:@"%@",[[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"created_at"]]];
    
    //[df setDateFormat:@"eee MMM dd yyyy"];
    //NSString *dateStr = [df stringFromDate:date];
    //twitter.dateString=dateStr;
    
    
    //twitter.imageURL=[[[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"user"]valueForKey:@"profile_image_url_https"];
    //twitter.titleName=[[[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"user"]valueForKey:@"name"];
    //twitter.screenName=[NSString stringWithFormat:@"@%@",[[[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"user"]valueForKey:@"screen_name"]];
    
    //twitter.tweet=[[self.tweetsArray objectAtIndex:indexPath.row] valueForKey:@"text"];
    
    //[self.navigationController pushViewController:twitter animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = [tableView fd_heightForCellWithIdentifier:@"CardCell" cacheByIndexPath:indexPath configuration:^(id cell) {
        [self configureCell:cell atIndexPath:indexPath];
    }];

    return height;
}

- (NSString *)loadAccessToken {
    return [[NSUserDefaults standardUserDefaults]objectForKey:@"SavedAccessHTTPBody"];
}

- (void)storeAccessToken:(NSString *)accessToken {
    [[NSUserDefaults standardUserDefaults]setObject:accessToken forKey:@"SavedAccessHTTPBody"];
}

@end
