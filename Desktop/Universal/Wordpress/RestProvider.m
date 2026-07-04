//
//  RestProvider.m
//  Universal
//
//  Created by Mark on 31/01/2017.
//  Copyright © 2017 Sherdle. All rights reserved.
//
#import "RestProvider.h"

@implementation RestProvider
@synthesize totalPages;

//Note that for Rest the category should be the category ID.
- (NSString *) getUrl:(NSString *)baseUrl forPage:(int)page withCategory:(NSString *)category withSearch:(NSString *) query {
    NSString *strURl;
    if (query){
        strURl= [NSString stringWithFormat: @"%@posts?_embed=1&page=%i&search=%@", baseUrl,page,query];
    } else {
        if ([category length] == 0)  {
            strURl= [NSString stringWithFormat: @"%@posts?_embed=1&page=%i", baseUrl,page];
        } else {
            strURl= [NSString stringWithFormat: @"%@posts?_embed=1&page=%i&categories=%@", baseUrl,page,category];
        }
    }
    
    return strURl;

}

- (NSMutableArray *) parseJSON:(NSData *)data into:(NSMutableArray *)parsedItems withResponse:(NSURLResponse *)response {
    NSArray *jsonArray = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    for (NSArray *resultkey in jsonArray) {
        NSMutableArray *result = [resultkey mutableCopy];
        
        //Find media
        NSString *thumbnailUrl;
        NSString *mediaUrl;
        if (![[[result valueForKey:@"_embedded"] valueForKey:@"wp:featuredmedia"] isKindOfClass:[NSNull class]]
            && [[[result valueForKey:@"_embedded"] valueForKey: @"wp:featuredmedia"] count] > 0
            && [[[[[result valueForKey:@"_embedded"] valueForKey: @"wp:featuredmedia"] objectAtIndex:0] valueForKey:@"media_type"] isEqualToString:@"image"]) {
            
            NSDictionary *sizes = [[[[[result valueForKey:@"_embedded"] valueForKey: @"wp:featuredmedia"] objectAtIndex:0] objectForKey:@"media_details"] objectForKey:@"sizes"];
            
            mediaUrl = [[sizes objectForKey:@"large"] valueForKey:@"source_url"];
            thumbnailUrl = [[sizes objectForKey:@"medium"] valueForKey:@"source_url"];
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
        NSString *authorname = [[[[result valueForKey:@"_embedded"] valueForKey:@"author"] objectAtIndex:0] valueForKey:@"name"];
        [result setValue:authorname forKey:@"author"];
        
        //Update date
        NSString *date = [self parseDateToString:[result valueForKey:@"date"]];
        [result setValue:date forKey:@"date"];
        
        //Update url
        NSString *url = [result valueForKey:@"link"];
        [result setValue:url forKey:@"url"];
        
        //Update title
        NSString *title = [[result valueForKey:@"title"] valueForKey: @"rendered"];
        [result setValue:title forKey:@"title"];
        
        //Update content
        NSString *content = [[result valueForKey:@"content"] valueForKey: @"rendered"];
        [result setValue:content forKey:@"excerpt"];
        
        [parsedItems addObject:result];
    }
    
    //Update the number of pages
    self.totalPages = [[[(NSHTTPURLResponse*) response allHeaderFields] valueForKey:@"X-WP-TotalPages"] intValue];
    return parsedItems;
}

-(NSString *)parseDateToString:(NSString *)dateString {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss"];
    NSDate *dte = [dateFormat dateFromString:dateString];
    
    NSDateFormatter *dF = [[NSDateFormatter alloc] init];
    [dF setDateFormat:@"dd MMMM yyyy HH:mm"];
    return [dF stringFromDate:dte];
}

@end
