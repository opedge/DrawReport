//
//  DRPBasecampClient.m
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 23.10.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import "DRPBasecampClient.h"
#import "DRPBasecampOperation.h"
#import "DRPBasecampUserAccount.h"
#import "DRPBasecampProject.h"
#import "DRPBasecampTodoList.h"
#import <NXOAuth2Client/NXOAuth2.h>
#import "NSError+DRPBasecamp.h"

static NSString * const DRPBasecampClientGetAuthorizationURLString = @"https://launchpad.37signals.com/authorization.json";

static NSUInteger const DRPBasecampClientQueueMaxConcurrentOperations = 4;

static NSString * const DRPBasecampClientProjectsPath = @"projects.json";
static NSString * const DRPBasecampClientTodoListsPath = @"todolists.json";
static NSString * const DRPBasecampClientAttachmentsPath = @"attachments.json";
static NSString * const DRPBasecampClientTodosPathFormat = @"todolists/%@/todos.json";
static NSString * const DRPBasecampClientCommentsPath = @"comments.json";

@interface DRPBasecampClient() {
    NSOperationQueue *_operationQueue;
}

@end

@implementation DRPBasecampClient

+ (instancetype)sharedInstance {
    static dispatch_once_t onceQueue;
    static DRPBasecampClient *client = nil;
    dispatch_once(&onceQueue, ^{
        client = [[self alloc] init];
    });
    return client;
}

- (id)init {
    self = [super init];
    if (self) {
        _operationQueue = [[NSOperationQueue alloc] init];
        [_operationQueue setMaxConcurrentOperationCount:DRPBasecampClientQueueMaxConcurrentOperations];
    }
    return self;
}

- (NSMutableURLRequest *)requestWithMethod:(NSString *)method accessToken:(NSString *)accessToken url:(NSString *)urlString {
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:urlString]];
    [request setHTTPMethod:method];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    [request setValue:[NSString stringWithFormat:@"Bearer %@", accessToken] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    return request;
}

- (BOOL)handleError:(NSError *)error result:(id)result complete:(void(^)(id result, NSError *error))completeBlock {
    BOOL errorhandled = NO;
    if (error) {
        errorhandled = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            completeBlock(nil, error);
        });
    } else if (!result) {
        errorhandled = YES;
        dispatch_async(dispatch_get_main_queue(), ^{
            completeBlock(nil, nil);
        });
    }
    
    return errorhandled;
}

- (void)getBCXAccountsWithAccessToken:(NSString *)accessToken
                             complete:(void(^)(NSArray *accounts, NSError *error))completeBlock {
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" accessToken:accessToken url:DRPBasecampClientGetAuthorizationURLString];
    DRPBasecampOperation *operation = [[DRPBasecampOperation alloc] initWithRequest:request];
    [operation setCompletion:^(id result, NSError *error) {
        if (![self handleError:error result:result complete:completeBlock]) {
            NSArray *accountDicts = result[@"accounts"];
            NSMutableArray *resultArray = [NSMutableArray new];
            for (NSDictionary *accDict in accountDicts) {
                NSString *product = accDict[@"product"];
                if ([product isEqualToString:@"bcx"]) {
                    DRPBasecampUserAccount *account = [[DRPBasecampUserAccount alloc] init];
                    account.accountId = accDict[@"id"];
                    account.name = accDict[@"name"];
                    account.href = accDict[@"href"];
                    [resultArray addObject:account];
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock(resultArray, nil);
            });
        }
    }];
    
    [_operationQueue addOperation:operation];
}

