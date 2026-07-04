//
//  WebViewController.h
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController<UIWebViewDelegate>

@property (strong, nonatomic) IBOutlet UIWebView *webView;

@property(strong,nonatomic)NSArray *params;
@property(strong,nonatomic)NSString *htmlString;
@property(nonatomic)bool basicMode;

@property(strong,nonatomic)UIActivityIndicatorView *loadingIndicator;
@property(strong,nonatomic)UIRefreshControl *refreshControl;

@end
