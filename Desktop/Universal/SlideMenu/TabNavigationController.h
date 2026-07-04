//
//  FrontNavigationController.h
//  Universal
//
//  Created by Mu-Sonic on 25/10/2015.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "NavbarGradientView.h"
#import <GoogleMobileAds/GoogleMobileAds.h>

@interface TabNavigationController: UINavigationController <GADInterstitialDelegate>

@property (strong, nonatomic) IBOutlet NavbarGradientView *gradientView;

@property (strong, nonatomic) NSArray *item;
@property (nonatomic) BOOL hiddenTabBar;

@end
