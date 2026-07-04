//
//  SoundCloudCell.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SoundCloudCell;

@protocol SoundCloudCellDelegate;

@interface SoundCloudCell : UITableViewCell

/** 
 * Damping of the physical spring animation. Expressed in percent.
 * 
 * @discussion Only applied for version of iOS > 7.
 */
@property (nonatomic, assign, readwrite) CGFloat damping;
@property (weak, nonatomic) IBOutlet UILabel *trackNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UIImageView *albumImageView;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;


@end

