//
//  DRPBasecampClient.h
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 23.10.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DRPBasecampObtainTokenSuccess)(NSString *accessToken);
typedef void (^DRPBasecampObtainTokenFailure)(NSError *error);

@class DRPBasecampUserAccount;
@class DRPBasecampProject;
@class DRPBasecampTodoList;
@class NXOAuth2AccessToken;

@interface DRPBasecampClient : NSObject

+ (instancetype)sharedInstance;

- (void)getBCXAccountsWithAccessToken:(NSString *)accessToken
                             complete:(void(^)(NSArray *accounts, NSError *error))completeBlock;

- (void)getProjectsForUserAccount:(DRPBasecampUserAccount *)userAccount
                      accessToken:(NSString *)accessToken
                         complete:(void(^)(NSArray *projects, NSError *error))completeBlock;

- (void)getTodoListsForProject:(DRPBasecampProject *)project
                   accessToken:(NSString *)accessToken
                      complete:(void(^)(NSArray *todoLists, NSError *error))completeBlock;

- (void)createTodoListWithName:(NSString *)name
                   description:(NSString *)description
                       project:(DRPBasecampProject *)project
                   accessToken:(NSString *)accessToken
                      complete:(void(^)(DRPBasecampTodoList *todoList, NSError *error))completeBlock;

- (void)createAttachmentInUserAccount:(DRPBasecampUserAccount *)userAccount
                                image:(UIImage *)image
                          accessToken:(NSString *)accessToken
                             complete:(void(^)(NSString *attachmentToken, NSError *error))completeBlock;

- (void)createTodoInTodoList:(DRPBasecampTodoList *)todoList
                     project:(DRPBasecampProject *)project
                     content:(NSString *)content
                 accessToken:(NSString *)accessToken
                    complete:(void(^)(NSString *todoURLString, NSError *error))completeBlock;

- (void)createCommentForTodoWithURL:(NSString *)todoURLString
                            content:(NSString *)content
                    attachmentToken:(NSString *)attachmentToken
                     attachmentName:(NSString *)attachmentName
                        accessToken:(NSString *)accessToken
                           complete:(void(^)(NSNumber *commentId, NSError *error))completeBlock;

- (void)refreshAccessToken:(NXOAuth2AccessToken *)accessToken
                  tokenURL:(NSURL *)tokenURL
                  clientId:(NSString *)clientId
              clientSecret:(NSString *)clientSecret
                  complete:(void(^)(NXOAuth2AccessToken *accessToken, NSError *error))completeBlock;

- (void)cancelCurrentOperations;

@end
