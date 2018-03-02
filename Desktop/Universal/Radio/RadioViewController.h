//
//  RadioViewController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MarqueeLabel.h"

@interface RadioViewController : UIViewController<AVAudioPlayerDelegate>

- (IBAction)btnplayclicked:(id)sender;

@property(strong,nonatomic)NSArray *params;
@property(strong,nonatomic)NSString *navTitle;

@property (strong, nonatomic) IBOutlet UIButton *btnPlay;
@property (weak, nonatomic) IBOutlet UISlider *volumeSlider;
@property (weak, nonatomic) IBOutlet MarqueeLabel *metaLabel;

@property(nonatomic , strong) AVPlayerItem *playerItem;

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;

-(void)remoteControlReceivedWithEvent:(UIEvent *)event;

@end
