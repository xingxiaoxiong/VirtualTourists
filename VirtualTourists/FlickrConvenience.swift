//
//  FlickrConvenience.swift
//  VirtualTourists
//
//  Created by xingxiaoxiong on 12/15/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation

extension Flickr {
    
    func getPhotoUrls(latitude: Double, longitude: Double, completionHandler: CompletionHandler) {
        
        var parameters = [
            "bbox": Flickr.createBoundingBoxString(latitude, longitude: longitude),
            "safe_search": Flickr.Constants.SAFE_SEARCH,
            "extras": Flickr.Constants.EXTRAS,
            "format": Flickr.Constants.DATA_FORMAT,
            "per_page": Flickr.Constants.PhotosPerPage
        ]
        
        Flickr.sharedInstance().taskForResource(parameters, completionHandler: { (parsedResult, error) -> Void in
            
            if let error = error {
                completionHandler(result: nil, error: error)
            } else {
                
                guard let stat = parsedResult["stat"] as? String where stat == "ok" else {
                    let error = NSError(domain: "Flickr API returned an error. See error code and message in \(parsedResult)", code: 0, userInfo: nil)
                    completionHandler(result: nil, error: error)
                    return
                }
                
                guard let photosDictionary = parsedResult["photos"] as? NSDictionary else {
                    let error = NSError(domain: "Cannot find keys 'photos' in \(parsedResult)", code: 0, userInfo: nil)
                    completionHandler(result: nil, error: error)
                    return
                }
                
                guard let totalPages = photosDictionary["pages"] as? Int else {
                    let error = NSError(domain: "Cannot find key 'pages' in \(photosDictionary)", code: 0, userInfo: nil)
                    completionHandler(result: nil, error: error)
                    return
                }
                
                let pageLimit = min(totalPages, 40)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                
                parameters["page"] = String(randomPage)
                
                Flickr.sharedInstance().taskForResource(parameters, completionHandler: completionHandler)
            }
        })

    }
}