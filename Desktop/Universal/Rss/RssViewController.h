//
//  RssViewController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//
//  Implements: MWFeedParser
//  Copyright (c) 2010 Michael Waterfall
//

#import <UIKit/UIKit.h>
#import "MWFeedParser.h"
#import "UIImageView+WebCache.h"
#import "STableViewController.h"

@interface RssViewController : STableViewController <MWFeedParserDelegate> {
	
	// Parsing
	MWFeedParser *feedParser;
	NSMutableArray *parsedItems;
	
	// Displaying
	NSArray *itemsToDisplay;
	NSDateFormatter *formatter;
	
}

// Properties
@property (nonatomic, strong) NSArray *itemsToDisplay;
@property(strong,nonatomic)NSArray *params;

@end
