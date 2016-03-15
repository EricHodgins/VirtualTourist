//
//  Pin.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-07.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import CoreData
import MapKit

class Pin : NSManagedObject, MKAnnotation {
    
    @NSManaged var longitude : NSNumber
    @NSManaged var latitude : NSNumber
    @NSManaged var totalPictureCount : Int
    @NSManaged var photos : [Photo]
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    
    init(lat: Double, lon: Double, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = NSNumber(double: lat)
        longitude = NSNumber(double: lon)

    }
    
    var coordinate : CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude as Double, longitude: longitude as Double)
    }
    
    var title : String? {
        return "\(latitude), \(longitude)"
    }
    
    func setCoordinate(newCoordinate: CLLocationCoordinate2D) {
        latitude = newCoordinate.latitude
        longitude = newCoordinate.longitude
    }
    
}
