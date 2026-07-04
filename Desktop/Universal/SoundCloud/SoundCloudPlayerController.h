//
//  SoundCloudPlayerController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "SoundCloudViewController.h"
#import "SoundCloudSong.h"

@interface SoundCloudPlayerController : UIViewController <AVAudioPlayerDelegate>

@property (strong, nonatomic) NSMutableArray* playArray;
@property (nonatomic) NSInteger playIndex;
@property (strong, nonatomic) SoundCloudSong* soundCloudTrack;
@property float soundCloudDuration;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (weak, nonatomic) IBOutlet UIImageView *dismissButton;

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent;
- (void)initialLoad;

@end
