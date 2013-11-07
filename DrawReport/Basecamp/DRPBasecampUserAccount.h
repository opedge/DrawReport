//
//  DRPBasecampUserAccount.h
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 28.10.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DRPBasecampUserAccount : NSObject

@property (nonatomic, strong) NSNumber *accountId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *href;

@end
