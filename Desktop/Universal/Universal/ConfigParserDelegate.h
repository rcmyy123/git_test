//
//  ConfigParserDelegate.h
//  Universal
//
//  Created by Mark on 14/06/2017.
//  Copyright © 2017 Sherdle. All rights reserved.
//


@protocol ConfigParserDelegate
- (void)parseSuccess:(NSMutableArray *)result;
- (void)parseFailed:(NSError *)error;
@end
