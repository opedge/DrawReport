//
//  DRPAccountsViewController.m
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 01.11.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import "DRPBasecampAccountsViewController.h"
#import "DRPBasecamp.h"
#import "DRPBasecampClient.h"
#import "NSError+DRPBasecamp.h"
#import "DRPBasecampUserAccount.h"
#import "DRPBasecampProjectsViewController.h"

static NSString * const DRPBasecampAccountCellId = @"DRPBasecampAccountCellId";

@interface DRPBasecampAccountsViewController ()

@end

@implementation DRPBasecampAccountsViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationItem.title = @"Basecamp Accounts";
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonClicked:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem *logoutButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Logout", nil) style:UIBarButtonItemStyleBordered target:self action:@selector(logoutButtonClicked:)];
    self.navigationItem.rightBarButtonItem = logoutButton;
}

- (void)logoutButtonClicked:(id)sender {
    [[DRPBasecamp sharedInstance] logout];
    [self dismissViewControllerAnimated:YES completion:^{
        [[DRPBasecamp sharedInstance] presentConfigurationViewController];
    }];
}

- (void)cancelButtonClicked:(id)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)loadData {
    __weak DRPBasecampAccountsViewController *weakSelf = self;
    [[DRPBasecampClient sharedInstance] getBCXAccountsWithAccessToken:self.accessToken complete:^(NSArray *accounts, NSError *error) {
        if (error) {
            if ([error drp_isBasecampError]) {
                [[DRPBasecamp sharedInstance] removeBasecampAccounts];
                [weakSelf showAlertForBasecampError];
            } else {
                [weakSelf showAlertForNetworkError];
            }
        } else {
            if (accounts.count > 0) {
                weakSelf.objects = accounts;
                [weakSelf.refreshControl endRefreshing];
                [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            } else {
                [weakSelf showAlertForNoAccountsError];
            }
        }
    }];
}

- (void)showAlertForBasecampError {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You don't have permissions to get your accounts", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)showAlertForNoAccountsError {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You don't have Basecamp available accounts. You need to create one", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)configureCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    DRPBasecampUserAccount *account = self.objects[indexPath.row];
    cell.textLabel.text = account.name;
}

#pragma mark - UIAlertViewDelegate method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITableViewDelegate methods
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    DRPBasecampUserAccount *userAccount = self.objects[indexPath.row];
    DRPBasecampProjectsViewController *projectsVC = [[DRPBasecampProjectsViewController alloc] init];
    projectsVC.accessToken = self.accessToken;
    projectsVC.userAccount = userAccount;
    [self.navigationController pushViewController:projectsVC animated:YES];
}

@end
