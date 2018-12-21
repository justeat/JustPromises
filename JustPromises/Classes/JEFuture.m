//
//  JEFuture.m
//  JustPromises
//
//  Created by Marek Rogosz on 26/11/2014.
//  Copyright (c) 2014 JUST EAT. All rights reserved.
//

#import "JEFuture.h"
#include <libkern/OSAtomic.h>

@interface JEFuture ()
{
    id _result;
    NSError *_error;
    BOOL _cancelled;
    JEContinuation _continuation;
    JEFutureState _state;
}

@property (strong, atomic) NSCondition *cv;

@end

@implementation JEFuture

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _cv = [NSCondition new];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<JEFuture: state: %@>", [self _stateString]];
}

#pragma mark - Factory Methods

+ (instancetype)futureWithResult:(id)result
{
    JEPromise *p = [JEPromise new];
    [p setResult:result];
    return [p future];
}

+ (instancetype)futureWithError:(NSError *)error
{
    JEPromise *p = [JEPromise new];
    [p setError:error];
    return [p future];
}

+ (instancetype)cancelledFuture
{
    JEPromise *p = [JEPromise new];
    [p setCancelled];
    return [p future];
}

+ (instancetype)futureWithResolutionOfFuture:(JEFuture *)src
{
    if ([src hasResult])
    {
        return [self futureWithResult:[src result]];
    }
    else if ([src hasError])
    {
        return [self futureWithError:[src error]];
    }
    else
    {
        return [self cancelledFuture];
    }
}

#pragma mark - Public Methods

- (BOOL)isResolved
{
    [self.cv lock];
    BOOL result = _state != JEFutureStateUnresolved;
    [self.cv unlock];
    
    return result;
}

- (JEFutureState)state
{
    [self.cv lock];
    JEFutureState state = _state;
    [self.cv unlock];
    
    return state;
}

- (BOOL)hasResult
{
    [self.cv lock];
    BOOL result = _result != nil;
    [self.cv unlock];
    
    return result;
}

- (BOOL)hasError
{
    [self.cv lock];
    BOOL result = _error != nil;
    [self.cv unlock];
    
    return result;
}

- (BOOL)isCancelled
{
    [self.cv lock];
    BOOL wasCancelled = _cancelled;
    [self.cv unlock];
    
    return wasCancelled;
}

- (void)wait
{
    [self.cv lock];
    
    while (_state == JEFutureStateUnresolved)
    {
        [self.cv wait];
    }
    
    [self.cv unlock];
}

- (BOOL)waitUntilDate:(NSDate *)timeout
{
    [self.cv lock];
    
    BOOL timeoutExpired = NO;
    while (_state == JEFutureStateUnresolved && !timeoutExpired)
    {
        timeoutExpired = ![self.cv waitUntilDate:timeout];
    }
    
    [self.cv unlock];
    return !timeoutExpired;
}

- (id)result
{
    [self wait];
    return _result;
}

- (NSError *)error
{
    [self wait];
    return _error;
}

- (void)setContinuation:(JEContinuation)continuation
{
    [self.cv lock];
    
    if (_continuation != nil)
    {        
        [self.cv unlock];
        NSException *e = [NSException exceptionWithName:@"Cannot set continuation."
                                                 reason:@"Continuation already attached."
                                               userInfo:nil];
        @throw e;
    }
    
    _continuation = continuation;
    BOOL resolved = _state != JEFutureStateUnresolved;
    
    [self.cv unlock];
    
    if (resolved)
    {
        _continuation(self);
    }
}

- (void)onQueue:(dispatch_queue_t)queue setContinuation:(JEContinuation)continuation
{
    [self setContinuation:^(JEFuture *fut)
    {
        dispatch_async(queue, ^{
            continuation(fut);
        });
    }];
}

- (JEFuture *)continueWithTask:(JETask)task
{
    JEPromise *p = [JEPromise new];
    
    [self setContinuation:^(JEFuture *fut)
     {
         JEFuture *f2 = task(fut);
         [f2 setContinuation:^(JEFuture *fut2) {
             [p setResolutionOfFuture:fut2];
         }];
     }];
    
    return [p future];
}

- (JEFuture *)continueOnQueue:(dispatch_queue_t)queue withTask:(JETask)task
{
    JEPromise *p = [JEPromise new];
    
    [self onQueue:queue setContinuation:^(JEFuture *fut)
    {
        JEFuture *f2 = task(fut);
        [f2 setContinuation:^(JEFuture *fut2) {
            [p setResolutionOfFuture:fut2];
        }];
    }];
    
    return [p future];
}

