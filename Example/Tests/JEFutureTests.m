//
//  JEFutureTests.m
//  JustPromises
//
//  Created by Marek Rogosz on 26/11/2014.
//  Copyright (c) 2014 JUST EAT. All rights reserved.
//

@import XCTest;
@import JustPromises;

static NSString *const kTestErrorDomain = @"TestError";

@interface JEFutureTests : XCTestCase

@end

@implementation JEFutureTests

- (void)test_GivenPromise_WhenNotResolved_ThenFutureHasResolutionStateUnresolved
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    XCTAssertEqual([f state], JEFutureStateUnresolved);
}

- (void)test_GivenPromise_WhenAskedFutureForInitialState_ThenFutureHasCorrectInitialState
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    XCTAssertFalse([f isResolved]);
    XCTAssertFalse([f hasResult]);
    XCTAssertFalse([f hasError]);
    XCTAssertFalse([f isCancelled]);
}

- (void)test_GivenPromise_WhenSetResult_ThenFutureHasResult
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    [p setResult:@1];
    XCTAssertTrue([f isResolved]);
    XCTAssertTrue([f hasResult]);
    XCTAssertFalse([f hasError]);
    XCTAssertFalse([f isCancelled]);
    
    XCTAssertEqualObjects([f result], @1);
    XCTAssertNil([f error]);
}

- (void)test_GivenPromise_WhenSetResult_ThenFutureHasResolutionStateResolvedWithResult
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    [p setResult:@1];
    XCTAssertEqual([f state], JEFutureStateResolvedWithResult);
}

- (void)test_GivenPromise_WhenSetError_ThenFutureHasError
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    [p setError:[NSError errorWithDomain:kTestErrorDomain code:0 userInfo:nil]];
    XCTAssertTrue([f isResolved]);
    XCTAssertFalse([f hasResult]);
    XCTAssertTrue([f hasError]);
    XCTAssertFalse([f isCancelled]);
    
    XCTAssertNil([f result]);
    XCTAssertEqualObjects([f error].domain, kTestErrorDomain);
}

- (void)test_GivenPromise_WhenSetError_ThenFutureHasResolutionStateResolvedWithError
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    [p setError:[NSError errorWithDomain:kTestErrorDomain code:0 userInfo:nil]];
    XCTAssertEqual([f state], JEFutureStateResolvedWithError);
}

- (void)test_GivenPromise_WhenCancelled_ThenFutureIsCancelled
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    [p setCancelled];
    XCTAssertTrue([f isResolved]);
    XCTAssertFalse([f hasResult]);
    XCTAssertFalse([f hasError]);
    XCTAssertTrue([f isCancelled]);
    
    XCTAssertNil([f result]);
    XCTAssertNil([f error]);
}

- (void)test_GivenPromise_WhenCancelled_ThenFutureHasResolutionStateResolvedWithCancellation
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    [p setCancelled];
    XCTAssertEqual([f state], JEFutureStateResolvedWithCancellation);
}

- (void)test_GivenPromise_WhenFutureSetResultWhileWaiting_ThenResultIsSet
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), queue, ^{
        [p setResult:@1];
    });
    
    XCTAssertEqualObjects([f result], @1);
}

- (void)test_GivenPromise_WhenFutureSetResultWhileExplicitlyWaiting_ThenResultIsSet
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), queue, ^{
        [p setResult:@1];
    });
    
    [f wait];
    XCTAssertTrue([f hasResult]);
    XCTAssertEqualObjects([f result], @1);
}

- (void)test_GivenPromise_WhenNotSatisfiedAndDealloced_ThenFutureHasError
{
    JEFuture *f;
    @autoreleasepool
    {
        JEPromise *p = [JEPromise new];
        f = [p future];
    }
    
    XCTAssertTrue([f hasError]);
    XCTAssertNotNil([f error]);
}

