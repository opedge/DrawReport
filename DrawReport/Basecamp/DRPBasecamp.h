//
//  DRPBasecamp.h
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 28/10/13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <DrawReport/DRPReporterViewController.h>

@class DRPBasecampClient;
@class DRPBasecampUserAccount;
@class DRPBasecampProject;
@class DRPBasecampTodoList;

@interface DRPBasecamp : NSObject <DRPReporterViewControllerDelegate>

+ (instancetype)sharedInstance;

@property (nonatomic, copy) NSString * (^todoContentCallback)(NSString *content);

- (id)initWithClient:(DRPBasecampClient *)client;

- (void)configureWithClientId:(NSString *)clientId
                 clientSecret:(NSString *)clientSecret
                  redirectURL:(NSURL *)redirectURL;

- (void)logout;
- (void)removeBasecampAccounts;

- (void)setUserAccount:(DRPBasecampUserAccount *)userAccount project:(DRPBasecampProject *)project todoList:(DRPBasecampTodoList *)todoList;

- (void)showReadyToSendAlert;

- (void)presentConfigurationViewController;

@end
