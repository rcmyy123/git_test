//
//  DetailViewAssistant.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//
//  Implements TGFoursquareLocationDetail-Demo
//  Copyright (c) 2013 Thibault Guégan. All rights reserved.
//

#import "DetailViewAssistant.h"

@implementation DetailViewAssistant

- (id)init
{
    self = [super init];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    return self;
}

- (void)initialize
{
    _defaultimagePagerHeight        = 200.0f;
    _parallaxScrollFactor           = 0.6f;
//    _headerFade                     = 130.0f;
    self.autoresizesSubviews        = YES;
//    self.autoresizingMask           = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
}

- (void)initialLayout {
    // table view -------------------
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.estimatedRowHeight = 200;
    
    //self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self.tableViewDelegate;
    self.tableView.dataSource = self.tableViewDataSource;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView.tableHeaderView.backgroundColor = [UIColor clearColor];
    // table view -------------------
    
    // image view -------------------
    _imageTopConstraint.constant = -self.defaultimagePagerHeight * self.parallaxScrollFactor * 0.6;
    _imageHeightConstraint.constant = self.defaultimagePagerHeight + (self.defaultimagePagerHeight * self.parallaxScrollFactor * 2);
    // image view -------------------
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    CGRect navbarFrame = _parentController.navigationController.navigationBar.frame;
    CGFloat topLayoutGuide = navbarFrame.origin.y + navbarFrame.size.height;
    
    // adjust blank table header when no image
    if (!self.hasImage && self.tableView.tableHeaderView.bounds.size.height != 0) {
        CGRect hRect = self.tableView.tableHeaderView.bounds;
        hRect.size.height = 0;
        self.tableView.tableHeaderView.bounds = hRect;
        // needed to shift the content of the table
        self.tableView.tableHeaderView = self.tableView.tableHeaderView;
    }
    
    // headerFade might also account for the tableView top inset, but it is zero
    _headerFade = self.tableView.tableHeaderView.bounds.size.height - topLayoutGuide;
}

- (void)setTableViewDataSource:(id<UITableViewDataSource>)tableViewDataSource
{
    _tableViewDataSource = tableViewDataSource;
    self.tableView.dataSource = _tableViewDataSource;
    
    if (_tableViewDelegate) {
        [self.tableView reloadData];
    }
}

- (void)setTableViewDelegate:(id<UITableViewDelegate>)tableViewDelegate
{
    _tableViewDelegate = tableViewDelegate;
    self.tableView.delegate = _tableViewDelegate;
    
    if (_tableViewDataSource) {
        [self.tableView reloadData];
    }
}

- (UITableView *)getTableView
{
    return self.tableView;
}

- (void)setHeaderView:(UIView *)headerView
{
    _headerView = headerView;
    
    if([self.delegate respondsToSelector:@selector(articleDetail:headerViewDidLoad:)]){
        [self.delegate articleDetail:self headerViewDidLoad:self.headerView];
    }
}

- (void)scrollViewDidScrollWithOffset:(CGFloat)scrollOffset {
    CGFloat junkViewFrameYAdjustment = 0.0;
    
    // If the user is pulling down
    if (scrollOffset < 0) {
        junkViewFrameYAdjustment = -self.defaultimagePagerHeight * self.parallaxScrollFactor * 0.6 - (scrollOffset * self.parallaxScrollFactor);
    }
    
    // If the user is scrolling normally,
    else {
        junkViewFrameYAdjustment = -self.defaultimagePagerHeight * self.parallaxScrollFactor * 0.6 - (scrollOffset * self.parallaxScrollFactor);
        
        // Don't move the map way off-screen
        if (junkViewFrameYAdjustment <= -(self.imageHeightConstraint.constant)) {
            junkViewFrameYAdjustment = -(self.imageHeightConstraint.constant);
        }

    }
    
    if (junkViewFrameYAdjustment) {
        self.imageTopConstraint.constant = junkViewFrameYAdjustment;
        [self setNeedsUpdateConstraints];
    }
}

@end
