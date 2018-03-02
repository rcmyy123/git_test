//
//  RadioViewController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "RadioViewController.h"
#import "SWRevealViewController.h"
#import <QuartzCore/QuartzCore.h>
#import "AppDelegate.h"
#import <MediaPlayer/MPMediaItem.h>
#import <MediaPlayer/MPNowPlayingInfoCenter.h>
#import "UIImageView+WebCache.h"

#define ALWAYS_RELOAD NO

@interface RadioViewController ()

@end

@implementation RadioViewController
AppDelegate *appDelegateRadio;

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
    
    //Configure Ads

    
    //Set the Sliding Menu listeners
    [self.view addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    [self.view addGestureRecognizer: self.revealViewController.tapGestureRecognizer];
    
    //Configure the layout
    [self configureAudioSession];
    
    //Allows us to update the player controls when the app is resumed
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterForeground:) name:UIApplicationWillEnterForegroundNotification object:nil];

    appDelegateRadio = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    //Initialize player items to be used when playback starts
    _playerItem=[AVPlayerItem alloc];
    _playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.params[0]]];
    
    [_playerItem addObserver:self forKeyPath:@"timedMetadata" options:NSKeyValueObservingOptionNew context:nil];
    
    //Set slider to actual volume level
    if (appDelegateRadio.player) {
        self.volumeSlider.value = appDelegateRadio.player.volume;
    }
        
    //Set the volume slider changed listener
    [self volumeSliderChanged:self];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [self updatePlayerControls];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self updatePlayerControls];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
}

-(void)viewDidDisappear:(BOOL)animated{
    [super viewDidDisappear:animated];
}

- (void) updatePlayerControls{
    //Set buttons to correct state after opening the radio
    if (appDelegateRadio.player.rate > 0){
        [self setPlayingLayout];
    } else {
        [self setPausedLayout];
    }
}

- (IBAction)volumeSliderChanged:(id)sender {
    appDelegateRadio.player.volume = self.volumeSlider.value;
}

-(NSString *)urlOfCurrentlyPlayingInPlayer:(AVPlayer *)player{
    // get current asset
    AVAsset *currentPlayerAsset = player.currentItem.asset;
    // make sure the current asset is an AVURLAsset
    if (![currentPlayerAsset isKindOfClass:AVURLAsset.class]) return nil;
    // return the NSURL
    return [[(AVURLAsset *)currentPlayerAsset URL] absoluteString];
}

