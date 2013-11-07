//
//  DRPBasecampTodoList.m
//  BasecampIntegration
//
//  Created by Oleg Poyaganov on 28.10.13.
//  Copyright (c) 2013 Oleg Poyaganov. All rights reserved.
//

#import "DRPBasecampTodoList.h"

static NSString * const DRPBasecampTodoListIdKey = @"DRPBasecampTodoListIdKey";
static NSString * const DRPBasecampTodoListNameKey = @"DRPBasecampTodoListNameKey";
static NSString * const DRPBasecampTodoListDescriptionKey = @"DRPBasecampTodoListDescriptionKey";

@implementation DRPBasecampTodoList

- (id)initWithCoder:(NSCoder *)decoder {
    self = [super init];
    if (self) {
        _todoListId = [decoder decodeObjectForKey:DRPBasecampTodoListIdKey];
        _name = [decoder decodeObjectForKey:DRPBasecampTodoListNameKey];
        _todoListDescription = [decoder decodeObjectForKey:DRPBasecampTodoListDescriptionKey];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_todoListId forKey:DRPBasecampTodoListIdKey];
    [encoder encodeObject:_name forKey:DRPBasecampTodoListNameKey];
    [encoder encodeObject:_todoListDescription forKey:DRPBasecampTodoListDescriptionKey];
}

@end
