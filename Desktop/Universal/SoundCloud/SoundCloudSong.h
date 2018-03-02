//
//  SoundCloudSong.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreData/CoreData.h>

@interface SoundCloudSong : NSObject

@property (strong, nonatomic) NSString* title;
@property (strong, nonatomic) NSString* stream_url;
@property (strong, nonatomic) NSDictionary* userDict;
@property (strong, nonatomic) NSString* userName;
@property (strong, nonatomic) NSString* artWorkURL;
@property (strong, nonatomic) NSString* userAvatar;
@property (strong, nonatomic) NSString* trackID;
@property (strong, nonatomic) NSNumber* duration;

+(NSMutableArray *) parseJSONData: (NSData *) JSONData;

@end
