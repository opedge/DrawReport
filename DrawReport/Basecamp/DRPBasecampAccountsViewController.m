//
// DRPAccountsViewController.m
//
// Copyright (c) 2013 Oleg Poyaganov (opedge@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

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
            [weakSelf.refreshControl endRefreshing];
            if (accounts.count > 0) {
                weakSelf.objects = accounts;
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
