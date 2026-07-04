//
//  AssistTableCell.h
//  Universal
//
//  Created by Mu-Sonic on 27/10/2015.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "KILabel.h"

@interface AssistTableCell : UITableViewCell

@property (strong, nonatomic) IBOutlet UIImageView *image;

// "HeaderCell" specific
@property (strong, nonatomic) IBOutlet UIView *gradientView;
@property (strong, nonatomic) IBOutlet KILabel *lblHeadTitle;

// "Cell" specific
@property (weak, nonatomic) IBOutlet UILabel *lblTitle;
@property (strong, nonatomic) IBOutlet UILabel *lblSummary;
@property (strong, nonatomic) IBOutlet UILabel *lblDate;

- (void)setNoImage:(BOOL)noImage;

@end
