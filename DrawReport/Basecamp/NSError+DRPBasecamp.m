//
//  NSError+DRPBasecamp.m
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 01.11.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import "NSError+DRPBasecamp.h"

NSString * DRPBasecampOperationErrorDomain = @"DRPBasecampOperationErrorDomain";

@implementation NSError (DRPBasecamp)

- (BOOL)drp_isBasecampError {
    return [self.domain isEqualToString:DRPBasecampOperationErrorDomain];
}

- (BOOL)drp_isURLCancelled {
    return ([self.domain isEqualToString:NSURLErrorDomain] && (self.code == NSURLErrorCancelled));
}

@end
