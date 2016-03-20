//
//  MapRegion.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-19.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import Foundation
import MapKit

class MapRegion: NSObject, NSCoding {
    
    struct Keys {
        static let latitude = "latitude"
        static let longitude = "longitude"
        static let latitudeDelta = "latitudeDelta"
        static let longitudeDelta = "longitudeDelta"
    }
    
    
    var latitude = CLLocationDegrees()
    var longitude = CLLocationDegrees()
    var latitudeDelta = CLLocationDegrees()
    var longitudeDelta = CLLocationDegrees()
    
    init(lat : CLLocationDegrees, lon : CLLocationDegrees, latDelta: CLLocationDegrees, lonDelta: CLLocationDegrees) {
        
        latitude = lat
        longitude = lon
        latitudeDelta = latDelta
        longitudeDelta = lonDelta
    }
    
    var center : CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    var span : MKCoordinateSpan {
        return MKCoordinateSpan(latitudeDelta: latitudeDelta, longitudeDelta: longitudeDelta)
    }
    
    var region : MKCoordinateRegion {
        return MKCoordinateRegion(center: center, span: span)
    }
    
    class var filePath : String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        return url.URLByAppendingPathComponent("mapRegionSavedData").path!
    }
    
    
    //MARK: NSCoding Protocol
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeObject(latitude, forKey: Keys.latitude)
        aCoder.encodeObject(longitude, forKey: Keys.longitude)
        aCoder.encodeObject(latitudeDelta, forKey: Keys.latitudeDelta)
        aCoder.encodeObject(longitudeDelta, forKey: Keys.longitudeDelta)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init()
        
        latitude = aDecoder.decodeObjectForKey(Keys.latitude) as! CLLocationDegrees
        longitude = aDecoder.decodeObjectForKey(Keys.longitude) as! CLLocationDegrees
        latitudeDelta = aDecoder.decodeObjectForKey(Keys.latitudeDelta) as! CLLocationDegrees
        longitudeDelta = aDecoder.decodeObjectForKey(Keys.longitudeDelta) as! CLLocationDegrees
    }
    
    
    
}