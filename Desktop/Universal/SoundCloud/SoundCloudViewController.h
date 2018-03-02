//
//  SoundCloudViewController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "SoundCloudPlayerController.h"
#import "STableViewController.h"


@interface SoundCloudViewController : STableViewController

@property (strong, nonatomic) NSMutableArray* SoundCloudSongList;

@property (strong, nonatomic) NSArray *params;


@end


