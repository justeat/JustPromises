//
//  JEProgress.m
//  JustPromises
//
//  Created by Marek Rogosz on 05/12/2014.
//  Copyright (c) 2014 JUST EAT. All rights reserved.
//

#import "JEProgress.h"


@interface JEProgress ()
{
    BOOL _cancelled;
    NSUInteger _completed;
    NSUInteger _total;
    NSUInteger _state;
    NSString *_progressDescription;
    
    JECancellationHandler _cancellationHandler;
    JEProgressHandler _progressHandler;
    JEProgressHandler _stateHandler;
    JEProgressHandler _progressDescriptionHandler;
}

@end


@implementation JEProgress

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _total = 100;
    }
    return self;
}

#pragma mark - JECancellationTokenProtocol

- (BOOL)isCancelled
{
    @synchronized (self)
    {
        return _cancelled;
    }
}

- (void)setCancellationHandler:(JECancellationHandler)handler
{
    @synchronized (self)
    {
        // we dont need to set handler if task was already cancelled
        // because we'll call it straight away anyway
        if (!_cancelled)
        {
            _cancellationHandler = handler;
            handler = nil;
        }
    }
    
    if (handler)
    {
        handler(self);
    }
}

- (void)updateCompletedUnitCount:(NSUInteger)completed total:(NSUInteger)total
{
    JEProgressHandler handler = nil;
    @synchronized (self)
    {
        handler = _progressHandler;
        _completed = completed;
        _total = total;
    }
    
    if (handler)
    {
        handler(self);
    }
}

- (void)updateState:(NSUInteger)state
{
    JEProgressHandler handler = nil;
    @synchronized (self)
    {
        handler = _stateHandler;
        _state = state;
    }
    
    if (handler)
    {
        handler(self);
    }
}

- (void)updateProgressDescription:(NSString *)progressDescription
{
    JEProgressHandler handler = nil;
    @synchronized (self)
    {
        handler = _progressDescriptionHandler;
        _progressDescription = progressDescription;
    }
    
    if (handler)
    {
        handler(self);
    }
}

#pragma mark - Public Methods

- (void)cancel
{
    JECancellationHandler handler = nil;
    @synchronized (self)
    {
        _cancelled = YES;
        handler = _cancellationHandler;
        
        // we dont need cancellation handler any more
        _cancellationHandler = nil;
    }
    
    if (handler)
    {
        handler(self);
    }
}
- (void)onQueue:(dispatch_queue_t)queue setCancellationHandler:(JECancellationHandler)handler
{
    [self setCancellationHandler:^(id<JECancellableProgressProtocol> token)
     {
         dispatch_async(queue,
                        ^{
                            handler(token);
                        });
     }];
}

#pragma mark Progress

- (void)getCompletedUnitCount:(NSUInteger *)completed total:(NSUInteger *)total
{
    @synchronized (self)
    {
        *completed = _completed;
        *total = _total;
    }
}

- (void)setProgressHandler:(JEProgressHandler)handler
{
    @synchronized (self)
    {
        _progressHandler = handler;
    }
}
- (void)onQueue:(dispatch_queue_t)queue setProgressHandler:(JEProgressHandler)handler
{
    [self setProgressHandler:^(JEProgress *progress)
     {
         dispatch_async(queue,
                        ^{
                            handler(progress);
                        });
     }];
}

#pragma mark State

- (NSUInteger)state
{
    @synchronized (self)
    {
        return _state;
    }
}

- (void)setStateHandler:(JEProgressHandler)handler
{
    @synchronized (self)
    {
        _stateHandler = handler;
    }
}
- (void)onQueue:(dispatch_queue_t)queue setStateHandler:(JEProgressHandler)handler
{
    [self setStateHandler:^(JEProgress *progress)
     {
         dispatch_async(queue,
                        ^{
                            handler(progress);
                        });
     }];
}

#pragma mark Description

- (NSString *)progressDescription
{
    @synchronized (self)
    {
        return _progressDescription;
    }
}

- (void)setProgressDescriptionHandler:(JEProgressHandler)handler
{
    @synchronized (self)
    {
        _progressDescriptionHandler = handler;
    }
}

- (void)onQueue:(dispatch_queue_t)queue setProgressDescriptionHandler:(JEProgressHandler)handler
{
    [self setProgressDescriptionHandler:^(JEProgress *progress)
     {
         dispatch_async(queue,
                        ^{
                            handler(progress);
                        });
     }];
}

@end

