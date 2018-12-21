![](JustPromises_logo.jpg)

### Warning: This library is not supported anymore by Just Eat and therefore considered deprecated. For Swift code, instead of JustPromises, the Just Eat iOS team adopted [Promis](https://github.com/albertodebortoli/promis).

A lightweight and thread-safe implementation of Promises & Futures in both Objective-C for iOS, macOS, watchOS and tvOS with 100% code coverage.


# Overview

A Promise represents the future value of an asynchronous task. It can be intended as an object that acts as a proxy for a result that is initially unknown, usually because the computation of its value is yet incomplete.

Asynchronous tasks can succeed, fail or be cancelled and the resolution is reflected to the promise object.

Promises are useful to standardize the API of asynchronous operations. They help both to clean up asynchronous code paths and simplify error handling.


## Installing via Cocoapods

To import JustPromises, in your Podfile:
```
pod 'JustPromises'
```


## Usage

Latest version of JustPromises is Objective-C only and removes the previous Swift version. [Further details in the Objective-C specific README](README_ObjC.md)


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

