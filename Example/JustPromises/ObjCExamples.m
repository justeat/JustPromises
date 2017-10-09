//
//  ObjCExamples.m
//  JustPromises
//
//  Created by Alberto De Bortoli on 21/01/2015.
//  Copyright (c) 2015 JUST EAT. All rights reserved.
//

#import "ObjCExamples.h"

@import JustPromises;

typedef NS_ENUM(NSUInteger, JERequestState) {
    JERequestStateNetworkRequestStarted,
    JERequestStateNetworkRequestComplete,
    JERequestStateNetworkRequestFailed,
    JERequestStateNetworkRequestCancelled,
};

static NSString *const kPromisesDemoErrorDomain = @"com.justeat.JUSTPromisesDemo";
static NSString *const kFoursquareBaseURL = @"https://api.foursquare.com/v2/";

static NSString *const kFoursquareApiClientId = @"ED233ZBBNC2IF4VHMAKE1CTARX44OJOGKRTAW34ISQLPT0HE";
static NSString *const kFoursquareApiClientSecret = @"OYPK3LZEXLSDQE1IG4RM5JXBX1D54W0PUCXFJL4CHLCIKU4H";

@interface ObjCExamples ()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation ObjCExamples

#pragma mark - Demo Examples

/**
 *  Following 2 are examples of using future chaining executing the following operations
 *
 *  1. Download JSON content using the request from 1.
 *  2. Parse the content retrieved from 2.
 *  3. Save the content retrieved from 3 to disk.
 *
 *  All the operations are asynchronous.
 */

- (void)runSucceedingExample
{
    __weak typeof(self) weakSelf = self;
    
    /**
     * Progress stuff
     */
    
    JEProgress *progress = [JEProgress new];
    
    [progress setStateHandler:^(JEProgress *progress)
     {
         NSLog(@"%ld", progress.state);
     }];
    
    [progress setProgressDescriptionHandler:^(JEProgress *progress)
    {
        NSLog(@"%@", progress.progressDescription);
    }];
    
    [progress setProgressHandler:^(JEProgress *progress)
    {
        NSLog(@"%ld", progress.state);
    }];
    
    /**
     * Promise stuff
     */

    NSURLRequest *request = [self createRequestWithQueryTerm:@"sushi"];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;

    dispatch_queue_t queue = dispatch_get_main_queue();
    
    // dispatch on the main queue with a success block providing the result of the previous future
    [[[[self downloadJSONWithRequest:request withProgress:progress] continueOnQueue:queue withSuccessTask:^JEFuture *(NSData *jsonData)
       {
           return [weakSelf parseJSON:jsonData];
       }]
      
      // set the continuation providing the result of the previous future
      continueWithSuccessTask:^JEFuture *(NSDictionary *jsonDict)
      {
          return [weakSelf saveToDisk:jsonDict filename:@"results"];
      }]
     
     // set the continuation, executed either way, acts as a finally block
     setContinuation:^(JEFuture *fut)
     {
         if ([fut hasError])
         {
             NSLog(@"Something failed along the way with error: %@", [[fut error] description]);
         }
         
         // code that need to be executed either way
         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
     }];
}

- (void)runFailingExample
{
    __weak typeof(self) weakSelf = self;
    
    NSURLRequest *request = [self createRequestWithQueryTerm:@"sushi"];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    
    dispatch_queue_t queue = dispatch_get_main_queue();
    
    // dispatch on the main queue with a success block providing the result of the previous future
    [[[[self failingdownloadJSONWithRequest:request withProgress:nil] continueOnQueue:queue withSuccessTask:^JEFuture *(NSData *jsonData)
    {
        // this is not called since the previous future failed
        return [weakSelf failingParseJSON:jsonData];
    }]
      
      // set the continuation providing the result of the previous future
      continueWithSuccessTask:^JEFuture *(NSDictionary *jsonDict)
      {
          // same as above, future passed on
          return [weakSelf saveToDisk:jsonDict filename:@"results"];
      }]
     
     setContinuation:^(JEFuture *fut)
     {
         // this acts as finally block, always executed no matter what happened to the previous futures (i.e. if they succeeded or not)
         if ([fut hasError])
         {
             NSLog(@"Something failed along the way with error: %@", [[fut error] description]);
         }
         
         // code that need to be executed either way
         [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
     }];
}

- (void)runWhenAllExample
{
    JEPromise *p1 = [JEPromise new];
    JEPromise *p2 = [JEPromise new];
    JEPromise *p3 = [JEPromise new];
    
    NSArray *futures = @[p1.future,
                         p2.future,
                         p3.future,
                         [self downloadJSONWithRequest:[self createRequestWithQueryTerm:@"pizza"] withProgress:nil],
                         [self downloadJSONWithRequest:[self createRequestWithQueryTerm:@"sushi"] withProgress:nil],
                         [self saveToDisk:@{@"someKey": @"some value"} filename:@"whenAllSucceeded"]
                         ];
    JEFuture *allFuture = [JEFuture whenAll:futures];
    
    /**
     * Promise 1
     */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // pretend this is a succeeding network operation
        [p1 setResult:[NSData data]];
    });
    
    /**
     * Promise 2
     */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // pretend this is a failing network operation
        NSError *error = [NSError errorWithDomain:kPromisesDemoErrorDomain
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey: @"Network connection failed."}];
        [p2 setError:error];
    });

    /**
     * Promise 3
     */
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        // pretend this is a cancelled network operation
        [p3 setCancelled];
    });

    // this call will hang until all the futures are resolved
    NSArray *results = [allFuture result];
    NSLog(@"WhenAll: futures");
    for (JEFuture *future in results) {
        NSLog(@"%@", [future description]);
    }
}

