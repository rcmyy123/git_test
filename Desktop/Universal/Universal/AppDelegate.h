//
//  AppDelegate.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//
//  INFO: In this file you can edit some of your apps main properties, like API keys
//

#import <UIKit/UIKit.h>
#import "SWRevealViewController.h"
#import "RearTableViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "SoundCloudPlayerController.h"
#import "RadioViewController.h"
#import <OneSignal/OneSignal.h>
#import "CJPAdMobHelper.h"

//START OF CONFIGURATION

#define CONFIG @"config"

/**
 * Layout options
 */
#define APP_DRAWER_HEADER YES
#define APP_THEME_COLOR [UIColor colorWithRed:209.0f/255.0f  green:7.0f/255.0f  blue:32.0f/255.0f  alpha:1.0]
#define MENU_BACKGROUND_COLOR_1 [UIColor colorWithRed:209.0f/255.0f  green:7.0f/255.0f  blue:32.0f/255.0f  alpha:1.0]
#define MENU_BACKGROUND_COLOR_2 [UIColor colorWithRed:0 green:0 blue:0 alpha:1.0]

/**
 * About / Texts
 **/
#define NO_CONNECTION_TEXT @"无法连接到服务器，请确保您的网络畅通。"
#define ABOUT_TEXT @"感谢您下载我们的应用!如果您需要帮助，请点击下面的按钮。"
#define ABOUT_URL @"http://cn.fmmii.com"

/**
 * Monetization
 **/
#define INTERSTITIAL_INTERVAL 5
#define ADMOB_INTERSTITIAL_ID @""
#define BANNER_ADS_ON false
#define ADMOB_UNIT_ID @""

#define IN_APP_PRODUCT @""

/**
 * API Keys
 **/
#define ONESIGNAL_APP_ID @""

#define MAPS_API_KEY @""

#define YOUTUBE_CONTENT_KEY @""

#define TWITTER_API @""
#define TWITTER_API_SECRET @""
#define TWITTER_TOKEN @""
#define TWITTER_TOKEN_SECRET @""

#define INSTAGRAM_ACCESS_TOKEN @""
#define FACEBOOK_ACCESS_TOKEN @""
#define PINTEREST_ACCESS_TOKEN @""

#define SOUNDCLOUD_CLIENT @""

/**
 * Other
 */
#define OPEN_IN_BROWSER false

//END OF CONFIGURATION

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (nonatomic, retain) AVPlayer *player;

@property (strong, nonatomic) OneSignal *oneSignal;

@property (nonatomic) int interstitialCount;


//Keeping a reference to controller that is currently playing audio. 
@property (strong, nonatomic) UIViewController* activePlayerController;
- (void) setActivePlayingViewController: (UIViewController *) active;
- (UIViewController *) activePlayingViewController;
- (void) closePlayerWithObserver: (NSObject *) observer;

//Utility methods
- (BOOL) shouldShowInterstitial;
+ (BOOL) hasPurchased;
+ (void) openUrl: (NSString *) url withNavigationController: (UINavigationController *) navController;
@end
