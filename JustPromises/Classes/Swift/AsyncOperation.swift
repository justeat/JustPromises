//
//  AsyncOperation.swift
//  JUSTEAT
//
//  Created by Keith Moon on 29/08/2016.
//  Copyright © 2016 JUST EAT. All rights reserved.
//

import Foundation

/**
 *  AsyncOperation
 *
 *  - abstract   Operation subclass to assist with running asynchronously.
 *  - discussion A abstract subclass of NSOperation that handles the KVO reporting involved in implementing an asynchronous operation.
 *               In abject conforming to OperationObserver can be provided, which will get called as the operation transition through it's execution lifecycle events.
 *               AsyncOperation should be subclassed, not used directly. Subclasses should override start() without calling super.
 *               Subclasses are reasonable for calling didStart() and didFinish() as appropriate, to ensure state is updated and observers are informed.
 */
open class AsyncOperation: Operation {
    
    // MARK: - State Reporting
    
    enum KeyPath: String {
        case isExecuting = "isExecuting"
        case isFinished = "isFinished"
        case isCancelled = "isCancelled"
    }
    
    fileprivate enum ExecutionState {
        case initial, executing, cancelled, finished
    }
    
    fileprivate var _executionState: ExecutionState = .initial
    
    fileprivate var executionState: ExecutionState {
        get {
            var state: ExecutionState = .initial
            objc_sync_enter(self)
            state = self._executionState
            objc_sync_exit(self)
            return state
        }
        set(newState) {
            
            let oldState = executionState
            guard canTransitionFromState(from: oldState, toState: newState) else {
                return
            }
            objc_sync_enter(self)
            triggerWillKVOFromState(from: oldState, toState: newState)
            self.transitionFromState(from: oldState, toState: newState)
            triggerDidKVOFromState(from: oldState, toState: newState)
            objc_sync_exit(self)
        }
    }
    
    fileprivate func triggerWillKVOFromState(from oldState: ExecutionState, toState newState: ExecutionState) {
        
        switch newState {
        case .executing:
            willChangeValue(forKey: KeyPath.isExecuting.rawValue)
        case .cancelled:
            if oldState == .executing {
                willChangeValue(forKey: KeyPath.isExecuting.rawValue)
            }
            willChangeValue(forKey: KeyPath.isCancelled.rawValue)
            willChangeValue(forKey: KeyPath.isFinished.rawValue)
        case .finished:
            if oldState == .executing {
                willChangeValue(forKey: KeyPath.isExecuting.rawValue)
            }
            willChangeValue(forKey: KeyPath.isFinished.rawValue)
        case .initial:
            return
        }
    }
    
    fileprivate func triggerDidKVOFromState(from oldState: ExecutionState, toState newState: ExecutionState) {
        
        switch newState {
        case .executing:
            didChangeValue(forKey: KeyPath.isExecuting.rawValue)
        case .cancelled:
            if oldState == .executing {
                didChangeValue(forKey: KeyPath.isExecuting.rawValue)
            }
            didChangeValue(forKey: KeyPath.isCancelled.rawValue)
            didChangeValue(forKey: KeyPath.isFinished.rawValue)
        case .finished:
            if oldState == .executing {
                didChangeValue(forKey: KeyPath.isExecuting.rawValue)
            }
            didChangeValue(forKey: KeyPath.isFinished.rawValue)
        case .initial:
            return
        }
        
    }
    
    fileprivate func canTransitionFromState(from oldState: ExecutionState, toState newState: ExecutionState) -> Bool {
        
        switch (oldState, newState) {
            
        case (let oldState, let newState) where oldState == newState:
            return false
            
        case (_, .initial),
             (.finished, _),
             (.cancelled, _):
            return false
            
        default:
            return true
        }
    }
    
    fileprivate func transitionFromState(from oldState: ExecutionState, toState newState: ExecutionState) {
        
        switch newState {
        case .executing:
            self._executionState = .executing
        case .cancelled:
            self._executionState = .cancelled
        case .finished:
            self._executionState = .finished
        case .initial:
            return
        }
    }
    
    override open var isAsynchronous: Bool {
        return true
    }
    
    override open var isExecuting: Bool {
        return self.executionState == .executing
    }
    
    override open var isFinished: Bool {
        return self.executionState == .cancelled || self.executionState == .finished
    }
    
    override open var isCancelled: Bool {
        return self.executionState == .cancelled
    }
    
    // MARK: - Execution
    
    override open func start() {
        guard !isCancelled && !isFinished else {
            return
        }
        self.executionState = .executing
        execute()
    }
    
    /**
     Subclasses should override execute() and begin it's asynchronous work within it's implementation. Subclasses should not implement start(), as it's implementation in AsyncOperations handles state transition.
     */
    open func execute() {
        fatalError("Should be overriden by subclass")
    }
    
    // MARK: - Finishing
    
    open func finish() {
        self.executionState = .finished
    }
    
    // MARK: - Cancellation
    
    override open func cancel() {
        self.executionState = .cancelled
    }
}
