//
//  WebViewController.m
//
//  Copyright (c) 2016 Sherdle. All rights reserved.
//

#import "WebViewController.h"
#import "SWRevealViewController.h"
#import "AppDelegate.h"

#define OFFLINE_FILE_EXTENSION @"html"

@implementation WebViewController
@synthesize params;

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.loadingIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [self.loadingIndicator startAnimating];
    self.navigationItem.titleView = self.loadingIndicator;
    
    _webView.delegate = self;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(handleRefresh:) forControlEvents:UIControlEventValueChanged];
    [_webView.scrollView addSubview:self.refreshControl]; //<- this is point to use. Add "scrollView" property.
    
    if (self.basicMode){
        self.navigationItem.rightBarButtonItems = nil;
        self.refreshControl.enabled = false;
    }
    
    [self loadWebViewContent];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
}

- (void)loadWebViewContent {
    //Set all the data
    //If the url begins with http (or https for that matter), load it as a webpage. Otherwise, load an asset
    if (self.htmlString) {
        [_webView loadHTMLString:self.htmlString baseURL:[NSURL URLWithString:params[0]]];
    } else {
        NSURL *url;
        NSString *urlString;
        
        //If a string does not start with http, does end with .html and does not contain any slashes, we'll assume it's a local page.
        if (![[params[0] substringToIndex:4] isEqualToString:@"http"] && [params[0] containsString: [NSString stringWithFormat: @".%@", OFFLINE_FILE_EXTENSION]] && ![params[0] containsString: @"/"]){
            urlString = [params[0] stringByReplacingOccurrencesOfString:
                          [NSString stringWithFormat: @".%@", OFFLINE_FILE_EXTENSION] withString:@""];
            url = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:urlString ofType: OFFLINE_FILE_EXTENSION inDirectory:@"Local"]];
        } else {
            if (![[params[0] substringToIndex:4] isEqualToString:@"http"]){
                urlString = [NSString stringWithFormat:@"http://%@", params[0]];
            } else {
                urlString = params[0];
            }
            
            url = [NSURL URLWithString: urlString];
        }
    
        [_webView loadRequest:[NSURLRequest requestWithURL:url]];
    }
}

- (IBAction)goForward:(id)sender {
    [_webView goForward];
}

- (IBAction)goBack:(id)sender {
    [_webView goBack];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    [[NSURLCache sharedURLCache] removeAllCachedResponses];
}

- (void)webViewDidStartLoad:(UIWebView *)webView{
    if (![self.refreshControl isRefreshing]){
        self.navigationItem.titleView = self.loadingIndicator;
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    self.navigationItem.titleView = nil;
    
    if (self.refreshControl && [self.refreshControl isRefreshing]){
        [self.refreshControl endRefreshing];
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error{
    if (error.code == NSURLErrorNotConnectedToInternet){
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error", nil)message:NO_CONNECTION_TEXT preferredStyle:UIAlertControllerStyleAlert];
            
        UIAlertAction* ok = [UIAlertAction actionWithTitle:NSLocalizedString(@"ok", nil) style:UIAlertActionStyleDefault handler:nil];
        [alertController addAction:ok];
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)loadRequest:(NSURLRequest *)request
{
    if ([_webView isLoading])
        [_webView stopLoading];
    [_webView loadRequest:request];
}

- (void)viewWillDisappear
{
    if ([_webView  isLoading])
        [_webView  stopLoading];
}

-(void)handleRefresh:(UIRefreshControl *)refresh {
    // Reload my data
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:_webView.request.URL];
    [_webView loadRequest:requestObj];
}

@end
