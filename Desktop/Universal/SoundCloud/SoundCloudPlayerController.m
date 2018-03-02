//
//  SoundCloudPlayerController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "SoundCloudPlayerController.h"
#import "PlayingCell.h"
#import "AppDelegate.h"
#import <MediaPlayer/MediaPlayer.h>

@interface SoundCloudPlayerController () <UICollectionViewDataSource, UICollectionViewDelegate>
- (IBAction)seekBarExit:(id)sender;
- (IBAction)seekBarEnter:(id)sender;

@property (strong, nonatomic) NSURLSession* session;
@property BOOL isSCPlaying;

- (IBAction)userScrubbing:(id)sender;
- (IBAction)setCurrentTime:(id)sender;

@property (strong, nonatomic) NSOperationQueue* dataQueue;

@property (strong, nonatomic) NSOperationQueue* imageQueue;
@property (weak, nonatomic) IBOutlet UILabel *artistLabel;
@property (weak, nonatomic) IBOutlet UILabel *trackTitleLabel;
@property (strong, nonatomic) IBOutlet UIView *viewToAnimate;
//@property (strong, nonatomic) NSArray* colors;

@property (strong, nonatomic) UIImage* playImage;
@property (strong, nonatomic) UIImage* pauseImage;
@property (weak, nonatomic) IBOutlet UIImageView *nextImageButton;
@property (weak, nonatomic) IBOutlet UIImageView *previousImageButton;

@property (strong, nonatomic) NSTimer *updateTimer;
@property (weak, nonatomic) IBOutlet UISlider *seekBar;
@property (weak, nonatomic) IBOutlet UILabel *durationLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentTimeLabel;
@property (strong, nonatomic) UIImage* currentAlbumImage;
@property (strong, nonatomic) UIImage* lockScreenImage;

@property float progress;
@property float duration;

@property BOOL isCrubbing;
@property BOOL isCurrentTrack;
@property BOOL shouldSkip;

@property (weak, nonatomic) IBOutlet UIImageView *playImageButton;

@property (weak, nonatomic) IBOutlet UIView *loadingBackground;
@property (strong, nonatomic) UIActivityIndicatorView* spinner;
@property (strong, nonatomic) UIView* loadingView;
@property (strong, nonatomic) UILabel* loadingLabel;
@property (strong, nonatomic) NSCache* artworkCache;

@property (weak, nonatomic) IBOutlet UIImageView *backGroundImageView;

@end

AppDelegate *appDelegate;

@implementation SoundCloudPlayerController

-(void)initialLoad {
    [self visualCustomization];
    
    self.dataQueue = [NSOperationQueue new];
    self.imageQueue = [[NSOperationQueue alloc]init];
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    [self addNOTObservers];
    
    [self configureAudioSession];
    
    self.artworkCache = [[NSCache alloc]init];
    
    self.playImage = [UIImage imageNamed:@"Play3"];
    self.pauseImage = [UIImage imageNamed:@"Pause3"];
    
    appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [appDelegate closePlayerWithObserver: self];
    
    self.seekBar.continuous = YES;
    
    //allows avlayer to continue in background...need to look into more
    
    //[self sizeCheck];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.collectionView reloadData];
}

-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    //gesture to dismiss when swiped down from anywhere
    UISwipeGestureRecognizer* swipeDownGestureRecognizer = [[UISwipeGestureRecognizer alloc]
                                                            initWithTarget:self
                                                            action:@selector(dismissViewController)];
    
    swipeDownGestureRecognizer.direction = UISwipeGestureRecognizerDirectionDown;
    
    [self.view addGestureRecognizer:swipeDownGestureRecognizer];
}

- (BOOL) canBecomeFirstResponder
{
    return YES;
}

- (void)remoteControlReceivedWithEvent:(UIEvent *)receivedEvent {
    
    if (receivedEvent.type == UIEventTypeRemoteControl) {
        
        switch (receivedEvent.subtype) {
                
            case UIEventSubtypeRemoteControlPlay:
                [appDelegate.player play];
                NSLog(@"bg play pressed");
                break;
                
            case UIEventSubtypeRemoteControlPause:
                [appDelegate.player pause];
                NSLog(@"bg pause pressed");
                break;
                
            case UIEventSubtypeRemoteControlPreviousTrack:
                NSLog(@"bg previous pressed");
                [self playPreviousTrack];
                break;
                
            case UIEventSubtypeRemoteControlNextTrack:
                NSLog(@"bg next pressed");
                [self playNextTrack];
                
            default:
                break;
        }
    }
    
}

