//
//  DetailViewAssistant.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//
//  Implements TGFoursquareLocationDetail-Demo
//  Copyright (c) 2013 Thibault Guégan. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol DetailViewAssistantDelegate;

// Moving this whole class to a parent view controller might be a good idea
// among other things that would let to get rid of UIViewController *parentController
@interface DetailViewAssistant : UIView <UIScrollViewDelegate>

@property (nonatomic) CGFloat defaultimagePagerHeight;

/**
 How fast is the table view scrolling with the image picker
*/
@property (nonatomic) CGFloat parallaxScrollFactor;

@property (nonatomic) CGFloat headerFade;
@property (nonatomic) BOOL hasImage;

@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *imageHeightConstraint;

@property (nonatomic) CGRect defaultimagePagerFrame;

@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (strong, nonatomic) IBOutlet UIButton *playButton;

@property (nonatomic, strong) UIView *headerView;

@property (nonatomic, weak) id<UITableViewDataSource> tableViewDataSource;

@property (nonatomic, weak) id<UITableViewDelegate> tableViewDelegate;

@property (nonatomic, weak) id<DetailViewAssistantDelegate> delegate;

@property (nonatomic, weak) UIViewController *parentController;

- (UITableView *)getTableView;
- (void)initialLayout;
- (void)scrollViewDidScrollWithOffset:(CGFloat)scrollOffset;

@end

@protocol DetailViewAssistantDelegate <NSObject>

@optional

- (void)articleDetail:(DetailViewAssistant *)articleDetail
      tableViewDidLoad:(UITableView *)tableView;

- (void)articleDetail:(DetailViewAssistant *)articleDetail
      headerViewDidLoad:(UIView *)headerView;

- (void)articleDetail:(DetailViewAssistant *)articleDetail
      topImageDidLoad:(UIView *)headerView;
@end
