//
//  DRPBasecampUserAccount.m
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 28.10.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import "DRPBasecampUserAccount.h"

static NSString * const DRPBasecampUserAccountIdKey = @"DRPBasecampUserAccountUserIdKey";
static NSString * const DRPBasecampUserAccountNameKey = @"DRPBasecampUserAccountNameKey";
static NSString * const DRPBasecampUserAccountHrefKey = @"DRPBasecampUserAccountHrefKey";

@implementation DRPBasecampUserAccount

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        _accountId = [decoder decodeObjectForKey:DRPBasecampUserAccountIdKey];
        _name = [decoder decodeObjectForKey:DRPBasecampUserAccountNameKey];
        _href = [decoder decodeObjectForKey:DRPBasecampUserAccountHrefKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_accountId forKey:DRPBasecampUserAccountIdKey];
    [encoder encodeObject:_name forKey:DRPBasecampUserAccountNameKey];
    [encoder encodeObject:_href forKey:DRPBasecampUserAccountHrefKey];
}

@end
