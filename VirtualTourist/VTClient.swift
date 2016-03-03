//
//  VTClient.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-02.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import Foundation

class VTClient {
    
    var session : NSURLSession
    
    // Setup Singleton instance
    static let sharedInstance = VTClient()
    
    //prevent others from using the class
    private init() {
        session = NSURLSession.sharedSession()
    }
    
    
    //MARK: Parse JSON Data
    
    class func parseJSONWithCompletionHandler(data: NSData, completionHandler:(result : AnyObject!, error: NSError?) -> Void) {
        
        var parsedResult : AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse JSON data: \(data)"]
            completionHandler(result: nil, error: NSError(domain: "parseJSONWithCompletionHandler", code: 0, userInfo: userInfo))
            return
        }
        
        completionHandler(result: parsedResult, error: nil)
    }
    
}