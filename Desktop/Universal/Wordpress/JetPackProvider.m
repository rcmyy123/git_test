//
//  JetPackProvider.m
//  Universal
//
//  Created by Mark on 31/01/2017.
//  Copyright © 2017 Sherdle. All rights reserved.
//

// Bicycle.m
#import "JetPackProvider.h"

@implementation JetPackProvider
@synthesize totalPages;

- (NSString *) getUrl:(NSString *)baseUrl forPage:(int)page withCategory:(NSString *)category withSearch:(NSString *) query {
    NSString *strURl;
    if (query){
        strURl= [NSString stringWithFormat: @"https://public-api.wordpress.com/rest/v1.1/sites/%@/posts/?page=%i&search=%@&fields=ID,author,title,URL,content,discussion,featured_image,post_thumbnail,tags,discussion,date,attachments", baseUrl,page,query];
    } else {
        if ([category length] == 0)  {
            strURl= [NSString stringWithFormat: @"https://public-api.wordpress.com/rest/v1.1/sites/%@/posts/?page=%i&fields=ID,author,title,URL,content,discussion,featured_image,post_thumbnail,tags,discussion,date,attachments", baseUrl,page];
        } else {
            strURl= [NSString stringWithFormat: @"https://public-api.wordpress.com/rest/v1.1/sites/%@/posts/?page=%i&category=%@&fields=ID,author,title,URL,content,discussion,featured_image,post_thumbnail,tags,discussion,date,attachments", baseUrl,page,category];
       
        
        }
    }
    
    return strURl;

}

- (NSMutableArray *) parseJSON:(NSData *)data into:(NSMutableArray *)parsedItems withResponse:(NSURLResponse *)response {
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    NSArray *jsonArray = [jsonDict valueForKey:@"posts"];
    
    for (NSArray *resultkey in jsonArray) {
        NSMutableArray *result = [resultkey mutableCopy];
        
        NSString *thumbnailUrl = @"";
        NSString *mediaUrl = [result valueForKey:@"featured_image"];;
        
        if (![[result valueForKey:@"post_thumbnail"] isKindOfClass:[NSNull class]]) {
            long postThumbnail = [[[result valueForKey:@"post_thumbnail"] valueForKey: @"ID"] longValue];
            
            BOOL thumbInAttachments = NO;
            if ([result valueForKey:@"attachments"] && [[result valueForKey:@"attachments"] count] > 0){
                NSDictionary *attachments = [result valueForKey:@"attachments"];
                for (NSString *attachmentKey in attachments){
                    NSDictionary *attachment = [attachments objectForKey:attachmentKey];
                    if ([[attachment valueForKey:@"ID"] longValue] == postThumbnail
                        && ![[attachment valueForKey:@"thumbnails"] isKindOfClass:[NSNull class]]
                        && ![[[attachment valueForKey:@"thumbnails"] valueForKey:@"medium"] isKindOfClass:[NSNull class]]){
                        thumbnailUrl = [[attachment valueForKey:@"thumbnails"] valueForKey:@"medium"];
                        thumbInAttachments = YES;
                    }
                }
            }
            
            if (!thumbInAttachments){
                thumbnailUrl = [[result valueForKey:@"post_thumbnail"] valueForKey:@"URL"];
            }
            
        }
        
        if ([thumbnailUrl length] == 0){
            thumbnailUrl = mediaUrl;
        }
        
        
        //Check if the urls are valid urls
        if (mediaUrl == (id)[NSNull null] || ![[mediaUrl classForCoder] isSubclassOfClass:[NSString class]]){
            mediaUrl = @"";
        }
        
        if (thumbnailUrl == (id)[NSNull null] || ![[thumbnailUrl classForCoder] isSubclassOfClass:[NSString class]]){
            thumbnailUrl = @"";
        }
        
        //Update media urls
        [result setValue:thumbnailUrl forKey:@"thumbUrl"];
        [result setValue:mediaUrl forKey:@"mediaUrl"];
        
        //Update username
        NSString *authorname = [[result valueForKey:@"author"] valueForKey:@"name"];
        [result setValue:authorname forKey:@"author"];
        
        //Update date
        NSString *date = [self parseDateToString:[result valueForKey:@"date"]];
        [result setValue:date forKey:@"date"];
        
        //Update url
        NSString *url = [result valueForKey:@"URL"];
        [result setValue:url forKey:@"url"];
        
        //Update content
        NSString *content = [result valueForKey:@"content"];
        [result setValue:content forKey:@"excerpt"];
        
        [parsedItems addObject:result];
    }
    
    //Update the number of pages
    static int JETPACK_PER_PAGE = 20;
    self.totalPages = [[jsonDict valueForKey:@"found"] intValue] / JETPACK_PER_PAGE + ([[jsonDict valueForKey:@"found"] intValue] % JETPACK_PER_PAGE == 0  ? 0 : 1);
    return parsedItems;
}

-(NSString *)parseDateToString:(NSString *)dateString {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
    NSDate *dte = [dateFormat dateFromString:dateString];
    
    NSDateFormatter *dF = [[NSDateFormatter alloc] init];
    [dF setDateFormat:@"dd MMMM yyyy HH:mm"];
    return [dF stringFromDate:dte];
}

@end
