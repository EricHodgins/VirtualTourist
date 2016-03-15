//
//  VTConvenience.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-03.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import Foundation

extension VTClient {
    
    //MARK: GET
    
    //Get photos from flickr
    func getPhotosFromFlick(lat : Double, lon : Double, page : Int, completionHandler: (success: Bool, results: [[String : AnyObject]]?, pictureCount: Int, errorString: String?) -> Void) {
        
        // setup the parameters
        let parameters: [String : AnyObject] = [
            VTClient.ParameterKeys.apiKey : VTClient.Constants.FLICKR_API_KEY,
            VTClient.ParameterKeys.latitude : lat,
            VTClient.ParameterKeys.longitude : lon,
            VTClient.ParameterKeys.extras : VTClient.Constants.FLICKR_PIC_URL_SHORTCUT,
            VTClient.ParameterKeys.perPage : VTClient.Constants.FLICKR_PER_PAGE,
            VTClient.ParameterKeys.page : page,
            VTClient.ParameterKeys.format : "json",
            VTClient.ParameterKeys.nojsoncallback : "1"
        ]
        
        taskForFlickrGETPhotos(VTClient.Methods.FlickrSearch, parameters: parameters) { (JSONResults, error) -> Void in
            if let error = error {
                completionHandler(success: false, results: nil, pictureCount: 0, errorString: error.localizedDescription)
                return
            }
            
            
            if let results = JSONResults["photos"] as? [String : AnyObject] {
                let max = results["total"] as? String
                print("max photos results = \(max)")
                if let photos = results["photo"] as? [[String : AnyObject]] {
                    completionHandler(success: true, results: photos, pictureCount: Int(max!)!, errorString: nil)
                    return
                }
            }
            
            completionHandler(success: false, results: nil, pictureCount: 0, errorString: "Could not get JSON data from Flickr for pictures")
        }
        
        
    }
    
    
    func taskForFlickrGETPhotos(method: String, parameters : [String : AnyObject], completionHandler: (results: AnyObject!, error: NSError?) -> Void) -> NSURLSessionTask {
        
        let urlString : String = VTClient.Constants.FLICKR_BASE_URL + "?" + method + "&" + VTClient.escapedParameters(parameters)
        let url = NSURL(string: urlString)!
        
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            //Guard Error
            guard error == nil else {
                completionHandler(results: nil, error: NSError(domain: "taskForFlickrGETPhotos", code: 0, userInfo: [NSLocalizedDescriptionKey : "\(error?.localizedDescription)"]))
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                completionHandler(results: nil, error: NSError(domain: "taskForFlickrGETPhotos", code: 0, userInfo: [NSLocalizedDescriptionKey : "Bad status code: \(response)"]))
                return
            }
            
            
            guard let data = data else {
                completionHandler(results: nil, error: NSError(domain: "taskForFlickrGETPhotos", code: 0, userInfo: [NSLocalizedDescriptionKey : "Unable get valid Flickr data"]))
                return
            }
            
            VTClient.parseJSONWithCompletionHandler(data, completionHandler: completionHandler)
            
        }
        
        task.resume()
        return task
    }
    
    
    
    func taskForImageDataWithURL(imageURL: String, completionHandler: (imageData: NSData?, error: NSError?) -> Void) -> NSURLSessionDataTask {
        let url = NSURL(string: imageURL)!
        
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            if error != nil {
                completionHandler(imageData: nil, error: NSError(domain: "taskForImageDataWithURL", code: 0, userInfo: [NSLocalizedDescriptionKey : "could not get image data: \(error?.localizedDescription)"]))
                return
            }
            
            guard let data = data else {
                completionHandler(imageData: nil, error: NSError(domain: "taskForImageDataWithURL", code: 0, userInfo: [NSLocalizedDescriptionKey : "image data invalid."]))
                return
            }
            
            completionHandler(imageData: data, error: nil)
            
        }
        
        task.resume()
        
        return task
    }
    
}