//
//  Flickr.swift
//  VirtualTourists
//
//  Created by xingxiaoxiong on 12/14/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation

class Flickr : NSObject {
    
    typealias CompletionHandler = (result: AnyObject!, error: NSError?) -> Void
    
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // MARK: - All purpose task method for data
    
    func taskForResource(parameters: [String : AnyObject], completionHandler: CompletionHandler) -> NSURLSessionDataTask {
        
        var mutableParameters = parameters
        
        // Add in the parameters
        mutableParameters["api_key"] = Constants.ApiKey
        mutableParameters["method"] = Constants.SearchPhotoMethod
        mutableParameters["nojsoncallback"] = "1"
        
        let urlString = Constants.BaseUrlSSL + Flickr.escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            guard (downloadError == nil) else {
                let error = NSError(domain: "Network connection error!", code: 0, userInfo: nil)
                completionHandler(result: nil, error: error)
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    let error = NSError(domain: "Your request returned an invalid response! Status code: \(response.statusCode)!", code: 0, userInfo: nil)
                    completionHandler(result: nil, error: error)
                } else if let response = response {
                    let error = NSError(domain: "Your request returned an invalid response! Response: \(response)!", code: 0, userInfo: nil)
                    completionHandler(result: nil, error: error)
                } else {
                    let error = NSError(domain: "Your request returned an invalid response!", code: 0, userInfo: nil)
                    completionHandler(result: nil, error: error)
                }
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "No data was returned by the request!", code: 0, userInfo: nil)
                completionHandler(result: nil, error: error)
                return
            }
            
            Flickr.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
            
        }
        
        task.resume()
        
        return task
    }
    
    // MARK: - All purpose task method for images
    
    func taskForImage(filePath: String, completionHandler: (imageData: NSData?, error: NSError?) ->  Void) -> NSURLSessionTask {
                
        let url = NSURL(string: filePath)!
        
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) {data, response, downloadError in
            
            if let error = downloadError {
                let newError = Flickr.errorForData(data, response: response, error: error)
                completionHandler(imageData: nil, error: newError)
            } else {
                completionHandler(imageData: data, error: nil)
            }
        }
        
        task.resume()
        
        return task
    }
    
    // MARK: - Shared Instance
    
    class func sharedInstance() -> Flickr {
        
        struct Singleton {
            static var sharedInstance = Flickr()
        }
        
        return Singleton.sharedInstance
    }
    
    // Parsing the JSON
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler: CompletionHandler) {
        var parsingError: NSError? = nil
        
        let parsedResult: AnyObject?
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: NSJSONReadingOptions.AllowFragments)
        } catch let error as NSError {
            parsingError = error
            parsedResult = nil
        }
        
        if let error = parsingError {
            completionHandler(result: nil, error: error)
        } else {
            completionHandler(result: parsedResult, error: nil)
        }
    }
    
    // URL Encoding a dictionary into a parameter string
    
    class func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            // make sure that it is a string value
            let stringValue = "\(value)"
            
            // Escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Append it
            
            if let unwrappedEscapedValue = escapedValue {
                urlVars += [key + "=" + "\(unwrappedEscapedValue)"]
            } else {
                print("Warning: trouble excaping string \"\(stringValue)\"")
            }
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    class func errorForData(data: NSData?, response: NSURLResponse?, error: NSError) -> NSError {
        
        if data == nil {
            return error
        }
        
        do {
            let parsedResult = try NSJSONSerialization.JSONObjectWithData(data!, options: NSJSONReadingOptions.AllowFragments)
            
            if let parsedResult = parsedResult as? [String : AnyObject], errorMessage = parsedResult[Flickr.Keys.ErrorStatusMessage] as? String {
                let userInfo = [NSLocalizedDescriptionKey : errorMessage]
                return NSError(domain: "Flickr Error", code: 1, userInfo: userInfo)
            }
            
        } catch _ {}
        
        return error
    }
    
    struct Caches {
        static let imageCache = ImageCache()
    }
    
    static func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        
        /* Fix added to ensure box is bounded by minimum and maximums */
        let bottom_left_lon = max(longitude - Constants.BOUNDING_BOX_HALF_WIDTH, Constants.LON_MIN)
        let bottom_left_lat = max(latitude - Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MIN)
        let top_right_lon = min(longitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LON_MAX)
        let top_right_lat = min(latitude + Constants.BOUNDING_BOX_HALF_HEIGHT, Constants.LAT_MAX)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
}