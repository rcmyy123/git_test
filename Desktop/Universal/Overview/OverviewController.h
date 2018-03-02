//
//  OverviewController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CardCell.h"
#import "UIImageView+WebCache.h"
#import "STableViewController.h"
#import "ConfigParserDelegate.h"

@interface OverviewController : STableViewController <CardCellDelegate, ConfigParserDelegate, UITableViewDataSource, UITableViewDelegate>  {
}

@property(strong,nonatomic)NSArray *itemsToDisplay;

@property(strong,nonatomic)NSArray *params;

@end
