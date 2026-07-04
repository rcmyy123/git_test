//
//  ShowPageCell.h
//
//  Implements: KnomeiOS-SSO
//  Copyright (c) 2013 tcs. All rights reserved.
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
@interface ShowPageCell : UITableViewCell <WKNavigationDelegate>

- (void)loadContent:(NSString *)html;
- (CGFloat)updateWebViewHeightForWidth:(CGFloat)width;

//@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *indicator;
//@property (weak, nonatomic) IBOutlet UIWebView *webView;
//@property (strong, nonatomic) UIActivityIndicatorView *indicator;
@property (strong, nonatomic) WKWebView *webView;
@property (weak, nonatomic) UITableView *parentTable;
@property (weak, nonatomic) UIViewController *parentViewController;

@end
