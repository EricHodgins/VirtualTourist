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
        static let FLICKR_API_KEY = "6f4f8287167e3952d30637004ae2c4a7"
    }
    
    //MARK: Parameter Keys 
    struct ParameterKeys {
        static let latitude = "lat"
        static let longitude = "lon"
        static let extras = "extras"
        static let format = "format"
        static let nojsoncallback = "nojsoncallback"
    }
}