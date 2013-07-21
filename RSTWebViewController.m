//
//  RSTWebViewController.m
//
//  Created by Riley Testut on 7/15/13.
//  Copyright (c) 2013 Riley Testut. All rights reserved.
//

#import "RSTWebViewController.h"
#import "NJKWebViewProgress.h"

@interface RSTWebViewController () <UIWebViewDelegate, NJKWebViewProgressDelegate, NSURLSessionDownloadDelegate>

@property (strong, nonatomic) UIWebView *webView;
@property (strong, nonatomic) NSURLRequest *currentRequest;
@property (strong, nonatomic) UIProgressView *progressView;
@property (strong, nonatomic) NJKWebViewProgress *webViewProgress;
@property (assign, nonatomic) BOOL loadingRequest; // Help prevent false positives

@end

@implementation RSTWebViewController

#pragma mark - Initialization

- (instancetype)initWithAddress:(NSString *)address
{
    return [self initWithURL:[NSURL URLWithString:address]];
}

- (instancetype)initWithURL:(NSURL *)url
{
    return [self initWithRequest:[NSURLRequest requestWithURL:url]];
}

- (instancetype)initWithRequest:(NSURLRequest *)request
{
    self = [super init];
    
    if (self)
    {
        _currentRequest = request;
        _loadingRequest = YES;
        
        _webViewProgress = [[NJKWebViewProgress alloc] init];
        _webViewProgress.webViewProxyDelegate = self;
        _webViewProgress.progressDelegate = self;
        
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        _progressView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        _progressView.trackTintColor = [UIColor clearColor];
        _progressView.alpha = 0.0;
        _progressView.progress = 0.0;
    }
    
    return self;
}

#pragma mark - Configure View

- (void)loadView
{
    self.webView = [[UIWebView alloc] init];
    self.webView.delegate = self.webViewProgress;
    self.webView.backgroundColor = [UIColor whiteColor];
    self.webView.scalesPageToFit = YES;
    self.view = self.webView;
    
    [self.webView loadRequest:self.currentRequest];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.progressView.frame = CGRectMake(0,
                                     CGRectGetHeight(self.navigationController.navigationBar.bounds) - CGRectGetHeight(self.progressView.bounds),
                                     CGRectGetWidth(self.navigationController.navigationBar.bounds),
                                     CGRectGetHeight(self.progressView.bounds));
    
    if (self.showDoneButton)
    {
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissWebViewController:)];
        [self.navigationItem setRightBarButtonItem:doneButton];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (self.presentingViewController)
        {
            // Presenting modally
            animated = NO;
        }
        
        [self.navigationController setToolbarHidden:NO animated:animated];
    }
    
    [self.navigationController.navigationBar addSubview:self.progressView];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone)
    {
        if (self.presentingViewController)
        {
            // Presenting modally
            animated = NO;
        }
        
        [self.navigationController setToolbarHidden:YES animated:animated];
    }
    
    [self hideProgressViewWithCompletion:^{
        [self.progressView removeFromSuperview];
    }];
}

- (void)refreshToolbarItems
{
    UIBarButtonItem *goBackButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Back Button"] style:UIBarButtonItemStylePlain target:nil action:nil];
    UIBarButtonItem *goForwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Forward Button"] style:UIBarButtonItemStylePlain target:nil action:nil];
    UIBarButtonItem *actionButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareLink:)];
    self.toolbarItems = @[goBackButton, goForwardButton, actionButton];
}

#pragma mark - Sharing

- (void)shareLink:(UIBarButtonItem *)barButtonItem {
    NSString *currentAddress = [self.webView stringByEvaluatingJavaScriptFromString:@"window.location.href"];
    NSURL *url = [NSURL URLWithString:currentAddress];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:self.additionalSharingActivities];
    [self presentViewController:activityViewController animated:YES completion:NULL];
}

#pragma mark - Progress View

