//
// YoutubeViewController.h
//
// Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STableViewController.h"
#import "UIImageView+WebCache.h"
#import "MWFeedParser.h"

@interface YoutubeViewController : STableViewController <UISearchBarDelegate> {
  
    UIImageView *imgVwCell;
    UILabel *lblCell;

    NSMutableArray *parsedItems;
    UITableView *tableView;
    
    NSDateFormatter *formatter;
    int count;
    NSDictionary *jsonDict;
    NSString *pageToken;
    
    UISearchBar *searchBar;
    UIBarButtonItem *searchButton;
    UIBarButtonItem *cancelButton;
    NSString *query;

}

@property(strong,nonatomic)NSArray *params;

@end
