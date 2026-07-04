//
//  SoundCloudViewController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "SoundCloudViewController.h"
#import "SoundCloudCell.h"
#import "SoundCloudSong.h"
#import "SoundCloudAPI.h"

#import "SoundCloudPlayerController.h"
#import "AppDelegate.h"

int const perPage = 20;

@interface SoundCloudViewController () <UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate>
- (void) addItemsOnBottom;

@property (strong, nonatomic) SoundCloudSong* selectedTrack;
@property (nonatomic) NSInteger selectedTrackRow;
@property (nonatomic) NSInteger selectedTrackSection;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@property (strong, nonatomic) NSMutableArray* filteredSoundCloudSongs;
@property (strong, nonatomic) NSMutableArray* soundCloudSearchResults;
@property (strong, nonatomic) NSOperationQueue* imageQueue;
@property (strong, nonatomic) NSCache * imageCache;
@property (strong, nonatomic) NSString *segueSender;
@property (strong, nonatomic) NSString* artworkURLSave;
@property (strong, nonatomic) SoundCloudPlayerController* playVC;

@property float verticalContentOffset;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *musicAnimationViewBarItem;

@property BOOL isFiltered;

@end

@implementation SoundCloudViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    

    
    [self.tableView addGestureRecognizer: self.revealViewController.panGestureRecognizer];
    [self.tableView addGestureRecognizer: self.revealViewController.tapGestureRecognizer];
    
    //We do not use the PullToRefresh from STAbleViewController, but our own.
    //Therefore, we remove their pull to refresh layout and disable the functionality
    self.pullToRefreshEnabled = NO;
    [self.headerView removeFromSuperview];
    
    [self initUI];
    
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(animateMusic) name:@"animateMusic" object:nil];
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(stopAnimateMusic) name:@"stopAnimateMusic" object:nil];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SoundCloudCell" bundle:[NSBundle mainBundle]]forCellReuseIdentifier:@"MC_TRACK_CELL"];
    
    self.imageQueue = [[NSOperationQueue alloc]init];
    self.imageQueue.maxConcurrentOperationCount = 8;
    self.imageCache = [[NSCache alloc]init];
    
    [self.tableView setContentOffset:CGPointMake(0, 44)];
    
    //[self sizeCheck];
    
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    //scroll to saved position
    [self.tableView setContentOffset:CGPointMake(0, self.verticalContentOffset)];
   
}

-(void) viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    //saves scroll position
    self.verticalContentOffset  = self.tableView.contentOffset.y;
    
}

-(void)initUI{
    
    //Refresh Control
    if (!self.refreshControl){
        self.refreshControl = [[UIRefreshControl alloc] init];
    }
    
    [self.refreshControl addTarget:self
                            action:@selector(refresh:)
                  forControlEvents:UIControlEventValueChanged];

    //tableview
    self.tableView.separatorColor = [UIColor clearColor];
    
    
    //searchbar
    self.tableView.tableHeaderView = self.searchBar;
    self.searchBar.showsCancelButton = YES;
    self.searchBar.delegate = self;
    self.searchBar.barTintColor = [UIColor whiteColor];
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses: @[[UISearchBar class]]] setTintColor:[UIColor redColor]];
    
    [self.musicAnimationViewBarItem setAction:@selector(playTapped)];
    
}

- (void)refresh:(id)sender {
    NSLog(@"Refreshing");
    
    [[SoundCloudAPI sharedInstance]soundCloudSongs:self.params[0] type:self.params[1] offset: 0 limit: perPage completionHandler:^(NSMutableArray *resultArray, NSString *error) {
        
        if (resultArray == nil) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil)message:NO_CONNECTION_TEXT preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:ok];
            
            [self presentViewController:alertController animated:YES completion:nil];
        } else {
            self.SoundCloudSongList = resultArray;
            [[self tableView]reloadData];
        }
        [(UIRefreshControl *)sender endRefreshing];
    }];
}

-(void)animateMusic {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPlay target:self action:@selector(playTapped)];
}

-(void)stopAnimateMusic {
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemPause target:self action:@selector(playTapped)];
}

- (void)reloadData {
    // Reload table data
    [self.tableView reloadData];
    
    // End the refreshing
    if (self.refreshControl) {
        [self.refreshControl endRefreshing];
    }
}

