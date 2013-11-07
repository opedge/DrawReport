//
// DRPBasecampOperation.m
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

#import "DRPBasecampOperation.h"
#import "NSError+DRPBasecamp.h"

typedef NS_ENUM(NSUInteger, DRPBasecampOperationState) {
    DRPBasecampOperationStateInit,
    DRPBasecampOperationExecuting,
    DRPBasecampOperationFinished
};

@interface DRPBasecampOperation() {
    NSMutableData *_receivedData;
    BOOL _cancelled;
}

@property (nonatomic, assign) DRPBasecampOperationState state;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, assign) NSInteger responseStatusCode;
@property (nonatomic, strong) NSURLRequest *request;

@end

@implementation DRPBasecampOperation

static inline NSString * DRPKeyPathFromOperationState(DRPBasecampOperationState state) {
    switch (state) {
        case DRPBasecampOperationStateInit:
            return @"isReady";
        case DRPBasecampOperationExecuting:
            return @"isExecuting";
        case DRPBasecampOperationFinished:
            return @"isFinished";
        default:
            return @"state";
    }
}

- (id)initWithRequest:(NSURLRequest *)request {
    self = [self init];
    if (self) {
        self.state = DRPBasecampOperationStateInit;
        self.request = request;
    }
    return self;
}

- (void)start {    
    if ([self isReady]) {
        [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:@[ NSRunLoopCommonModes ]];
    }
}

- (void)operationDidStart {
    if (! [self isCancelled]) {
        self.state = DRPBasecampOperationExecuting;
        [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
        _receivedData = [NSMutableData dataWithCapacity:0];
        
        self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [self.connection scheduleInRunLoop:runLoop forMode:NSRunLoopCommonModes];
        [self.connection start];
    }
}

- (BOOL)isConcurrent {
    return YES;
}

- (BOOL)isExecuting {
    return self.state == DRPBasecampOperationExecuting;
}

- (BOOL)isFinished {
    return self.state == DRPBasecampOperationFinished;
}

- (BOOL)isCancelled {
    return _cancelled;
}

+ (void)networkRequestThreadEntryPoint:(id __unused)object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"DRPBasecamp"];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}

- (void)setState:(DRPBasecampOperationState)state {
    NSString *oldStateKey = DRPKeyPathFromOperationState(self.state);
    NSString *newStateKey = DRPKeyPathFromOperationState(state);
    
    [self willChangeValueForKey:newStateKey];
    [self willChangeValueForKey:oldStateKey];
    _state = state;
    [self didChangeValueForKey:oldStateKey];
    [self didChangeValueForKey:newStateKey];
}

#pragma mark - NSURLConnectionDelegate
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    [_receivedData setLength:0];
    
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        self.responseStatusCode = ((NSHTTPURLResponse *)response).statusCode;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_receivedData appendData:data];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.state = DRPBasecampOperationFinished;
    
    if (self.completion) {
        self.completion(nil, error);
    }
    
    _connection = nil;
    _receivedData = nil;
    self.completion = nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
    self.state = DRPBasecampOperationFinished;
    if ((self.responseStatusCode / 100) == 2) {
        if (_receivedData.length > 0) {
            if (self.skipJSONParse) {
                if (self.completion) {
                    self.completion(_receivedData, nil);
                }
            } else {
                NSError *jsonParseError = nil;
                id obj = [NSJSONSerialization JSONObjectWithData:_receivedData options:0 error:&jsonParseError];
                if (self.completion) {
                    self.completion(obj, jsonParseError);
                }
            }
        } else {
            if (self.completion) {
                self.completion(nil, nil);
            }
        }
    } else {
        if (self.completion) {
            self.completion(nil, [NSError errorWithDomain:DRPBasecampOperationErrorDomain code:self.responseStatusCode userInfo:nil]);
        }
    }
    
    _connection = nil;
    _receivedData = nil;
    self.completion = nil;
}

- (void)cancel {
    if (![self isFinished] && ![self isCancelled]) {
        [self willChangeValueForKey:@"isCancelled"];
        _cancelled = YES;
        [super cancel];
        [self didChangeValueForKey:@"isCancelled"];
        
        [self performSelector:@selector(cancelConnection) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:@[ NSRunLoopCommonModes ]];
    }
}

- (void)cancelConnection {
    NSDictionary *userInfo = nil;
    if ([self.request URL]) {
        userInfo = [NSDictionary dictionaryWithObject:[self.request URL] forKey:NSURLErrorFailingURLErrorKey];
    }
    NSError *error = [NSError errorWithDomain:NSURLErrorDomain code:NSURLErrorCancelled userInfo:userInfo];
    
    if (self.connection) {
        [self.connection cancel];
        [self performSelector:@selector(connection:didFailWithError:) withObject:self.connection withObject:error];
    }
}

@end
