//
//  DRPBasecampNewTodoListViewController.h
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 05/11/13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import <UIKit/UIKit.h>

@class DRPBasecampProject;
@class DRPBasecampTodoList;
@class DRPBasecampNewTodoListViewController;

@protocol DRPBasecampNewTodoListViewControllerDelegate <NSObject>

- (void)todoListViewController:(DRPBasecampNewTodoListViewController *)todoListViewController didCreatedTodoList:(DRPBasecampTodoList *)todoList;

@end

@interface DRPBasecampNewTodoListViewController : UITableViewController

@property (nonatomic, weak) id<DRPBasecampNewTodoListViewControllerDelegate> delegate;
@property (nonatomic, strong) DRPBasecampProject *project;
@property (nonatomic, strong) NSString *accessToken;

@end
