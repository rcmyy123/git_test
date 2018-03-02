//
//  RssDetailViewController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewAssistant.h"
#import "ActionCell.h"
#import "TitleCell.h"
#import "ShowPageCell.h"
#import "MWFeedItem.h"

@interface RssDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, DetailViewAssistantDelegate, DetailViewActionDelegate>

@property (nonatomic, strong) DetailViewAssistant *articleDetail;

@property (nonatomic, retain) NSString *wrappedText;
@property (nonatomic, retain) NSString *titleText;
@property (nonatomic, retain) UIFont *textFont;

//old
@property (strong,nonatomic) NSString *imageUrl;
@property (strong,nonatomic) NSString *date;
@property (strong,nonatomic) NSString *html;

@property (nonatomic, strong) MWFeedItem *item;

@property (weak, nonatomic) IBOutlet UILabel *headerTitle;
@end