//MARK: FetchTracks
-(void)fetchTracks {
    
    [[SoundCloudAPI sharedInstance]soundCloudSongs:self.params[0] type:self.params[1] offset: (int) [self.SoundCloudSongList count] limit: (int) [self.SoundCloudSongList count] + perPage completionHandler:^(NSMutableArray *resultArray, NSString *error) {
        
        if (resultArray == nil) {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil)message:NO_CONNECTION_TEXT preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil];
            [alertController addAction:ok];
            
            [self presentViewController:alertController animated:YES completion:nil];
            
            self.canLoadMore = NO;
        } else {
            if (!self.SoundCloudSongList){
                self.SoundCloudSongList = [[NSMutableArray alloc] init];;
            }
        
            if ([resultArray count] < 1){
                self.canLoadMore = NO; // signal that there won't be any more items to load
            } else {
                self.canLoadMore = YES;
            }
        
            [self.SoundCloudSongList addObjectsFromArray: resultArray];
            [[self tableView]reloadData];
            
        }
        
        if (self.refreshControl.isRefreshing)
            [self.refreshControl endRefreshing];
        
        [self loadMoreCompleted];
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [self.tableView setContentOffset:CGPointMake(0, 44) animated:YES];
    [self.searchBar resignFirstResponder];
    [self fetchTracks];
}

-(void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    
    if (searchText.length == 0) {
        self.isFiltered = NO;
    } else {
        self.isFiltered = YES;
        self.filteredSoundCloudSongs = [[NSMutableArray alloc]init];
        for (SoundCloudSong* track in self.SoundCloudSongList)
        {
            NSRange titleRange = [track.title rangeOfString:searchText options:NSCaseInsensitiveSearch];
            NSRange usernameRange = [track.userName rangeOfString:searchText options:NSCaseInsensitiveSearch];
            if(titleRange.location != NSNotFound || usernameRange.location != NSNotFound)
            {
                [self.filteredSoundCloudSongs addObject:track];
            }
        }
    }
    
    [self.tableView reloadData];
    
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    
    NSString *search = [searchBar.text stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    
    //We only want to have search results within the scope of the user. As the soundcloud API does not yet have an option to search within the tracks of a user, we'll simply perform a search with the username and the query combined.
    NSString *query = [NSString stringWithFormat:@"%%22%@%%22%%20%@", self.params[0], search];
    
    [[SoundCloudAPI sharedInstance]searchSoundCloudSongs:query completionHandler:^(NSMutableArray *resultArray, NSString *error) {
        
        if (resultArray == nil) {
            //Do nothing
        } else {
            self.soundCloudSearchResults = resultArray;
            [self.tableView  reloadData];
        }
    }];
    
    [self.searchBar resignFirstResponder];
}

//MARK: TableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSInteger sectionCount;
    
    if(self.isFiltered){
        sectionCount = 2;
    }else{
        sectionCount = 1;
    }
    return sectionCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    
    NSInteger rowCount = 0;
    if(self.isFiltered){
        if (section == 0) {
            rowCount = self.filteredSoundCloudSongs.count;
        }else if (section == 1)
            rowCount = self.soundCloudSearchResults.count;
    }else {
        rowCount = self.SoundCloudSongList.count;
    }
    return rowCount;
    
    
}

- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
        return 0.0f;
    return 32.0f;
}


-(NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    NSString* sectionTitle;
    if (section == 0) {
        return nil;
    }else if (section == 1) {
        sectionTitle = NSLocalizedString(@"soundcloud_search", nil);
    }
    return sectionTitle;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    SoundCloudCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MC_TRACK_CELL"];
    
    SoundCloudSong* selectedTrack;
    if(self.isFiltered){
        if (indexPath.section == 0 ) {
            selectedTrack = [self.filteredSoundCloudSongs objectAtIndex:indexPath.row];
            self.selectedTrackSection = 0;
            
        }else if (indexPath.section == 1) {
            selectedTrack = [self.soundCloudSearchResults objectAtIndex:indexPath.row];
            self.selectedTrackSection = 1;
            
        }
    } else if (self.isFiltered == NO){
        selectedTrack = [self.SoundCloudSongList objectAtIndex:indexPath.row];
    
    }
    
    //[cell setDefaultColor:self.tableView.backgroundView.backgroundColor];
    
    [cell.trackNameLabel setText:selectedTrack.title];
    [cell.trackNameLabel sizeToFit];
    [cell.artistLabel setText:selectedTrack.userName];
    [cell.artistLabel sizeToFit];
    
    float durationInMilliSec = [selectedTrack.duration integerValue];
    float durationInSec = durationInMilliSec / 1000.00;
    [cell.durationLabel setText:[self timeFormatted:durationInSec]];
    
    NSURL* url = nil;
    
    cell.albumImageView.image = nil;
    
    if (self.isFiltered == NO) {
        NSString *imagename = [self.SoundCloudSongList objectAtIndex:indexPath.row];
        UIImage *image = [self.imageCache objectForKey:imagename];
        
        if (image) {
            [cell.albumImageView setImage:image];
        }else {
            
            //Sometimes track doesn't have artwork_url; use user avatar instead
            if ( [selectedTrack.artWorkURL  isEqual: [NSNull null]]) {
                url = [NSURL URLWithString:selectedTrack.userAvatar];
                
            }else{
                url = [[NSURL alloc]initWithString:selectedTrack.artWorkURL];
                
            }
        }
        
        if (url) {
            
            [self fetchArtwork:cell imageURL:url imagename:imagename];
        }
        
    }else if (self.isFiltered){
        if ( [selectedTrack.artWorkURL  isEqual: [NSNull null]]) {
            url = [NSURL URLWithString:selectedTrack.userAvatar];
            
        }else{
            url = [[NSURL alloc]initWithString:selectedTrack.artWorkURL];
        }
        
        if (url) {
            
            [self fetchArtwork:cell imageURL:url imagename:nil];
        }
    }
    
    return cell;
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.searchBar resignFirstResponder];
}

