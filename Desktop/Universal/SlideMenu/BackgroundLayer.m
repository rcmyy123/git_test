//
//  BackgroundLayer.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "BackgroundLayer.h"
#import "AppDelegate.h"

@implementation BackgroundLayer

//Blue gradient background
+ (CAGradientLayer*) colorGradient {
    UIColor *colorOne = MENU_BACKGROUND_COLOR_1;
    UIColor *colorTwo = MENU_BACKGROUND_COLOR_2;
    
    NSArray *colors = [NSArray arrayWithObjects:(id)colorOne.CGColor, colorTwo.CGColor, nil];
    
    NSNumber *stopOne = [NSNumber numberWithFloat:0.0];
    NSNumber *stopTwo = [NSNumber numberWithFloat:1.0];
    
    NSArray *locations = [NSArray arrayWithObjects:stopOne, stopTwo, nil];
    
    CAGradientLayer *headerLayer = [CAGradientLayer layer];
	headerLayer.colors = colors;
	headerLayer.locations = locations;
	
	return headerLayer;
                       
}

@end
