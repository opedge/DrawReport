//
//  DRPBasecampTodoListsViewController.h
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 05.11.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import "DRPBasecampBaseViewController.h"

@class DRPBasecampProject;
@class DRPBasecampUserAccount;

@interface DRPBasecampTodoListsViewController : DRPBasecampBaseViewController

@property (nonatomic, strong) DRPBasecampUserAccount *userAccount;
@property (nonatomic, strong) DRPBasecampProject *project;

@end
