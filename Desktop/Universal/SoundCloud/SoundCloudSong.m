//
//  SoundCloudSong.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "SoundCloudSong.h"

@implementation SoundCloudSong

-(instancetype) initWithDictionary: (NSDictionary*) SoundCloudSongDict {
    self = [self init];
    if (self) {
        self.title = SoundCloudSongDict[@"title"];
        self.stream_url = SoundCloudSongDict[@"stream_url"];
        self.userDict = SoundCloudSongDict[@"user"];
        self.userName = self.userDict[@"username"];
        self.artWorkURL = SoundCloudSongDict[@"artwork_url"];
        self.trackID = SoundCloudSongDict[@"id"];
        self.userAvatar = self.userDict[@"avatar_url"];
        self.duration = SoundCloudSongDict[@"duration"];
        
    }
    return self;
}

+(NSMutableArray *) parseJSONData: (NSData *) JSONData {
    NSError* error;
    NSMutableArray* SoundCloudSongArray = [NSMutableArray new];
    
    NSArray *JSONArray= [NSJSONSerialization JSONObjectWithData:JSONData options:0 error: &error];
    if ([JSONArray isKindOfClass:[NSArray class]]) {
        for (NSDictionary* trackDict in JSONArray) {
            SoundCloudSong* trackObject = [[SoundCloudSong alloc]initWithDictionary:trackDict];
            [SoundCloudSongArray addObject:trackObject];
        }
    }
    return SoundCloudSongArray;
    
    
}

@end