- (void)test_GivenPromise_WhenFutureIsAskedToWaitUntilDateAndSetResult_ThenFutureHasResult
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    XCTAssertFalse([f waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]]);
    
    [p setResult:@1];
    XCTAssertTrue([f waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:1]]);
    
    XCTAssertTrue([f hasResult]);
    XCTAssertEqualObjects([f result], @1);
}

- (void)test_GivenPromise_WhenSetContinuationAndResultIsSet_ThenContinuationIsExecuted
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"test expectation"];
    [f setContinuation:^(JEFuture *fut) {
        XCTAssertEqual([fut result], @123);
        [exp fulfill];
    }];
    
    [p setResult:@123];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenPromise_WhenSetContinuationOnSpecificQueueAndResultIsSet_ThenContinuationIsExecuted
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    XCTestExpectation *exp = [self expectationWithDescription:@"test expectation"];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    [f onQueue:queue setContinuation:^(JEFuture *fut) {
        XCTAssertEqual([fut result], @123);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        XCTAssertEqual(queue, dispatch_get_current_queue());
#pragma clang diagnostic pop
        [exp fulfill];
    }];
    
    [p setResult:@123];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenPromise_WhenFutureContinuesWithSynchronousTaskAndResultIsSet_ThenNewFutureHasResult
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = [f continueWithTask:^JEFuture *(JEFuture *fut) {
        JEPromise *p = [JEPromise new];
        [p setResult:@([[fut result] intValue] * 2)];
        return [p future];
    }];
    
    [p setResult:@(1)];
    XCTAssertTrue([f2 hasResult]);
    XCTAssertEqualObjects([f2 result], @(2));
}

- (void)test_GivenPromise_WhenFutureContinuesWithNotSatisfyingSynchronousTaskAndResultIsSet_ThenNewFutureHasError
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = [f continueWithTask:^JEFuture *(JEFuture *fut) {
        JEPromise *p = [JEPromise new];
        return [p future];
    }];
    
    [p setResult:@(1)];
    XCTAssertTrue([f2 hasError]);
    XCTAssertNotNil([f2 error]);
}

- (void)test_GivenPromise_WhenFutureContinuesWithAsynchronousTaskAndResultIsSet_ThenNewFutureHasResult
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = [f continueWithTask:^JEFuture *(JEFuture *fut) {
        JEPromise *p = [JEPromise new];
        
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), queue, ^{
            [p setResult:@([[fut result] intValue] * 2)];
        });
        
        return [p future];
    }];
    
    [p setResult:@(1)];
    [f2 wait];
    XCTAssertTrue([f2 hasResult]);
    XCTAssertEqualObjects([f2 result], @(2));
}

- (void)test_GivenPromise_WhenContinuesWithTaskAndSetResult_ThenFutureHasResult
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = [f continueWithTask:^JEFuture *(JEFuture *fut) {
        XCTAssertTrue([fut hasResult]);
        return [JEFuture futureWithResolutionOfFuture:fut];
    }];
    
    [p setResult:@42];
    XCTAssertTrue([f2 hasResult]);
    XCTAssertEqualObjects([f2 result], @42);
}

- (void)test_GivenPromise_WhenContinuesWithTaskAndSetError_ThenFutureHasError
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = [f continueWithTask:^JEFuture *(JEFuture *fut) {
        XCTAssertTrue([fut hasError]);
        return [JEFuture futureWithResolutionOfFuture:fut];
    }];
    
    [p setError:[NSError errorWithDomain:@"TestError" code:0 userInfo:nil]];
    XCTAssertTrue([f2 hasError]);
    XCTAssertEqualObjects([f2 error].domain, @"TestError");
}

- (void)test_GivenPromise_WhenContinuesWithTaskAndCancelled_ThenFutureIsCancelled
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = [f continueWithTask:^JEFuture *(JEFuture *fut) {
        XCTAssertTrue([fut isCancelled]);
        return [JEFuture futureWithResolutionOfFuture:fut];
    }];
    
    [p setCancelled];
    XCTAssertTrue([f2 isCancelled]);
}

