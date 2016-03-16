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
    
    
    var flickrImage : UIImage? {
        get {
            let url = NSURL(string: photoPath!)!
            let path = url.lastPathComponent!
            return VTClient.Caches.imageCache.imageWithIdentifier(path)
        }
        
        set {
            let url = NSURL(string: photoPath!)!
            let path = url.lastPathComponent!
            VTClient.Caches.imageCache.storeImage(newValue, withIdentifier: path)
        }
    }
    
    
    override func prepareForDeletion() {
        let fileManager = NSFileManager.defaultManager()
        let fullPath = getPathToImageDataInDocumentsDirectory()
        
        do {
            try fileManager.removeItemAtPath(fullPath)
        } catch {
            print("Unable to delete image files in documentary folder...the image may not of finished downloading")
        }
    }
    
    
    //MARK: Helper method
    func getPathToImageDataInDocumentsDirectory() -> String {
        let url = NSURL(string: photoPath!)!
        let path = url.lastPathComponent!
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(path)

        return fullURL.path!
    }
    
}
