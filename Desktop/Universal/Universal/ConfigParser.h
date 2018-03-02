//
//  ConfigParser.h
//  Universal
//
//  Created by Mark on 14/06/2017.
//  Copyright © 2017 Sherdle. All rights reserved.
//

@protocol ConfigParserDelegate;

@interface ConfigParser : NSObject
@property (weak, nonatomic) id delegate;

- (void)parseConfig:(NSString *)file;
- (void)parseOverview:(NSString *)file;
+ (NSMutableArray *) navItemFromJSON:(NSDictionary *) jsonTab;

@end
