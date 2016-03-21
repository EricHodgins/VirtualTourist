//
//  TravelLocationsViewController.swift
//  VirtualTourist
//
//  Created by Eric Hodgins on 2016-03-01.
//  Copyright © 2016 Eric Hodgins. All rights reserved.
//

import UIKit
import MapKit
import CoreData


class TravelLocationsViewController: UIViewController, MKMapViewDelegate {
    
    @IBOutlet weak var deletePinsView: UIView!
    @IBOutlet weak var mapView: MKMapView!
    
    var finishedDraggingMapPin : Bool = true
    var originalFrame = CGRect()
    var mapViewIsEditable : Bool = false
    var pinHasFinishedDownloadingURLS : Bool = true
    
    var taskForURLDownload : NSURLSessionTask? // Get a reference to the URL downloads in case it needs to be cancelled upon pin update (when it's moved to a different location)
    var tasksForImageDataDownloads = [NSURLSessionTask]() // Get a reference to all imageData downloads for each imageURL.  These need to be cancelled upon pin update
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Load the previous map region values if any
        loadInPreviousSavedMapRegion()
        
        //Get the orignal view frame to restore back to normal whent the view is moved to show the pins can be removed
        originalFrame = self.view.frame
        
        do {
            try fetchedResultsController.performFetch()
        } catch {}
        
        addCoreDataSavedPinsToMapView()
        
        
        mapView.delegate = self
        
        // Gesture to add Pin annotation to the mapView
        let longGestureRecognizer = UILongPressGestureRecognizer(target: self, action: "addAnnotation:")
        longGestureRecognizer.minimumPressDuration = 0.75
        mapView.addGestureRecognizer(longGestureRecognizer)
        
    }
    
    
    //MARK: Download Flickr Photos
    func downloadFlickrPhotos(withLatitude latitude: Double, andLongitude longitude: Double, pin: Pin) {
        pinHasFinishedDownloadingURLS = false
        taskForURLDownload =  VTClient.sharedInstance.getPhotosFromFlick(latitude, lon: longitude, page: pin.currentPage) { (success, photoResults, pictureCount, errorString) -> Void in
            if success {
                pin.totalPictureCount = pictureCount
                for pic in photoResults! {
                    let photo = Photo(imagePath: pic["url_m"] as! String, context: self.sharedContext)
                    photo.pin = pin
                }
                
                self.pinHasFinishedDownloadingURLS = true
                
                // Notifiy on the main queue because this will ultimately update the UI (indicatorviews) in the PhotoAlbumViewController
                dispatch_async(dispatch_get_main_queue()) {
                    NSNotificationCenter.defaultCenter().postNotificationName(VTClient.NotificationKeys.finishedDownloadingURLsNotificationKey, object: self)
                }
                
                self.sharedContext.performBlock({ () -> Void in
                    CoreDataStackManager.sharedInstance.saveContext()
                    //Prefetch the matching photos
                    self.prefetchPhotosForPin(pin)
                })

            }
        }
    }
    
   
    //MARK: Pre-fetch photo data
    func prefetchPhotosForPin(pin : Pin) {
        for p in pin.photos as NSArray {
            let photo = p as! Photo
            
            let task = VTClient.sharedInstance.taskForImageDataWithURL(photo.photoPath!, completionHandler: { (imageData, error) -> Void in
                if error != nil {
                    return
                }
                
                photo.flickrImage = UIImage(data: imageData!)
            })
            
            self.tasksForImageDataDownloads.append(task)
        }
    }
    
    
    
    //MARK: Core Data
    var sharedContext : NSManagedObjectContext {
        return CoreDataStackManager.sharedInstance.managedObjectContext
    }
    
    lazy var fetchedResultsController : NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        return NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
    }()
    
    
    //MARK: Edit Button Pressed
    @IBAction func editButtonPressed(sender: AnyObject) {

        if !mapViewIsEditable {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Done, target: self, action: "editButtonPressed:")
            let editFrame = CGRectMake(view.frame.origin.x, view.frame.origin.y - deletePinsView.frame.height, view.frame.width, view.frame.height)
            UIView.animateWithDuration(0.3) { () -> Void in
                self.view.frame = editFrame
            }
        } else {
            navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Edit, target: self, action: "editButtonPressed:")
            UIView.animateWithDuration(0.3) { () -> Void in
                //TODO: when device orientation changes may need to fix this here
                self.view.frame = self.originalFrame
            }
        }
        
        mapViewIsEditable = !mapViewIsEditable
    }

}








