//
//  InstagramViewController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardCell.h"
#import "SocialFetcher.h"
#import "UIImageView+WebCache.h"
#import "STableViewController.h"

@interface InstagramViewController : STableViewController <CardCellDelegate, UITableViewDataSource, UITableViewDelegate>

@property(strong,nonatomic)NSArray *params;
@property(strong,nonatomic)NSMutableArray *postItems;

@end
