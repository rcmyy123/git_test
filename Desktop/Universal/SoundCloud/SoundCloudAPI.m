//
//  SoundCloudAPI.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "SoundCloudAPI.h"
#import "SoundCloudSong.h"
#import "AppDelegate.h"

#define ONLINE_SEARCH_ENABLED YES

@interface SoundCloudAPI ()

@property (strong, nonatomic) NSURLSession* session;
@property (strong, nonatomic) NSURLSessionConfiguration* sessionConfiguration;
@property (strong, nonatomic) NSCache* imageCache;
@property (strong, nonatomic) NSOperationQueue* imageQueue;


@end

@implementation SoundCloudAPI

//Singleton Instance
+ (SoundCloudAPI *)sharedInstance {
    static SoundCloudAPI *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[self alloc]init];
    });
    return sharedInstance;
    
}

//Instantiating Session
-(instancetype) init
{
    self = [super init];
    if (self) {
        self.sessionConfiguration = [NSURLSessionConfiguration defaultSessionConfiguration];
        self.session = [NSURLSession sessionWithConfiguration: self.sessionConfiguration];
    }
    return self;
}

-(void)searchSoundCloudSongs: (NSString*) searchTerm completionHandler: (void(^)(NSMutableArray *resultArray, NSString *error)) completionHandler; {
    
    if (!ONLINE_SEARCH_ENABLED)
        return;
    
    NSString* apiURL = [NSString stringWithFormat:@"http://api.soundcloud.com/tracks?client_id=%@&q=%@&format=json",SOUNDCLOUD_CLIENT, searchTerm];
    
    NSURL* url = [[NSURL alloc]initWithString:apiURL];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc]initWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *dataTask = [[self session] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *callResponse = (NSHTTPURLResponse *)response;
        
        if (data == nil) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{completionHandler(nil, @"no connection");}];
        } else {
        
            if ([callResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                NSInteger responseCode = [callResponse statusCode];
                
                if (responseCode >= 200 && responseCode <= 299) {
                    NSMutableArray* resultArray = [SoundCloudSong parseJSONData:data];
                    [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                        completionHandler(resultArray, nil);
                    }];
                }else{
                    NSLog(@"%ld", (long)responseCode);
                }
            }
        }
    }];
    [dataTask resume];
}

-(void)soundCloudSongs: (NSString*) param type: (NSString*) type offset: (int) offset limit: (int) limit completionHandler: (void(^)(NSMutableArray *resultArray, NSString *error)) completionHandler; {
    
    NSString* apiURL;
    if ([type  isEqual: @"user"]){
        apiURL = [NSString stringWithFormat:@"http://api.soundcloud.com/users/%@/tracks?client_id=%@&offset=%i&limit=%i&format=json",param, SOUNDCLOUD_CLIENT, offset, limit];
    } else {
        apiURL = [NSString stringWithFormat:@"http://api.soundcloud.com/playlists/%@/tracks?client_id=%@&offset=%i&limit=%i&format=json",param, SOUNDCLOUD_CLIENT, offset, limit];
    }
    NSLog(@"%@", apiURL);
    NSURL* url = [[NSURL alloc]initWithString:apiURL];
    
    NSMutableURLRequest* request = [[NSMutableURLRequest alloc]initWithURL:url];
    request.HTTPMethod = @"GET";
    
    NSURLSessionDataTask *dataTask = [[self session] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSHTTPURLResponse *callResponse = (NSHTTPURLResponse *)response;
        
        if (data == nil) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{completionHandler(nil, @"no connection");}];
        } else {
        
            if ([callResponse isKindOfClass:[NSHTTPURLResponse class]]) {
                NSInteger responseCode = [callResponse statusCode];
            
                if (responseCode >= 200 && responseCode <= 299) {
                    NSMutableArray* resultArray = [SoundCloudSong parseJSONData:data];
                    [[NSOperationQueue mainQueue]addOperationWithBlock:^{
                    completionHandler(resultArray, nil);
                    }];
                }else{
                    NSLog(@"%ld", (long)responseCode);
                }
            }
        }
    }];
    [dataTask resume];
    
}

@end
