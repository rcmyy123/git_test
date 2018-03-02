//
//  InstagramViewController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "InstagramViewController.h"
#import "AppDelegate.h"
#import "AssistTableHeaderView.h"
#import "AssistTableFooterView.h"

#import "SWRevealViewController.h"
#import "UITableView+FDTemplateLayoutCell.h"

@interface InstagramViewController ()
- (void) addItemsOnTop;
- (void) addItemsOnBottom;

@property (nonatomic, strong) NSString *nextPage;

@end

@implementation InstagramViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
        self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self.tableView addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    [self.tableView addGestureRecognizer: self.revealViewController.tapGestureRecognizer];
    
    // register cell nib once
    [self.tableView registerNib:[UINib nibWithNibName:@"CardCell" bundle:nil] forCellReuseIdentifier:@"CardCell"];
    
    [self willBeginLoadingMore];
    [self fetchData];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void) fetchData {
    NSString *query;
    if (_nextPage){
        query = _nextPage;
    } else {
        query = [NSString stringWithFormat:@"https://api.instagram.com/v1/users/%@/media/recent?access_token=%@", _params[0], INSTAGRAM_ACCESS_TOKEN];
        
        // init image indexPath list as there can be new images in the feed
        loadedImages = [NSMutableSet new];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0.0), ^{
        NSDictionary *dictionary = [SocialFetcher executeFetch:query];
        NSArray *jsonArray = [dictionary objectForKey:@"data"];
        if (jsonArray == nil){
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil)message:NO_CONNECTION_TEXT preferredStyle:UIAlertControllerStyleAlert];
            
                UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil];
                [alertController addAction:ok];
                [self presentViewController:alertController animated:YES completion:nil];
            
                [self refreshCompleted];
                [self loadMoreCompleted];
            });
        } else {
        
            if (!self.postItems){
                self.postItems = [[NSMutableArray alloc]init];
            }
            
            for (id result in jsonArray) {
                [self.postItems addObject:result];
            }
        
            _nextPage = [[dictionary objectForKey:@"pagination"] valueForKey:@"next_url"];
            
            //If nextpage is nil, we can't load more
            if (_nextPage == nil)
                self.canLoadMore = NO; // signal that there won't be any more items to load
            else
                self.canLoadMore = YES;
        
            dispatch_async(dispatch_get_main_queue(), ^{
                //[self.tableView reloadData];
                //[indicator stopAnimating];
            
                [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
                
                [self loadMoreCompleted];
                [self refreshCompleted];
            
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
    self.postItems = nil;
    _nextPage = nil;
    [self fetchData];
    
    
    // Call this to indicate that we have finished "refreshing".
    // This will then result in the headerView being unpinned (-unpinHeaderView will be called).
    [self refreshCompleted];
}

- (void) addItemsOnBottom
{
    
    [self fetchData];
    
    // Inform STableViewController that we have finished loading more items
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.postItems count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat height = [tableView fd_heightForCellWithIdentifier:@"CardCell" cacheByIndexPath:indexPath configuration:^(id cell) {
        [self configureCell:cell atIndexPath:indexPath];
    }];
    
    return height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CardCell";
    CardCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];

    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)configureCell:(CardCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    NSDictionary *dictionary = [self.postItems objectAtIndex:indexPath.row];

        cell.username.text = [[dictionary objectForKey:@"user"] objectForKey:@"full_name"];
        int likeInt = (int)[[[dictionary objectForKey:@"likes"] objectForKey:@"count"]integerValue];;
        int commentInt = (int)[[[dictionary objectForKey:@"comments"] objectForKey:@"count"]integerValue];;
        cell.likeCount.text = [@(likeInt) stringValue];
        cell.commentCount.text = [@(commentInt) stringValue];
        
        int unixTimeStamp =[[dictionary objectForKey:@"created_time"] intValue];
        cell.time.text = [self dateIntToString:unixTimeStamp];
        
        cell.shareUrl = [dictionary objectForKey:@"link"];
        
        NSString *imageURL = [[dictionary objectForKey:@"user"] objectForKey:@"profile_picture"];
        [cell.userPic sd_setImageWithURL:[NSURL URLWithString:imageURL]
                        placeholderImage:[UIImage imageNamed:@"default_placeholder"] options:indexPath.row == 0 ? SDWebImageRefreshCached : 0];
        
        NSString *thumbnailUrlString = [[[dictionary objectForKey:@"images"] objectForKey:@"low_resolution"] objectForKey:@"url"];
        [cell.photoView  sd_setImageWithURL:[NSURL URLWithString:thumbnailUrlString]
                           placeholderImage:[UIImage imageNamed:@"default_placeholder"] options:(indexPath.row == 0 ? SDWebImageRefreshCached : 0) completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                               [self webImageLoadedForCell:cell atIndexPath:indexPath];
                           }];
        if(![[dictionary objectForKey:@"caption"] isKindOfClass:[NSNull class]])
        {
            cell.caption.text = [[dictionary objectForKey:@"caption"] objectForKey:@"text"];
        }else{
            cell.caption.text = @"";
        }
    cell.delegate = self;
    cell.parentController = self;
    
    cell.caption.urlLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        [AppDelegate openUrl:string withNavigationController:self.navigationController];

    };
    
    cell.caption.hashtagLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        UIApplication *app = [UIApplication sharedApplication];
        
        NSString *cleanQuery = [[string stringByReplacingOccurrencesOfString:@"#" withString:@""] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        NSURL *facebookURL = [NSURL URLWithString:[NSString stringWithFormat:@"instagram://tag?name=%@", cleanQuery]];
        if ([app canOpenURL:facebookURL]) {
            UIApplication *application = [UIApplication sharedApplication];
            [application openURL:facebookURL options:@{} completionHandler:nil];
        } else {
            NSString *safariURL = [NSString stringWithFormat:@"https://instagram.com/explore/tags/%@", cleanQuery];
            
            [AppDelegate openUrl:safariURL withNavigationController:self.navigationController];
        }
    };
}

-(NSString *)dateIntToString:(int)dateInt {
    NSTimeInterval interval=dateInt;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970: interval];
    NSDateFormatter *formatter= [[NSDateFormatter alloc] init];
    [formatter setLocale:[NSLocale currentLocale]];
    [formatter setDateFormat:@"dd-MM-yyyy hh:mm"];
    NSString *dateString = [formatter stringFromDate:date];
    return dateString;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //CardCell *cell = (CardCell *)[tableView cellForRowAtIndexPath:indexPath];
}

@end