-(void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
}

//MARK: Notifications, Delegates, KVO
-(void)addNOTObservers {
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(playSoundCloudTrack) name:@"playSoundCloud" object:nil];
    
    //Observing <current item> that AVPlayer is playing if end is reached
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playNextTrack) name:AVPlayerItemDidPlayToEndTimeNotification object:[appDelegate.player currentItem]];
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"rate"]) {
        if (appDelegate.player.rate == 0) {
            [self.playImageButton setImage:self.playImage];
            [[NSNotificationCenter defaultCenter]postNotificationName:@"stopAnimateMusic" object:nil];
        }else {
            [self.playImageButton setImage:self.pauseImage];
            
            [[NSNotificationCenter defaultCenter]postNotificationName:@"animateMusic" object:nil];
        }
        
        [self setMPNowPlayingInfoCenterInfo];
    }
    
}


//MARK: PLAY Logics
-(void)playSoundCloudTrack  {
    
    [self.spinner startAnimating];
    [self.loadingBackground setHidden:NO];
    
    self.isCurrentTrack = YES;
    
    //removing any existing observers (as we don't know their original, e.g. radio). So we can set our own observers later.
    [appDelegate closePlayerWithObserver: self];
    
    self.shouldSkip = NO;
    
    [self.playImageButton setImage:self.pauseImage];
    
    
    self.soundCloudTrack = [self.playArray objectAtIndex:self.playIndex];
    
    appDelegate.player = [[AVPlayer alloc]initWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@?client_id=%@",self.soundCloudTrack.stream_url, SOUNDCLOUD_CLIENT]]];
    //NSLog(@"no soundcloudplayer, allocating new one");
    
    [appDelegate.player addObserver:self
                              forKeyPath:@"rate"
                                 options:NSKeyValueObservingOptionNew
                                 context:nil];
    
    [self playPauseTapped];
    
    [self.artistLabel setText:self.soundCloudTrack.userName];
    [self.trackTitleLabel setText:self.soundCloudTrack.title];
    
    [self.seekBar setTintColor:[UIColor whiteColor]];
    
    [self startSeekBar];
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"animateMusic" object:nil];
    
    [self setMPNowPlayingInfoCenterInfo];
    
}

- (void)configureAudioSession {
    NSError *error;
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
    [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (error) {
        NSLog(@"Error setting category: %@", [error description]);
    }
    
}


//MARK: UI elements/animations
-(void)visualCustomization {
    
    //activity spinner
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.spinner.center = self.view.center;
    self.spinner.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleBottomMargin;
    self.spinner.tag = 12;
    [self.view addSubview:self.spinner];
    
    self.loadingBackground.hidden = YES;
    self.loadingBackground.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    [self.loadingBackground.layer setCornerRadius:10.0];
    
    self.seekBar.minimumValue = 0.0;
    
    UITapGestureRecognizer *playPauseTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(playPauseTapped)];
    UITapGestureRecognizer *dismissTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:
                                          @selector(dismissViewController)];
    
    [self.playImageButton setUserInteractionEnabled:YES];
    [self.playImageButton addGestureRecognizer:playPauseTap];
    
    [self.dismissButton setUserInteractionEnabled:YES];
    [self.dismissButton addGestureRecognizer:dismissTap];
    
    [self.seekBar setMinimumValue:0];
    
    [self applyBlurToView:self.backGroundImageView withEffectStyle:UIBlurEffectStyleDark andConstraints:YES];
    
}

