//
//  RSTWebViewController.h
//
//  Created by Riley Testut on 7/15/13.
//  Copyright (c) 2013 Riley Testut. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, RSTWebViewControllerSharingActivity) {
    RSTWebViewControllerSharingActivityNone = 0,
    RSTWebViewControllerSharingActivityAll = 1,
    RSTWebViewControllerSharingActivitySafari = 1 << 0,
    RSTWebViewControllerSharingActivityChrome = 1 << 1,
    RSTWebViewControllerSharingActivityMail = 1 << 2,
    RSTWebViewControllerSharingActivityCopy = 1 << 3,
    RSTWebViewControllerSharingActivityMessage = 1 << 4,
};

@protocol RSTWebViewControllerDelegate <NSObject>

@end

@interface RSTWebViewController : UIViewController

// Included UIActivities to be displayed when sharing a link. Default is RSTWebViewControllerSharingActivityAll
@property (assign, nonatomic) RSTWebViewControllerSharingActivity supportedSharingActivities;

// Additional UIActivities to be displayed when sharing a link
@property (copy, nonatomic) NSArray /* UIActivity */ *additionalSharingActivities;

// Set to YES when presenting modally to show a Done button that'll dismiss itself. Must be set before presentation.
@property (assign, nonatomic) BOOL showDoneButton;

- (instancetype)initWithAddress:(NSString *)address;
- (instancetype)initWithURL:(NSURL *)url;
- (instancetype)initWithRequest:(NSURLRequest *)request;

@end