- (void)test_GivenPromise_WhenContinuesWithTaskOnSpecificQueueAndResultIsSet_ThenFutureHasResult
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    JEFuture *f2 = [f continueOnQueue:queue withTask:^JEFuture *(JEFuture *fut) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        XCTAssertEqual(queue, dispatch_get_current_queue());
#pragma clang diagnostic pop
        JEPromise *p = [JEPromise new];
        [p setResult:@([[fut result] intValue] * 2)];
        return [p future];
    }];
    
    [p setResult:@(1)];
    
    [f2 wait];
    XCTAssertTrue([f2 hasResult]);
    XCTAssertEqualObjects([f2 result], @(2));
}

- (void)test_GivenPromise_WhenFutureContinuesWithSuccessTaskAndResultIsSet_ThenResultIsSetOnSubsequentFuture
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = [f continueWithSuccessTask:^JEFuture *(id val) {
        JEPromise *p = [JEPromise new];
        [p setResult:@([val intValue] * 2)];
        return [p future];
    }];
    
    [p setResult:@(1)];
    XCTAssertTrue([f2 hasResult]);
    XCTAssertEqualObjects([f2 result], @(2));
}

- (void)test_GivenPromise_WhenFutureContinuesWithSuccessTaskAndErrorIsSet_ThenSubsequentFutureHasError
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = [f continueWithSuccessTask:^JEFuture *(id val) {
        JEPromise *p = [JEPromise new];
        [p setResult:@([val intValue] * 2)];
        return [p future];
    }];
    
    NSError *error = [NSError errorWithDomain:kTestErrorDomain code:0 userInfo:nil];
    [p setError:error];
    
    XCTAssertTrue([f2 hasError]);
    XCTAssertEqualObjects([[f2 error] domain], kTestErrorDomain);
}

- (void)test_GivenPromise_WhenFutureContinuesWithSuccessTaskAndIsCancelled_ThenSubsequentFutureIsCancelled
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = [f continueWithSuccessTask:^JEFuture *(id val) {
        XCTAssert(NO, @"This block should not be called");
        JEPromise *p = [JEPromise new];
        [p setResult:@([val intValue] * 2)];
        return [p future];
    }];
    
    [p setCancelled];
    XCTAssertTrue([f2 isCancelled]);
    XCTAssertNil([f2 result]);
}

- (void)test_GivenPromise_WhenContinuesWithSuccessCancelledTask_ThenFutureIsCancelled
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    JEFuture *f2 = [f continueWithSuccessTask:^JEFuture *(id val) {
        return [JEFuture cancelledFuture];
    }];
    
    [p setResult:@1];
    
    XCTAssertTrue([f2 isCancelled]);
    XCTAssertNil([f2 result]);
}

- (void)test_GivenPromise_WhenContinuesWithSuccessAndSetResult_ThenFutureHasResult
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    JEFuture *f2 = [f continueOnQueue:queue withSuccessTask:^JEFuture *(id val) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        XCTAssertEqual(queue, dispatch_get_current_queue());
#pragma clang diagnostic pop
        JEPromise *p = [JEPromise new];
        [p setResult:@([val intValue] * 2)];
        return [p future];
    }];
    
    [p setResult:@1];
    
    [f2 wait];
    XCTAssertTrue([f2 hasResult]);
    XCTAssertEqualObjects([f2 result], @2);
}

- (void)test_GivenPromise_WhenContinuesWithSuccessCancelledTaskOnSpecificQueue_ThenFutureIsCancelled
{
    JEPromise *p = [JEPromise new];
    JEFuture *f = [p future];
    
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    JEFuture *f2 = [f continueOnQueue:queue withSuccessTask:^JEFuture *(id val) {
        return [JEFuture cancelledFuture];
    }];
    
    [p setResult:@1];
    
    [f2 wait];
    XCTAssertTrue([f2 isCancelled]);
    XCTAssertNil([f2 result]);
}