- (UIView *)applyBlurToView:(UIView *)view withEffectStyle:(UIBlurEffectStyle)style andConstraints:(BOOL)addConstraints
{
    //only apply the blur if the user hasn't disabled transparency effects
    if(!UIAccessibilityIsReduceTransparencyEnabled())
    {
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:style];
        UIVisualEffectView *blurEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        blurEffectView.frame = view.bounds;
        
        [view addSubview:blurEffectView];
        
        if(addConstraints)
        {
            //add auto layout constraints so that the blur fills the screen upon rotating device
            [blurEffectView setTranslatesAutoresizingMaskIntoConstraints:NO];
            
            [view addConstraint:[NSLayoutConstraint constraintWithItem:blurEffectView
                                                             attribute:NSLayoutAttributeTop
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:view
                                                             attribute:NSLayoutAttributeTop
                                                            multiplier:1
                                                              constant:0]];
            
            [view addConstraint:[NSLayoutConstraint constraintWithItem:blurEffectView
                                                             attribute:NSLayoutAttributeBottom
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:view
                                                             attribute:NSLayoutAttributeBottom
                                                            multiplier:1
                                                              constant:0]];
            
            [view addConstraint:[NSLayoutConstraint constraintWithItem:blurEffectView
                                                             attribute:NSLayoutAttributeLeading
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:view
                                                             attribute:NSLayoutAttributeLeading
                                                            multiplier:1
                                                              constant:0]];
            
            [view addConstraint:[NSLayoutConstraint constraintWithItem:blurEffectView
                                                             attribute:NSLayoutAttributeTrailing
                                                             relatedBy:NSLayoutRelationEqual
                                                                toItem:view
                                                             attribute:NSLayoutAttributeTrailing
                                                            multiplier:1
                                                              constant:0]];
        }
    }
    else
    {
        view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.7];
    }
    
    return view;
}

- (void) setMPNowPlayingInfoCenterInfo {
    [MPNowPlayingInfoCenter defaultCenter].nowPlayingInfo = @{
                                                              MPMediaItemPropertyTitle : self.soundCloudTrack.title,
                                                              MPMediaItemPropertyArtist : self.soundCloudTrack.userName,
                                                              //MPMediaItemPropertyPlaybackDuration : self.soundCloudTrack.duration,
                                                              MPMediaItemPropertyAlbumTrackCount : [NSNumber numberWithLong: self.playArray.count],
                                                              MPMediaItemPropertyAlbumTrackNumber : [NSNumber numberWithLong: self.playIndex],
                                                              MPNowPlayingInfoPropertyPlaybackRate:[NSNumber numberWithDouble:appDelegate.player.rate]
                                                              };
}

- (void)dismissViewController {
    [self dismissViewControllerAnimated:YES completion:nil];
}

//MARK: Play/UI Actions

- (IBAction)userScrubbing:(id)sender {
    self.isCrubbing = YES;
    
}

- (IBAction)setCurrentTime:(id)sender {
    CMTime t = CMTimeMake(self.seekBar.value, 1);
    
    if (self.soundCloudTrack) {
        [appDelegate.player seekToTime:t];
    }
    
    self.isCrubbing = NO;
}

-(void)startSeekBar {
    
    float duration = 0.0;
    if (self.soundCloudTrack) {
        float durationInMilliSec = [self.soundCloudTrack.duration integerValue];
        float durationInSec = durationInMilliSec / 1000.00;
        duration = durationInSec;
    }
    
    self.seekBar.maximumValue = duration;
    [self.durationLabel setText:[self stringFromTimeInterval:duration]];
    
    self.updateTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateSeekBar) userInfo:nil repeats:YES];
    
}

- (NSString *)stringFromTimeInterval:(NSTimeInterval)interval {
    NSInteger ti = (NSInteger)interval;
    NSInteger seconds = ti % 60;
    NSInteger minutes = (ti / 60) % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld",(long)minutes, (long)seconds];
}

-(void)updateSeekBar {
    
    if (self.soundCloudTrack) {
        float f = CMTimeGetSeconds(appDelegate.player.currentTime);
        self.progress = f;
        if (f > 0.1) {
            [self.spinner stopAnimating];
            [self.loadingBackground setHidden:YES];
        }
    }
    
    if (self.isCrubbing == NO) {
        [self.seekBar setValue:self.progress animated:YES];
        [self.currentTimeLabel setText:[self stringFromTimeInterval:self.progress]];
    }
    
    if (self.progress < 1) {
        self.shouldSkip = YES;
    }
    
    
    //NSLog(@"progress %f", self.progress);
    
}

-(void)playPauseTapped {
    if (self.soundCloudTrack) {
        
        if (appDelegate.player.rate > 0) {
            [appDelegate.player pause];
            
            //controls
            [[UIApplication sharedApplication] endReceivingRemoteControlEvents];
            [self resignFirstResponder];
            [appDelegate setActivePlayerController:nil];
        } else {
            [appDelegate.player play];
            
            //controls
            [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
            [self becomeFirstResponder];
            [appDelegate setActivePlayerController: self];
        }
        
    }
}

-(void)playNextTrack {
    
    NSLog(@"PlayNextTrack called");
    
    if ((self.playIndex +1) < self.playArray.count) {
        self.playIndex ++;
        
        if(self.soundCloudTrack){
            [self playSoundCloudTrack];
        }
    }
    
    self.shouldSkip = NO;
    
}

-(void)playPreviousTrack {
    
    if (self.playIndex > 0) {
        
        if (self.progress < 3 ) {
            self.playIndex --;
        }
        
        self.shouldSkip = NO;
        
        if(self.soundCloudTrack){
            [self playSoundCloudTrack];
        }
    }
    
}

- (IBAction)seekBarExit:(id)sender {
    self.isCrubbing = NO;
}

- (IBAction)seekBarEnter:(id)sender {
    self.isCrubbing = YES;
}

//MARK: CollectionView
-(CGSize) collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return self.collectionView.frame.size;
}

