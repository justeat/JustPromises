//
//  JEFuture_DotNotationTests.m
//  JustPromises
//
//  Created by Alberto De Bortoli on 08/07/2015.
//  Copyright © 2015 JUST EAT. All rights reserved.
//

@import XCTest;
@import JustPromises;

static NSString *const kTestErrorDomain = @"TestError";

@interface JEFuture_DotNotationTests : XCTestCase

@end

@implementation JEFuture_DotNotationTests

- (void)test_GivenPromise_WhenSetContinuationAndResultIsSet_ThenContinuationIsExecuted
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"test expectation"];
    
    f.continues(^(JEFuture *fut) {
        XCTAssertEqual([fut result], @123);
        [exp fulfill];
    });
    
    [p setResult:@123];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenPromise_WhenSetContinuationOnMainQueueAndResultIsSet_ThenContinuationIsExecutedOnMainQueue
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"test expectation"];
    
    f.continueOnMainQueue(^(JEFuture *fut) {
        XCTAssertEqual([fut result], @123);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        dispatch_queue_t queue = dispatch_get_current_queue();
        XCTAssertEqual(queue, dispatch_get_main_queue());
#pragma clang diagnostic pop
        [exp fulfill];
    });
    
    [p setResult:@123];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenPromise_WhenSetContinuationOnSpecificQueueAndResultIsSet_ThenContinuationIsExecutedOnSpecificQueue
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"test expectation"];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    f.continueOnQueue(queue, ^(JEFuture *fut) {
        XCTAssertEqual([fut result], @123);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        dispatch_queue_t currentQueue = dispatch_get_current_queue();
        XCTAssertEqual(queue, currentQueue);
#pragma clang diagnostic pop
        [exp fulfill];
    });
    
    [p setResult:@123];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenPromise_WhenFutureContinuesWithSynchronousTaskAndResultIsSet_ThenNewFutureHasResult
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = f.continueWithTask(^JEFuture* (JEFuture *fut) {
        JEPromise *p = [JEPromise new];
        [p setResult:@([[fut result] intValue] * 2)];
        return [p future];
    });
    
    [p setResult:@(1)];
    XCTAssertTrue([f2 hasResult]);
    XCTAssertEqualObjects([f2 result], @(2));
}

- (void)test_GivenPromise_WhenFutureContinuesWithNotSatisfyingSynchronousTaskAndResultIsSet_ThenNewFutureHasError
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = f.continueWithTask(^JEFuture* (JEFuture *fut) {
        JEPromise *p = [JEPromise new];
        return [p future];
    });
    
    [p setResult:@(1)];
    XCTAssertTrue([f2 hasError]);
    XCTAssertNotNil([f2 error]);
}

- (void)test_GivenPromise_WhenFutureContinuesWithAsynchronousTaskAndResultIsSet_ThenNewFutureHasResult
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = f.continueWithTask(^JEFuture* (JEFuture *fut) {
        JEPromise *p = [JEPromise new];
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), queue, ^{
            [p setResult:@([[fut result] intValue] * 2)];
        });
        
        return [p future];
    });
    
    [p setResult:@(1)];
    [f2 wait];
    XCTAssertTrue([f2 hasResult]);
    XCTAssertEqualObjects([f2 result], @(2));
}

- (void)test_GivenPromise_WhenContinuesWithTaskAndSetResult_ThenFutureHasResult
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = f.continueWithTask(^JEFuture* (JEFuture *fut) {
        XCTAssertTrue([fut hasResult]);
        return [JEFuture futureWithResolutionOfFuture:fut];
    });
    
    [p setResult:@42];
    XCTAssertTrue([f2 hasResult]);
    XCTAssertEqualObjects([f2 result], @42);
}

- (void)test_GivenPromise_WhenContinuesWithTaskAndSetError_ThenFutureHasError
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = f.continueWithTask(^JEFuture* (JEFuture *fut) {
        XCTAssertTrue([fut hasError]);
        return [JEFuture futureWithResolutionOfFuture:fut];
    });
    
    [p setError:[NSError errorWithDomain:@"TestError" code:0 userInfo:nil]];
    XCTAssertTrue([f2 hasError]);
    XCTAssertEqualObjects([f2 error].domain, @"TestError");
}

- (void)test_GivenPromise_WhenContinuesWithTaskAndCancelled_ThenFutureIsCancelled
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = f.continueWithTask(^JEFuture* (JEFuture *fut) {
        XCTAssertTrue([fut isCancelled]);
        return [JEFuture futureWithResolutionOfFuture:fut];
    });
    
    [p setCancelled];
    XCTAssertTrue([f2 isCancelled]);
}

