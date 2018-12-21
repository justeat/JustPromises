//
//  JEFuture.h
//  JustPromises
//
//  Created by Marek Rogosz on 26/11/2014.
//  Copyright (c) 2014 JUST EAT. All rights reserved.
//

#import <Foundation/Foundation.h>

@class JEFuture;

typedef void (^JEContinuation)(JEFuture *fut);

typedef JEFuture* (^JETask)(JEFuture *fut);
typedef JEFuture* (^JESuccessTask)(id val);

typedef NS_ENUM(NSUInteger, JEFutureState) {
    JEFutureStateUnresolved = 0,
    JEFutureStateResolvedWithResult,
    JEFutureStateResolvedWithError,
    JEFutureStateResolvedWithCancellation
};


/**
 *  This class represents the future value of an asynchronous task.
 */
@interface JEFuture : NSObject

/**
 *  Handy factory methods.
 */
+ (instancetype)futureWithResult:(id)result;
+ (instancetype)futureWithError:(NSError *)error;
+ (instancetype)cancelledFuture;
+ (instancetype)futureWithResolutionOfFuture:(JEFuture *)src;

/**
 *  Check if the receiver is resolved.
 *
 *  @return YES if the future is resolved, NO otherwise.
 */
- (BOOL)isResolved;

/**
 *  This method returns the receiver state as an enumeration.
 *
 *  @return The future state enum.
 */
- (JEFutureState)state;

/**
 *  Check if the receiver has a result. You should call this method prior to call -result to avoid an undesired blocking call.
 *
 *  @return YES if the receiver has a result, NO otherwise.
 */
- (BOOL)hasResult;

/**
 *  Check if the receiver has an error. You should call this method prior to call -error to avoid an undesired blocking call.
 *
 *  @return YES if the receiver has an error, NO otherwise.
 */
- (BOOL)hasError;

/**
 *  Check if the receiver is cancelled.
 *
 *  @return YES if the receiver is cancelled, NO otherwise.
 */
- (BOOL)isCancelled;

/**
 *  Explicitly wait until the receiver is resolved.
 */
- (void)wait;

/**
 *  Explicitly wait with a timeout until the receiver is resolved.
 */
- (BOOL)waitUntilDate:(NSDate *)timeout;

/**
 *  This method hangs until the future is resolved.
 *
 *  @return The result of the receiver if it succeeded, nil otherwise.
 */
- (id)result;

/**
 *  This method hangs until the future is resolved.
 *
 *  @return The error of the receiver if it failed, nil otherwise.
 */
- (NSError *)error;

/**
 *  Set the continuation on the receiver. If the receiver is already resolved, the continuation block will execute immediately.
 *
 *  @param continuation The continuation block.
*/
- (void)setContinuation:(JEContinuation)continuation;

/**
 *  Set the continuation on the receiver executing it on a specific queue. If the receiver is already resolved, the continuation block will execute immediately.
 *
 *  @param queue        The queue on which the continuation block is executed.
 *  @param continuation The continuation block.
 */
- (void)onQueue:(dispatch_queue_t)queue setContinuation:(JEContinuation)continuation;

/**
 *  Set the continuation on the receiver providing a block and return the subsequent future.
 *  This method should be used for asynchronous operations that return a future straightaway.
 *
 *  @param task The task block.
 *
 *  @return The subsequent future.
 */
- (JEFuture *)continueWithTask:(JETask)task;

/**
 *  Set the continuation on the receiver providing a block and a queue and return the subsequent future.
 *  This method should be used for asynchronous operations that return a future straightaway.
 *
 *  @param queue The queue on which the task block is executed.
 *  @param task The task block
 *
 *  @return The subsequent future.
 */
- (JEFuture *)continueOnQueue:(dispatch_queue_t)queue withTask:(JETask)task;

/**
 *  Set the continuation on the receiver providing a block and return the subsequent future.
 *  This method should be used for asynchronous operations that return a future straightaway.
 *
 *  @param successTask The task block to execute for the continuation if the future passed in suceeded.
 *
 *  @return The subsequent future.
 */
- (JEFuture *)continueWithSuccessTask:(JESuccessTask)successTask;

/**
 *  Set the continuation on the receiver providing a block and a queue and return the subsequent future.
 *  This method should be used for asynchronous operations that return a future straightaway.
 *
 *  @param queue The queue on which the task block is executed.
 *  @param successTask The task block to execute for the continuation if the future passed in suceeded.
 *
 *  @return The subsequent future.
 */
- (JEFuture *)continueOnQueue:(dispatch_queue_t)queue withSuccessTask:(JESuccessTask)successTask;

/**
 *  Return a future that is resolved only when all the passed in futures are resolved.
 *  Once this method is called, it's not possible to add further continuations to the futures passed in.
 *
 *  @param futures The futures the received checks for resolution.
 *
 *  @return A future that is resolved only when all the futures passed in are resolved.
 */
+ (instancetype)whenAll:(NSArray *)futures;

@end


/**
 *  This class wraps a future object representing the future value of an asynchronous task.
 */
@interface JEPromise : NSObject

/**
 *  The future wrapped in the receiver.
 *
 *  @return The future.
 */
- (JEFuture *)future;

/**
 *  Make the wrapped future succeeded.
 *
 *  @param result The result.
 */
- (void)setResult:(id)result;

/**
 *  Make the wrapped future fail with an error.
 *
 *  @param error The error.
 */
- (void)setError:(NSError *)error;

/**
 *  Cancel the wrapped future.
 */
- (void)setCancelled;

/**
 *  Provides a future with the same resolution of the one passed as a parameter.
 *
 *  @param future The source future.
 */
- (void)setResolutionOfFuture:(JEFuture *)future;

@end

