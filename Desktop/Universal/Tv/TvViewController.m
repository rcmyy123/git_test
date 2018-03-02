//
//  TvViewController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "TvViewController.h"
#import "SWRevealViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import <MediaPlayer/MPMediaItem.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import "UIImageView+WebCache.h"

@interface TvViewController ()

@end

@implementation TvViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Set the Sliding Menu listeners
    [self.view addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    [self.view addGestureRecognizer: self.revealViewController.tapGestureRecognizer];
    
    //Configure the videoPlayer
    self.videoPlayerViewController = [VideoPlayerKit videoPlayerWithContainingViewController:self optionalTopView:nil hideTopViewWithControls:YES];
    self.videoPlayerViewController.allowPortraitFullscreen = YES;
    self.videoPlayerViewController.delegate = self;
    self.videoPlayerViewController.view.backgroundColor = [UIColor blackColor];
    self.videoPlayerViewController.videoPlayerView.shareButton.hidden = YES;
    [self.view addSubview:self.videoPlayerViewController.view];
   
    NSURL *url = [NSURL URLWithString:self.params[0]];
    [self.videoPlayerViewController playVideoWithTitle:@"" URL:url videoID:nil shareURL:nil isStreaming:YES playInFullScreen:NO];

}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];

    if (!self.videoPlayerViewController.fullScreenModeToggled) {
        self.videoPlayerViewController.videoPlayerView.frame = self.videoView.frame;
        self.videoPlayerViewController.videoPlayerView.bounds = self.videoView.bounds;
    }

}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
}

-(void)viewWillAppear:(BOOL)animated{
}

-(void)viewWillDisappear:(BOOL)animated{

}

-(void)viewDidDisappear:(BOOL)animated{
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}




@end