- (void)showProgressView
{
    [UIView animateWithDuration:0.4 animations:^{
        self.progressView.alpha = 1.0;
    }];
}

- (void)hideProgressViewWithCompletion:(void (^)(void))completion
{
    [UIView animateWithDuration:0.4 animations:^{
        self.progressView.alpha = 0.0;
    } completion:^(BOOL finished) {
        if (completion) {
            completion();
        }
    }];
}

- (void)webViewProgress:(NJKWebViewProgress *)webViewProgress updateProgress:(float)progress
{
    if (self.loadingRequest) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressView setProgress:progress animated:YES];
            
            if (progress >= 1.0)
            {
                self.loadingRequest = NO;
                [self hideProgressViewWithCompletion:NULL];
                
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
                [self refreshToolbarItems];
            }
            else if (self.progressView.alpha <= 0.01)
            {
                [self showProgressView];
                [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
                [self refreshToolbarItems];
            }
        });
    }
}

#pragma mark - UIWebViewController delegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
	// Called multiple times per loading of a large web page, so we do our start methods in webViewProgress:updateProgress:
}


- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.navigationItem.title = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
    self.currentRequest = self.webView.request;
    // Don't hide progress view here, as the webpage isn't visible yet
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    [self refreshToolbarItems];
    
    [self hideProgressViewWithCompletion:NULL];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    self.loadingRequest = YES;
    
    if ([self.delegate respondsToSelector:@selector(webViewController:shouldStartDownloadWithRequest:)])
    {
        if ([self.delegate webViewController:self shouldStartDownloadWithRequest:request])
        {
            [self startDownloadWithRequest:request];
        }
    }
    
    return YES;
}

#pragma mark - Private

- (void)startDownloadWithRequest:(NSURLRequest *)request
{
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.allowsCellularAccess = YES;
    configuration.discretionary = NO;
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration delegate:self delegateQueue:nil];
    
    NSURLSessionDownloadTask *downloadTask = [session downloadTaskWithRequest:request];
    downloadTask.uniqueTaskIdentifier = [[NSUUID UUID] UUIDString];
    
    if ([self.delegate respondsToSelector:@selector(webViewController:willStartDownloadWithTask:startDownloadBlock:)])
    {
        [self.delegate webViewController:self willStartDownloadWithTask:downloadTask startDownloadBlock:^(BOOL shouldContinue)
        {
            if (shouldContinue)
            {
                [downloadTask resume];
            }
            else
            {
                [downloadTask cancel];
            }
        }];
    }
    else
    {
        [downloadTask resume];
    }
    
}

#pragma mark - NSURLSession delegate

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    if ([self.delegate respondsToSelector:@selector(webViewController:downloadTask:totalBytesDownloaded:totalBytesExpected:)])
    {
        [self.delegate webViewController:self downloadTask:downloadTask totalBytesDownloaded:totalBytesWritten totalBytesExpected:totalBytesExpectedToWrite];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)location
{
    if ([self.delegate respondsToSelector:@selector(webViewController:downloadTask:didDownloadFileToURL:)])
    {
        [self.delegate webViewController:self downloadTask:downloadTask didDownloadFileToURL:location];
    }
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
    if ([self.delegate respondsToSelector:@selector(webViewController:downloadTask:didCompleteDownloadWithError:)])
    {
        [self.delegate webViewController:self downloadTask:(NSURLSessionDownloadTask *)task didCompleteDownloadWithError:error];
    }
}

- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
    // TODO: Support download resuming
}

#pragma mark - Dismissal

- (void)dismissWebViewController:(UIBarButtonItem *)barButtonItem
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - Interface Orientation

- (NSUInteger)supportedInterfaceOrientations
{
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIInterfaceOrientationMaskAllButUpsideDown;
    }
    
    return UIInterfaceOrientationMaskAll;
}

#pragma mark - Memory Management

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc
{
    [self.webView stopLoading];
 	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    self.webView.delegate = nil;
}

@end
