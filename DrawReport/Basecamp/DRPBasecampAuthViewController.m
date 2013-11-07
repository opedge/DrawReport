//
//  DRPBasecampAuthViewController.m
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 23.10.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import "DRPBasecampAuthViewController.h"
#import <NXOAuth2Client/NXOAuth2.h>

@interface DRPBasecampAuthViewController ()

@property (nonatomic, weak) UIWebView *webView;
@property (nonatomic, weak) UIActivityIndicatorView *indicatorView;

@end

@implementation DRPBasecampAuthViewController

- (id)init {
    self = [super initWithNibName:nil bundle:[NSBundle mainBundle]];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Basecamp";
    
    [self setupBarButtons];
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver:self selector:@selector(handleSuccessAuth:) name:NXOAuth2AccountStoreAccountsDidChangeNotification object:[NXOAuth2AccountStore sharedStore]];
    [notificationCenter addObserver:self selector:@selector(handleFailedAuth:) name:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore]];
    
    UIWebView *webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    webView.delegate = self;

    [self.view addSubview:webView];
    _webView = webView;
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:self.authURL];
    [_webView loadRequest:request];
}

- (void)handleSuccessAuth:(NSNotification *)notification {
    NXOAuth2Account *account = notification.userInfo[NXOAuth2AccountStoreNewAccountUserInfoKey];
    [self dismissViewControllerAnimated:YES completion:^{
        self.successBlock(account.accessToken.accessToken);
    }];
}

- (void)handleFailedAuth:(NSNotification *)notification {
    NSError *error = [notification.userInfo objectForKey:NXOAuth2AccountStoreErrorKey];
    [self dismissViewControllerAnimated:YES completion:^{
        self.failureBlock(error);
    }];
}

- (void)dealloc {
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter removeObserver:self name:NXOAuth2AccountStoreAccountsDidChangeNotification object:[NXOAuth2AccountStore sharedStore]];
    [notificationCenter removeObserver:self name:NXOAuth2AccountStoreDidFailToRequestAccessNotification object:[NXOAuth2AccountStore sharedStore]];
}

- (void)setupBarButtons {
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    UIBarButtonItem *indicatorButton = [[UIBarButtonItem alloc] initWithCustomView:indicatorView];
    self.navigationItem.rightBarButtonItem = indicatorButton;
    _indicatorView = indicatorView;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelClicked:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void)cancelClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UIWebViewDelegate methods
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    return ![store handleRedirectURL:request.URL];
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [_indicatorView startAnimating];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    [_indicatorView stopAnimating];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [_indicatorView stopAnimating];
}

@end
