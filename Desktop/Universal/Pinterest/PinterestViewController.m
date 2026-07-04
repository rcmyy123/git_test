//
//  PinterestViewController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "PinterestViewController.h"
#import "AppDelegate.h"
#import "AssistTableHeaderView.h"
#import "AssistTableFooterView.h"

#import "SWRevealViewController.h"
#import "UITableView+FDTemplateLayoutCell.h"

@interface PinterestViewController ()
- (void) addItemsOnTop;
- (void) addItemsOnBottom;

@property (nonatomic, strong) NSString *nextPage;

@end

@implementation PinterestViewController

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
        query = [NSString stringWithFormat:@"https://api.pinterest.com/v1/boards/%@/pins/?fields=id,original_link,note,image,media,attribution,created_at,creator(image,first_name),counts&limit=100&access_token=%@", _params[0], PINTEREST_ACCESS_TOKEN];
        
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
        
            _nextPage = [[dictionary objectForKey:@"page"] valueForKey:@"next"];
            
            //If nextpage is nil, we can't load more
            if (_nextPage == (id)[NSNull null] || _nextPage.length == 0 )
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
    
    [cell.countOne setImage:[UIImage imageNamed:@"pin"]];

    cell.username.text = [[dictionary objectForKey:@"creator"] objectForKey:@"first_name"];
    int likeInt = (int)[[[dictionary objectForKey:@"counts"] objectForKey:@"saves"]integerValue];
    int commentInt = (int)[[[dictionary objectForKey:@"counts"] objectForKey:@"comments"]integerValue];
    cell.likeCount.text = [@(likeInt) stringValue];
    cell.commentCount.text = [@(commentInt) stringValue];
    
    cell.time.text = [self parseDateToString: [dictionary objectForKey:@"created_at"] ];
    
    cell.shareUrl = [dictionary objectForKey:@"original_link"];
        
    NSString *imageURL = [[[[dictionary objectForKey:@"creator"] objectForKey:@"image"] objectForKey:@"60x60"] objectForKey:@"url"];
    [cell.userPic sd_setImageWithURL:[NSURL URLWithString:imageURL]
                        placeholderImage:[UIImage imageNamed:@"default_placeholder"] options:indexPath.row == 0 ? SDWebImageRefreshCached : 0];
        
    NSString *thumbnailUrlString = [[[dictionary objectForKey:@"image"] objectForKey:@"original"] objectForKey:@"url"];
    [cell.photoView  sd_setImageWithURL:[NSURL URLWithString:thumbnailUrlString]
                           placeholderImage:[UIImage imageNamed:@"default_placeholder"] options:(indexPath.row == 0 ? SDWebImageRefreshCached : 0) completed:^(UIImage *image, NSError *error, SDImageCacheType cacheType, NSURL *imageURL) {
                               [self webImageLoadedForCell:cell atIndexPath:indexPath];
                           }];

    cell.caption.text = [dictionary objectForKey:@"note"];
    
    cell.delegate = self;
    cell.parentController = self;
    
    cell.caption.urlLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        [AppDelegate openUrl:string withNavigationController:self.navigationController];

    };
    
    cell.caption.hashtagLinkTapHandler = ^(KILabel *label, NSString *string, NSRange range) {
        NSString *cleanQuery = [[string stringByReplacingOccurrencesOfString:@"#" withString:@""] stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
        NSString *safariURL = [NSString stringWithFormat:@"https://pinterest.com/search/pins/?q=%@", cleanQuery];
            
        [AppDelegate openUrl:safariURL withNavigationController:self.navigationController];
    };
}

-(NSString *)parseDateToString:(NSString *)dateString {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    NSDate *dte = [dateFormat dateFromString:dateString];
    
    NSDateFormatter *dF = [[NSDateFormatter alloc] init];
    [dF setDateFormat:@"dd MMMM yyyy HH:mm"];
    return [dF stringFromDate:dte];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //CardCell *cell = (CardCell *)[tableView cellForRowAtIndexPath:indexPath];
}

@end
