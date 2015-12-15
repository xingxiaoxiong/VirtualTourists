//
//  Flickr-constants.swift
//  VirtualTourists
//
//  Created by xingxiaoxiong on 12/15/15.
//  Copyright © 2015 Udacity. All rights reserved.
//

import Foundation

extension Flickr {
    
    struct Constants {
        
        // MARK: - URLs
        static let ApiKey = "99b630fe6ac1d13553ef621a949538d4"
        static let BaseUrlSSL = "https://api.flickr.com/services/rest/"
        
        static let SearchPhotoMethod = "flickr.photos.search"
        
        static let BOUNDING_BOX_HALF_WIDTH = 1.0
        static let BOUNDING_BOX_HALF_HEIGHT = 1.0
        static let LAT_MIN = -90.0
        static let LAT_MAX = 90.0
        static let LON_MIN = -180.0
        static let LON_MAX = 180.0
        
        static let EXTRAS = "url_m"
        static let SAFE_SEARCH = "1"
        static let DATA_FORMAT = "json"
    }
    
    struct Keys {
        static let ID = "id"
        static let ErrorStatusMessage = "status_message"
        static let ConfigBaseImageURL = "base_url"
        static let ConfigSecureBaseImageURL = "secure_base_url"
        static let ConfigImages = "images"
        static let ConfigPosterSizes = "poster_sizes"
        static let ConfigProfileSizes = "profile_sizes"
    }
    
}