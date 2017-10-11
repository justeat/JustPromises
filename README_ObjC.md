# JustPromises

![](./logo.png)

A lightweight and thread-safe implementation of Promises & Futures in Objective-C for iOS and OS X with 100% code coverage.

# Overview

A Promise represents the future value of an asynchronous task. It can be intended as an object that acts as a proxy for a result that is initially unknown, usually because the computation of its value is yet incomplete.

Asynchronous tasks can succeed, fail or be cancelled and the resolution is reflected to the promise object.

Promises are useful to standardize the API of asynchronous operations. They help both to clean up asynchronous code paths and simplify error handling.

The main features of JustPromises for Objective-C are listed below.

1. Fully unit-tested and documented
2. Thread-safe
3. Clean interface
4. Support for chaining
5. Support for progress
6. Support for cancellation
7. Queue-based block execution if needed

More information at [the Wikipedia page](http://en.wikipedia.org/wiki/Futures_and_promises).


## Importing

To import just the Objective-C version of JustPromises, in your Podfile:
```
pod 'JustPromises/Objective-C'
```

In your .m files:
```
#import "JustPromises.h"
```

## Usage of JEPromise and JEFuture

Please refer to the demo project to have an idea of how to use this component.


### API Overview

In our terminology, a `task` is intended to represent an asynchronous operation.

These methods set the continuation on the future providing a block and return the subsequent future.
The block in the 'success' versions is called only when the previos future in the chain has a result (i.e. doesn't fail or is not cancelled).

The followings should be used for asynchronous operations that return a future straightaway.
The block parameter returns the future, representing the async operation.

``` objective-c
- (JEFuture *)continueWithTask:(JEFuture *(^)(JEFuture *fut))task;
- (JEFuture *)continueWithSuccessTask:(JEFuture *(^)(id result))successTask;
```

Versions with the ability to specify the queue
``` objective-c
- (JEFuture *)continueOnQueue:(dispatch_queue_t)queue withTask:(JETask)task;
- (JEFuture *)continueOnQueue:(dispatch_queue_t)queue withSuccessTask:(JESuccessTask)successTask;
```

In version 2.0 of the library we added support for the dot-notation to allow a nicer and a more square bracket-free code.

```objective-c
- (void (^)(JEContinuation))continues;
- (void (^)(JEContinuation))continueOnMainQueue;
- (void (^)(dispatch_queue_t q, JEContinuation))continueOnQueue;

- (JEFuture* (^)(JETask task))continueWithTask;
- (JEFuture* (^)(JETask task))continueWithTaskOnMainQueue;
- (JEFuture* (^)(dispatch_queue_t q, JETask task))continueWithTaskOnQueue;

- (JEFuture* (^)(JESuccessTask task))continueWithSuccessTask;
- (JEFuture* (^)(JESuccessTask task))continueWithSuccessTaskOnMainQueue;
- (JEFuture* (^)(dispatch_queue_t q, JESuccessTask task))continueWithSuccessTaskOnQueue;
```

### Wrapping an asynchronous API

By nature, futures are very useful when they wrap asynchronous operation rather than synchronous ones.
Here is an example of how to wrap an existing asynchronous API.

``` objective-c
- (JEFuture *)wrappedAsyncMethod
{
    JEPromise *p = [JEPromise new];
    [SomeClass asyncMethodWithCompletionHandler:^(id result, NSError *error) {
        if (error) {
            [p setError:error];
        }
        else {
            [p setResult:result];
        }
    }];
    return [p future];
}
```

Consider the task of retrieving information from a remote API. It can be broken down into the following sequence of operations:

1. Download JSON content.
2. Parse the content.
3. Save the content to disk.

All the operations are asynchronous.

Here is an example of chaining the operations.

``` objective-c
__weak typeof(self) weakSelf = self;
NSURLRequest *request = ...

[self downloadJSONWithRequest:request] continueOnQueue:queue
                                       withSuccessTask:^JEFuture *(NSData *jsonData) {
    return [weakSelf parseJSON:jsonData];
}];
```

Here we continue the chaining setting the continuation providing the result of the previous future

``` objective-c
...] continueWithSuccessTask:^JEFuture *(NSDictionary *jsonDict) {
    return [weakSelf saveToDisk:jsonDict];
}];
```

Here we set the continuation, executed either way, acts as a finally block.

``` objective-c
...] onQueue:mainQueue setContinuation:^(JEFuture *fut) {
    if ([fut hasError]) {
        NSLog(@"Something failed along the way with error: %@", [[fut error] description]);
    }

    // code that need to be executed either way
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
}];
```

or if you like it, in the dot-notation flavour:

``` objective-c
__weak typeof(self) weakSelf = self;
NSURLRequest *request = ...

[self downloadJSONWithRequest:request].continueWithSuccessTaskOnQueue(queue, ^JEFuture* (NSData *jsonData) {
    return [weakSelf parseJSON:jsonData];
}).continueWithSuccessTask(^JEFuture* (NSDictionary *jsonDict) {
    return [weakSelf saveToDisk:jsonDict];
}).continueOnMainQueue(^(JEFuture *fut) {
    if ([fut hasError]) {
        NSLog(@"Something failed along the way with error: %@", [[fut error] description]);
    }
    [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
});
```

Generally, you should avoid to store future objects in local variables. Doing so, it would make the chaining less explicit and it would be too easy to set multiple continuations on the same future (which will cause assertion to fail).

Here is the implementation for `downloadJSONWithRequest:`. Check the demo project for the implementations of `parseJSON:` and `saveToDisk:`, they are similar to the one below.

``` objective-c
- (JEFuture *)downloadJSONWithRequest:(NSURLRequest *)request
{
    JEPromise *p = [JEPromise new];

    NSURLSessionDataTask *fetchDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!error) {
            if (data) {
                [p setResult:data];
            }
            else {
                NSError *errorToUse = [NSError errorWithDomain:kPromisesDemoErrorDomain
                                                          code:0
                                                      userInfo:@{NSLocalizedDescriptionKey: @"Data received is nil."}];
                [p setError:errorToUse];
            }
        }
        else {
            [p setError:error];
        }
    }];

    [fetchDataTask resume];

    return [p future];
}
```  


### whenAll:

The `whenAll:` class method returns a future that is resolved only when all the passed in futures are resolved. Once this method is called, it's not possible to add further continuations to the futures passed in.
This is particularly useful when dealing with different tasks that have dependencies between each other or in cases that lead to the usage of GCD's `dispatch_group()` to synchronize tasks.

Here is an example:

``` objective-c
JEPromise *p1 = [JEPromise new];
JEPromise *p2 = [JEPromise new];
JEPromise *p3 = [JEPromise new];

NSArray *futures = @[p1.future, p2.future, p3.future];

[self downloadJSONWithRequest:... ];

JEFuture *allFuture = [JEFuture whenAll:futures];

dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    // pretend this is a succeeding network operation
    [p1 setResult:[NSData data]];
});

dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    // pretend this is an failing network operation
    NSError *error = [NSError errorWithDomain:...];
    [p2 setError:error];
});

dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
    // pretend this is a cancelled network operation
    [p3 setCancelled];
});

// this call will hang until all the futures are resolved
NSArray *results = [allFuture result];

for (JEFuture *future in results) {
    NSLog(@"%ld", (long)[future state]);
}

// will print
// JEFutureStateResolvedWithResult
// JEFutureStateResolvedWithError
// JEFutureStateResolvedWithCancellation
// JEFutureStateResolvedWithResult or JEFutureStateResolvedWithError depending on how downloadJSONWithRequest: goes
```

## Usage of JEProgress

`JEProgress` helps tracking the progress of asynchronous tasks. It provides a progress description, the completed unit count out of total and a state.

``` objective-c

JEProgress *p = [JEProgress new];

[p setCancellationHandler:^(id<JECancellableProgressProtocol> progress) {
    // called when the progress is cancelled
}];

[p setProgressHandler:^(JEProgress *progress) {
    // called on progress update
}];

[p setProgressDescriptionHandler:^(JEProgress *progress) {
    // called when the description is updated
}];

```

You usually use this object in asynchronous operations like so:

``` objective-c

JEProgress *p = [JEProgress new];

[p updateState:JERequestStateNetworkRequestStarted];

[self downloadWithProgress:^(NSUInteger bytesWritten, NSUInteger totalBytes, NSError *error) {
    if (!error) {
        [p updateCompletedUnitCount:bytesWritten total:totalBytes];

        if (bytesWritten < totalBytes) {
            [p updateProgressDescription:@"Downloading..."];
        }
        else {
            [p updateState:JERequestStateNetworkRequestComplete];
            [p updateProgressDescription:@"Download completed!"];
        }
    }
    else {
        [p updateState:JERequestStateNetworkRequestFailed];
    }
}];

```

## Other implementations

These are some third-party libraries mainly used by the community.

- [PromiseKit](http://promisekit.org/)
- [Bolts-iOS](https://github.com/BoltsFramework/Bolts-iOS) (not only promises)
- [RXPromise](https://github.com/couchdeveloper/RXPromise)


## Contributing

We've been adding things ONLY as they are needed, so please feel free to either bring up suggestions or to submit pull requests with new GENERIC functionalities.

Don't bother submitting any breaking changes or anything without unit tests against it. It will be declined.

## Licence

JustPromises is released under the Apache 2.0 License.

- Just Eat iOS team
