//
// WordpressViewController.h
//
// Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STableViewController.h"
#import "UIImageView+WebCache.h"
#import "MWFeedParser.h"
#import "WordpressProvider.h"

@interface WordpressViewController : STableViewController <UISearchBarDelegate> {
  
    NSMutableArray *parsedItems;
    
    NSDateFormatter *formatter;
    int page;
    id <WordpressProvider> provider;
    
    UISearchBar *searchBar;
    UIBarButtonItem *searchButton;
    UIBarButtonItem *cancelButton;
    NSString *query;

}

@property(strong,nonatomic)NSArray *params;

@end
