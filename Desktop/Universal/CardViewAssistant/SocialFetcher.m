//
//  SocialFetcher.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "SocialFetcher.h"

@implementation SocialFetcher

+ (NSDictionary *)executeFetch:(NSString *)query
{
    NSURL *url = [NSURL URLWithString:query];
    NSLog(@"Query: %@", query);
    
    NSError *error = nil;
    NSData *theData =  [NSData dataWithContentsOfURL:url options:NSDataReadingUncached error:&error];
    
    if (theData != nil) {
        NSDictionary *newJSON = [NSJSONSerialization JSONObjectWithData:theData
                                                            options:0
                                                              error:nil];
       return newJSON;
    } else {
        NSLog(@"Error %@", error);
        return nil;
    }
}

@end
