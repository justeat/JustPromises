//
//  JEFuture+JEDotNotation.m
//  JustPromises
//
//  Created by Alberto De Bortoli on 08/07/2015.
//  Copyright © 2015 JUST EAT. All rights reserved.
//

#import "JEFuture+JEDotNotation.h"

@implementation JEFuture (JEDotNotation)

- (JEContinuationDotNotation)continues
{
    __weak typeof(self) weakSelf = self;
    
    return ^(JEContinuation continuation) {
        return [weakSelf setContinuation:continuation];
    };
}

- (JEContinuationDotNotation)continueOnMainQueue
{
    __weak typeof(self) weakSelf = self;
    
    return ^(JEContinuation continuation) {
        return [weakSelf onQueue:dispatch_get_main_queue() setContinuation:continuation];
    };
}

- (JEContinuationQueueDotNotation)continueOnQueue
{
    __weak typeof(self) weakSelf = self;
    
    return ^(dispatch_queue_t q, JEContinuation continuation) {
        return [weakSelf onQueue:q setContinuation:continuation];
    };
}

- (JETaskDotNotation)continueWithTask
{
    __weak typeof(self) weakSelf = self;
    
    return ^JEFuture *(JETask task) {
        return [weakSelf continueWithTask:task];
    };
}


- (JETaskDotNotation)continueWithTaskOnMainQueue
{
    __weak typeof(self) weakSelf = self;
    
    return ^JEFuture *(JETask task) {
        return [weakSelf continueOnQueue:dispatch_get_main_queue() withTask:task];
    };
}

- (JETaskQueueDotNotation)continueWithTaskOnQueue
{
    __weak typeof(self) weakSelf = self;
    
    return ^JEFuture *(dispatch_queue_t q, JETask task) {
        return [weakSelf continueOnQueue:q withTask:task];
    };
}

- (JESuccessTaskDotNotation)continueWithSuccessTask
{
    __weak typeof(self) weakSelf = self;
    
    return ^JEFuture *(JESuccessTask task) {
        return [weakSelf continueWithSuccessTask:task];
    };
}

- (JESuccessTaskDotNotation)continueWithSuccessTaskOnMainQueue
{
    __weak typeof(self) weakSelf = self;
    
    return ^JEFuture *(JESuccessTask task) {
        return [weakSelf continueOnQueue:dispatch_get_main_queue() withSuccessTask:task];
    };
}

- (JESuccessTaskQueueDotNotation)continueWithSuccessTaskOnQueue
{
    __weak typeof(self) weakSelf = self;
    
    return ^JEFuture *(dispatch_queue_t q, JESuccessTask task) {
        return [weakSelf continueOnQueue:q withSuccessTask:task];
    };
}

@end
