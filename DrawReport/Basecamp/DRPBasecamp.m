//
// DRPBasecamp.m
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

#import "DRPBasecamp.h"
#import "DRPBasecampClient.h"
#import <NXOAuth2Client/NXOAuth2.h>
#import "DRPBasecampAuthViewController.h"
#import "DRPBasecampUserAccount.h"
#import "DRPBasecampProject.h"
#import "DRPBasecampTodoList.h"
#import "DRPBasecampOperation.h"
#import "NSError+DRPBasecamp.h"
#import "DRPBasecampAccountsViewController.h"

static NSString * const DRPBasecampUserAccountKey = @"DRPBasecampUserAccountKey";
static NSString * const DRPBasecampProjectKey = @"DRPBasecampProjectKey";
static NSString * const DRPBasecampTodoListKey = @"DRPBasecampTodoListKey";

static NSString * const DRPBasecampClientAccountType = @"DRPBasecampClientAccountType";

static NSString * const DRPBasecampClientAuthorizationURLString = @"https://launchpad.37signals.com/authorization/new";
static NSString * const DRPBasecampClientTokenURLString = @"https://launchpad.37signals.com/authorization/token";

static CGFloat const DRPBasecampLoadingCancelButtonWidth = 160;
static CGFloat const DRPBasecampLoadingCancelButtonHeight = 55;

static NSString * const DRPBasecampAttachmentNamePrefix = @"Screenshot";

@interface DRPBasecamp() <UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) DRPBasecampClient *client;
@property (nonatomic, strong) DRPBasecampUserAccount *userAccount;
@property (nonatomic, strong) DRPBasecampProject *project;
@property (nonatomic, strong) DRPBasecampTodoList *todoList;

@property (nonatomic, weak) DRPReporterViewController *sourceVC;
@property (nonatomic, strong) UIImage *reportImage;
@property (nonatomic, strong) NSString *reportText;

@property (nonatomic, weak) UIView *loadingView;

@end

@implementation DRPBasecamp

+ (instancetype)sharedInstance {
    static dispatch_once_t onceQueue;
    static DRPBasecamp *bc = nil;
    dispatch_once(&onceQueue, ^{
        bc = [[self alloc] initWithClient:[DRPBasecampClient sharedInstance]];
    });
    return bc;
}

- (id)initWithClient:(DRPBasecampClient *)client {
    self = [super init];
    if (self) {
        _client = client;
        [self loadConfiguration];
    }
    return self;
}

- (void)configureWithClientId:(NSString *)clientId
                 clientSecret:(NSString *)clientSecret
                  redirectURL:(NSURL *)redirectURL {
    
    NSDictionary *configuration = @{
                                    kNXOAuth2AccountStoreConfigurationClientID: clientId,
                                    kNXOAuth2AccountStoreConfigurationSecret: clientSecret,
                                    kNXOAuth2AccountStoreConfigurationAuthorizeURL: [NSURL URLWithString:DRPBasecampClientAuthorizationURLString],
                                    kNXOAuth2AccountStoreConfigurationTokenURL: [NSURL URLWithString:DRPBasecampClientTokenURLString],
                                    kNXOAuth2AccountStoreConfigurationRedirectURL: redirectURL,
                                    kNXOAuth2AccountStoreConfigurationAdditionalAuthenticationParameters: @{ @"type": @"web_server" }
                                    };
    
    [[NXOAuth2AccountStore sharedStore] setConfiguration:configuration
                                          forAccountType:DRPBasecampClientAccountType];
}

- (void)openAuthorizationModalViewControllerFromViewController:(UIViewController *)sourceViewController
                                                       success:(DRPBasecampObtainTokenSuccess)success
                                                       failure:(DRPBasecampObtainTokenFailure)failure {
    [self removeBasecampAccounts];
    
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    
    DRPBasecampAuthViewController *destinationViewController = [[DRPBasecampAuthViewController alloc] init];
    UINavigationController *navVC = [[UINavigationController alloc] initWithRootViewController:destinationViewController];
    
    [store requestAccessToAccountWithType:DRPBasecampClientAccountType withPreparedAuthorizationURLHandler:^(NSURL *preparedURL) {
        destinationViewController.authURL = preparedURL;
        destinationViewController.successBlock = success;
        destinationViewController.failureBlock = failure;
	[sourceViewController presentViewController:navVC animated:YES completion:nil];
    }];
}

