//
//  JSONProvider.m
//  Universal
//
//  Created by Mark on 31/01/2017.
//  Copyright © 2017 Sherdle. All rights reserved.
//

#import "JSONProvider.h"

@implementation JSONProvider
@synthesize totalPages;

- (NSString *) getUrl:(NSString *)baseUrl forPage:(int)page withCategory:(NSString *)category withSearch:(NSString *) query {
    NSString *strURl;
    if (query){
        strURl= [NSString stringWithFormat: @"%@/api/get_search_results/?page=%i&dev=1&search=%@", baseUrl,page, query];
    } else {
        if ([category length] == 0)  {
            strURl=[NSString stringWithFormat:@"%@/api/get_recent_posts/?page=%i&dev=1",baseUrl,page];
        } else{
            strURl=[NSString stringWithFormat:@"%@/api/get_category_posts/?page=%i&slug=%@&dev=1",baseUrl,page,category];
        }
    }
    return strURl;
}

- (NSMutableArray *) parseJSON:(NSData *)data into:(NSMutableArray *)parsedItems withResponse:(NSURLResponse *)response {
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
    
    NSArray *jsonArray = [jsonDict valueForKey:@"posts"];
    
    
    for (NSArray *resultkey in jsonArray) {
        NSMutableArray *result = [resultkey mutableCopy];
        
        NSString *htmlString = [result valueForKey:@"excerpt"];
        
        NSString *thumbnailUrl = @"";
        NSString *mediaUrl = @"";
        
        NSArray *postAttachments= [result valueForKey:@"attachments"];
        NSObject *postThumbnails= [result valueForKey:@"thumbnail_images"];
        NSString *postThumbnail = [result valueForKey:@"thumbnail"];
        
        //Find the header image
        if ([postAttachments count] > 0
            && [NSNull null] != [[postAttachments objectAtIndex:0] valueForKey:@"url"]
            && ([[[[postAttachments objectAtIndex:0] valueForKey:@"url"] pathExtension] isEqualToString:@"jpg"] ||
                [[[[postAttachments objectAtIndex:0] valueForKey:@"url"] pathExtension] isEqualToString:@"jpeg"] ||
                [[[[postAttachments objectAtIndex:0] valueForKey:@"url"] pathExtension] isEqualToString:@"gif"] ||
                [[[[postAttachments objectAtIndex:0] valueForKey:@"url"] pathExtension] isEqualToString:@"png"])){
                
                mediaUrl = [[postAttachments objectAtIndex:0] valueForKey:@"url"];
            } else {
                NSScanner *theScanner = [NSScanner scannerWithString:htmlString];
                // find start of IMG tag
                [theScanner scanUpToString:@"<img" intoString:nil];
                if (![theScanner isAtEnd]) {
                    [theScanner scanUpToString:@"src" intoString:nil];
                    NSCharacterSet *charset = [NSCharacterSet characterSetWithCharactersInString:@"\"'"];
                    [theScanner scanUpToCharactersFromSet:charset intoString:nil];
                    [theScanner scanCharactersFromSet:charset intoString:nil];
                    [theScanner scanUpToCharactersFromSet:charset intoString:&mediaUrl];
                }
            }
        
        //Find the thumbnail
        if ([NSNull null] != postThumbnails && [postThumbnails valueForKey:@"medium"] != nil){
            thumbnailUrl = [[postThumbnails valueForKey:@"medium"] valueForKey:@"url"];
        } else if (![postThumbnail isEqual: [NSNull null]] && [postThumbnail length] != 0){
            thumbnailUrl = postThumbnail;
        } else if ([postAttachments count] > 0
                   && [NSNull null] != [[postAttachments objectAtIndex:0] valueForKey:@"images"]){
            if ([NSNull null] != [[[postAttachments objectAtIndex:0] valueForKey:@"images"] valueForKey:@"post-thumbnail"]){
                thumbnailUrl = [[[[postAttachments objectAtIndex:0] valueForKey:@"images"] valueForKey:@"post-thumbnail"] valueForKey:@"url"];
            } else if ([NSNull null] != [[[postAttachments objectAtIndex:0] valueForKey:@"images"] valueForKey:@"thumbnail"]){
                thumbnailUrl = [[[[postAttachments objectAtIndex:0] valueForKey:@"images"] valueForKey:@"thumbnail"] valueForKey:@"url"];
            }
        }
        
        
        //Check if the urls are valid urls
        if (mediaUrl == (id)[NSNull null] || ![[mediaUrl classForCoder] isSubclassOfClass:[NSString class]]){
            mediaUrl = @"";
        }
        
        if (thumbnailUrl == (id)[NSNull null] || ![[thumbnailUrl classForCoder] isSubclassOfClass:[NSString class]]){
            thumbnailUrl = @"";
        }
        
        //If no thumbnail was found, let's use the regular header image
        if ([thumbnailUrl length] == 0){
            thumbnailUrl = mediaUrl;
        }
        
        [result setValue:thumbnailUrl forKey:@"thumbUrl"];
        [result setValue:mediaUrl forKey:@"mediaUrl"];
        
        NSString *authorname = @"";
        NSObject *author;
        
        if ([result valueForKey:@"author"] != nil){
            if ([[result valueForKey:@"author"] isKindOfClass:[NSArray class]] && [[result valueForKey:@"author"] count] > 0){
                author = [[result valueForKey:@"author"] objectAtIndex:0];
            } else {
                author = [result valueForKey:@"author"];
            }
            
            if ([author isKindOfClass:[NSObject class]] && [author valueForKey:@"name"] != nil){
                authorname = [author valueForKey:@"name"];
            }
        }
        
        [result setValue:authorname forKey:@"author"];
        
        [parsedItems addObject:result];
    }
    
    //Update the number of pages
    NSString *total=[NSString stringWithFormat:@"%@",[jsonDict valueForKey:@"pages"]];
    self.totalPages =(int)[total integerValue];
    return parsedItems;
}

-(NSString *)parseDateToString:(NSString *)dateString {
    NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
    [dateFormat setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'+00:00'"];
    NSDate *dte = [dateFormat dateFromString:dateString];
    
    NSDateFormatter *dF = [[NSDateFormatter alloc] init];
    [dF setDateFormat:@"dd MMMM yyyy HH:mm"];
    return [dF stringFromDate:dte];
}

@end
