//
//  AppDelegate.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "AppDelegate.h"
#import <GoogleMaps/GoogleMaps.h>
#import "Config.h"
#import "WBInAppHelper.h"
#import "WebViewController.h"
#import "TabNavigationController.h"
#import "WXApi.h"

#import <UMSocialCore/UMSocialCore.h>

@interface AppDelegate ()<WXApiDelegate>

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [UIApplication sharedApplication].statusBarStyle = UIStatusBarStyleLightContent;
    
    [GMSServices provideAPIKey: MAPS_API_KEY];
    
    // Ads
    if (BANNER_ADS_ON && ![AppDelegate hasPurchased]){
        SWRevealViewController *revealController = (SWRevealViewController *)self.window.rootViewController;
        
        [CJPAdMobHelper sharedInstance].adMobUnitID = ADMOB_UNIT_ID;
        [[CJPAdMobHelper sharedInstance] startWithViewController:revealController];
        [[[UIApplication sharedApplication] delegate] window].rootViewController = [CJPAdMobHelper sharedInstance];
    
        [revealController.frontViewController viewDidLoad];
    }
    
    //In App purchases
    if ([IN_APP_PRODUCT length] > 0){
        [WBInAppHelper setProductsList:@[IN_APP_PRODUCT]];
    }
    
    // Navbar appearance
    [[UINavigationBar appearance] setBarTintColor:APP_THEME_COLOR];
    [[UINavigationBar appearance] setTintColor:[UIColor whiteColor]];
    [[UINavigationBar appearance] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIColor whiteColor],NSForegroundColorAttributeName, nil]];
    [WXApi registerApp:@"wxe58c890534399ad3"];
    // OneSignal/Notifications
    if ([ONESIGNAL_APP_ID length] > 0){
        self.oneSignal = [OneSignal initWithLaunchOptions:launchOptions appId:ONESIGNAL_APP_ID];
    }
    
    return YES;
}

- (void)application:(UIApplication*)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken
{
	NSString *newToken = [deviceToken description];
	newToken = [newToken stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]];
	newToken = [newToken stringByReplacingOccurrencesOfString:@" " withString:@""];
    
	NSLog(@"My token is: %@", newToken);
}

- (void)application:(UIApplication*)application didFailToRegisterForRemoteNotificationsWithError:(NSError*)error
{
	NSLog(@"Failed to get token, error: %@", error);
}

#pragma mark WXApiDelegate 微信分享的相关回调

-(BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url{
    return [WXApi handleOpenURL:url delegate:self];
}

-(BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<NSString *,id> *)options{
    return [WXApi handleOpenURL:url delegate:self];
}

// onReq是微信终端向第三方程序发起请求，要求第三方程序响应。第三方程序响应完后必须调用sendRsp返回。在调用sendRsp返回时，会切回到微信终端程序界面
- (void)onReq:(BaseReq *)req
{
    NSLog(@"onReq是微信终端向第三方程序发起请求，要求第三方程序响应。第三方程序响应完后必须调用sendRsp返回。在调用sendRsp返回时，会切回到微信终端程序界面");
}

// 如果第三方程序向微信发送了sendReq的请求，那么onResp会被回调。sendReq请求调用后，会切到微信终端程序界面
- (void)onResp:(BaseResp *)resp
{
    NSLog(@"回调处理");
    
    // 处理 分享请求 回调
    if ([resp isKindOfClass:[SendMessageToWXResp class]]) {
        switch (resp.errCode) {
            case WXSuccess:
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"分享成功!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }
                break;
                
            default:
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"分享失败!" delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
                [alert show];
            }
                break;
        }
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

//Player management

- (UIViewController *) activePlayingViewController {
    return self.activePlayerController;
}

- (void) setActivePlayingViewController: (UIViewController *) active {
    self.activePlayerController = active;
}

- (void) closePlayerWithObserver:(NSObject *)observer {
    if (self.player){
        
        @try{
            [self.player removeObserver:observer forKeyPath:@"rate"];
        }@catch(id anException){
            //do nothing, obviously it wasn't attached because an exception was thrown
        }
        
        /**
        @try{
            [self.player.currentItem removeObserver:observer forKeyPath:@"timedMetadata"];
        }@catch(id anException){
            //do nothing, obviously it wasn't attached because an exception was thrown
        }
         **/
        
        [self.player pause];
        self.player = nil;
    }
}

//-- Utility method

+ (void) openUrl: (NSString *) url withNavigationController: (UINavigationController *) navController {
    if (OPEN_IN_BROWSER || ![navController isKindOfClass:[UIViewController class]]){
        UIApplication *application = [UIApplication sharedApplication];
        [application openURL:[NSURL URLWithString:url] options:@{} completionHandler:nil];
    } else {
        //Make the header/navbar solid
        if ([navController isKindOfClass:[TabNavigationController class]]){
            TabNavigationController *nc = (TabNavigationController *) navController;
            [nc.gradientView turnTransparencyOn:NO animated:YES];
        }
        
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Main" bundle:nil];
        WebViewController *vc = [storyboard instantiateViewControllerWithIdentifier:@"WebViewController"];
        vc.params = @[url];
        [navController pushViewController:vc animated:YES];
    }
}

- (BOOL) shouldShowInterstitial {
    if ([ADMOB_INTERSTITIAL_ID length] == 0) return false;
    if (INTERSTITIAL_INTERVAL == 0) return false;
    if ([AppDelegate hasPurchased]) return false;
    
    if (!_interstitialCount) _interstitialCount = 0;
    
    BOOL shouldShowInterstitial = false;
    if (_interstitialCount == INTERSTITIAL_INTERVAL) {
        shouldShowInterstitial = true;
        _interstitialCount = 0;
    }
    
    _interstitialCount++;
    return shouldShowInterstitial;
}

+ (BOOL) hasPurchased {
    if ([IN_APP_PRODUCT length] == 0) return false;
    
    return [WBInAppHelper isProductPaid:IN_APP_PRODUCT];
}



@end
