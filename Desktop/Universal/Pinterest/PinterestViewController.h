//
//  PinterestViewController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardCell.h"
#import "SocialFetcher.h"
#import "UIImageView+WebCache.h"
#import "STableViewController.h"

@interface PinterestViewController : STableViewController <CardCellDelegate, UITableViewDataSource, UITableViewDelegate>

@property(strong,nonatomic)NSArray *params;
@property(strong,nonatomic)NSMutableArray *postItems;

@end
