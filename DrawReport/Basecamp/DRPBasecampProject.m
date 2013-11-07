//
// DRPBasecampProject.m
//
// Copyright (c) 2013 Oleg Poyaganov (opedge@gmail.com)
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

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
