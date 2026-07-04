//
//  FacebookViewController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "FacebookViewController.h"
#import "AppDelegate.h"
#import "AssistTableHeaderView.h"
#import "AssistTableFooterView.h"
#import "NSString+HTML.h"
#import "SWRevealViewController.h"
#import "UITableView+FDTemplateLayoutCell.h"

@interface FacebookViewController ()
- (void) addItemsOnTop;
- (void) addItemsOnBottom;

@property (nonatomic, strong) NSString *nextPage;

@end

@implementation FacebookViewController

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
    [self FetchData];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void) FetchData {
    NSString *param = @"";
    if (_nextPage){
        //Why so complicated? Why can't we use Facebook's provided nextPage url as is? Because it does not work (copy & paste from api)!
        NSMutableDictionary *queryStringDictionary = [[NSMutableDictionary alloc] init];
        NSArray *urlComponents = [_nextPage componentsSeparatedByString:@"&"];
        
        for (NSString *keyValuePair in urlComponents)
        {
            NSArray *pairComponents = [keyValuePair componentsSeparatedByString:@"="];
            NSString *key = [[pairComponents firstObject] stringByRemovingPercentEncoding];
            NSString *value = [[pairComponents lastObject] stringByRemovingPercentEncoding];
            
            [queryStringDictionary setObject:value forKey:key];
        }
        
        NSString *pagingToken = [queryStringDictionary objectForKey:@"__paging_token"];
        NSString *limit = [queryStringDictionary objectForKey:@"limit"];
        NSString *until = [queryStringDictionary objectForKey:@"until"];
        
        param = [NSString stringWithFormat: @"&__paging_token=%@&limit=%@&until=%@",pagingToken,limit,until];
    } else {
        // init image indexPath list as there can be new images in the feed
        loadedImages = [NSMutableSet new];
    }
    
    NSString *escapedToken = [FACEBOOK_ACCESS_TOKEN stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
    
    NSString *query = [NSString stringWithFormat:@"https://graph.facebook.com/%@/posts/?access_token=%@&date_format=U&fields=comments.limit(0).summary(1),likes.limit(0).summary(1),from,picture,message,story,name,link,created_time,full_picture%@", _params[0], escapedToken, param];
    
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
        }
        
        if (!self.postItems){
            self.postItems = [[NSMutableArray alloc]init];
        }
        
        for (id result in jsonArray) {
            [self.postItems addObject:result];
        }
        
        _nextPage = [[dictionary objectForKey:@"paging"] valueForKey:@"next"];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            //[self.tableView reloadData];
            //[indicator stopAnimating];
            
            [self.tableView performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
            
            [self loadMoreCompleted];
            [self refreshCompleted];
            
        });
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
    [self FetchData];
    
    
    // Call this to indicate that we have finished "refreshing".
    // This will then result in the headerView being unpinned (-unpinHeaderView will be called).
    [self refreshCompleted];
}

- (void) addItemsOnBottom
{
    
    [self FetchData];
    
    //TODO see if this get's executed correctly, and if canLoadMore is correctly used later
    if ([_nextPage length] > 0)
        self.canLoadMore = YES;
    else
        self.canLoadMore = NO; // signal that there won't be any more items to load

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
    
    cell.username.text = [[dictionary objectForKey:@"from"] objectForKey:@"name"];
    
    NSString *imageURL = [NSString stringWithFormat:@"https://graph.facebook.com/%@/picture", [[dictionary objectForKey:@"from"] objectForKey:@"id"]] ;
    
    [cell.userPic sd_setImageWithURL:[NSURL URLWithString:imageURL]
                    placeholderImage:[UIImage imageNamed:@"default_placeholder"] options:indexPath.row == 0 ? SDWebImageRefreshCached : 0];
    
    int unixTimeStamp =[[dictionary objectForKey:@"created_time"] intValue];
    cell.time.text = [self dateIntToString:unixTimeStamp];
    
    if ([dictionary objectForKey:@"full_picture"] != nil) {
        NSString *thumbnailUrlString = [dictionary objectForKey:@"full_picture"];
        //    cell.photoView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:thumbnailUrl]];
        [cell.photoView  sd_setImageWithURL:[NSURL URLWithString:thumbnailUrlString]
                           placeholderImage:[UIImage imageNamed:@"default_placeholder"] options:(indexPath.row == 0 ? SDWebImageRefreshCached : 0) completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                               [self webImageLoadedForCell:cell atIndexPath:indexPath];
                           }];
        cell.photoView.hidden = NO;
    } else if ([dictionary objectForKey:@"picture"] != nil) {
        NSString *thumbnailUrlString = [dictionary objectForKey:@"picture"];
        //    cell.photoView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:thumbnailUrl]];
        [cell.photoView  sd_setImageWithURL:[NSURL URLWithString:thumbnailUrlString]
                           placeholderImage:[UIImage imageNamed:@"default_placeholder"] options:(indexPath.row == 0 ? SDWebImageRefreshCached : 0) completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                               [self webImageLoadedForCell:cell atIndexPath:indexPath];
                           }];
        cell.photoView.hidden = NO;
    }else{
        cell.photoView.hidden = YES;
    }
    
    if([dictionary objectForKey:@"message"] != nil)
    {
        cell.caption.text = [dictionary objectForKey:@"message"] ;
    }else if([dictionary objectForKey:@"story"] != nil){
        cell.caption.text = [dictionary objectForKey:@"story"] ;
    }else if([dictionary objectForKey:@"name"] != nil){
        cell.caption.text = [dictionary objectForKey:@"name"] ;
    }else{
        cell.caption.text = @"";
    }
    
    if ([[dictionary objectForKey:@"link"] length] > 0){
         cell.shareUrl = [dictionary objectForKey:@"link"];
         cell.openButton.hidden = false;
    } else{
         cell.openButton.hidden = true;
    }
    
    NSString *likes = [NSString stringWithFormat:@"%@",[[[dictionary objectForKey:@"likes"] objectForKey:@"summary"] objectForKey:@"total_count"]];
    cell.likeCount.text = likes;
    
    NSString *comments = [NSString stringWithFormat:@"%@",[[[dictionary objectForKey:@"comments"] objectForKey:@"summary"] objectForKey:@"total_count"]];
    cell.commentCount.text = comments;
    
    cell.caption.urlLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        [AppDelegate openUrl:string withNavigationController:self.navigationController];
    };
    
    cell.caption.hashtagLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        UIApplication *app = [UIApplication sharedApplication];
        
        NSString *cleanQuery = [[string stringByReplacingOccurrencesOfString:@"#" withString:@""] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        NSURL *facebookURL = [NSURL URLWithString:[NSString stringWithFormat:@"fb://hashtag/%@", cleanQuery]];
        if ([app canOpenURL:facebookURL]) {
            [UIApplication sharedApplication];
            UIApplication *application = [UIApplication sharedApplication];
            [application openURL:facebookURL options:@{} completionHandler:nil];
        } else {
            NSString *safariURL = [NSString stringWithFormat:@"https://www.facebook.com/hashtag/%@", cleanQuery];
            
            [AppDelegate openUrl:safariURL withNavigationController:self.navigationController];
        }
    };
    
    cell.delegate = self;
    cell.parentController = self;
}

-(NSString *)dateIntToString:(int)dateInt {
    NSTimeInterval _interval=dateInt;
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:_interval];
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
