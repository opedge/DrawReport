//
//  DRPBasecampAuthViewController.h
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 23.10.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "DRPBasecampClient.h"

@interface DRPBasecampAuthViewController : UIViewController <UIWebViewDelegate>

@property (nonatomic, strong) NSURL *authURL;

@property (nonatomic, copy) DRPBasecampObtainTokenSuccess successBlock;
@property (nonatomic, copy) DRPBasecampObtainTokenFailure failureBlock;

@end
