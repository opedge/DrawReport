//
//  DRPBasecampOperation.h
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 24.10.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DRPBasecampOperationCompletion)(id result, NSError *error);

@interface DRPBasecampOperation : NSOperation <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

- (id)initWithRequest:(NSURLRequest *)request;

@property (nonatomic, copy) DRPBasecampOperationCompletion completion;

@property (nonatomic, assign) BOOL skipJSONParse;

@end