- (void)test_GivenPromises_WhenAllPromisesSucceeded_ThenWhenAllFutureHasResult
{
    JEPromise *p1 = [JEPromise new];
    JEPromise *p2 = [JEPromise new];
    JEPromise *p3 = [JEPromise new];
    
    NSArray *futures = @[p1.future, p2.future, p3.future];
    JEFuture *allFuture = [JEFuture whenAll:futures];
    
    XCTAssertFalse([allFuture hasResult]);
    [p3 setResult:@3];
    XCTAssertFalse([allFuture hasResult]);
    [p1 setResult:@1];
    XCTAssertFalse([allFuture hasResult]);
    [p2 setResult:@2];
    
    XCTAssertTrue([allFuture hasResult]);
    
    NSArray *results = [allFuture result];
    XCTAssertEqualObjects([results[0] result], @1);
    XCTAssertEqualObjects([results[1] result], @2);
    XCTAssertEqualObjects([results[2] result], @3);
}

- (void)test_GivenPromises_WhenAllPromisesAreSatisfied_ThenWhenAllFutureHasResult
{
    JEPromise *p1 = [JEPromise new];
    JEPromise *p2 = [JEPromise new];
    JEPromise *p3 = [JEPromise new];
    
    NSArray *futures = @[p1.future, p2.future, p3.future];
    JEFuture *allFuture = [JEFuture whenAll:futures];
    
    XCTAssertFalse([allFuture hasResult]);
    [p3 setCancelled];
    XCTAssertFalse([allFuture hasResult]);
    [p1 setResult:@1];
    XCTAssertFalse([allFuture hasResult]);
    NSError *error = [NSError errorWithDomain:kTestErrorDomain code:0 userInfo:nil];
    [p2 setError:error];
    
    XCTAssertTrue([allFuture hasResult]);
    
    NSArray *results = [allFuture result];
    XCTAssertEqualObjects([results[0] result], @1);
    XCTAssertTrue([results[1] hasError]);
    XCTAssertTrue([results[2] isCancelled]);
}

- (void)test_GivenUnresolvedPromise_WhenPrintedDescription_ThenProperDescriptionIsPrinted
{
    JEPromise *p = [JEPromise new];
    NSString *testValue = [@"Unresolved" lowercaseString];
    NSString *targetValue = [[p description] lowercaseString];
    XCTAssertTrue([targetValue rangeOfString:testValue].location != NSNotFound);
}

- (void)test_GivenPromiseResolvedWithResult_WhenPrintedDescription_ThenProperDescriptionIsPrinted
{
    JEPromise *p = [JEPromise new];
    [p setResult:@42];
    NSString *testValue = [@"Resolved with result" lowercaseString];
    NSString *targetValue = [[p description] lowercaseString];
    XCTAssertTrue([targetValue rangeOfString:testValue].location != NSNotFound);
}

- (void)test_GivenPromiseResolvedWithError_WhenPrintedDescription_ThenProperDescriptionIsPrinted
{
    JEPromise *p = [JEPromise new];
    [p setError:[NSError errorWithDomain:@"com.justeat.JustPromises" code:0 userInfo:nil]];
    NSString *testValue = [@"Resolved with error" lowercaseString];
    NSString *targetValue = [[p description] lowercaseString];
    XCTAssertTrue([targetValue rangeOfString:testValue].location != NSNotFound);
}

- (void)test_GivenCanceledPromise_WhenPrintedDescription_ThenProperDescriptionIsPrinted
{
    JEPromise *p = [JEPromise new];
    [p setCancelled];
    NSString *testValue = [@"Resolved with cancellation" lowercaseString];
    NSString *targetValue = [[p description] lowercaseString];
    XCTAssertTrue([targetValue rangeOfString:testValue].location != NSNotFound);
}

- (void)test_GivenPromise_WhenSettingFutureContinuationTwice_ThenExceptionIsThrown
{
    JEPromise *p = [JEPromise new];
    [[p future] setContinuation:^(JEFuture *fut) { }];
    XCTAssertThrows([[p future] setContinuation:^(JEFuture *fut) { }]);
    [p setResult:@42];
}

@end