- (void)getProjectsForUserAccount:(DRPBasecampUserAccount *)userAccount
                      accessToken:(NSString *)accessToken
                         complete:(void(^)(NSArray *projects, NSError *error))completeBlock {
    NSString *urlString = [userAccount.href stringByAppendingPathComponent:DRPBasecampClientProjectsPath];
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" accessToken:accessToken url:urlString];
    DRPBasecampOperation *operation = [[DRPBasecampOperation alloc] initWithRequest:request];
    [operation setCompletion:^(id result, NSError *error) {
        if (![self handleError:error result:result complete:completeBlock]) {
            NSArray *projectDicts = result;
            NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:projectDicts.count];
            for (NSDictionary *projDict in projectDicts) {
                DRPBasecampProject *project = [[DRPBasecampProject alloc] init];
                project.projectId = projDict[@"id"];
                project.name = projDict[@"name"];
                project.projectDescription = projDict[@"description"];
                project.url = projDict[@"url"];
                [resultArray addObject:project];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock(resultArray, nil);
            });
        }
    }];
    
    [_operationQueue addOperation:operation];
}

- (void)getTodoListsForProject:(DRPBasecampProject *)project
                   accessToken:(NSString *)accessToken
                      complete:(void(^)(NSArray *todoLists, NSError *error))completeBlock {
    NSString *urlString = [[project.url stringByDeletingPathExtension] stringByAppendingPathComponent:DRPBasecampClientTodoListsPath];
    NSMutableURLRequest *request = [self requestWithMethod:@"GET" accessToken:accessToken url:urlString];
    DRPBasecampOperation *operation = [[DRPBasecampOperation alloc] initWithRequest:request];
    [operation setCompletion:^(id result, NSError *error) {
        if (![self handleError:error result:result complete:completeBlock]) {
            NSArray *todoListsDicts = result;
            NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:todoListsDicts.count];
            for (NSDictionary *tlDict in todoListsDicts) {
                DRPBasecampTodoList *todoList = [[DRPBasecampTodoList alloc] init];
                todoList.todoListId = tlDict[@"id"];
                todoList.name = tlDict[@"name"];
                todoList.todoListDescription = tlDict[@"description"];
                [resultArray addObject:todoList];
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock(resultArray, nil);
            });
        }
    }];
    
    [_operationQueue addOperation:operation];
}

- (void)createTodoListWithName:(NSString *)name
                   description:(NSString *)description
                       project:(DRPBasecampProject *)project
                   accessToken:(NSString *)accessToken
                      complete:(void(^)(DRPBasecampTodoList *todoList, NSError *error))completeBlock {
    NSString *urlString = [[project.url stringByDeletingPathExtension] stringByAppendingPathComponent:DRPBasecampClientTodoListsPath];
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" accessToken:accessToken url:urlString];
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:@{ @"name": name, @"description": description ? description : @"" } options:0 error:NULL];
    [request setHTTPBody:bodyData];
    DRPBasecampOperation *operation = [[DRPBasecampOperation alloc] initWithRequest:request];
    [operation setCompletion:^(id result, NSError *error) {
        if (![self handleError:error result:result complete:completeBlock]) {
            NSDictionary *tlDict = result;
            DRPBasecampTodoList *todoList = [[DRPBasecampTodoList alloc] init];
            todoList.todoListId = tlDict[@"id"];
            todoList.name = tlDict[@"name"];
            todoList.todoListDescription = tlDict[@"description"];
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock(todoList, nil);
            });
        }
    }];
    
    [_operationQueue addOperation:operation];
}

- (void)createAttachmentInUserAccount:(DRPBasecampUserAccount *)userAccount
                                image:(UIImage *)image
                          accessToken:(NSString *)accessToken
                             complete:(void(^)(NSString *attachmentToken, NSError *error))completeBlock {
    NSString *urlString = [userAccount.href stringByAppendingPathComponent:DRPBasecampClientAttachmentsPath];
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" accessToken:accessToken url:urlString];
    NSData *bodyData = UIImagePNGRepresentation(image);
    [request setHTTPBody:bodyData];
    [request setValue:@"image/png" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%d", bodyData.length] forHTTPHeaderField:@"Content-Length"];
    DRPBasecampOperation *operation = [[DRPBasecampOperation alloc] initWithRequest:request];
    [operation setCompletion:^(id result, NSError *error) {
        if (![self handleError:error result:result complete:completeBlock]) {
            NSString *token = result[@"token"];
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock(token, nil);
            });
        }
    }];
    
    [_operationQueue addOperation:operation];
}

