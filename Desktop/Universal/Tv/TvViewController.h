//
//  TvViewController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "MarqueeLabel.h"
#import "VideoPlayerKit.h"
#import "VideoPlayerView.h"

@interface TvViewController : UIViewController <VideoPlayerDelegate>

@property(strong,nonatomic)NSArray *params;
@property (weak, nonatomic) IBOutlet VideoPlayerView *videoView;

@property (nonatomic, strong) VideoPlayerKit *videoPlayerViewController;

@end
