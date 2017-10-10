//
//  JustPromisesSwift_iOSArrayTests.swift
//  JustPromisesSwift_iOSTests
//
//  Created by Keith Moon [Contractor] on 2/10/17.
//  Copyright © 2017 JUST EAT. All rights reserved.
//

import XCTest
import JustPromises
import Dispatch
import Foundation

class DelayedOperation: AsyncOperation {
    
    var complete: Bool = false
    let queue = DispatchQueue(label: UUID().uuidString)
    
    override func execute() {
        
        queue.async { [weak self] in
            self?.complete = true
            self?.finish()
        }
    }
    
}

class ArrayTests: XCTestCase {
    
    var operations: [Operation]!
    var queue: OperationQueue!
    var promise: Promise<Void>!
    
    override func setUp() {
        super.setUp()
        queue = OperationQueue()
    }
    
    override func tearDown() {
        super.tearDown()
        operations = nil
        queue = nil
        promise = nil
    }
    
    func testArrayOfOperationsCanBeContinuedWithPromise() {
        
        let expection = expectation(description: "Await outcome of operations")
        
        let operation1 = DelayedOperation()
        let operation2 = DelayedOperation()
        let operation3 = DelayedOperation()
        let operation4 = DelayedOperation()
        let operation5 = DelayedOperation()
        
        operations = [operation1, operation2, operation3, operation4, operation5]
        
        promise = operations.continuation { () -> Promise<Void> in
            return Promise { promise in
                
                XCTAssertTrue(operation1.complete)
                XCTAssertTrue(operation2.complete)
                XCTAssertTrue(operation3.complete)
                XCTAssertTrue(operation4.complete)
                XCTAssertTrue(operation5.complete)
                
                promise.futureState = .result()
                
                expection.fulfill()
            }
        }
        
        // Start operations
        queue.addOperations(operations, waitUntilFinished: false)
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
    func testArrayOfOperationsCanBeContinuedWithBlock() {
        
        let expection = expectation(description: "Await outcome of operations")
        
        let operation1 = DelayedOperation()
        let operation2 = DelayedOperation()
        let operation3 = DelayedOperation()
        let operation4 = DelayedOperation()
        let operation5 = DelayedOperation()
        
        operations = [operation1, operation2, operation3, operation4, operation5]
        
        operations.continuation { 
            
            XCTAssertTrue(operation1.complete)
            XCTAssertTrue(operation2.complete)
            XCTAssertTrue(operation3.complete)
            XCTAssertTrue(operation4.complete)
            XCTAssertTrue(operation5.complete)
            
            expection.fulfill()
        }
        
        // Start operations
        queue.addOperations(operations, waitUntilFinished: false)
        
        waitForExpectations(timeout: 3.0) { error in
            XCTAssertNil(error)
        }
    }
    
}
