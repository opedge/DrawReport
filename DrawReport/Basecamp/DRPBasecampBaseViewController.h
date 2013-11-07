//
//  DRPBasecampBaseViewController.h
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 05.11.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DRPBasecampBaseViewController : UITableViewController

@property (nonatomic, strong) NSArray *objects;

@property (nonatomic, strong) NSString *accessToken;

- (void)showAlertForNetworkError;

@end
