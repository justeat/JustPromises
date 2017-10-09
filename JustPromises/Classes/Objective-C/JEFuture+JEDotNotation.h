//
//  JEFuture+JEDotNotation.h
//  JustPromises
//
//  Created by Alberto De Bortoli on 08/07/2015.
//  Copyright © 2015 JUST EAT. All rights reserved.
//

#import "JEFuture.h"

typedef void (^JEContinuationDotNotation)(JEContinuation);
typedef void (^JEContinuationQueueDotNotation)(dispatch_queue_t q, JEContinuation);

typedef JEFuture* (^JETaskDotNotation)(JETask task);
typedef JEFuture* (^JETaskQueueDotNotation)(dispatch_queue_t q, JETask task);

typedef JEFuture* (^JESuccessTaskDotNotation)(JESuccessTask task);
typedef JEFuture* (^JESuccessTaskQueueDotNotation)(dispatch_queue_t q, JESuccessTask task);

@interface JEFuture (JEDotNotation)

- (JEContinuationDotNotation)continues;
- (JEContinuationDotNotation)continueOnMainQueue;
- (JEContinuationQueueDotNotation)continueOnQueue;

- (JETaskDotNotation)continueWithTask;
- (JETaskDotNotation)continueWithTaskOnMainQueue;
- (JETaskQueueDotNotation)continueWithTaskOnQueue;

- (JESuccessTaskDotNotation)continueWithSuccessTask;
- (JESuccessTaskDotNotation)continueWithSuccessTaskOnMainQueue;
- (JESuccessTaskQueueDotNotation)continueWithSuccessTaskOnQueue;

@end
