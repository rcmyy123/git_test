//
//  WordpressProvider.h
//  Universal
//
//  Created by Mark on 31/01/2017.
//  Copyright © 2017 Sherdle. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol WordpressProvider <NSObject>

- (NSString *) getUrl: (NSString *) baseUrl forPage: (int) page withCategory: (NSString *) category withSearch: (NSString *) query ;
- (NSMutableArray *) parseJSON:(NSData *)data into:(NSMutableArray *)parsedItems withResponse:(NSURLResponse *) response;

@property(nonatomic) int totalPages;

@end