- (IBAction)btnplayclicked:(id)sender {
    
    //If the player is non existant or paused, intepret as play
    if (appDelegateRadio.player == nil || appDelegateRadio.player.rate == 0){
    
        //Initialize new player if it does not yet exist, or if it is a player for a different url;
        if (appDelegateRadio.player == nil ||
            ![[self urlOfCurrentlyPlayingInPlayer:appDelegateRadio.player] isEqualToString: self.params[0]] || ALWAYS_RELOAD){
        
            _indicator.hidden = false;
        
            //We'll register our own new observers, so quit any existing players
            [appDelegateRadio closePlayerWithObserver: self];
        
            //In the case that ALWAYS_RELOAD is YES, we can not use the _playerItem so we create a new one.
            @try {
                appDelegateRadio.player = [AVPlayer playerWithPlayerItem:_playerItem];
            } @catch(NSException *e){
                appDelegateRadio.player = [AVPlayer playerWithURL:[NSURL URLWithString:self.params[0]]];
            }
        
            // Declare block scope variables to avoid retention cycles
            // from references inside the block
            __block AVPlayer* blockPlayer = appDelegateRadio.player;
            __weak UIActivityIndicatorView* indicator = _indicator;
            __block id obs;
        
            // Setup boundary time observer to trigger when audio really begins,
            // specifically after 1/3 of a second playback
            obs = [appDelegateRadio.player addBoundaryTimeObserverForTimes:
                   @[[NSValue valueWithCMTime:CMTimeMake(1, 3)]]
                                                            queue:NULL
                                                       usingBlock:^{
                                                           indicator.hidden = true;
                                                           
                                                           [self showMetaDataWithAnimation];
                                                           
                                                           // Remove the boundary time observer
                                                           [blockPlayer removeTimeObserver:obs];
                                                       }];
        } else {
            [self showMetaDataWithAnimation];
        }
    
        //We have now initialized the player with the correct URL, so we can play
        [appDelegateRadio.player play];
    
        [self setPlayingLayout];
    
        //Register for remove control events
        [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
        [self becomeFirstResponder];
        [appDelegateRadio setActivePlayerController:self];
    } else {
        [appDelegateRadio.player pause];
        [self setPausedLayout];
        
        //Unregister for remove control events
        [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
        [self resignFirstResponder];
        [appDelegateRadio setActivePlayerController:nil];

    }
}

- (void) setPlayingLayout {
    [_btnPlay setBackgroundImage:[UIImage imageNamed:@"Pause3.png"] forState:UIControlStateNormal];
    
    //Set the playing info for the Control Center
    [self setMPNowPlayingInfoCenterInfo: @"Live Streaming" : _navTitle];
}

- (void) setPausedLayout {
    [_btnPlay setBackgroundImage:[UIImage imageNamed:@"Play3.png"] forState:UIControlStateNormal];
    
    _metaLabel.hidden = true;
    
    //In the emulator, the MPNowPlayingInfo does not dissapear, so we'll manually set it to null;
    [self setMPNowPlayingInfoCenterInfo: @"" : @""];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setMPNowPlayingInfoCenterInfo:(NSString *) title :(NSString *) artist{
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{
            MPMediaItemPropertyTitle : title,
            MPMediaItemPropertyArtist : artist,
            MPNowPlayingInfoPropertyPlaybackRate:[NSNumber numberWithDouble:appDelegateRadio.player.rate],
     };
}

- (void) observeValueForKeyPath:(NSString*)keyPath ofObject:(id)object
                         change:(NSDictionary*)change context:(void*)context {
    
    if ([keyPath isEqualToString:@"timedMetadata"])
    {
        AVPlayerItem* playerItem = object;
        
        for (AVMetadataItem* metadata in playerItem.timedMetadata)
        {
            
            NSLog(@"Artist - Title: %@", metadata.stringValue); //at least for shoutcast
            
            [UIView beginAnimations:nil context:NULL];
            [UIView setAnimationDuration:1.0];
            [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.metaLabel cache:YES];
            
            [self.metaLabel setText: metadata.stringValue];
            
            [UIView commitAnimations];
            
            //NSLog(@"\nkey: %@\nkeySpace: %@\ncommonKey: %@\nvalue: %@", [metadata.key description], metadata.keySpace, metadata.commonKey, metadata.stringValue);
        }
    }
}

- (void) showMetaDataWithAnimation {
    [UIView beginAnimations:nil context:NULL];
    [UIView setAnimationDuration:1.0];
    [UIView setAnimationTransition:UIViewAnimationTransitionFlipFromLeft forView:self.metaLabel cache:YES];
    
    self.metaLabel.hidden = false;
    
    [UIView commitAnimations];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event {
    if (event.type == UIEventTypeRemoteControl) {

        switch(event.subtype)
        {
            case UIEventSubtypeRemoteControlPause:
                [appDelegateRadio.player pause];
            case UIEventSubtypeRemoteControlStop:
                break;
            case UIEventSubtypeRemoteControlPlay:
                [appDelegateRadio.player play];
            default:
                break;
        }
        
        NSDictionary *songInfo = [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo;
        NSMutableDictionary *mutableSongInfo = [songInfo mutableCopy];
        [mutableSongInfo setObject: [NSNumber numberWithDouble:appDelegateRadio.player.rate] forKey: MPNowPlayingInfoPropertyPlaybackRate];
        
        [[MPNowPlayingInfoCenter defaultCenter] setNowPlayingInfo:mutableSongInfo];
    }
}

- (void)configureAudioSession {
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
    }
    
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_playerItem removeObserver:self forKeyPath:@"timedMetadata" context:nil];

}


@end
