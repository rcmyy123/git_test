//
//  WordpressDetailViewController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DetailViewAssistant.h"
#import "ActionCell.h"
#import "TitleCell.h"
#import "ShowPageCell.h"

@interface WordpressDetailViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, DetailViewAssistantDelegate, DetailViewActionDelegate>

@property (nonatomic, strong) IBOutlet DetailViewAssistant *articleDetail;

@property (nonatomic, retain) NSString *titleText;
@property (nonatomic, retain) NSString *subTitleText;
@property (nonatomic, retain) UIFont *textFont;

@property BOOL isJSONAPI;

@property (strong,nonatomic) NSArray *apiConfig;
@property (strong,nonatomic) NSString *detailID;
@property (strong,nonatomic) NSString *articleUrl;
@property (strong,nonatomic) NSString *imageUrl;
@property (strong,nonatomic) NSString *date;
@property (strong,nonatomic) NSString *author;
@property (strong,nonatomic) NSString *html;

@property (weak, nonatomic) IBOutlet UILabel *headerTitle;
@end
