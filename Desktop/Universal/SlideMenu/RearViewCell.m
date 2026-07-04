//
//  RearViewCell.m
//  Universal
//
//  Created by Mu-Sonic on 07/11/2015.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import "RearViewCell.h"

@implementation RearViewCell

- (void)awakeFromNib {
    //self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
   //    cell.textLabel.textColor = [UIColor whiteColor];
   //    cell.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16];

    UIView *bgColorView = [[UIView alloc] init];
    bgColorView.backgroundColor = SELECTED_COLOR;
    [self setSelectedBackgroundView:bgColorView];
    [super awakeFromNib];
}

- (void)prepareForReuse {
    self.imageView.image = nil;
    [super prepareForReuse];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
@end
