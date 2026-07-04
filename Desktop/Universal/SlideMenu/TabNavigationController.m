//
//  FrontNavigationController.m
//  Universal
//
//  Created by Mu-Sonic on 25/10/2015.
//  Copyright © 2016 Sherdle. All rights reserved.
//

#import "SWRevealViewController.h"
#import "TabNavigationController.h"
#import "AppDelegate.h"
#import "Config.h"
#import "Section.h"

// This affects navbar animation during transitions to transparent bar in detail view.
// White color seems to work best here. APP_THEME_COLOR is another option.
#define NAVBAR_TRANSITION_BGCOLOR [UIColor whiteColor]

@implementation TabNavigationController
{
    UIColor *prevShadowColor;
    GADInterstitial *interstitial;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    prevShadowColor = self.revealViewController.frontViewShadowColor;
    [self createAndLoadInterstitial];
    [self configureNavbar];
}

- (void)configureNavbar {
    _gradientView.plainView.backgroundColor = APP_THEME_COLOR;
    
    // attach gradient view just below the nav bar
    [self.view insertSubview:_gradientView belowSubview:self.navigationBar];
    
    // set appearance of status and nav bars
    self.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationBar.tintColor = [UIColor whiteColor];
    self.navigationBar.shadowImage = [UIImage new];
    [self.navigationBar setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
    
    //    self.navigationBar.backgroundColor = [UIColor clearColor];
    //    self.navigationBar.barTintColor = [UIColor clearColor];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    // gradient view to cover both status bar (if present) and nav bar
    CGRect barFrame = self.navigationBar.frame;
    _gradientView.frame = CGRectMake(0, 0, barFrame.size.width, barFrame.origin.y + barFrame.size.height);
}

- (void)pushViewController:(UIViewController *)viewController animated:(BOOL)animated {
    [super pushViewController:viewController animated:animated];
    
    bool hasOneItem = [[Config config] count] == 1 && [((Section *)[[Config config] objectAtIndex:0]).items count] == 1;
    
    // add reveal button to the first nav item on the stack
    if (self.viewControllers.count == 1 && !hasOneItem) {
        UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
        btn.frame = CGRectMake(0, 0, 20, 20);
        [btn setImage:[UIImage imageNamed:@"reveal-icon"] forState:UIControlStateNormal];
        [btn addTarget:self.revealViewController action:@selector(revealToggle:) forControlEvents:UIControlEventTouchUpInside];
        UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]initWithCustomView:btn];
        viewController.navigationItem.leftBarButtonItem = leftBarButton;
    }
    
    if (self.viewControllers.count > 1) {
        self.revealViewController.frontViewShadowColor = NAVBAR_TRANSITION_BGCOLOR;
    }
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    UIViewController *poppedVC = [super popViewControllerAnimated:animated];
    
    // switch off navbar transparency
    if (self.viewControllers.count <= 1) {
        [self.gradientView turnTransparencyOn:NO animated:YES];
        self.revealViewController.frontViewShadowColor = prevShadowColor;
    }
    
    return poppedVC;
}

- (void)createAndLoadInterstitial {
    if (![(AppDelegate *)[[UIApplication sharedApplication] delegate] shouldShowInterstitial]) return;
    
    interstitial =  [[GADInterstitial alloc] initWithAdUnitID:ADMOB_INTERSTITIAL_ID];
    interstitial.delegate = self;
    GADRequest *request = [GADRequest request];
    // Request test ads on devices you specify. Your test device ID is printed to the console when
    // an ad request is made.
    request.testDevices = @[ kGADSimulatorID, @"YourTestDevice" ];
    [interstitial loadRequest:request];
}

- (void)interstitialDidReceiveAd:(GADInterstitial *)ad
{
    [interstitial presentFromRootViewController:self];
}


@end