-(void)fetchArtwork: (SoundCloudCell*)cell
           imageURL: (NSURL*)imageURL
          imagename: (NSString*)imagename
{
    [self.imageQueue addOperationWithBlock:^{
        NSError *error = nil;
        UIImage *image = nil;
        NSData *imageData = [NSData dataWithContentsOfURL:imageURL options:0 error:&error];
        
        if (imageData != nil) {
            image = [UIImage imageWithData:imageData];
            
        }
        
        if (image) {
            
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [cell.albumImageView setImage:image];
            }];
            
            [self.imageCache setObject:image forKey:imagename];
        }
    }];
}

- (void) willBeginLoadingMore
{
    AssistTableFooterView *fv = (AssistTableFooterView *)self.tableView.tableFooterView;
    [fv.activityIndicator startAnimating];
}

- (void) addItemsOnBottom
{
    NSLog(@"Add Items on Bottom");
    [self fetchTracks];
    //Calculations on if more items can be loaded are done in fetchTracks
}

- (BOOL) loadMore
{
    if (![super loadMore])
        return NO;
    
    // Do your async loading here
    [self addItemsOnBottom];
    
    return YES;
}

- (void) loadMoreCompleted
{
    [super loadMoreCompleted];
    
    AssistTableFooterView *fv = (AssistTableFooterView *)self.tableView.tableFooterView;
    [fv.activityIndicator stopAnimating];
    
    if (!self.canLoadMore) {
        // Do something if there are no more items to load
        
        // We can hide the footerView by: [self setFooterViewVisibility:NO];
        
        // Just show a textual info that there are no more items to load
        fv.infoLabel.hidden = NO;
    }
}


-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    if (!self.playVC) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle: nil];
        self.playVC = [storyboard instantiateViewControllerWithIdentifier:@"PLAY_VC"];
        [self.playVC initialLoad];
    }
    
    if(self.isFiltered){
        if (indexPath.section == 0 ) {
            self.selectedTrack = [self.filteredSoundCloudSongs objectAtIndex:indexPath.row];
            
        }else if (indexPath.section == 1)
            self.selectedTrack = [self.soundCloudSearchResults objectAtIndex:indexPath.row];
        
    } else if (self.isFiltered == NO){
        self.selectedTrack = [self.SoundCloudSongList objectAtIndex:indexPath.row];
    }
    self.selectedTrackRow = indexPath.row;
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (self.isFiltered == NO) {
        self.playVC.playArray = self.SoundCloudSongList;
    }else if (self.isFiltered){
        if (self.selectedTrackSection == 0) {
            self.playVC.playArray = self.filteredSoundCloudSongs;
        }else if (self.selectedTrackSection == 1) {
            self.playVC.playArray = self.soundCloudSearchResults;
        }
    }
    
    self.playVC.playIndex = indexPath.row;
    float durationInMilliSec = [self.selectedTrack.duration integerValue];
    float durationInSec = durationInMilliSec / 1000.00;
    self.playVC.soundCloudDuration = durationInSec;
    
    [[NSNotificationCenter defaultCenter]postNotificationName:@"playSoundCloud" object:nil];
    
    [self presentViewController:self.playVC animated:YES completion:nil];
    
}

- (NSString *)timeFormatted:(NSInteger)secondsToConvert{
    NSInteger seconds = secondsToConvert % 60;
    NSInteger minutes =  (secondsToConvert / 60) % 60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)seconds];
}

//MARK: BUTTON ACTIONS

-(void)playTapped {
    if (self.playVC && [self.playVC.playArray count] > 0) {
        [self presentViewController:self.playVC animated:YES completion:nil];
    }
}

@end
