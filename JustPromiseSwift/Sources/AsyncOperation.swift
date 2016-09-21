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
public class AsyncOperation: NSOperation {
    
    // MARK: - State Reporting
    
    enum KeyPath: String {
        case isExecuting = "isExecuting"
        case isFinished = "isFinished"
        case isCancelled = "isCancelled"
    }
    
    private enum ExecutionState {
        case Initial, Executing, Cancelled, Finished
    }
    
    private var _executionState: ExecutionState = .Initial
    
    private var executionState: ExecutionState {
        get {
            var state: ExecutionState = .Initial
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
    
    private func triggerWillKVOFromState(from oldState: ExecutionState, toState newState: ExecutionState) {
        
        switch newState {
        case .Executing:
            willChangeValueForKey(KeyPath.isExecuting.rawValue)
        case .Cancelled:
            if oldState == .Executing {
                willChangeValueForKey(KeyPath.isExecuting.rawValue)
            }
            willChangeValueForKey(KeyPath.isCancelled.rawValue)
            willChangeValueForKey(KeyPath.isFinished.rawValue)
        case .Finished:
            if oldState == .Executing {
                willChangeValueForKey(KeyPath.isExecuting.rawValue)
            }
            willChangeValueForKey(KeyPath.isFinished.rawValue)
        case .Initial:
            return
        }
    }
    
    private func triggerDidKVOFromState(from oldState: ExecutionState, toState newState: ExecutionState) {
        
        switch newState {
        case .Executing:
            didChangeValueForKey(KeyPath.isExecuting.rawValue)
        case .Cancelled:
            if oldState == .Executing {
                didChangeValueForKey(KeyPath.isExecuting.rawValue)
            }
            didChangeValueForKey(KeyPath.isCancelled.rawValue)
            didChangeValueForKey(KeyPath.isFinished.rawValue)
        case .Finished:
            if oldState == .Executing {
                didChangeValueForKey(KeyPath.isExecuting.rawValue)
            }
            didChangeValueForKey(KeyPath.isFinished.rawValue)
        case .Initial:
            return
        }
        
    }
    
    private func canTransitionFromState(from oldState: ExecutionState, toState newState: ExecutionState) -> Bool {
        
        switch (oldState, newState) {
            
        case (let oldState, let newState) where oldState == newState:
            return false
            
        case (_, .Initial),
             (.Finished, _),
             (.Cancelled, _):
            return false
            
        default:
            return true
        }
    }
    
    private func transitionFromState(from oldState: ExecutionState, toState newState: ExecutionState) {
        
        switch newState {
        case .Executing:
            self._executionState = .Executing
        case .Cancelled:
            self._executionState = .Cancelled
        case .Finished:
            self._executionState = .Finished
        case .Initial:
            return
        }
    }
    
    override public var asynchronous: Bool {
        return true
    }
    
    override public var executing: Bool {
        return self.executionState == .Executing
    }
    
    override public var finished: Bool {
        return self.executionState == .Cancelled || self.executionState == .Finished
    }
    
    override public var cancelled: Bool {
        return self.executionState == .Cancelled
    }
    
    // MARK: - Execution
    
    override public func start() {
        guard !cancelled && !finished else {
            return
        }
        self.executionState = .Executing
        execute()
    }
    
    /**
     Subclasses should override execute() and begin it's asynchronous work within it's implementation. Subclasses should not implement start(), as it's implementation in AsyncOperations handles state transition.
     */
    public func execute() {
        fatalError("Should be overriden by subclass")
    }
    
    // MARK: - Finishing
    
    public func finish() {
        self.executionState = .Finished
    }
    
    // MARK: - Cancellation
    
    override public func cancel() {
        self.executionState = .Cancelled
    }
}
