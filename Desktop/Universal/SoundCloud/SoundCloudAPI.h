//
//  SoundCloudAPI.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SoundCloudSong.h"
@interface SoundCloudAPI : NSObject

+ (SoundCloudAPI *)sharedInstance ;

//-(void)requestOAuthAccess;
//-(void)downloadAlbumArt: (SoundCloudSong*)SoundCloudSong completionHandler:(void(^)(UIImage* image)) completionHandler;
-(void)searchSoundCloudSongs: (NSString*) searchTerm completionHandler: (void(^)(NSMutableArray *resultArray, NSString *error)) completionHandler;
-(void)soundCloudSongs: (NSString*) param type: (NSString*) type offset: (int) offset limit: (int) limit completionHandler: (void(^)(NSMutableArray *resultArray, NSString *error)) completionHandler;



@end