- (void)obtainAccessTokenWithSourceViewController:(UIViewController *)viewController
                                          success:(DRPBasecampObtainTokenSuccess)success
                                          failure:(DRPBasecampObtainTokenFailure)failure {
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *accounts = [store accountsWithAccountType:DRPBasecampClientAccountType];
    if (accounts.count > 0) {
        NXOAuth2Account *account = accounts[0];
        NXOAuth2AccessToken *at = account.accessToken;
        if ([at.expiresAt earlierDate:[NSDate date]] == at.expiresAt) {
            // try to refresh access token
            NSDictionary *configuration = [store configurationForAccountType:DRPBasecampClientAccountType];
            NSString *clientId = configuration[kNXOAuth2AccountStoreConfigurationClientID];
            NSString *clientSecret = configuration[kNXOAuth2AccountStoreConfigurationSecret];
            [self.client refreshAccessToken:at tokenURL:[NSURL URLWithString:DRPBasecampClientTokenURLString] clientId:clientId clientSecret:clientSecret complete:^(NXOAuth2AccessToken *accessToken, NSError *error) {
                if (!error && accessToken) {
                    [[account oauthClient] setAccessToken:accessToken];
                    success(accessToken.accessToken);
                } else {
                    [self openAuthorizationModalViewControllerFromViewController:viewController
                                                                         success:success
                                                                         failure:failure];
                }
            }];
        } else {
            success(at.accessToken);
        }
    } else {
        [self openAuthorizationModalViewControllerFromViewController:viewController
                                                             success:success
                                                             failure:failure];
    }
}

- (void)dealloc {
    [self saveConfiguration];
}

- (NSDictionary *)userData {
    NSMutableDictionary *userData = [NSMutableDictionary dictionary];
    if (_userAccount) {
        [userData setObject:_userAccount forKey:DRPBasecampUserAccountKey];
        if (_project) {
            [userData setObject:_project forKey:DRPBasecampProjectKey];
            if (_todoList) {
                [userData setObject:_todoList forKey:DRPBasecampTodoListKey];
            }
        }
    }
    return [NSDictionary dictionaryWithDictionary:userData];
}

- (void)setUserAccount:(DRPBasecampUserAccount *)userAccount project:(DRPBasecampProject *)project todoList:(DRPBasecampTodoList *)todoList {
    _userAccount = userAccount;
    _project = project;
    _todoList = todoList;
    [self saveConfiguration];
}

- (void)saveConfiguration {
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *accounts = [store accountsWithAccountType:DRPBasecampClientAccountType];
    if (accounts.count > 0) {
        NXOAuth2Account *account = accounts[0];
        [account setUserData:[self userData]];
    }
}

- (void)loadConfiguration {
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *accounts = [store accountsWithAccountType:DRPBasecampClientAccountType];
    if (accounts.count > 0) {
        NXOAuth2Account *account = accounts[0];
        NSDictionary *userData = (NSDictionary *)account.userData;
        _userAccount = userData[DRPBasecampUserAccountKey];
        _project = userData[DRPBasecampProjectKey];
        _todoList = userData[DRPBasecampTodoListKey];
    }
}

- (void)removeBasecampAccounts {
    NXOAuth2AccountStore *store = [NXOAuth2AccountStore sharedStore];
    NSArray *accounts = [store accountsWithAccountType:DRPBasecampClientAccountType];
    for (NXOAuth2Account *account in accounts) {
        [store removeAccount:account];
    }
    _userAccount = nil;
    _project = nil;
    _todoList = nil;
}

- (void)logout {
    [self removeBasecampAccounts];
    [self clearAuthCookies];
}

- (void)clearAuthCookies {
    NSURL *url = [NSURL URLWithString:DRPBasecampClientAuthorizationURLString];
    NSString *domain = [url host];
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *cookie in cookieStorage.cookies) {
        if ([[cookie domain] isEqualToString:domain]) {
            [cookieStorage deleteCookie:cookie];
        }
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)isAllConfigurationLoaded {
    return _userAccount && _project && _todoList;
}

