//
//  DRPBasecampProjectsViewController.m
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 05.11.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import "DRPBasecampProjectsViewController.h"
#import "DRPBasecampClient.h"
#import "NSError+DRPBasecamp.h"
#import "DRPBasecamp.h"
#import "DRPBasecampProject.h"
#import "DRPBasecampTodoListsViewController.h"

@interface DRPBasecampProjectsViewController ()

@end

@implementation DRPBasecampProjectsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Projects";
}

- (void)loadData {
    __weak DRPBasecampProjectsViewController *weakSelf = self;
    [[DRPBasecampClient sharedInstance] getProjectsForUserAccount:self.userAccount accessToken:self.accessToken complete:^(NSArray *projects, NSError *error) {
        if (error) {
            if ([error drp_isBasecampError]) {
                [[DRPBasecamp sharedInstance] removeBasecampAccounts];
                [weakSelf showAlertForBasecampError];
            } else {
                [weakSelf showAlertForNetworkError];
            }
        } else {
            if (projects.count > 0) {
                weakSelf.objects = projects;
                [weakSelf.refreshControl endRefreshing];
                [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [weakSelf showAlertForNoProjectsError];
            }
        }
    }];
}

- (void)showAlertForBasecampError {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You don't have permissions to get your projects", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)showAlertForNoProjectsError {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You don't have projects in this account. You need to create one", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    DRPBasecampProject *project = self.objects[indexPath.row];
    cell.textLabel.text = project.name;
    cell.detailTextLabel.text = project.projectDescription;
}

#pragma mark - UITableViewDelegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    DRPBasecampProject *project = self.objects[indexPath.row];
    
    DRPBasecampTodoListsViewController *todoListsVC = [[DRPBasecampTodoListsViewController alloc] init];
    todoListsVC.userAccount = self.userAccount;
    todoListsVC.project = project;
    todoListsVC.accessToken = self.accessToken;
    [self.navigationController pushViewController:todoListsVC animated:YES];
}

@end
