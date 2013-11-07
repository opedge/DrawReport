//
//  DRPBasecampNewTodoListViewController.m
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 05/11/13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import "DRPBasecampNewTodoListViewController.h"
#import "DRPBasecampClient.h"
#import "DRPBasecamp.h"
#import "NSError+DRPBasecamp.h"

static CGFloat const DRPBasecampNewTodoListFormLeftMargin = 15;
static CGFloat const DRPBasecampNewTodoListFormTopMargin = 15;

@interface DRPBasecampNewTodoListViewController ()

@property (nonatomic, weak) UITextField *nameField;
@property (nonatomic, weak) UITextField *descriptionField;

@property (nonatomic, strong) UITableViewCell *nameFieldCell;
@property (nonatomic, strong) UITableViewCell *descriptionFieldCell;

@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UIBarButtonItem *loadingButton;

@end

@implementation DRPBasecampNewTodoListViewController

- (id)init {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self) {
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)]) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.extendedLayoutIncludesOpaqueBars = NO;
    }
    
    self.view.backgroundColor = [UIColor colorWithWhite:0.9 alpha:1];
    
    self.navigationItem.title = NSLocalizedString(@"New TODO List", nil);
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonClicked:)];
    self.navigationItem.leftBarButtonItem = cancelButton;
    
    UIBarButtonItem *saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonClicked:)];
    self.navigationItem.rightBarButtonItem = saveButton;
    saveButton.enabled = NO;
    self.saveButton = saveButton;
    
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    indicatorView.color = [UIColor blackColor];
    UIBarButtonItem *loadingButton = [[UIBarButtonItem alloc] initWithCustomView:indicatorView];
    self.loadingButton = loadingButton;
    
    UITableViewCell *nameCell = [[UITableViewCell alloc] init];
    nameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    CGFloat leftIndent = nameCell.indentationWidth;
    CGFloat width;
    if ([self.tableView respondsToSelector:@selector(separatorInset)]) {
        leftIndent = self.tableView.separatorInset.left;
        width = nameCell.contentView.frame.size.width;
    } else {
        width = nameCell.contentView.frame.size.width - 20;
    }
    UITextField *nameField = [[UITextField alloc] initWithFrame:CGRectMake(leftIndent, 0, width - leftIndent, self.tableView.rowHeight)];
    nameField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    nameField.placeholder = NSLocalizedString(@"List name", nil);
    [nameField addTarget:self action:@selector(nameFieldDidChange:) forControlEvents:UIControlEventEditingChanged];
    [nameCell.contentView addSubview:nameField];
    self.nameField = nameField;
    self.nameFieldCell = nameCell;
    
    UITableViewCell *descriptionCell = [[UITableViewCell alloc] init];
    descriptionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    UITextField *descriptionField = [[UITextField alloc] initWithFrame:nameField.frame];
    descriptionField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    descriptionField.placeholder = NSLocalizedString(@"Description", nil);
    [descriptionCell.contentView addSubview:descriptionField];
    self.descriptionField = descriptionField;
    self.descriptionFieldCell = descriptionCell;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self.nameField becomeFirstResponder];
}

- (void)nameFieldDidChange:(UITextField *)nameField {
    NSString *text = [nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    self.navigationItem.rightBarButtonItem.enabled = ![text isEqualToString:@""];
}

- (void)cancelButtonClicked:(id)sender {
    [[DRPBasecampClient sharedInstance] cancelCurrentOperations];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveButtonClicked:(id)sender {
    [self setupLoadingViewMode];
    
    NSString *name = [self.nameField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *description = [self.descriptionField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    __weak DRPBasecampNewTodoListViewController *weakSelf = self;
    [[DRPBasecampClient sharedInstance] createTodoListWithName:name description:description project:self.project accessToken:self.accessToken complete:^(DRPBasecampTodoList *todoList, NSError *error) {
        [weakSelf setupEditingViewMode];
        if (error) {
            if ([error drp_isBasecampError]) {
                [[DRPBasecamp sharedInstance] removeBasecampAccounts];
                [weakSelf showAlertForBasecampError];
            } else {
                if (![error drp_isURLCancelled]) {
                    [weakSelf showAlertForNetworkError];
                }                
            }
        } else {            
            [weakSelf.delegate todoListViewController:weakSelf didCreatedTodoList:todoList];
        }
    }];
}

- (void)showAlertForNetworkError {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"Network error", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)showAlertForBasecampError {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:NSLocalizedString(@"You don't have permissions to create TODO Lists", nil) delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

#pragma mark - UIAlertViewDelegate method
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)setupLoadingViewMode {
    self.navigationItem.rightBarButtonItem = self.loadingButton;
    UIActivityIndicatorView *indicatorView = (UIActivityIndicatorView *)self.loadingButton.customView;
    [indicatorView startAnimating];
    [self.tableView endEditing:YES];
    self.nameField.enabled = NO;
    self.descriptionField.enabled = NO;
}

- (void)setupEditingViewMode {
    UIActivityIndicatorView *indicatorView = (UIActivityIndicatorView *)self.loadingButton.customView;
    [indicatorView stopAnimating];
    self.navigationItem.rightBarButtonItem = self.saveButton;
    self.nameField.enabled = YES;
    self.descriptionField.enabled = YES;
}

#pragma mark - UITableViewDataSource methods
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = nil;
    switch (indexPath.row) {
        case 0:
            cell = self.nameFieldCell;
            break;
        case 1:
            cell = self.descriptionFieldCell;
            break;
    }
    return cell;
}

@end
