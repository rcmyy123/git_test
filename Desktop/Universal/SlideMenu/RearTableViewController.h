//
//  RearTableViewController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ConfigParserDelegate.h"

@interface RearTableViewController : UITableViewController <UITableViewDataSource, UITableViewDelegate> {
    UILabel *lblVertLine;
    UIImageView *cellImgVw;
    UILabel *lblHorizLineBottom;
}

@property (strong, nonatomic) UIView *headerView;
@property (strong, nonatomic) NSIndexPath *selectedIndexPath;

@property (strong, nonatomic) IBOutlet UIView *footerView;
@property (weak, nonatomic) IBOutlet UIButton *aboutButton;

@end