-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.playArray.count;
}

-(UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    
    PlayingCell* cell = (PlayingCell*)[collectionView dequeueReusableCellWithReuseIdentifier:@"PLAYING_CELL" forIndexPath:indexPath];
    
    if (self.soundCloudTrack ) {
        //NSLog(@"SOUNDCLOUD IN DA CELL");
        self.soundCloudTrack = self.playArray[indexPath.row];
        [self fetchSoundCloudArtwork:self.soundCloudTrack cell:cell];
        
    }
    
    return cell;
}

-(void)scrollViewWillBeginDragging:(UIScrollView *)scrollView{
    self.isCurrentTrack = NO;
    
}

//MARK: CollectionView Action
//get index when scrolling stop and run play logic
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate) {
        [self trackSelectedBySwipe];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    [self trackSelectedBySwipe];
}

- (void) trackSelectedBySwipe {
    for (PlayingCell *cell in [self.collectionView visibleCells]) {
        NSIndexPath *indexPath = [self.collectionView indexPathForCell:cell];
        
        if (self.playIndex != indexPath.row) {
            //NSLog(@"INDEXPATH%@",indexPath);
            self.playIndex = indexPath.row;
            
            self.isCurrentTrack = YES;
            self.shouldSkip = NO;
            
            if(self.soundCloudTrack){
                [self playSoundCloudTrack];
                
                //replaces backgroundimage when song is actually playing
                [self fetchSoundCloudArtwork:self.soundCloudTrack cell:nil];
                
            }
            
        }
    }

}

//Will scroll to playing track
- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    if (self.soundCloudTrack) {
        
       NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.playIndex inSection:0];
        
        //We introduce a small delay, which solves the issue that the correct track would not be shown
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.3 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            [self.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
        });
        
        //[self.view layoutIfNeeded];

    }
}

//MARK: Data fetching
-(void)fetchSoundCloudArtwork: (SoundCloudSong*)soundCloudTrack cell: (PlayingCell*)cell {
    
    [cell.imageView setImage:[UIImage imageNamed:@"blur2"]];
    
    //Sometimes track doesn't have artwork_url; use user avatar instead
    NSURL* url = nil;
    if ( [soundCloudTrack.artWorkURL  isEqual: [NSNull null]]) {
        if ([soundCloudTrack.userAvatar containsString:@"large"]) {
            NSString* bigVer =[soundCloudTrack.userAvatar stringByReplacingOccurrencesOfString:@"large" withString:@"t500x500"];
            url = [[NSURL alloc]initWithString:bigVer];
            
        }
    }else{
        url = [[NSURL alloc]initWithString:soundCloudTrack.artWorkURL];
        if ([soundCloudTrack.artWorkURL containsString:@"large"]) {
            NSString* bigVer = [soundCloudTrack.artWorkURL stringByReplacingOccurrencesOfString:@"large" withString:@"t500x500"];
            url = [[NSURL alloc]initWithString:bigVer];
        }
    }
    if (url) {
        
        [self.imageQueue addOperationWithBlock:^{
            NSError *error = nil;
            UIImage *image = nil;
            NSData *imageData = [NSData dataWithContentsOfURL:url options:0 error:&error];
            
            if (imageData != nil) {
                image = [UIImage imageWithData:imageData];
                
            }
            
            if (image) {
                
                [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                    
                    //self.lockScreenImage = image;
                    
                    [UIView transitionWithView:cell.imageView
                                      duration:0.5f
                                       options:UIViewAnimationOptionTransitionCrossDissolve
                                    animations:^{
                                        cell.imageView.image = image;
                                        
                                    } completion:nil];
                    
                    if (self.isCurrentTrack == YES) {
                        [self.backGroundImageView setImage:image];
                    }
                    
                    
                }];
            }
        }];
    }
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


@end
