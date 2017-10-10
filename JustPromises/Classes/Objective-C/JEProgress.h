//
//  JEProgress.h
//  JustPromises
//
//  Created by Marek Rogosz on 05/12/2014.
//  Copyright (c) 2014 JUST EAT. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol JECancellableProgressProtocol;
@class JEProgress;


typedef void (^JECancellationHandler)(id<JECancellableProgressProtocol> token);
typedef void (^JEProgressHandler)(JEProgress *progress);

/**
 *  This protocol represents a general interface for a cancellable progress operation.
 */
@protocol JECancellableProgressProtocol

/**
 *  This method is intended to check the cancellation status of the receiver.
 *
 *  @return YES if the receiver is cancelled, NO otherwise.
 */
- (BOOL)isCancelled;

/**
 *  This method is intended to set a handler to be executed when the the receiver is cancelled.
 *  If the receiver is already cancelled the handler should be executed immediately.
 *
 *  @param handler The cancellation handler.
 */
- (void)setCancellationHandler:(JECancellationHandler)handler;
- (void)onQueue:(dispatch_queue_t)queue setCancellationHandler:(JECancellationHandler)handler;

/**
 *  This method is intended to update the receiver with a partial unit count and a total.
 *
 *  @param completed The unit count.
 *  @param total     The total.
 */
- (void)updateCompletedUnitCount:(NSUInteger)completed total:(NSUInteger)total;

/**
 *  This method is intended to set a state on the receiver.
 *
 *  @param state The state.
 */
- (void)updateState:(NSUInteger)state;

/**
 *  This method is intended to set a progress description on the receiver.
 *
 *  @param progressDescription The progress description.
 */
- (void)updateProgressDescription:(NSString *)progressDescription;

@end

/**
 *  This class represents a cancellable progress operation.
 */
@interface JEProgress : NSObject <JECancellableProgressProtocol>

/**
 *  Cancel the receiver.
 */
- (void)cancel;

/**
 *  Get the completed amount of units and total of the receiver.
 *
 *  @param completed The passed-in by reference unit count.
 *  @param total     The passed-in by reference total.
 */
- (void)getCompletedUnitCount:(NSUInteger *)completed total:(NSUInteger *)total;

/**
 *  Set a handler called when the state is updated through updateState:
 *
 *  @param handler The handler.
 */
- (void)setProgressHandler:(JEProgressHandler)handler;

/**
 *  Set a handler called on a specific queue when the state is updated through updateState:
 *
 *  @param queue The queue.
 *  @param handler The handler.
 */
- (void)onQueue:(dispatch_queue_t)queue setProgressHandler:(JEProgressHandler)handler;

/**
 *  Retrieve the state of the receiver.
 *
 *  @return The state of the receiver.
 */
- (NSUInteger)state;

/**
 *  Set a handler called when the progress is updated through updateCompletedUnitCount:total:
 *
 *  @param handler The handler.
 */
- (void)setStateHandler:(JEProgressHandler)handler;

/**
 *  Set a handler called on a specific queue when the state is updated through updateCompletedUnitCount:total:
 *
 *  @param queue The queue.
 *  @param handler The handler.
 */
- (void)onQueue:(dispatch_queue_t)queue setStateHandler:(JEProgressHandler)handler;

/**
 *  Retrieve the current description of the receiver.
 *
 *  @return The current description of the receiver.
 */
- (NSString *)progressDescription;

/**
 *  Set a handler called when the state is updated through updateProgressDescription:
 *
 *  @param handler The handler.
 */
- (void)setProgressDescriptionHandler:(JEProgressHandler)handler;

/**
 *  Set a handler called on a specific queue when the state is updated through updateProgressDescription:
 *
 *  @param queue The queue.
 *  @param handler The handler.
 */
- (void)onQueue:(dispatch_queue_t)queue setProgressDescriptionHandler:(JEProgressHandler)handler;

@end

