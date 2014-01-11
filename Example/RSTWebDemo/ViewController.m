//
//  ViewController.m
//  RSTWebDemo
//
//  Created by Riley Testut on 7/15/13.
//  Copyright (c) 2013 Riley Testut. All rights reserved.
//

#import "ViewController.h"
#import "RSTWebViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.title = @"Demo";
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)presentWebViewController:(id)sender {
    RSTWebViewController *webViewController = [[RSTWebViewController alloc] initWithAddress:@"http://rileytestut.com"];
    webViewController.supportedSharingActivities = RSTWebViewControllerSharingActivitySafari;
    [self.navigationController pushViewController:webViewController animated:YES];
}

@end