- (JEFuture *)continueWithSuccessTask:(JESuccessTask)successTask
{
    JEPromise *p = [JEPromise new];
    
    [self setContinuation:^(JEFuture *fut)
     {
         if ([fut hasResult])
         {
             JEFuture *f2 = successTask([fut result]);
             [f2 setContinuation:^(JEFuture *fut2) {
                 [p setResolutionOfFuture:fut2];
             }];
         }
         else
         {
             [p setResolutionOfFuture:fut];
         }
     }];
    
    return [p future];
}

- (JEFuture *)continueOnQueue:(dispatch_queue_t)queue withSuccessTask:(JESuccessTask)successTask
{
    JEPromise *p = [JEPromise new];
    
    [self setContinuation:^(JEFuture *fut)
     {
         if ([fut hasResult])
         {
             dispatch_async(queue, ^
             {
                 JEFuture *f2 = successTask([fut result]);
                 [f2 setContinuation:^(JEFuture *fut2) {
                     [p setResolutionOfFuture:fut2];
                 }];
             });
         }
         else
         {
             [p setResolutionOfFuture:fut];
         }
     }];
    
    return [p future];
}

+ (instancetype)whenAll:(NSArray *)futures
{
    JEPromise *p = [JEPromise new];
    
    NSArray *results = [NSArray arrayWithArray:futures];
    __block volatile int counter = (int)futures.count;
    
    for (NSInteger idx = 0; idx < futures.count; ++idx)
    {
        JEFuture *f = [futures objectAtIndex:idx];
        [f continueWithTask:^JEFuture *(JEFuture *fut) {
            
            if (OSAtomicDecrement32(&counter) == 0)
            {
                [p setResult:results];
            }
            return [JEFuture futureWithResult:[NSNull null]];
        }];
    }
    
    return [p future];
}

#pragma mark - Private Methods

- (void)_setResult:(id)value
{
    [self.cv lock];
    NSAssert(_state == JEFutureStateUnresolved, @"Cannot set result. Promise already satisfied");
    NSAssert(value != nil, @"Result cannot be nil");
    
    _result = value;
    _state = JEFutureStateResolvedWithResult;
    JEContinuation continuation = _continuation;
    _continuation = nil;
    
    [self.cv signal];
    [self.cv unlock];
    
    if (continuation)
    {
        continuation(self);
    }
}

- (void)_setError:(NSError *)error
{
    [self.cv lock];
    NSAssert(_state == JEFutureStateUnresolved, @"Cannot set error. Promise already satisfied");
    
    _error = error;
    _state = JEFutureStateResolvedWithError;
    JEContinuation continuation = _continuation;
    _continuation = nil;
    
    [self.cv signal];
    [self.cv unlock];
    
    if (continuation)
    {
        continuation(self);
    }
}

- (void)_cancel
{
    [self.cv lock];
    NSAssert(_state == JEFutureStateUnresolved, @"Cannot set cancelled. Promise already satisfied");
    
    _cancelled = YES;
    _state = JEFutureStateResolvedWithCancellation;
    JEContinuation continuation = _continuation;
    _continuation = nil;
    
    [self.cv signal];
    [self.cv unlock];
    
    if (continuation)
    {
        continuation(self);
    }
}

- (NSString *)_stateString
{
    NSString *result = nil;
    
    switch([self state]) {
        case JEFutureStateResolvedWithResult:
            result = @"Resolved with result";
            break;
        case JEFutureStateResolvedWithError:
            result = @"Resolved with error";
            break;
        case JEFutureStateResolvedWithCancellation:
            result = @"Resolved with cancellation";
            break;
        case JEFutureStateUnresolved:
        default:
            result = @"Unresolved";
            break;
    }
    
    return result;
}

@end


@interface JEPromise ()

@property (strong, atomic) JEFuture *future;

@end

@implementation JEPromise

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.future = [JEFuture new];
    }
    return self;
}

- (void)dealloc
{
    if (![self.future isResolved])
    {
        NSError *error = [NSError errorWithDomain:@"JEPromise was not satisfied" code:0 userInfo:nil];
        [self setError:error];
    }
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<JEPromise: future %@>", [self future]];
}

#pragma mark - Public Methods

- (void)setResult:(id)result
{
    [self.future _setResult:result];
}

- (void)setError:(NSError *)error
{
    [self.future _setError:error];
}

- (void)setCancelled
{
    [self.future _cancel];
}

- (void)setResolutionOfFuture:(JEFuture *)future
{
    if ([future hasError])
    {
        [self setError:[future error]];
    }
    else if ([future isCancelled])
    {
        [self setCancelled];
    }
    else
    {
        [self setResult:[future result]];
    }
}

@end

