//
//  VTConstants.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-03.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import Foundation

extension VTClient {
    
    //MARK: Constants
    struct Constants {
        static let FLICKR_BASE_URL = "https://api.flickr.com/services/rest/"
        static let FLICKR_API_KEY = "d5c77bcf5997864103340b3743519aed"
        static let FLICKR_PIC_URL_SHORTCUT = "url_m"
        static let FLICKR_PER_PAGE = 21
    }
    
    //MARK: Parameter Keys 
    struct ParameterKeys {
        static let apiKey = "api_key"
        static let latitude = "lat"
        static let longitude = "lon"
        static let extras = "extras"
        static let format = "format"
        static let page = "page"
        static let perPage = "per_page"
        static let nojsoncallback = "nojsoncallback"
    }
    
    
    //MARK: Methods
    struct Methods {
        static let FlickrSearch = "method=flickr.photos.search"
    }
    
    struct NotificationKeys {
        static let finishedDownloadingURLsNotificationKey = "com.erichodgins.finishedDownloadingURLsNotificationKey"
    }
}