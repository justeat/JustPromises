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
/// - Error:      There is an error, associated value is the error
/// - Cancelled:  The promise was cancelled
public enum FutureState<FutureType> {
    case unresolved
    case result(FutureType)
    case error(Error)
    case cancelled
    
    public var result: FutureType? {
        switch self {
        case .result(let result): return result
        default: return nil
        }
    }
    
    public var error: Error? {
        switch self {
        case .error(let error): return error
        default: return nil
        }
    }
}

public let sharedPromiseQueue = OperationQueue()


/// A promise to fulfill try and fulfill a future value.
/// Built onto of Operations, so can be combined with other operations,
/// added to queues and used as a dependancy.
open class Promise<FutureType>: AsyncOperation {
    
    fileprivate var executionBlock: (Promise<FutureType>) -> Void
    
    /// The state of the promise that will potentially contain the fulfilled future
    public var futureState: FutureState<FutureType> = .unresolved {
        didSet {
            switch (futureState, retryCount) {
                
            case (.error(_), let retriesRemaining) where retriesRemaining > 0:
                retryCount = retryCount - 1
                retry()
                
            case (.error(_), _), (.result(_), _):
                finish()
                
            default:
                break
            }
        }
    }
    
    // MARK: Lifecycle
    
    /// Create a promise with an execution block.
    ///
    /// - parameter executionBlock: Execution block that will fulfill the futureState of the Promise. Ensure that you update the futureState as part of this execution.
    ///
    /// - returns: A Promise, that has not been put on a queue. Call await() or awaitOnMainQueue() to enqueue
    public init(executionBlock: @escaping (Promise<FutureType>) -> Void) {
        self.executionBlock = executionBlock
        super.init()
    }
    
    /// Create a promise with the given future state. Useful if you are continuing from a previous promise that has failed.
    ///
    /// - parameter immediateFutureState: The future state to immediately set on the Promise.
    ///
    /// - returns: A Promise, that has not been put on a queue. Call await() or awaitOnMainQueue() to enqueue
    public convenience init(immediateFutureState state: FutureState<FutureType>) {
        self.init(executionBlock: { promise in
            promise.futureState = state
        })
    }
    
    // MARK: Start/Stop
    
    /// Cannot be overriden. This will fire the execution block.
    override final public func execute() {
        executionBlock(self)
    }
    
    /// Will cancel the promise
    open override func cancel() {
        timer?.invalidate()
        timer = nil
        super.cancel()
        futureState = .cancelled
    }
    
    // MARK: Retrying
    
    // Number of times to retry if error. Promise will retry until result or retries runout, in which case the
    // last error is returned.
    public var retryCount: UInt = 0
    
    // Amount to delay a retry, if nil, retry will be executed immediately.
    public var retryDelay: TimeInterval?
    private var timer: Timer?
    
    private func retry() {
        
        // If there is a retry delay, only retry when the timer fires, otherwise, retry immediately
        if let retryDelay = retryDelay, timer == nil {
            let retryTimer = Timer(timeInterval: retryDelay, target: self, selector: #selector(timerFired(sender:)), userInfo: nil, repeats: false)
            timer = retryTimer
            RunLoop.main.add(retryTimer, forMode: RunLoopMode.defaultRunLoopMode)
        } else {
            execute()
        }
    }
    
    @objc func timerFired(sender: Timer) {
        sender.invalidate()
        timer = nil
        execute()
    }
}

extension Promise {
    
    /// The promise will be added to the given queue.
    ///
    /// - parameter queue: The queue to await the promise on.
    ///
    /// - returns: The same promise will be returned, allowing chaining.
    @discardableResult
    public func await(onQueue queue: OperationQueue = sharedPromiseQueue) -> Promise<FutureType> {
        queue.addOperation(self)
        return self
    }
    
    /// The promise will be added to the main queue.
    ///
    /// - returns: The same promise will be returned, allowing chaining.
    @discardableResult
    public func awaitOnMainQueue() -> Promise<FutureType>  {
        return await(onQueue: .main)
    }
}

extension Promise {
    
