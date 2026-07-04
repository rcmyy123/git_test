//
//  RssDetailViewController.m
//
// Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "RssDetailViewController.h"
#import "AppDelegate.h"
#import "UIImageView+WebCache.h"
#import "TabNavigationController.h"
#import "UIViewController+PresentActions.h"

#define LABEL_WIDTH self.articleDetail.tableView.frame.size.width - 20

@implementation RssDetailViewController
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

    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    [formatter setTimeStyle:NSDateFormatterMediumStyle];
    
    _imageUrl = _item.media;
    _html = @"";
    _titleText = _item.title;
    _date = _item.date; //[formatter stringFromDate:_item.date];

    if (_imageUrl) {
        [self.articleDetail.imageView sd_setImageWithURL:[NSURL URLWithString:_imageUrl] placeholderImage:[UIImage imageNamed:@"default_placeholder"]];
        self.articleDetail.imageView.contentMode = UIViewContentModeScaleAspectFill;
        
        //Make the header/navbar transparent
        TabNavigationController *nc = (TabNavigationController *) self.navigationController;
        [nc.gradientView turnTransparencyOn:YES animated:YES];
        
        self.articleDetail.hasImage = YES;
    } else {
        // No header image? Hide the image top view
        self.articleDetail.hasImage = NO;
    }

    // after setting the above properties
    [self.articleDetail initialLayout];
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
        cell.lblDescription.numberOfLines = 1;
        
        return cell;
    }
    else if (indexPath.row == 1) {
        if ([_html length] == 0) {
            _html = ([_item.content length] == 0) ? _item.summary : _item.content;
        }
        
        contentCell = (ShowPageCell *)[tableView dequeueReusableCellWithIdentifier:@"ShowPageCell" forIndexPath:indexPath];
        
        contentCell.parentTable = [self.articleDetail getTableView];
        contentCell.parentViewController = self;
        [contentCell loadContent:_html];
        
        return contentCell;
    }
    else if (indexPath.row == 2) {
        ActionCell *cell = [tableView dequeueReusableCellWithIdentifier:@"actionCell" forIndexPath:indexPath];
        cell.actionDelegate = self;
        
        if ([_item.enclosures count] > 0){
            [[cell btnOpen] setTitle:NSLocalizedString(@"play", nil) forState:UIControlStateNormal];
        }
        
        return cell;
    }
    else{
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
    if ([_item.enclosures count] > 0){
        [AppDelegate openUrl:[[_item.enclosures objectAtIndex:0] objectForKey:@"url"] withNavigationController:self.navigationController];
    } else {
        [AppDelegate openUrl:_item.link withNavigationController:self.navigationController];
    }
}

- (IBAction)share:(id)sender
{
    NSArray *activityItems = [NSArray arrayWithObjects:_item.link,  nil];
    
    [self presentActions:activityItems sender:(id)sender];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
