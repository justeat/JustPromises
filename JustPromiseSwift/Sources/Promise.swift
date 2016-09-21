//
//  Promise.swift
//  JustPromises
//
//  Created by Keith Moon on 09/09/2016.
//  Copyright © 2016 JUST EAT. All rights reserved.
//

import Foundation


/// The state of the Promise
///
/// - Unresolved: The promise has let to be resolved
/// - Result:     There is a result, associated value is the result
/// - Error:      There is an erroe, associated value is the error
/// - Cancelled:  The promise was cancelled
public enum FutureState<FutureType> {
    case Unresolved
    case Result(FutureType)
    case Error(ErrorType)
    case Cancelled
}

public let sharedPromiseQueue = NSOperationQueue()


/// A promise to fulfill try and fulfill a future value.
/// Built onto of Operations, so can be combined with other operations,
/// added to queues and used as a dependancy.
public class Promise<FutureType>: AsyncOperation {
    
    private var executionBlock: (Promise<FutureType>) -> Void
    
    /// The state of the promise that will potentially contain the fulfilled future
    public var futureState: FutureState<FutureType> = .Unresolved {
        didSet {
            switch futureState {
            case .Error(_), .Result(_): finish()
            default: break
            }
        }
    }
    
    /// Create a promise with an execution block.
    ///
    /// - parameter executionBlock: Execution block that will fulfill the futureState of the Promise. Ensure that you update the futureState as part of this execution.
    ///
    /// - returns: A Promise, that has not been put on a queue. Call await() or awaitOnMainQueue() to enqueue
    public init(executionBlock: (Promise<FutureType>) -> Void) {
        self.executionBlock = executionBlock
        super.init()
    }
    
    /// Should not be called directly. This will fire the execution block.
    override public func execute() {
        executionBlock(self)
    }
    
    /// Will cancel the promise
    public override func cancel() {
        super.cancel()
        futureState = .Cancelled
    }
}

extension Promise {
    
    
    /// The promise will be added to the given queue.
    ///
    /// - parameter queue: The queue to await the promise on.
    ///
    /// - returns: The same promise will be returned, allowing chaining.
    public func await(onQueue queue: NSOperationQueue = sharedPromiseQueue) -> Promise<FutureType> {
        queue.addOperation(self)
        return self
    }
    
    
    /// The promise will be added to the main queue.
    ///
    /// - returns: The same promise will be returned, allowing chaining.
    public func awaitOnMainQueue() -> Promise<FutureType>  {
        return await(onQueue: .mainQueue())
    }
}

extension Promise {
    
    
    /// Continue after this Promise with another Promise
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining.
    public func continuation<NextFutureType>(onQueue queue: NSOperationQueue = sharedPromiseQueue, withBlock executionBlock: (Promise<FutureType>) -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        
        let nextPromise = executionBlock(self)
        nextPromise.addDependency(self)
        queue.addOperation(nextPromise)
        return nextPromise
    }
    
    /// Continue after this Promise with a given block
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to execute after this Promise
    public func continuation(onQueue queue: NSOperationQueue = sharedPromiseQueue, withBlock executionBlock: (Promise<FutureType>) -> Void) {
        
        let operaton = NSBlockOperation { [weak self] in
            guard let strongSelf = self else { return }
            executionBlock(strongSelf)
        }
        operaton.addDependency(self)
        queue.addOperation(operaton)
    }
    
    /// Continue after this Promise with another Promise on the main queue
    ///
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining.
    public func continuationOnMainQueue<NextFutureType>(withBlock executionBlock: (Promise<FutureType>) -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        return continuation(onQueue: .mainQueue(), withBlock: executionBlock)
    }
    
    /// Continue after this Promise a given block on the main queue
    ///
    /// - parameter executionBlock: The block to execute after this Promise
    public func continuationOnMainQueue(withBlock executionBlock: (Promise<FutureType>) -> Void) {
        continuation(onQueue: .mainQueue(), withBlock: executionBlock)
    }
    
    
    /// Continue after this Promise if it succeeds with another Promise
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining
    public func continuationOnSuccess<NextFutureType>(onQueue queue: NSOperationQueue = sharedPromiseQueue, withBlock executionBlock: (Promise<FutureType>) -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        
        let nextPromise = executionBlock(self)
        
        let existingBlock = nextPromise.executionBlock
        
        nextPromise.executionBlock = { [weak self] promise in
            
            guard let strongSelf = self else { return }
            
            // If we have a result, execute the block, otherwise inherit the previous promise's state
            switch strongSelf.futureState {
            
            case .Result(_):
                existingBlock(promise)
                
            case .Cancelled:
                promise.futureState = .Cancelled
                
            case .Unresolved:
                promise.futureState = .Unresolved
                
            case .Error(let error):
                promise.futureState = .Error(error)
            }
        }
        nextPromise.addDependency(self)
        queue.addOperation(nextPromise)
        return nextPromise
    }
    
    /// Continue after this Promise if it succeeds, with a given block on the given queue
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to execute after this Promise
    public func continuationOnSuccess(onQueue queue: NSOperationQueue = sharedPromiseQueue, withBlock executionBlock: (Promise<FutureType>) -> Void) {
        
        let operaton = NSBlockOperation { [weak self] in
            
            guard let strongSelf = self else { return }
            
            // If we have a result, execute the block, otherwise inherit the previous promise's state
            switch strongSelf.futureState {
            case .Result(_): executionBlock(strongSelf)
            default: break
            }
        }
        operaton.addDependency(self)
        queue.addOperation(operaton)
    }
    
    /// Continue after this Promise if it succeeds with another Promise
    ///
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining
    public func continuationOnSuccessOnMainQueue<NextFutureType>(withBlock executionBlock: (Promise<FutureType>) -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        return continuationOnSuccess(onQueue: .mainQueue(), withBlock: executionBlock)
    }
    
    /// Continue after this Promise if it succeeds, with a given block on the main queue
    ///
    /// - parameter executionBlock: The block to execute after this Promise
    public func continuationOnSuccessOnMainQueue(withBlock executionBlock: (Promise<FutureType>) -> Void) {
        continuationOnSuccess(onQueue: .mainQueue(), withBlock: executionBlock)
    }
}

extension Array where Element: NSOperation {
    
    
    /// Continue after all these operations are finished with a Promise
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining
    public func continuation<NextFutureType>(onQueue queue: NSOperationQueue = sharedPromiseQueue, withBlock executionBlock: () -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        
        let nextPromise = executionBlock()
        for operation in self {
            nextPromise.addDependency(operation)
        }
        queue.addOperation(nextPromise)
        
        return nextPromise
    }
    
    /// Continue after all these operations are finished with a Promise
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to execute after all operations are finished
    public func continuation(onQueue queue: NSOperationQueue = sharedPromiseQueue, withBlock executionBlock: () -> Void) {
        
        let operaton = NSBlockOperation(block: executionBlock)
        for operation in self {
            operation.addDependency(operation)
        }
        queue.addOperation(operaton)
    }
    
    /// Continue after all these operations are finished with a Promise on given queue
    ///
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining
    public func continuationOnMainQueue<NextFutureType>(withBlock executionBlock: () -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        return continuation(onQueue: .mainQueue(), withBlock: executionBlock)
    }
    
    /// Continue after all these operations are finished with a Promise on main queue
    ///
    /// - parameter executionBlock: The block to execute after all operations are finished
    public func continuationOnMainQueue(withBlock executionBlock: () -> Void) {
        continuation(onQueue: .mainQueue(), withBlock: executionBlock)
    }
}