    /// Continue after this Promise with another Promise
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining.
    @discardableResult
    public func continuation<NextFutureType>(onQueue queue: OperationQueue = sharedPromiseQueue, withBlock executionBlock: (Promise<FutureType>) -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        
        let nextPromise = executionBlock(self)
        nextPromise.addDependency(self)
        queue.addOperation(nextPromise)
        return nextPromise
    }
    
    /// Continue after this Promise if it has a result, passing through the future state for further chaining
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: A block to handle the result of the promise
    ///
    /// - returns: The next Promise, with the same future state as the previous Promise. Allows further chaining.
    @discardableResult
    public func continuationWithResult(onQueue queue: OperationQueue = sharedPromiseQueue, withBlock executionBlock: @escaping (FutureType) -> Void) -> Promise<FutureType> {
        
        let nextPromise = Promise<FutureType> { [weak self] promise in
            
            guard let strongSelf = self else { return }
            
            // If we have a result, execute the block, otherwise inherit the previous promise's state
            switch strongSelf.futureState {
                
            case .result(let result):
                executionBlock(result)
                promise.futureState = .result(result)
                
            case .cancelled:
                promise.futureState = .cancelled
                
            case .unresolved:
                promise.futureState = .unresolved
                
            case .error(let error):
                promise.futureState = .error(error)
            }
        }
        nextPromise.addDependency(self)
        queue.addOperation(nextPromise)
        return nextPromise
    }
    
    /// Continue after this Promise if it has an error, passing through the future state for further chaining
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to create and return the next Promise, which is given the error of the previous Promise
    ///
    /// - returns: The next Promise, with the same future state as the previous Promise. Allows further chaining.
    @discardableResult
    public func continuationWithError(onQueue queue: OperationQueue = sharedPromiseQueue, withBlock executionBlock: @escaping (Error) -> Void) -> Promise<FutureType> {
        
        let nextPromise = Promise<FutureType> { [weak self] promise in
            
            guard let strongSelf = self else { return }
            
            // If we have a result, execute the block, otherwise inherit the previous promise's state
            switch strongSelf.futureState {
                
            case .result(let result):
                promise.futureState = .result(result)
                
            case .cancelled:
                promise.futureState = .cancelled
                
            case .unresolved:
                promise.futureState = .unresolved
                
            case .error(let error):
                executionBlock(error)
                promise.futureState = .error(error)
            }
        }
        nextPromise.addDependency(self)
        queue.addOperation(nextPromise)
        return nextPromise
    }
    
    /// Continue after this Promise with a given block
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to execute after this Promise, which is given the previous Promise
    public func continuation(onQueue queue: OperationQueue = sharedPromiseQueue, withBlock executionBlock: @escaping (Promise<FutureType>) -> Void) {
        
        let blockOperation = BlockOperation { [weak self] in
            guard let strongSelf = self else { return }
            executionBlock(strongSelf)
        }
        blockOperation.addDependency(self)
        queue.addOperation(blockOperation)
    }
}

extension Array where Element: Operation {
    
    /// Continue after all these operations are finished with a Promise
    ///
    /// - parameter queue:          The queue to continue on
    /// - parameter executionBlock: The block to create and return the next Promise
    ///
    /// - returns: The next created Promise, allows chaining
    @discardableResult
    public func continuation<NextFutureType>(onQueue queue: OperationQueue = sharedPromiseQueue, withBlock executionBlock: () -> Promise<NextFutureType>) -> Promise<NextFutureType> {
        
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
    public func continuation(onQueue queue: OperationQueue = sharedPromiseQueue, withBlock executionBlock: @escaping () -> Void) {
        
        let blockOperation = BlockOperation(block: executionBlock)
        for operation in self {
            blockOperation.addDependency(operation)
        }
        queue.addOperation(blockOperation)
    }
}