- (void)showAlertForError:(NSError *)error {
    if (![error drp_isURLCancelled]) {
        NSString *message;
        if ([error drp_isBasecampError]) {
            message = NSLocalizedString(@"We need permission to post to Basecamp", nil);
            [self removeBasecampAccounts];
        } else if ([error.domain isEqualToString:NSURLErrorDomain]) {
            message = NSLocalizedString(@"Network error", nil);
        } else {
            message = NSLocalizedString(@"Couln't complete operation. Please, try again later", nil);
        }
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error", nil) message:message delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
    }
}

- (void)showReadyToSendAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information", nil) message:NSLocalizedString(@"Ok, you are ready to post your report to Basecamp now!", nil) delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:NSLocalizedString(@"Post", nil), nil];
    [alertView show];
}

#pragma mark - DRPReporterViewControllerDelegate methods
- (void)reporterViewController:(DRPReporterViewController *)reporterViewController
         didFinishDrawingImage:(UIImage *)image
                  withNoteText:(NSString *)noteText {
    self.sourceVC = reporterViewController;
    self.reportImage = image;
    self.reportText = noteText;
    
    UIActionSheet *actionSheet = [[UIActionSheet alloc] init];
    actionSheet.delegate = self;
    
    if ([self isAllConfigurationLoaded]) {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"Post to Basecamp", nil)];
    }
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Configure Basecamp", nil)];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", nil)];
    actionSheet.cancelButtonIndex = actionSheet.numberOfButtons - 1;
    [actionSheet showInView:reporterViewController.view];
}

- (void)presentConfigurationViewController {
    __weak DRPBasecamp *weakSelf = self;
    [self obtainAccessTokenWithSourceViewController:self.sourceVC success:^(NSString *accessToken) {
        DRPBasecampAccountsViewController *accountsVC = [[DRPBasecampAccountsViewController alloc] init];
        accountsVC.accessToken = accessToken;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:accountsVC];
        [weakSelf.sourceVC presentViewController:navigationController animated:YES completion:nil];
    } failure:^(NSError *error) {
        [weakSelf showAlertForError:error];
    }];
}

- (void)showLoadingView {
    if (self.loadingView) {
        [self.loadingView removeFromSuperview];
    }
    
    UIView *topView;
    if (self.sourceVC.parentViewController) {
        topView = self.sourceVC.parentViewController.view;
    } else {
        topView = self.sourceVC.view;
    }
    
    UIView *loadingView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.sourceVC.view.frame.size.width, self.sourceVC.view.frame.size.height)];
    loadingView.userInteractionEnabled = YES;
    loadingView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.85];
    loadingView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    UIActivityIndicatorView *indicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    indicatorView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin| UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin| UIViewAutoresizingFlexibleBottomMargin;
    indicatorView.center = loadingView.center;
    [loadingView addSubview:indicatorView];
    [indicatorView startAnimating];
    
    UIButton *cancelButton = [UIButton buttonWithType:UIButtonTypeCustom];
    cancelButton.autoresizingMask = indicatorView.autoresizingMask;
    cancelButton.backgroundColor = [UIColor clearColor];
    cancelButton.frame = CGRectMake((loadingView.frame.size.width - DRPBasecampLoadingCancelButtonWidth) / 2., indicatorView.frame.origin.y + indicatorView.frame.size.height + 50, DRPBasecampLoadingCancelButtonWidth, DRPBasecampLoadingCancelButtonHeight);
    [cancelButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [cancelButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelLoadingButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    cancelButton.layer.cornerRadius = 4;
    cancelButton.layer.borderColor = [UIColor whiteColor].CGColor;
    cancelButton.layer.borderWidth = 1;
    [loadingView addSubview:cancelButton];
    
    UILabel *titleLabel = [[UILabel alloc] init];
    titleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin| UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleTopMargin| UIViewAutoresizingFlexibleBottomMargin;
    titleLabel.text = NSLocalizedString(@"Posting Report", nil);
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.textColor = [UIColor whiteColor];
    titleLabel.font = [UIFont systemFontOfSize:22];
    [titleLabel sizeToFit];
    titleLabel.frame = CGRectMake((loadingView.frame.size.width - titleLabel.frame.size.width) / 2.0, indicatorView.frame.origin.y - 50 - titleLabel.frame.size.height, titleLabel.frame.size.width, titleLabel.frame.size.height);
    [loadingView addSubview:titleLabel];
    
    loadingView.alpha = 0;
    [topView addSubview:loadingView];
    self.loadingView = loadingView;
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseIn  animations:^{
        loadingView.alpha = 1;
    } completion:nil];
}

