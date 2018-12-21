//
//  JEProgressTests.m
//  JustPromises
//
//  Created by Marek Rogosz on 05/12/2014.
//  Copyright (c) 2014 JUST EAT. All rights reserved.
//

@import XCTest;
@import JustPromises;

static NSString *const kTestExpectationDescription = @"test expectation";
static NSString *const kTestExpectationDescription2 = @"test expectation 2";


@interface JEProgressTests : XCTestCase

@end


@implementation JEProgressTests

- (void)test_GivenProgress_WhenTestedForInitialState_ThenStateIsDefault
{
    JEProgress *p = [JEProgress new];
    
    NSUInteger completed, total;
    [p getCompletedUnitCount:&completed total:&total];
    XCTAssertEqual(completed, 0);
    XCTAssertEqual(total, 100);
    
    XCTAssertFalse([p isCancelled]);
    XCTAssertEqual([p state], 0);
    XCTAssertNil([p progressDescription]);
}

- (void)test_GivenProgress_WhenCancelled_ThenIsCancelled
{
    JEProgress *p = [JEProgress new];
    XCTAssertFalse([p isCancelled]);
    
    XCTestExpectation *exp = [self expectationWithDescription:kTestExpectationDescription];
    [p setCancellationHandler:^(id<JECancellableProgressProtocol> progress) {
        XCTAssertTrue([progress isCancelled]);
        [exp fulfill];
    }];
    
    [p cancel];
    XCTAssertTrue([p isCancelled]);
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenProgress_WhenCancelled_ThenCancellationHandlerIsCalledOnSpecificQueue
{
    JEProgress *p = [JEProgress new];
    XCTAssertFalse([p isCancelled]);
    
    XCTestExpectation *exp = [self expectationWithDescription:kTestExpectationDescription];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    [p onQueue:queue setCancellationHandler:^(id<JECancellableProgressProtocol> progress) {
        XCTAssertTrue([progress isCancelled]);
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        XCTAssertEqual(queue, dispatch_get_current_queue());
#pragma clang diagnostic pop
        
        [exp fulfill];
    }];
    
    [p cancel];
    XCTAssertTrue([p isCancelled]);
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenProgress_WhenCancelledTwice_ThenIsCancellationHandlerIsCalledOnce
{
    JEProgress *p = [JEProgress new];
    XCTAssertFalse([p isCancelled]);
    
    XCTestExpectation *exp = [self expectationWithDescription:kTestExpectationDescription];
    
    __block BOOL alreadyCalled = NO;
    [p setCancellationHandler:^(id<JECancellableProgressProtocol> progress) {
        XCTAssertFalse(alreadyCalled);
        alreadyCalled = YES;
        
        XCTAssertTrue([progress isCancelled]);
        [exp fulfill];
    }];
    
    [p cancel];
    XCTAssertTrue([p isCancelled]);
    
    [p cancel];
    XCTAssertTrue([p isCancelled]);
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenProgress_WhenCancelledBeforeSettingCancellationHandler_ThenCancellationHandlerIsStillCalled
{
    JEProgress *p = [JEProgress new];
    XCTAssertFalse([p isCancelled]);
    
    [p cancel];
    XCTAssertTrue([p isCancelled]);
    
    XCTestExpectation *exp = [self expectationWithDescription:kTestExpectationDescription];
    [p setCancellationHandler:^(id<JECancellableProgressProtocol> progress) {
        XCTAssertTrue([progress isCancelled]);
        [exp fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenProgress_WhenCancelledBeforeSettingCancellationHandlerTwice_ThenCancellationHandlersAreStillCalled
{
    JEProgress *p = [JEProgress new];
    XCTAssertFalse([p isCancelled]);
    
    [p cancel];
    XCTAssertTrue([p isCancelled]);
    
    XCTestExpectation *exp1 = [self expectationWithDescription:kTestExpectationDescription];
    [p setCancellationHandler:^(id<JECancellableProgressProtocol> progress) {
        XCTAssertTrue([progress isCancelled]);
        [exp1 fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
    
    
    XCTestExpectation *exp2 = [self expectationWithDescription:kTestExpectationDescription2];
    [p setCancellationHandler:^(id<JECancellableProgressProtocol> progress) {
        XCTAssertTrue([progress isCancelled]);
        [exp2 fulfill];
    }];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenProgress_WhenUpdateCompletedUnit_ThenProgressHandlerIsCalled
{
    JEProgress *p = [JEProgress new];
    
    XCTestExpectation *exp = [self expectationWithDescription:kTestExpectationDescription];
    
    [p setProgressHandler:^(JEProgress *progress) {
        NSUInteger completed, total;
        [progress getCompletedUnitCount:&completed total:&total];
        XCTAssertEqual(completed, 51);
        XCTAssertEqual(total, 1024);
        
        [exp fulfill];
    }];
    
    [p updateCompletedUnitCount:51 total:1024];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenProgress_WhenUpdateCompletedUnit_ThenProgressHandlerIsCalledOnSpecificQueue
{
    JEProgress *p = [JEProgress new];
    
    XCTestExpectation *exp = [self expectationWithDescription:kTestExpectationDescription];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    [p onQueue:queue setProgressHandler:^(JEProgress *progress) {
        NSUInteger completed, total;
        [progress getCompletedUnitCount:&completed total:&total];
        XCTAssertEqual(completed, 51);
        XCTAssertEqual(total, 1024);
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        XCTAssertEqual(queue, dispatch_get_current_queue());
#pragma clang diagnostic pop
        
        [exp fulfill];
    }];
    
    [p updateCompletedUnitCount:51 total:1024];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenProgress_WhenUpdateState_ThenStateHandlerIsCalled
{
    JEProgress *p = [JEProgress new];
    
    XCTestExpectation *exp = [self expectationWithDescription:kTestExpectationDescription];
    
    [p setStateHandler:^(JEProgress *progress) {
        XCTAssertEqual([progress state], 123);
        [exp fulfill];
    }];
    
    [p updateState:123];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenProgress_WhenUpdateState_ThenStateHandlerIsCalledOnSpecificQueue
{
    JEProgress *p = [JEProgress new];
    
    XCTestExpectation *exp = [self expectationWithDescription:kTestExpectationDescription];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    [p onQueue:queue setStateHandler:^(JEProgress *progress) {
        XCTAssertEqual([progress state], 123);
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        XCTAssertEqual(queue, dispatch_get_current_queue());
#pragma clang diagnostic pop
        
        [exp fulfill];
    }];
    
    [p updateState:123];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenProgress_WhenUpdateDescription_ThenDescriptionHandlerIsCalled
{
    JEProgress *p = [JEProgress new];
    
    XCTestExpectation *exp = [self expectationWithDescription:kTestExpectationDescription];
    
    [p setProgressDescriptionHandler:^(JEProgress *progress) {
        XCTAssertEqualObjects([progress progressDescription], @"Object description");
        [exp fulfill];
    }];
    
    [p updateProgressDescription:@"Object description"];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

- (void)test_GivenProgress_WhenUpdateDescription_ThenDescriptionHandlerIsCalledOnSpecificQueue
{
    JEProgress *p = [JEProgress new];
    
    XCTestExpectation *exp = [self expectationWithDescription:kTestExpectationDescription];
    dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    [p onQueue:queue setProgressDescriptionHandler:^(JEProgress *progress) {
        XCTAssertEqualObjects([progress progressDescription], @"Object description");
        
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        XCTAssertEqual(queue, dispatch_get_current_queue());
#pragma clang diagnostic pop
        
        [exp fulfill];
    }];
    
    [p updateProgressDescription:@"Object description"];
    [self waitForExpectationsWithTimeout:10 handler:nil];
}

@end
