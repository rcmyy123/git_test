//
//  ConfigParser.m
//  Universal
//
//  Created by Mark on 14/06/2017.
//  Copyright © 2017 Sherdle. All rights reserved.
//

#import "ConfigParser.h"
#import "Section.h"
#import "Item.h"
#import "Tab.h"
#import "ConfigParserDelegate.h"

#define CACHE_TIME -60 * 60 * 24

@implementation ConfigParser

// Config

- (void)parseConfig:(NSString*)file {
    if (![file hasPrefix:@"http"]) {
        
        NSURL *localFileUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:([file isEqualToString:@""] ? @"config" : file) ofType: @"json" inDirectory:@"Local"]];
        [self parseConfigJSON:[NSData dataWithContentsOfURL:localFileUrl]];
    } else {
        NSMutableArray *cacheConfig = [self loadArrayFromCache];
        if (cacheConfig == nil) {
            NSURL *url = [[NSURL alloc] initWithString:file];
            NSLog(@"Retrieving configuration from url: %@", file);
            
            NSURLSession *session = [NSURLSession sharedSession];
            [[session dataTaskWithURL:url
                    completionHandler:^(NSData *data,
                                        NSURLResponse *response,
                                        NSError *error) {
                        dispatch_async(dispatch_get_main_queue(), ^{
                            if (error) {
                                [self.delegate parseFailed:error];
                            } else {
                                [self parseConfigJSON:data];
                            }
                        });
                        
                    }] resume];
        } else {
            [self.delegate parseSuccess:cacheConfig];
        }
    }
}

- (void)parseConfigJSON:(NSData *)json {
    NSError *localError = nil;
    NSArray *jsonMenu = [NSJSONSerialization JSONObjectWithData:json options:0 error:&localError];
    
    if (localError != nil) {
        [self.delegate parseFailed:localError];
    }
    
    NSMutableArray *sections = [[NSMutableArray alloc] init];
    Section *section = nil;
    
    for (NSDictionary *jsonMenuItem in jsonMenu) {
        Item *menuItem = [[Item alloc] init];
        
        menuItem.name = [jsonMenuItem objectForKey:@"title"];
        
        NSMutableArray *menuTabs = [[NSMutableArray alloc] init];
        for (NSDictionary *jsonTab in [jsonMenuItem objectForKey:@"tabs"]) {
            [menuTabs addObject:[ConfigParser navItemFromJSON:jsonTab]];
        }
        menuItem.tabs = menuTabs;
        
        NSString *drawableName = nil;
        if ([jsonMenuItem objectForKey:@"drawable"] != nil
            && ![[jsonMenuItem objectForKey:@"drawable"] isEqualToString:@""]
            && ![[jsonMenuItem objectForKey:@"drawable"] isEqualToString: @"0"]){
            drawableName = [jsonMenuItem objectForKey:@"drawable"];
            menuItem.icon = drawableName;
        }
        
        BOOL requiresIap = false;
        if ([jsonMenuItem objectForKey:@"iap"] != nil)
            requiresIap = [[jsonMenuItem valueForKey:@"iap"]  boolValue];
        menuItem.iap = requiresIap;
        
        //Determine the section
        NSString *subMenu = @"";
        if ([jsonMenuItem objectForKey:@"submenu"] != nil
            && ![[jsonMenuItem objectForKey:@"submenu"] isEqualToString:@""]) {
            subMenu = [jsonMenuItem objectForKey:@"submenu"];
        }
        //If this is a different section than the previous
        if (![subMenu isEqualToString:section.name]){
            //Clean up previous section
            if (section != nil)
                [sections addObject:section];
            //Create the new section
            section = [[Section alloc] init];
            section.name = subMenu;
            section.items = [[NSMutableArray alloc] init];
        }
        //Add the item to the section
        [section.items addObject:menuItem];
    }
    
    [sections addObject:section];
    
    [self saveArrayToCache:sections];
    [self.delegate parseSuccess:sections];
}

// Overview

- (void)parseOverview:(NSString*)file{
    if (![file hasPrefix:@"http"]) {
        
        if ([file hasSuffix:@".json"])
            file = [file stringByReplacingOccurrencesOfString:@".json" withString:@""];
        
        NSURL *localFileUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:([file isEqualToString:@""] ? @"config" : file) ofType: @"json" inDirectory:@"Local"]];
        [self parseOverviewJSON:[NSData dataWithContentsOfURL:localFileUrl]];
    } else {
        NSURL *url = [[NSURL alloc] initWithString:file];
        NSLog(@"Retrieving overview from url: %@", file);
        
        NSURLSession *session = [NSURLSession sharedSession];
        [[session dataTaskWithURL:url
                completionHandler:^(NSData *data,
                                    NSURLResponse *response,
                                    NSError *error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        if (error) {
                            [self.delegate parseFailed:error];
                        } else {
                            [self parseOverviewJSON:data];
                        }
                    });
                    
                }] resume];
    }
}

- (void)parseOverviewJSON:(NSData *)json {
    NSError *localError = nil;
    NSArray *jsonOverview = [NSJSONSerialization JSONObjectWithData:json options:0 error:&localError];
    
    if (localError != nil) {
        [self.delegate parseFailed:localError];
    }
    
    NSMutableArray *overview = [[NSMutableArray alloc] init];
    
    for (NSDictionary *jsonOverviewItem in jsonOverview) {
       [overview addObject:[ConfigParser navItemFromJSON:jsonOverviewItem]];
    }
    
    [self.delegate parseSuccess:overview];
}

// Items

+ (Tab *) navItemFromJSON:(NSDictionary *) jsonTab {
    Tab *item = [[Tab alloc] init];
    
    item.name = [jsonTab objectForKey:@"title"];
    item.type = [jsonTab objectForKey:@"provider"];
    item.params = [jsonTab objectForKey:@"arguments"];
    
    NSString *image = nil;
    if ([jsonTab objectForKey:@"image"] != nil) {
        
        image = [jsonTab objectForKey:@"image"];
        item.icon = image;
        
    }
    
    return item;
}

- (NSString *) getStorageLocation {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *cacheFile = [documentsDirectory stringByAppendingPathComponent:@"cache.dat"];
    return cacheFile;
}

- (NSMutableArray *) loadArrayFromCache {
    NSURL *fileUrl = [NSURL fileURLWithPath:[self getStorageLocation]];
    NSDate *fileDate;
    NSError *error;
    [fileUrl getResourceValue:&fileDate forKey:NSURLContentModificationDateKey error:&error];

    if (!error && [fileDate compare:[NSDate dateWithTimeIntervalSinceNow: CACHE_TIME] ] == NSOrderedDescending)
    {
        NSLog(@"Loading config from cache..");
        return [[NSMutableArray alloc] initWithContentsOfFile: [self getStorageLocation]];
    } else {
        return nil;
    }
    
}

- (void) saveArrayToCache: (NSMutableArray *) array {
    [array writeToFile:[self getStorageLocation] atomically:YES];
}

@end