- (void)createTodoInTodoList:(DRPBasecampTodoList *)todoList
                     project:(DRPBasecampProject *)project
                     content:(NSString *)content
                 accessToken:(NSString *)accessToken
                    complete:(void(^)(NSString *todoURLString, NSError *error))completeBlock {
    NSString *urlString = [[project.url stringByDeletingPathExtension] stringByAppendingPathComponent:[NSString stringWithFormat:DRPBasecampClientTodosPathFormat, todoList.todoListId]];
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" accessToken:accessToken url:urlString];
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:@{ @"content": content } options:0 error:NULL];
    [request setHTTPBody:bodyData];
    DRPBasecampOperation *operation = [[DRPBasecampOperation alloc] initWithRequest:request];
    [operation setCompletion:^(id result, NSError *error) {
        if (![self handleError:error result:result complete:completeBlock]) {
            NSString *url = result[@"url"];
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock(url, nil);
            });
        }
    }];
    
    [_operationQueue addOperation:operation];
}

- (void)createCommentForTodoWithURL:(NSString *)todoURLString
                            content:(NSString *)content
                    attachmentToken:(NSString *)attachmentToken
                     attachmentName:(NSString *)attachmentName
                        accessToken:(NSString *)accessToken complete:(void(^)(NSNumber *commentId, NSError *error))completeBlock {
    NSString *urlString = [[todoURLString stringByDeletingPathExtension] stringByAppendingPathComponent:DRPBasecampClientCommentsPath];
    NSMutableURLRequest *request = [self requestWithMethod:@"POST" accessToken:accessToken url:urlString];
    NSData *bodyData = [NSJSONSerialization dataWithJSONObject:@{ @"content": content,
                                                                  @"attachments": @[ @{ @"token": attachmentToken, @"name": attachmentName } ] }
                                                       options:0
                                                         error:NULL];
    [request setHTTPBody:bodyData];
    DRPBasecampOperation *operation = [[DRPBasecampOperation alloc] initWithRequest:request];
    [operation setCompletion:^(id result, NSError *error) {
        if (![self handleError:error result:result complete:completeBlock]) {
            NSNumber *commentId = result[@"id"];
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock(commentId, nil);
            });
        }
    }];
    
    [_operationQueue addOperation:operation];
}

- (void)refreshAccessToken:(NXOAuth2AccessToken *)accessToken
                  tokenURL:(NSURL *)tokenURL
                  clientId:(NSString *)clientId
              clientSecret:(NSString *)clientSecret
                  complete:(void(^)(NXOAuth2AccessToken *accessToken, NSError *error))completeBlock {
    NSString *queryString = [NSString stringWithFormat:@"type=refresh&client_id=%@&client_secret=%@&refresh_token=%@", clientId, clientSecret, accessToken.refreshToken];
    NSData *bodyData = [queryString dataUsingEncoding:NSUTF8StringEncoding];
    NSString *contentType = @"application/x-www-form-urlencoded";
    NSString *contentLength = [NSString stringWithFormat:@"%d", [bodyData length]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:tokenURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
    [request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:bodyData];
    DRPBasecampOperation *operation = [[DRPBasecampOperation alloc] initWithRequest:request];
    operation.skipJSONParse = YES;
    [operation setCompletion:^(id result, NSError *error) {
        if (![self handleError:error result:result complete:completeBlock]) {
            NSData *responseData = result;
            NSString *responseString = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
            NXOAuth2AccessToken *newToken = [NXOAuth2AccessToken tokenWithResponseBody:responseString tokenType:accessToken.tokenType];
            [newToken restoreWithOldToken:accessToken];
            dispatch_async(dispatch_get_main_queue(), ^{
                completeBlock(newToken, nil);
            });
        }
    }];
    
    [_operationQueue addOperation:operation];
}

- (void)cancelCurrentOperations {
    for (NSOperation *operation in _operationQueue.operations) {
        [operation cancel];
    }
}

@end
