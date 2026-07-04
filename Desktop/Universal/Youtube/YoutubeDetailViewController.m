//
//  YoutubeDetailViewController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "YoutubeDetailViewController.h"
#import "AppDelegate.h"
#import "UIImageView+WebCache.h"
#import "TabNavigationController.h"
#import "UIViewController+PresentActions.h"
#import <MediaPlayer/MediaPlayer.h>

@import AVFoundation;
@import AVKit;

#import "XCDYouTubeKit.h"
#import "XCDYouTubeVideoPlayerViewController.h"

#define LABEL_WIDTH self.articleDetail.tableView.frame.size.width - 20

@implementation YoutubeDetailViewController
{
    ShowPageCell *contentCell;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.articleDetail.tableViewDataSource = self;
    self.articleDetail.tableViewDelegate = self;
    
    self.articleDetail.delegate = self;
    self.articleDetail.parallaxScrollFactor = 0.3; // little slower than normal.
    
    self.view.clipsToBounds = YES;
    
    //self.articleDetail.headerFade = 100.0f;
    self.articleDetail.defaultimagePagerHeight = 160.0f;
    
    // after setting the above properties
    [self.articleDetail initialLayout];
    
    [self addImage];
    
    //Make the header/navbar transparent
    TabNavigationController *nc = (TabNavigationController *)self.navigationController;
    [nc.gradientView turnTransparencyOn:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    TabNavigationController *nc = (TabNavigationController *)self.navigationController;
    [nc.gradientView turnTransparencyOn:NO animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"articleDetail"]) {
        self.articleDetail = (DetailViewAssistant *)segue.destinationViewController.view;
        self.articleDetail.parentController = segue.destinationViewController;
    }
}

#pragma mark - UITableView

- (void)addImage {
    UIView *header = self.articleDetail.tableView.tableHeaderView;
    // CGRect hRect = header.bounds;
    //hRect.size.height = 180;
    //header.bounds = hRect;
    
    //[self.articleDetail bringSubviewToFront:self.articleDetail.playButton];
    //[self.articleDetail.tableView.tableHeaderView action:@selector(playVideo) forControlEvents:UIControlEventTouchUpInside];
    
    [self.articleDetail.playButton setHidden:false];
    UITapGestureRecognizer *singleFingerTap =
    [[UITapGestureRecognizer alloc] initWithTarget:self
                                            action:@selector(playVideo)];
    [self.articleDetail.tableView.tableHeaderView addGestureRecognizer:singleFingerTap];
    
    [self.articleDetail.imageView sd_setImageWithURL:[NSURL URLWithString:_imageUrl] placeholderImage:[UIImage imageNamed:@"default_placeholder"]];
    self.articleDetail.imageView.contentMode = UIViewContentModeScaleAspectFill;
    // [self.articleDetail.youtubeImageView sd_setImageWithURL:[NSURL //URLWithString:_imageUrl]
    //             placeholderImage:[UIImage imageNamed:@"default_placeholder"]];
    
    CGRect hRect = self.articleDetail.tableView.tableHeaderView.bounds;
    hRect.size.height = 170.0f;
    self.articleDetail.tableView.tableHeaderView.bounds = hRect;
    
    self.articleDetail.hasImage = YES;
    
    header.hidden = NO;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 1) {
        return contentCell ? [contentCell updateWebViewHeightForWidth:tableView.frame.size.width] : 50.0f;
    }
    
    return UITableViewAutomaticDimension;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        TitleCell *cell = [tableView dequeueReusableCellWithIdentifier:@"titleCell" forIndexPath:indexPath];
        
        cell.lblTitle.text = _titleText;
        cell.lblDescription.text = [NSString stringWithFormat:NSLocalizedString(@"published_on", nil), _date];
        
        return cell;
    }
    else if (indexPath.row == 1) {
        contentCell = (ShowPageCell *)[tableView dequeueReusableCellWithIdentifier:@"ShowPageCell" forIndexPath:indexPath];
        
        contentCell.parentTable = [self.articleDetail getTableView];
        contentCell.parentViewController = self;
        
        //If the description is empty, just load blank html
        NSString *htmlContent;
        if ([_summary length] == 0){
            htmlContent = @"<br>";
        } else {
            htmlContent = _summary;
        }
        
        [contentCell loadContent:htmlContent];
        
        return contentCell;
    }
    else if (indexPath.row == 2) {
        ActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"actionCell" forIndexPath:indexPath];
        cell.actionDelegate = self;
        
        return cell;
    }
    else {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reusable"];
        if (!cell) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"reusable"];
        }
        
        cell.textLabel.text = @"Default cell";
        
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    cell.contentView.backgroundColor = [UIColor whiteColor];
}

- (void)articleDetail:(DetailViewAssistant *)articleDetail tableViewDidLoad:(UITableView *)tableView
{
    //    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat scrollOffset = scrollView.contentOffset.y;
    
    // let the view handle the paralax effect
    [self.articleDetail scrollViewDidScrollWithOffset:scrollOffset];
    
    if (self.articleDetail.hasImage) {
        // switch the nav bar opaque/transparent at the threshold
        TabNavigationController *nc = (TabNavigationController *)self.navigationController;
        [nc.gradientView turnTransparencyOn:(scrollOffset < self.articleDetail.headerFade) animated:YES];
    }
}

#pragma mark - UIContentContainer Protocol

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [contentCell updateWebViewHeightForWidth:size.width];
}

#pragma mark - Button actions

- (void)open
{
    [AppDelegate openUrl:_videoUrl withNavigationController:self.navigationController];
}

- (IBAction)share:(id)sender
{
    NSArray *activityItems = [NSArray arrayWithObjects:_videoUrl,  nil];
    
    [self presentActions:activityItems sender:(id)sender];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) playVideo {
    //XCDYouTubeVideoPlayerViewController *videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:_videoId];
    //[self presentMoviePlayerViewControllerAnimated:videoPlayerViewController];
    
    AVPlayerViewController *playerViewController = [AVPlayerViewController new];
    [self presentViewController:playerViewController animated:YES completion:nil];
    
    __weak AVPlayerViewController *weakPlayerViewController = playerViewController;
    [[XCDYouTubeClient defaultClient] getVideoWithIdentifier:_videoId completionHandler:^(XCDYouTubeVideo * _Nullable video, NSError * _Nullable error) {
        if (video)
        {
            NSDictionary *streamURLs = video.streamURLs;
            NSURL *streamURL = streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?: streamURLs[@(XCDYouTubeVideoQualityHD720)] ?: streamURLs[@(XCDYouTubeVideoQualityMedium360)] ?: streamURLs[@(XCDYouTubeVideoQualitySmall240)];
            weakPlayerViewController.player = [AVPlayer playerWithURL:streamURL];
            [weakPlayerViewController.player play];
        }
        else
        {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

@end

