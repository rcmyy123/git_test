//
//  YoutubeDetailViewController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewAssistant.h"
#import "ActionCell.h"
#import "TitleCell.h"
#import "ShowPageCell.h"

@interface YoutubeDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, DetailViewAssistantDelegate, DetailViewActionDelegate>

@property (nonatomic, strong) DetailViewAssistant *articleDetail;

@property (nonatomic, retain) NSString *titleText;
@property (nonatomic, retain) UIFont *textFont;

@property (strong,nonatomic) NSString *videoUrl;
@property (strong,nonatomic) NSString *videoId;
@property (strong,nonatomic) NSString *imageUrl;
@property (strong,nonatomic) NSString *summary;
@property (strong,nonatomic) NSString *date;

@property (strong,nonatomic) UIButton *buttonPost;
@property (strong,nonatomic) UIButton *buttonBack;

@property (weak, nonatomic) IBOutlet UILabel *headerTitle;
@end