- (void)test_GivenPromise_WhenContinuesWithTaskOnMainQueueAndResultIsSet_ThenFutureIsExecutedOnMainQueue
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];

    XCTestExpectation *exp = [self expectationWithDescription:@"test"];

    f.continueWithTaskOnMainQueue(^JEFuture* (JEFuture *fut) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        dispatch_queue_t currentQueue = dispatch_get_current_queue();
        XCTAssertEqual(dispatch_get_main_queue(), currentQueue);
#pragma clang diagnostic pop
        [exp fulfill];
        return [JEFuture futureWithResolutionOfFuture:fut];
    });

    [p setResult:@(1)];

    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenPromise_WhenContinuesWithTaskOnSpecificQueueAndResultIsSet_ThenFutureIsExecutedOnSpecificQueue
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];

    XCTestExpectation *exp = [self expectationWithDescription:@"test"];

    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);

    f.continueWithTaskOnQueue(queue, ^JEFuture* (JEFuture *fut) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        dispatch_queue_t currentQueue = dispatch_get_current_queue();
        XCTAssertEqual(queue, currentQueue);
#pragma clang diagnostic pop
        [exp fulfill];
        return [JEFuture futureWithResolutionOfFuture:fut];
    });

    [p setResult:@(1)];

    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenPromise_WhenContinuesWithTaskOnMainQueueAndResultIsSet_ThenFutureHasResult
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"test"];
    
    JEFuture *f2 = f.continueWithTaskOnMainQueue(^JEFuture* (JEFuture *fut) {
        JEPromise *p = [JEPromise new];
        [p setResult:@([[fut result] intValue] * 2)];
        [exp fulfill];
        return [p future];
    });
    
    [p setResult:@(1)];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    XCTAssertTrue([f2 hasResult]);
    XCTAssertEqualObjects([f2 result], @(2));
}

- (void)test_GivenPromise_WhenFutureContinuesWithSuccessTaskAndResultIsSet_ThenResultIsSetOnSubsequentFuture
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = f.continueWithSuccessTask(^JEFuture* (NSNumber *val) {
        JEPromise *p = [JEPromise new];
        [p setResult:@([val intValue] * 2)];
        return [p future];
    });
    
    [p setResult:@(1)];
    XCTAssertTrue([f2 hasResult]);
    XCTAssertEqualObjects([f2 result], @(2));
}

- (void)test_GivenPromise_WhenFutureContinuesWithSuccessTaskAndErrorIsSet_ThenSubsequentFutureHasError
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = f.continueWithSuccessTask(^JEFuture* (NSNumber *val) {
        JEPromise *p = [JEPromise new];
        [p setResult:@([val intValue] * 2)];
        return [p future];
    });
    
    NSError *error = [NSError errorWithDomain:kTestErrorDomain code:0 userInfo:nil];
    [p setError:error];
    
    XCTAssertTrue([f2 hasError]);
    XCTAssertEqualObjects([[f2 error] domain], kTestErrorDomain);
}

- (void)test_GivenPromise_WhenFutureContinuesWithSuccessTaskAndIsCancelled_ThenSubsequentFutureIsCancelled
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = f.continueWithSuccessTask(^JEFuture* (NSNumber *val) {
        XCTAssert(NO, @"This block should not be called");
        JEPromise *p = [JEPromise new];
        [p setResult:@([val intValue] * 2)];
        return [p future];
    });
    
    [p setCancelled];
    XCTAssertTrue([f2 isCancelled]);
    XCTAssertNil([f2 result]);
}

- (void)test_GivenPromise_WhenContinuesWithSuccessCancelledTask_ThenFutureIsCancelled
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = f.continueWithSuccessTask(^JEFuture* (NSNumber *val) {
        return [JEFuture cancelledFuture];
    });
    
    [p setResult:@1];
    
    XCTAssertTrue([f2 isCancelled]);
    XCTAssertNil([f2 result]);
}

- (void)test_GivenPromise_WhenContinuesWithSuccessOnMainQueue_ThenFutureIsExecutedOnMainQueue
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"test expectation"];
    
    f.continueWithSuccessTaskOnMainQueue(^JEFuture* (NSNumber *val) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        dispatch_queue_t queue = dispatch_get_current_queue();
        XCTAssertEqual(queue, dispatch_get_main_queue());
#pragma clang diagnostic pop
        [exp fulfill];
        return [JEFuture futureWithResult:val];
    });
    
    [p setResult:@1];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenPromise_WhenContinuesWithSuccessOnSpecificQueue_ThenFutureIsExecutedOnSpecificQueue
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"test expectation"];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    f.continueWithSuccessTaskOnQueue(queue, ^JEFuture* (NSNumber *val) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        dispatch_queue_t currentQueue = dispatch_get_current_queue();
        XCTAssertEqual(queue, currentQueue);
#pragma clang diagnostic pop
        [exp fulfill];
        return [JEFuture futureWithResult:val];
    });
    
    [p setResult:@1];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenPromise_WhenContinuesWithSuccessAndSetResult_ThenFutureHasResult
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"test"];
    
    JEFuture *f2 = f.continueWithSuccessTaskOnMainQueue(^JEFuture* (NSNumber *val) {
        JEPromise *p = [JEPromise new];
        [p setResult:@([val intValue] * 2)];
        [exp fulfill];
        return [p future];
    });
    
    [p setResult:@1];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue([f2 hasResult]);
    XCTAssertEqualObjects([f2 result], @2);
}

- (void)test_GivenPromise_WhenContinuesWithSuccessCancelledTaskOnMainQueue_ThenFutureIsCancelled
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"test"];
    
    JEFuture *f2 = f.continueWithSuccessTaskOnMainQueue(^JEFuture* (NSNumber *val) {
        [exp fulfill];
        return [JEFuture cancelledFuture];
    });
    
    [p setResult:@1];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
    XCTAssertTrue([f2 isCancelled]);
    XCTAssertNil([f2 result]);
}

@end