- (void)cancelLoadingButtonClicked:(id)sender {
    [self.client cancelCurrentOperations];
    [self hideLoadingView];
}

- (void)hideLoadingView {
    [UIView animateWithDuration:0.3 delay:0 options:UIViewAnimationOptionAllowAnimatedContent|UIViewAnimationOptionAllowUserInteraction|UIViewAnimationOptionBeginFromCurrentState|UIViewAnimationOptionCurveEaseIn  animations:^{
        self.loadingView.alpha = 0;
    } completion:^(BOOL finished) {
        [self.loadingView removeFromSuperview];
    }];
}

- (void)showSuccessPostAlert {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Information", nil) message:NSLocalizedString(@"Your report was posted to Basecamp", nil) delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alertView show];
}

- (void)postReport {
    __weak DRPBasecamp *weakSelf = self;
    
    NSDate *now = [NSDate date];
    NSString *content = [self.reportText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (self.todoContentCallback) {
        content = self.todoContentCallback(content);
    } else if (!content || [content isEqualToString:@""]) {
        content = [[self dateFormatter] stringFromDate:now];
    }
    
    [self obtainAccessTokenWithSourceViewController:self.sourceVC success:^(NSString *accessToken) {
        [weakSelf showLoadingView];
        [weakSelf.client createTodoInTodoList:weakSelf.todoList project:weakSelf.project content:content accessToken:accessToken complete:^(NSString *todoURLString, NSError *error) {
            if (error) {
                [weakSelf hideLoadingView];
                [weakSelf showAlertForError:error];
            } else {
                [weakSelf.client createAttachmentInUserAccount:weakSelf.userAccount image:weakSelf.reportImage accessToken:accessToken complete:^(NSString *attachmentToken, NSError *error) {
                    if (error) {
                        [weakSelf hideLoadingView];
                        [weakSelf showAlertForError:error];
                    } else {
                        [weakSelf.client createCommentForTodoWithURL:todoURLString content:DRPBasecampAttachmentNamePrefix attachmentToken:attachmentToken attachmentName:[weakSelf attachmentNameForDate:now] accessToken:accessToken complete:^(NSNumber *commentId, NSError *error) {
                            if (error) {
                                [weakSelf showAlertForError:error];
                            } else {
                                [weakSelf showSuccessPostAlert];
                            }
                            
                            [weakSelf hideLoadingView];
                        }];
                    }
                }];
            }
        }];
    } failure:^(NSError *error) {
        [weakSelf hideLoadingView];
        [weakSelf showAlertForError:error];
    }];
}

- (NSString *)attachmentNameForDate:(NSDate *)date {
    return [NSString stringWithFormat:@"%@ %@.png", DRPBasecampAttachmentNamePrefix, [[self dateFormatter] stringFromDate:date]];
}

- (NSDateFormatter *)dateFormatter {
    static NSDateFormatter *dateFormatter = nil;
    if (!dateFormatter) {
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    
    return dateFormatter;
}

#pragma mark - UIActionSheetDelegate methods
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != (actionSheet.numberOfButtons - 1)) {
        if ([self isAllConfigurationLoaded]) {
            switch (buttonIndex) {
                case 0:
                    [self postReport];
                    break;
                    
                case 1:
                    [self presentConfigurationViewController];
                    break;
            }
        } else {
            if (buttonIndex == 0) {
                [self presentConfigurationViewController];
            }
        }
    }
}

#pragma mark - UIAlertViewDelegate methods
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        [self postReport];
    }
}

@end
