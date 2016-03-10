//
//  Photo.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-07.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import UIKit
import CoreData

class Photo : NSManagedObject {
    
    @NSManaged var photoPath : String?
    @NSManaged var pin : Pin
    
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    
    init(imagePath : String, context: NSManagedObjectContext) {
        
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        photoPath = imagePath
    }
    
    
    var flickImage : UIImage? {
        get {
            return VTClient.Caches.imageCache.imageWithIdentifier(photoPath)
        }
        
        set {
            VTClient.Caches.imageCache.storeImage(newValue, withIdentifier: photoPath!)
        }
    }
    
}
