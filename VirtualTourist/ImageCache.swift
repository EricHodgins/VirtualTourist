//
//  ImageCache.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-10.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import Foundation
import UIKit

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    //MARK: Get images
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        
        if identifier == nil || identifier == "" {
            return nil
        }
        
        let path = pathForIdentifier(identifier!)
        
        // In memory Cache already?
        
        if let image = inMemoryCache.objectForKey(path) as? UIImage {
            return image
        }
        
        // If not, on Hard drive?
        if let data = NSData(contentsOfFile: path) {
            return UIImage(data: data)
        }
        
        return nil
        
    }
    
    
    //MARK: Save Images
    func storeImage(image: UIImage?, withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)
        
        if image == nil {
            inMemoryCache.removeObjectForKey(path)
            
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch _ {}
            
            return
        }
        
        // Keep image in memory
        inMemoryCache.setObject(image!, forKey: path)

        //And keep in documents directory
        let data = UIImagePNGRepresentation(image!)!
        data.writeToFile(path, atomically: true)
    }
    
    
    
    //MARK: Helper - file path
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL.path!
    }
}
