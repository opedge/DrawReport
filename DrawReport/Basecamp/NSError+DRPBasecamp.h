//
//  NSError+DRPBasecamp.h
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 01.11.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * DRPBasecampOperationErrorDomain;

@interface NSError (DRPBasecamp)

- (BOOL)drp_isBasecampError;
- (BOOL)drp_isURLCancelled;

@end
