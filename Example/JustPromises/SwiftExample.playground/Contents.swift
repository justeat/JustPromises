//: Playground - noun: a place where people can play

import Foundation
import PlaygroundSupport
import JustPromises

PlaygroundPage.current.needsIndefiniteExecution = true

let session = URLSession(configuration: .default)

// MARK: Request Builder Methods

let foursquareBaseURL = "https://api.foursquare.com/v2/"
let foursquareApiClientId = "ED233ZBBNC2IF4VHMAKE1CTARX44OJOGKRTAW34ISQLPT0HE"
let foursquareApiClientSecret = "OYPK3LZEXLSDQE1IG4RM5JXBX1D54W0PUCXFJL4CHLCIKU4H"

// MARK: Request Builder

func createFoursquareRequest(withQuery query: String) -> URLRequest {
    
    let urlString = "\(foursquareBaseURL)/venues/search?client_id=\(foursquareApiClientId)&client_secret=\(foursquareApiClientSecret)&v=20130815&ll=40.7,-74&query=\(query)"
    
    let url = URL(string: urlString)!
    return URLRequest(url: url)
}

// MARK: Example of Wrapping Async APIs

enum DownloadError: Error {
    case noResponseData
}

func downloadJSON(with request: URLRequest) -> Promise<Data> {
    
    return Promise<Data> { promise in
        
        let fetchDataTask = session.dataTask(with: request) { (data, response, error) in
            
            switch (data, error) {
                
            case (let data?, _):
                promise.futureState = .result(data)
                
            case (nil, let error?):
                promise.futureState = .error(error)
                
            case (nil, nil):
                promise.futureState = .error(DownloadError.noResponseData)
            }
        }
        fetchDataTask.resume()
    }
}

enum ParseError: Error {
    case dataNotAJSONObject
}

func parseJSONDataToDictionary(from downloadPromise: Promise<Data>) -> Promise<[String: AnyObject]> {
    
    return Promise<[String: AnyObject]> { promise in
        
        switch downloadPromise.futureState {
            
        case .unresolved:
            promise.futureState = .unresolved
            
        case .cancelled:
            promise.futureState = .cancelled
            
        case .error(let error):
            promise.futureState = .error(error)
            
        case .result(let downloadedData):
            
            do {
                if let parsedJSON = try JSONSerialization.jsonObject(with: downloadedData, options: []) as? [String: AnyObject] {
                    promise.futureState = .result(parsedJSON)
                } else {
                    promise.futureState = .error(ParseError.dataNotAJSONObject)
                }
            } catch {
                promise.futureState = .error(error)
            }
        }
    }
}

struct Venue {
    let id: String
    let name: String
}

enum MappingError: Error {
    case previousPromiseDidNotReturnResult
    case unexpectedResponse
}

func mapToVenue(from parsedPromise: Promise<[String: AnyObject]>) -> Promise<[Venue]> {
    
    return Promise<[Venue]> { promise in
        
        guard let parsedDictionary = parsedPromise.futureState.result else {
            promise.futureState = .error(MappingError.previousPromiseDidNotReturnResult)
            return
        }
        
        print(parsedDictionary)
        
        guard
            let response = parsedDictionary["response"] as? [String: Any],
            let venuesArray = response["venues"] as? [[String: Any]] else {
            
                promise.futureState = .error(MappingError.unexpectedResponse)
                return
        }
        
        let venues = venuesArray.flatMap { dictionary -> Venue? in
            
            guard let id = dictionary["id"] as? String, let name = dictionary["name"] as? String else {
                return nil
            }
            return Venue(id: id, name: name)
        }
        
        promise.futureState = .result(venues)
    }
    
}

// MARK: Use Promises to Search for restaurants

let request = createFoursquareRequest(withQuery: "sushi")

let downloadPromise = downloadJSON(with: request)
downloadPromise.retryCount = 3 // If results in error, retry up to 3 times before giving up
downloadPromise.retryDelay = 2.0 // Leave 2 seconds in between each retry

downloadPromise.await().continuation { downloadPromise in
    
    return parseJSONDataToDictionary(from: downloadPromise)
    
    }.continuation { (parsedPromise) in
        
        return mapToVenue(from: parsedPromise)
        
    }.continuationWithResult(onQueue: .main) { venues in
        
        print("Number of sushi restaurants: \(venues.count)")
        
    }.continuationWithError() { error in
        
        print("There was an error: \(error)")
        
    }.continuation(onQueue: .main) { _ in
        
        PlaygroundPage.current.finishExecution()
}
