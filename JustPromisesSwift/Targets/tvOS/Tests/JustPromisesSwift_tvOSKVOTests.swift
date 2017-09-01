//
//  JustPromisesSwift_iOSKVOTests.swift
//  JustPromises
//
//  Created by Keith Moon [Contractor] on 2/27/17.
//  Copyright © 2017 JUST EAT. All rights reserved.
//

import XCTest
import Dispatch
import JustPromisesSwift_tvOS

class TrivialOperation: AsyncOperation {
    
    override func execute() {
        DispatchQueue.main.async { [weak self] in
            self?.finish()
        }
    }
}

class JustPromisesSwift_tvOSKVOTests: XCTestCase {
    
    var promiseQueue: OperationQueue!
    var operationQueue: OperationQueue!
    
    override func setUp() {
        super.setUp()
        promiseQueue = OperationQueue()
        operationQueue = OperationQueue()
    }
    
    override func tearDown() {
        promiseQueue = nil
        operationQueue = nil
        super.tearDown()
    }
    
    func testKVOPromiseCanObserveQueueOperationCount() {
        
        let asyncExpectation = expectation(description: "Queue empty")
        
        operationQueue.isSuspended = true
        
        let op1 = TrivialOperation()
        let op2 = TrivialOperation()
        let op3 = TrivialOperation()
        let op4 = TrivialOperation()
        let op5 = TrivialOperation()
        
        operationQueue.addOperations([op1, op2, op3, op4, op5], waitUntilFinished: false)
        
        XCTAssertEqual(operationQueue.operationCount, 5)
        
        let kvoPromise = KVOPromise<Void, OperationQueue>(objectToObserve: operationQueue, forKeyPath: "operationCount", options: [.new]) { (object, changeDictionary, promise) in
            
            if object.operationCount == 0 {
                promise.futureState = .result()
                asyncExpectation.fulfill()
            }
        }
        
        kvoPromise.await(onQueue: promiseQueue)
        
        // Start queue
        operationQueue.isSuspended = false
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
}
