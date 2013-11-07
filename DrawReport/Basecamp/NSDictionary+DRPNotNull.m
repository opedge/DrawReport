//
//  NSDictionary+DRPNotNull.m
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 08.11.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import "NSDictionary+DRPNotNull.h"

@implementation NSDictionary (DRPNotNull)

- (id)drp_objectForKeyNotNull:(id)key {
    id object = [self objectForKey:key];
    if (object == [NSNull null])
        return nil;
    
    return object;
}

@end
