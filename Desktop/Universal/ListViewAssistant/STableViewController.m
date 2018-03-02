//
// STableViewController.m
//
// Copyright (c) 2016 Sherdle. All rights reserved.
//
// Implements: STTableViewController
// Copyright (C) 2011 by BJ Basañes, http://shikii.net under MIT
//

#import "STableViewController.h"

#define DEFAULT_HEIGHT_OFFSET 52.0f

@implementation STableViewController

@synthesize headerView;

@synthesize isDragging;
@synthesize isRefreshing;
@synthesize isLoadingMore;

@synthesize canLoadMore;
@synthesize pullToRefreshEnabled;
@synthesize clearsSelectionOnViewWillAppear;

- (void) initialize
{
    pullToRefreshEnabled = YES;
    canLoadMore = YES;
    clearsSelectionOnViewWillAppear = YES;
}

- (id) init
{
    if ((self = [super init]))
        [self initialize];
    return self;
}

- (id) initWithCoder:(NSCoder *)aDecoder
{
    if ((self = [super initWithCoder:aDecoder]))
        [self initialize];
    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self initialize];
    
    // set the custom view for "pull to refresh". See AssistTableHeaderView.xib.
    NSArray *hNib = [[NSBundle mainBundle] loadNibNamed:@"AssistTableHeaderView" owner:self options:nil];
    self.headerView = (AssistTableHeaderView *)[hNib objectAtIndex:0];
    [self addHeaderView];
    
    // set the custom view for "load more". See AssistTableFooterView.xib.
    NSArray *fNib = [[NSBundle mainBundle] loadNibNamed:@"AssistTableFooterView" owner:self options:nil];
    self.tableView.tableFooterView = (AssistTableFooterView *)[fNib objectAtIndex:0];
}

//- (void) viewWillAppear:(BOOL)animated
//{
//    [super viewWillAppear:animated];
//    [self initialize];
//}

- (void) addHeaderView
{
    [self.tableView addSubview:headerView];
    [self.tableView addConstraints:@[
                                     [NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeLeading relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeLeading multiplier:1.0f constant:0.f],
                                     [NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeWidth relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeWidth multiplier:1.0f constant:0.f],
                                     [NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeTop multiplier:1.0f constant:-headerView.frame.size.height],
                                     [NSLayoutConstraint constraintWithItem:headerView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.tableView attribute:NSLayoutAttributeTop multiplier:1.0f constant:0.f]
                                     ]];
}

- (CGFloat) headerRefreshHeight
{
    if (!CGRectIsEmpty(headerView.frame))
        return headerView.frame.size.height;
    else
        return DEFAULT_HEIGHT_OFFSET;
}

- (void) pinHeaderView
{
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.tableView.contentInset = UIEdgeInsetsMake([self headerRefreshHeight], 0, 0, 0);
    }];
}

- (void) unpinHeaderView
{
    [UIView animateWithDuration:0.3 animations:^(void) {
        self.tableView.contentInset = UIEdgeInsetsZero;
    }];
}

- (void) willBeginRefresh
{
    if (pullToRefreshEnabled)
        [self pinHeaderView];
}

- (void) willShowHeaderView:(UIScrollView *)scrollView
{
}

- (void) headerViewDidScroll:(BOOL)willRefreshOnRelease scrollView:(UIScrollView *)scrollView
{
}

- (BOOL) refresh
{
    if (isRefreshing)
        return NO;
    
    [self willBeginRefresh];
    isRefreshing = YES;
    return YES;
}

- (void) refreshCompleted
{
    isRefreshing = NO;
    
    if (pullToRefreshEnabled)
        [self unpinHeaderView];
}

- (void) willBeginLoadingMore
{
}

- (void) loadMoreCompleted
{
    isLoadingMore = NO;
}

- (BOOL) loadMore
{
    if (isLoadingMore)
        return NO;
    
    [self willBeginLoadingMore];
    isLoadingMore = YES;
    return YES;
}

- (CGFloat) footerLoadMoreHeight
{
    return self.tableView.tableFooterView.frame.size.height;
}

- (void) allLoadingCompleted
{
    if (isRefreshing)
        [self refreshCompleted];
    if (isLoadingMore)
        [self loadMoreCompleted];
}

- (void) scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    if (isRefreshing)
        return;
    isDragging = YES;
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (!isRefreshing && isDragging && scrollView.contentOffset.y < 0) {
        [self headerViewDidScroll:scrollView.contentOffset.y < 0 - [self headerRefreshHeight] scrollView:scrollView];
    } else if (!isLoadingMore && canLoadMore) {
        CGFloat scrollPosition = scrollView.contentSize.height - scrollView.frame.size.height - scrollView.contentOffset.y;
        if (scrollPosition < [self footerLoadMoreHeight]) {
            [self loadMore];
        }
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (isRefreshing)
        return;
    
    isDragging = NO;
    if (scrollView.contentOffset.y <= 0 - [self headerRefreshHeight]) {
        if (pullToRefreshEnabled)
            [self refresh];
    }
}

- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

- (UITableViewCell *) tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return nil;
}

- (void)webImageLoadedForCell:(CardCell *)cell atIndexPath:(NSIndexPath *)indexPath
{
    [cell updateImageAspectRatio];
    if (![loadedImages containsObject:indexPath]) {
        // invalidate height cache entry once
        //NSLog(@"Loaded image for row %ld", indexPath.row);
        [self.tableView.fd_indexPathHeightCache invalidateHeightAtIndexPath:indexPath];
        [loadedImages addObject:indexPath];
        
        // ensure the cell still belongs to the table and hasn't been reused
        NSIndexPath *currentIndexPath = [self.tableView indexPathForCell:cell];
        if (currentIndexPath == indexPath) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            });
        }
    }
}

- (void) releaseViewComponents
{
    [headerView release]; headerView = nil;
}

- (void) dealloc
{
    [self releaseViewComponents];
    [super dealloc];
}

- (void) viewDidUnload
{
    [self releaseViewComponents];
    [super viewDidUnload];
}

@end