#pragma mark - Accessor Methods

- (NSURLSession *)session
{
    if (!_session) {
        NSURLSessionConfiguration *sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
        _session = [NSURLSession sessionWithConfiguration:sessionConfig
                                                 delegate:nil
                                            delegateQueue:nil];
    }
    
    return _session;
}

#pragma mark - Helper Methods

- (NSURLRequest *)createRequestWithQueryTerm:(NSString *)queryTerm
{
    NSString *urlString = [NSString stringWithFormat:@"%@/venues/search?client_id=%@&client_secret=%@&v=20130815&ll=40.7,-74&query=%@",
                           kFoursquareBaseURL,
                           kFoursquareApiClientId,
                           kFoursquareApiClientSecret,
                           queryTerm];
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
    return request;
}

#pragma mark - Examples of wrapping async APIs

- (JEFuture *)downloadJSONWithRequest:(NSURLRequest *)request withProgress:(id<JECancellableProgressProtocol>)progress
{
    NSLog(@"[Async operation] Starting network operation.");
    
    JEPromise *p = [JEPromise new];
    
    [progress updateState:JERequestStateNetworkRequestStarted];
    
    NSURLSessionDataTask *fetchDataTask = [self.session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error)
                                           {
                                               if (!error)
                                               {
                                                   [progress updateState:JERequestStateNetworkRequestComplete];
                                                   
                                                   if (data)
                                                   {
                                                       NSLog(@"[Async operation] Network operation succeeded.");
                                                       [p setResult:data];
                                                   }
                                                   else
                                                   {
                                                       NSError *errorToUse = [NSError errorWithDomain:kPromisesDemoErrorDomain
                                                                                                 code:0
                                                                                             userInfo:@{NSLocalizedDescriptionKey: @"Data received is nil."}];
                                                       NSLog(@"[Async operation] Network operation failed.");
                                                       [p setError:errorToUse];
                                                   }
                                               }
                                               else
                                               {
                                                   [progress updateState:JERequestStateNetworkRequestFailed];
                                                   [p setError:error];
                                               }
                                           }];
    
    [fetchDataTask resume];
    
    return [p future];
}

- (JEFuture *)failingdownloadJSONWithRequest:(NSURLRequest *)request withProgress:(id<JECancellableProgressProtocol>)progress
{
    NSLog(@"[Async operation] Starting network operation.");
    
    JEPromise *p = [JEPromise new];
    
    [progress updateState:JERequestStateNetworkRequestStarted];
    
    // pretend this is an asynchronous failing network operation
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = [NSError errorWithDomain:kPromisesDemoErrorDomain
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey: @"Network connection failed."}];
        
        NSLog(@"[Async operation] Network operation failed.");

        [progress updateState:JERequestStateNetworkRequestFailed];
        [p setError:error];
    });
    
    return [p future];
}

- (JEFuture *)parseJSON:(NSData *)data
{
    JEPromise *p = [JEPromise new];
    
    NSLog(@"[Async operation] Parsing data to dictionary.");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSError *error = nil;
        NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&error];
        
        if (!error)
        {
            [p setResult:jsonDict];
        }
        else
        {
            [p setError:error];
        }
    });
    
    return [p future];
}

- (JEFuture *)failingParseJSON:(NSData *)data
{
    JEPromise *p = [JEPromise new];
    
    NSLog(@"[Async operation] Parsing data to dictionary.");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSError *error = [NSError errorWithDomain:kPromisesDemoErrorDomain
                                             code:0
                                         userInfo:@{NSLocalizedDescriptionKey: @"Cannot parse content."}];
        [p setError:error];
    });
    
    return [p future];
}

- (JEFuture *)saveToDisk:(NSDictionary *)obj filename:(NSString *)filename
{
    JEPromise *p = [JEPromise new];
    
    NSLog(@"[Async operation] Parsing data to dictionary.");
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentsDirectory = [paths objectAtIndex:0];
        NSString *path = [documentsDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", filename]];
        
        BOOL success = [obj writeToFile:path atomically:YES];
        
        if (success)
        {
            [p setResult:@1];
        }
        else
        {
            NSError *error = [NSError errorWithDomain:kPromisesDemoErrorDomain
                                                 code:0
                                             userInfo:@{NSLocalizedDescriptionKey: @"Cannot write to file."}];
            [p setError:error];
        }
    });
    
    return [p future];
}

@end
