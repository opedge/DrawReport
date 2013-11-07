//
// DRPBasecampUserAccount.m
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
