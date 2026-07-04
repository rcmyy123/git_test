//
//  Config.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//
//  In this newer version of Universal, please set your configuration in config.json. Read your documentation for more info.
//

#import "Config.h"

@implementation Config {
}
static NSArray * _config;

+ (NSArray *)config { return _config; }
+ (void)setConfig:(NSArray *)config { _config = config; }

@end
