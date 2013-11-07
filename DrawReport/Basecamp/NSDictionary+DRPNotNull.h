//
//  NSDictionary+DRPNotNull.h
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 08.11.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (DRPNotNull)

- (id)drp_objectForKeyNotNull:(id)key;

@end
