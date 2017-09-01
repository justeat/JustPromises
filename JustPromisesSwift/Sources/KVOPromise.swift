//
//  File.swift
//  JustPromises
//
//  Created by Keith Moon [Contractor] on 2/24/17.
//  Copyright © 2017 JUST EAT. All rights reserved.
//

import Foundation

/// A promise to fulfill try and fulfill a future value, which respect to a KVO keypath.
open class KVOPromise<FutureType, ObservingType: NSObject>: Promise<FutureType> {
    
    open weak var objectToObserve: ObservingType?
    open var keyPath: String
    open var options: NSKeyValueObservingOptions
    open var context: UnsafeMutableRawPointer?
    open var observeBlock: (ObservingType, [NSKeyValueChangeKey : Any], Promise<FutureType>) -> Void
    
    /// Create a promise to perform Key-Value Observing.
    /// 
    /// - parameter objectToObserve: The object to observe
    /// - parameter forKeyPath: The keypath to observe
    /// - parameter options: The KVO options to use
    /// - parameter context: Optional context for KVO
    /// - parameter observeBlock: Block that receives the observed object, the change dictionary and a reference to the promise. 
    ///                           This fires whenever there is a change to the keypath in line with provided options. 
    ///                           Block should eventually fulfill the futureState of the Promise.
    ///
    /// - returns: A Promise, that has not been put on a queue. Call await() or awaitOnMainQueue() to enqueue
    public init(objectToObserve object: ObservingType,
         forKeyPath keyPath: String,
         options: NSKeyValueObservingOptions,
         context: UnsafeMutableRawPointer? = nil,
         observeBlock:@escaping (ObservingType, [NSKeyValueChangeKey : Any], Promise<FutureType>) -> Void) {
        
        self.objectToObserve = object
        self.keyPath = keyPath
        self.options = options
        self.context = context
        self.observeBlock = observeBlock
        
        super.init() { promise in
            object.addObserver(promise, forKeyPath: keyPath, options: options, context: context)
        }
    }
    
    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        
        if let providedContext = self.context, providedContext != context {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }
        
        guard
            let providedObject = objectToObserve,
            let triggeredObject = object as? ObservingType,
            providedObject == triggeredObject,
            let triggeredKeyPath = keyPath,
            self.keyPath == triggeredKeyPath,
            let changeDictionary = change
            else {
                print("Sending to Super: KeyPath: \(keyPath), Object: \(object), Change: \(change), Context: \(context)")
                super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
                return
        }
        
        observeBlock(triggeredObject, changeDictionary, self)
    }
    
    open override func finish() {
        objectToObserve?.removeObserver(self, forKeyPath: keyPath, context: context)
        super.finish()
    }
}
