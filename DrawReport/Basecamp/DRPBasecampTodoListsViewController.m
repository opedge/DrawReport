//
//  DRPBasecampTodoListsViewController.m
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 05.11.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import "DRPBasecampTodoListsViewController.h"
#import "DRPBasecampClient.h"
#import "NSError+DRPBasecamp.h"
#import "DRPBasecamp.h"
#import "DRPBasecampTodoList.h"
#import "DRPBasecampNewTodoListViewController.h"

@interface DRPBasecampTodoListsViewController () <DRPBasecampNewTodoListViewControllerDelegate>

@end

@implementation DRPBasecampTodoListsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = NSLocalizedString(@"TODO Lists", nil);
    
    UIBarButtonItem *createTodoListButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createTodoListButtonClicked:)];
    self.navigationItem.rightBarButtonItem = createTodoListButton;
}

- (void)createTodoListButtonClicked:(id)sender {
    DRPBasecampNewTodoListViewController *newTodoListVC = [[DRPBasecampNewTodoListViewController alloc] init];
    newTodoListVC.accessToken = self.accessToken;
    newTodoListVC.project = self.project;
    newTodoListVC.delegate = self;
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:newTodoListVC];
    [self presentViewController:navVC animated:YES completion:nil];
}

- (void)loadData {
    __weak DRPBasecampTodoListsViewController *weakSelf = self;
    [[DRPBasecampClient sharedInstance] getTodoListsForProject:self.project accessToken:self.accessToken complete:^(NSArray *todoLists, NSError *error) {
        if (error) {
            if ([error drp_isBasecampError]) {
                [[DRPBasecamp sharedInstance] removeBasecampAccounts];
                [weakSelf showAlertForBasecampError];
            } else {
                [weakSelf showAlertForNetworkError];
            }
        } else {
            if (todoLists.count > 0) {
                weakSelf.objects = todoLists;
                [weakSelf.refreshControl endRefreshing];
                [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [weakSelf showAlertForNoTodoListsError];
            }
        }
    }];
}

- (void)showAlertForBasecampError {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You don't have permissions to get TODO Lists", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)showAlertForNoTodoListsError {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You don't have TODO Lists in this project. You need to create one", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    DRPBasecampTodoList *todoList = self.objects[indexPath.row];
    cell.textLabel.text = todoList.name;
    cell.detailTextLabel.text = todoList.todoListDescription;
}

#pragma mark - DRPBasecampNewTodoListViewControllerDelegate methods
- (void)todoListViewController:(DRPBasecampNewTodoListViewController *)todoListViewController didCreatedTodoList:(DRPBasecampTodoList *)todoList {
    [todoListViewController dismissViewControllerAnimated:YES completion:nil];
    [self.refreshControl beginRefreshing];
    [self loadData];
}

#pragma mark - UITableViewDelegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    DRPBasecampTodoList *todoList = self.objects[indexPath.row];
    [[DRPBasecamp sharedInstance] setUserAccount:self.userAccount project:self.project todoList:todoList];
    [[DRPBasecamp sharedInstance] showReadyToSendAlert];
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
