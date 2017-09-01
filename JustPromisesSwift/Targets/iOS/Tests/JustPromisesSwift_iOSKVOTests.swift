//
//  JustPromisesSwift_iOSKVOTests.swift
//  JustPromises
//
//  Created by Keith Moon [Contractor] on 2/27/17.
//  Copyright © 2017 JUST EAT. All rights reserved.
//

import XCTest
import Dispatch
import JustPromisesSwift_iOS

class TrivialOperation: AsyncOperation {
    
    override func execute() {
        DispatchQueue.main.async { [weak self] in
            self?.finish()
        }
    }
}

class JustPromisesSwift_iOSKVOTests: XCTestCase {
    
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
        
        let asyncExpectation0 = expectation(description: "Queue empty")
        let asyncExpectation1 = expectation(description: "Queue empty")
        let asyncExpectation2 = expectation(description: "Queue empty")
        let asyncExpectation3 = expectation(description: "Queue empty")
        let asyncExpectation4 = expectation(description: "Queue empty")
        
        operationQueue.isSuspended = true
        
        let op1 = TrivialOperation()
        let op2 = TrivialOperation()
        let op3 = TrivialOperation()
        let op4 = TrivialOperation()
        let op5 = TrivialOperation()
        
        operationQueue.addOperations([op1, op2, op3, op4, op5], waitUntilFinished: false)
        
        XCTAssertEqual(operationQueue.operationCount, 5)
        
        let kvoPromise = KVOPromise<Void, OperationQueue>(objectToObserve: operationQueue, forKeyPath: "operationCount", options: [.new]) { (object, changeDictionary, promise) in
            
            switch object.operationCount {
                
            case 4:
                asyncExpectation4.fulfill()
                
            case 3:
                asyncExpectation3.fulfill()
                
            case 2:
                asyncExpectation2.fulfill()
                
            case 1:
                asyncExpectation1.fulfill()
                
            case 0:
                promise.futureState = .result()
                asyncExpectation0.fulfill()
                
            default: break
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
