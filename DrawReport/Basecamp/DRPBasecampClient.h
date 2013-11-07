//
// DRPBasecampClient.h
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
