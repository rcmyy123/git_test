//
//  ShowPageCell.m
//
//  Implements: KnomeiOS-SSO
//  Created by tcs on 19/10/13.
//  Copyright (c) 2013 tcs. All rights reserved.
//

#import "ShowPageCell.h"
#import "AppDelegate.h"

#define WIDTH [UIScreen mainScreen].bounds.size.width
#define HEIGHT [UIScreen mainScreen].bounds.size.height

@implementation ShowPageCell
{
    BOOL contentLoaded;
    CGFloat contentWidth;
    CGFloat contentHeight;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    
    _webView = [[WKWebView alloc] initWithFrame:CGRectMake(15, 0, WIDTH-30, HEIGHT)];
    _webView.navigationDelegate = self;
    _webView.layer.cornerRadius = 0;
    _webView.userInteractionEnabled = YES;
    _webView.multipleTouchEnabled = YES;
    _webView.clipsToBounds = YES;
//    _webView.scalesPageToFit = NO;
    _webView.backgroundColor = [UIColor clearColor];
    _webView.scrollView.scrollEnabled = NO;
    _webView.scrollView.bounces = NO;
    
    contentHeight = 50.0f;
    [self addSubview:_webView];
}

- (CGFloat)updateWebViewHeightForWidth:(CGFloat)width {
//    if (!contentWidth) {//width == contentWidth
//        NSLog(@"返回高度");
//        return contentHeight;
//    }
    
    // scrollView.scrollEnabled must be set to NO
    CGRect vwFrame = _webView.frame;
    CGFloat wvWidth = width - self.layoutMargins.left - self.layoutMargins.right;
    vwFrame.size = CGSizeMake(wvWidth, 1);
    _webView.frame = vwFrame;
    CGFloat newHeight = _webView.scrollView.contentSize.height;
    vwFrame.size.height = newHeight;
    _webView.frame = vwFrame;
    
    //NSLog(@"web cell LayoutSubviews with width = %f, height = %f", width, newHeight);
    contentWidth = width;
    contentHeight = newHeight;
    
    //Bugfix. Calling endUpdates immediately will crash upon rotation.
    double delayInSeconds = 0.5;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
         [_parentTable beginUpdates];
         [_parentTable endUpdates];
    });
    
    return contentHeight;
}

- (void)loadContent:(NSString *)htmlContent {
    NSString *style = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"style" ofType:@"css"] encoding:NSUTF8StringEncoding error:nil];
    
    //Add the content to the another string with styling and the original html content
    NSString *htmlStyling = [NSString stringWithFormat:@"<html>"
                             "<head>"
                             "<meta name=\"viewport\" content=\"width=device-width, initial-scale=1, minimum-scale=1, maximum-scale=1, user-scalable=0\" />"
                             "<style type=\"text/css\">"
                             "%@"
                             "</style>"
                             "</head>"
                             "<body>"
                             "<p>%@</p>"
                             "</body></html>", style, htmlContent];
    NSLog(@"loadContent");
    [_webView loadHTMLString:htmlStyling baseURL:nil];
}

#pragma mark - UIWebViewDelegate

-(BOOL) webView:(UIWebView *)inWeb shouldStartLoadWithRequest:(NSURLRequest *)inRequest navigationType:(UIWebViewNavigationType)inType {
    contentLoaded = NO;
    
    if (inType == UIWebViewNavigationTypeLinkClicked) {
        [AppDelegate openUrl:inRequest.URL.absoluteString withNavigationController:self.parentViewController.navigationController];
        return NO;
    }
    
    if ([[[inRequest URL] absoluteString] rangeOfString:@"youtube.com/watch" options:NSCaseInsensitiveSearch].location == NSNotFound) {
        //NSLog(@"Does not contain youtube.com/watch %@", [[inRequest URL] absoluteString]);
    } else {
        UIApplication *application = [UIApplication sharedApplication];
        [application openURL:inRequest.URL options:@{} completionHandler:nil];
        return NO;
    }
    NSLog(@"哈哈哈");
    return YES;
}

- (void)webViewDidFinishLoad:(UIWebView *)aWebView {
    // on new content, force web view height recalculation
    contentWidth = 0;
    contentLoaded = YES;

    _webView.hidden = false;
    NSLog(@"jiuzheyang");
    [self updateWebViewHeightForWidth:self.frame.size.width];
}

#pragma mark - WKNavigationDelegate
// 页面开始加载时调用
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {

}

// 当内容开始返回时调用
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {

}

// 页面加载完成之后调用
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    contentWidth = 0;
//    contentLoaded = YES;
    
    NSLog(@"jiuzheyang");
    CGFloat height = 0.0;
    [webView sizeToFit];
    height = _webView.scrollView.contentSize.height;
    CGRect webFrame = webView.frame;
    webFrame.size.height = height;
    webView.frame = webFrame;
//    [_parentTable beginUpdates];
//    [_parentTable endUpdates];
//    [self updateWebViewHeightForWidth:self.frame.size.width];
}

// 页面加载失败时调用
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation {
    
//    [self.view showLoadingMeg:@"数据加载失败！" time:MESSAGE_SHOW_TIME];
    
}

@end
