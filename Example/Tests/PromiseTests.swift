//
//  JustPromisesSwift_iOSPromiseTests.swift
//  JustPromisesSwift_iOSTests
//
//  Created by Keith Moon on 04/12/2016.
//  Copyright © 2016 JUST EAT. All rights reserved.
//

import XCTest
import Foundation
import JustPromises
import Dispatch

enum TestError: Error {
    case somethingWentWrong
}

class PromiseTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testPromiseWillExecuteWhenAwaiting() {
        
        let asyncExpectation = expectation(description: "Await execution")
        
        let _ = Promise<Void> { promise in
            promise.futureState = .result()
            asyncExpectation.fulfill()
            }.await()
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseWillExecuteOnMainQueueWhenAwaiting() {
        
        let asyncExpectation = expectation(description: "Await execution")
        
        let _ = Promise<Void> { promise in
            
            let onMainQueue = Thread.current.isMainThread
            XCTAssertTrue(onMainQueue)
            
            promise.futureState = .result()
            asyncExpectation.fulfill()
            }.awaitOnMainQueue()
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseCanBeContinued() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        let asyncExpectation3 = expectation(description: "Await execution")
        
        let _ = Promise<Void> { promise in
            
            promise.futureState = .result()
            asyncExpectation1.fulfill()
            
            }.await().continuation { previousPromise in
                
                return Promise<Void> { promise in
                    promise.futureState = .result()
                    asyncExpectation2.fulfill()
                }
                
            }.continuation { _ in
                
                asyncExpectation3.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseCanBeContinuedOnMainQueue() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        let asyncExpectation3 = expectation(description: "Await execution")
        
        let _ = Promise<Void> { promise in
            
            promise.futureState = .result()
            asyncExpectation1.fulfill()
            
            }.await().continuation(onQueue: .main) { previousPromise in
                
                return Promise<Void> { promise in
                    
                    let onMainQueue = Thread.current.isMainThread
                    XCTAssertTrue(onMainQueue)
                    
                    promise.futureState = .result()
                    asyncExpectation2.fulfill()
                }
                
            }.continuation(onQueue: .main) { _ in
                
                let onMainQueue = Thread.current.isMainThread
                XCTAssertTrue(onMainQueue)
                
                asyncExpectation3.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseCanBeContinuedOnSuccess() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        
        let _ = Promise<Bool> { promise in
            
            // Complete with result
            promise.futureState = .result(true)
            asyncExpectation1.fulfill()
            
            }.await().continuationWithResult() { result in
                
                // This block fires with the result of the previous block
                XCTAssertTrue(result)
                asyncExpectation2.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseContinuedOnSuccessDoesntExecuteIfFailed() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        
        let _ = Promise<Bool> { promise in
            
            // Complete promise with errpr
            promise.futureState = .error(TestError.somethingWentWrong)
            asyncExpectation1.fulfill()
            
            }.await().continuationWithResult() { result in
                
                // The block shouldn't execute because
                // previous Promise completed with error.
                XCTFail()
                
            }.continuation { _ in
                
                asyncExpectation2.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseCanBeContinuedOnError() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        
        let _ = Promise<Bool> { promise in
            
            // Complete with error
            promise.futureState = .error(TestError.somethingWentWrong)
            asyncExpectation1.fulfill()
            
            }.await().continuationWithError() { error in
                
                guard let testError = error as? TestError else {
                    XCTFail()
                    return
                }
                
                // This block fires with the error of the previous block
                XCTAssertTrue(testError == TestError.somethingWentWrong)
                asyncExpectation2.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseContinuedOnErrorDoesntExecuteIfSucceed() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        let asyncExpectation2 = expectation(description: "Await execution")
        
        let _ = Promise<Bool> { promise in
            
            // Complete promise with result
            promise.futureState = .result(true)
            asyncExpectation1.fulfill()
            
            }.await().continuationWithError() { error in
                
                // The block shouldn't execute because
                // previous Promise completed with result.
                XCTFail()
                
            }.continuation { _ in
                
                asyncExpectation2.fulfill()
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    enum Failed: Error {
        case attempt(Int)
    }
    
    class FailThenSucceed {
        
        var numberOfTimesToFail: Int
        
        init(numberOfTimesToFail: Int) {
            self.numberOfTimesToFail = numberOfTimesToFail
        }
        
        func tryToSucceed() -> Bool {
            if numberOfTimesToFail == 0 {
                return true
            } else {
                numberOfTimesToFail = numberOfTimesToFail - 1
                return false
            }
        }
    }
    
    func testPromiseCanRety() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        
        var attempt = 0
        let fail4Times = FailThenSucceed(numberOfTimesToFail: 4)
        
        let promise = Promise<Bool>(executionBlock: { promise in
            
            DispatchQueue.main.async {
                
                let didSucceed = fail4Times.tryToSucceed()
                
                if didSucceed {
                    promise.futureState = .result(true)
                } else {
                    attempt = attempt + 1
                    promise.futureState = .error(Failed.attempt(attempt))
                }
            }
        })
        
        promise.retryCount = 5
        promise.await().continuation { promise in
            
            switch promise.futureState {
            case .result(true):
                asyncExpectation1.fulfill()
            default:
                XCTFail()
            }
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseWillFailAfterGivenNumberOfRetries() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        
        var attempt = 0
        let fail6Times = FailThenSucceed(numberOfTimesToFail: 6)
        
        let promise = Promise<Bool>(executionBlock: { promise in
            
            DispatchQueue.main.async {
             
                let didSucceed = fail6Times.tryToSucceed()
                
                if didSucceed {
                    promise.futureState = .result(true)
                } else {
                    attempt = attempt + 1
                    promise.futureState = .error(Failed.attempt(attempt))
                }
            }
        })
        
        promise.retryCount = 5
        promise.await().continuation { promise in
            
            switch promise.futureState {
            case .error(Failed.attempt(6)):
                asyncExpectation1.fulfill()
            default:
                XCTFail()
            }
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseCanBeDelayedBetweenRetries() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        
        var startTime: Date?
        
        var attempt = 0
        let fail3Times = FailThenSucceed(numberOfTimesToFail: 3)
        
        let promise = Promise<Void>(executionBlock: { promise in
            
            if startTime == nil {
                startTime = Date()
            }
            
            let didSucceed = fail3Times.tryToSucceed()
            
            if didSucceed {
                promise.futureState = .result()
            } else {
                attempt = attempt + 1
                promise.futureState = .error(Failed.attempt(attempt))
            }
        })
        
        promise.retryCount = 3
        promise.retryDelay = 0.5
        promise.await().continuation { promise in
            
            defer {
                asyncExpectation1.fulfill()
            }
            
            guard let startTime = startTime else {
                XCTFail()
                return
            }
            
            switch promise.futureState {
            case .result():
                
                // It should have teken about 1.5 seconds
                // Try 1 -> Wait 0.5s -> Retry 1 -> Wait 0.5s -> Retry 2 -> Wait 0.5s -> Retry 3 -> Success = 1.5s
                let elasedTime = -startTime.timeIntervalSinceNow // This would be negative, invert it to make more sense
                
                if elasedTime > 1.1 && elasedTime < 1.9 {
                    XCTAssertEqual(attempt, 3)
                } else {
                    XCTFail()
                }
                
            default:
                XCTFail()
            }
        }
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testPromiseCanBeCancelledBeforeRetry() {
        
        let asyncExpectation1 = expectation(description: "Await execution")
        
        var attempt = 0
        let fail3Times = FailThenSucceed(numberOfTimesToFail: 3)
        
        let promise = Promise<Void>(executionBlock: { promise in
            
            let didSucceed = fail3Times.tryToSucceed()
            
            if didSucceed {
                promise.futureState = .result()
            } else {
                attempt = attempt + 1
                promise.futureState = .error(Failed.attempt(attempt))
            }
        })
        
        // Promise will take about 4.5 seconds
        promise.retryCount = 3
        promise.retryDelay = 1.5
        promise.await().continuation { promise in
            
            defer {
                asyncExpectation1.fulfill()
            }
            
            switch promise.futureState {
            case .cancelled: break
            default: XCTFail()
            }
        }
        
        // Cancel after 1 second
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1.0) { 
            promise.cancel()
        }
        
        // Wait up to 3 seconds
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
}
