//
//  DRPBasecampProject.m
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 28.10.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import "DRPBasecampProject.h"

static NSString * const DRPBasecampProjectIdKey = @"DRPBasecampProjectIdKey";
static NSString * const DRPBasecampProjectNameKey = @"DRPBasecampProjectNameKey";
static NSString * const DRPBasecampProjectDescriptionKey = @"DRPBasecampProjectDescriptionKey";
static NSString * const DRPBasecampProjectURLKey = @"DRPBasecampProjectURLKey";

@implementation DRPBasecampProject

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        _projectId = [decoder decodeObjectForKey:DRPBasecampProjectIdKey];
        _name = [decoder decodeObjectForKey:DRPBasecampProjectNameKey];
        _projectDescription = [decoder decodeObjectForKey:DRPBasecampProjectDescriptionKey];
        _url = [decoder decodeObjectForKey:DRPBasecampProjectURLKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_projectId forKey:DRPBasecampProjectIdKey];
    [encoder encodeObject:_name forKey:DRPBasecampProjectNameKey];
    [encoder encodeObject:_projectDescription forKey:DRPBasecampProjectDescriptionKey];
    [encoder encodeObject:_url forKey:DRPBasecampProjectURLKey];
}

@end
